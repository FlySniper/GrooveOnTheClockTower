local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldReinforce = require "verbs/reinforce"
local GotC = require "gotc"


--------------------
local conversionRate = 1       -- Every health point taken from city becomes <this value> for unit
local minCityHealthAfter = 1   -- minimum % of health left on city after action
local maxUnitHealth = 100      -- maximum % of health that the unit can achieve
--------------------


local Reinforce = Verb:new()

function Reinforce.init()
    Reinforce.oldExecute = OldReinforce.execute
    OldReinforce.execute = Reinforce.execute
    OldReinforce.getHealAndCost = Reinforce.getHealAndCost
    OldReinforce.canExecuteAt = Reinforce.canExecuteAt
end

local function getHealingAvailableFrom(city)
    return math.floor((city.health - minCityHealthAfter) * conversionRate + 0.5)
end


local function getSurroundingCities(unit, pos)
    result = {}
    for i, p in ipairs(Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")) do
        local city = Wargroove.getUnitAt(p)
        if city and city.unitClass.canReinforce and Wargroove.areAllies(unit.playerId, city.playerId) then
            table.insert(result, city)
        end
    end
    return result
end


local function getHealingAvailableAt(unit, pos)
    local healingAvailable = 0
    for i, city in ipairs(getSurroundingCities(unit, pos)) do
        healingAvailable = healingAvailable + getHealingAvailableFrom(city)
    end
    return healingAvailable
end

local function getReinforceMultiplierAt(unit, pos)
    local reinforceMultiplier = 1.0
    for i, city in ipairs(getSurroundingCities(unit, pos)) do
        reinforceMultiplier = math.min(reinforceMultiplier, city.unitClass.reinforceMultiplier)
    end
    return reinforceMultiplier
end


local function getHealingCost(health, unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId, unit.id).cost
    return math.ceil(health * fullCost / 100)
end


local function getAffordableHealing(unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId, unit.id).cost
    return math.floor(GotC.getExpectedGoldFromPlayer(unit.playerId) * 100 / fullCost)
end


function Reinforce:canExecuteAt(unit, endPos)
    local desiredHealing = maxUnitHealth - unit.health
    if desiredHealing == 0 then
        return false
    end

    if getHealingCost(1, unit) > GotC.getExpectedGoldFromPlayer(unit.playerId) then
        return false
    end

    if not Verb.canExecuteAt(self, unit, endPos) then
        return false
    end

    return getHealingAvailableAt(unit, endPos) > 0
end


function Reinforce:getHealAndCost(unit, targetPos)
    local desiredHealing = maxUnitHealth - unit.health
    local availableHealing = getHealingAvailableAt(unit, targetPos)
    local affordableHealing = getAffordableHealing(unit)
    local reinforceMultiplier = getReinforceMultiplierAt(unit, targetPos)

    local toHeal = math.min(math.min(desiredHealing, availableHealing), affordableHealing)
    local cost = getHealingCost(toHeal, unit) * reinforceMultiplier

    return toHeal, cost
end


function Reinforce:execute(unit, targetPos, strParam, path)
    local toHeal, cost = self:getHealAndCost(unit, targetPos)
    GotC.addExpectedGoldToPlayer(unit.playerId, -cost)
    Reinforce:oldExecute(unit, targetPos, strParam, path)
end


return Reinforce
