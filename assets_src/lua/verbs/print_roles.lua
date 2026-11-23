local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local GotC = require "gotc"

local PrintRoles = Verb:new()

function PrintRoles:getMaximumRange(unit, endPos)
    return 0
end


function PrintRoles:getTargetType()
    return "unit"
end

function PrintRoles:canExecuteAnywhere(unit)
    return true
end


function PrintRoles:execute(unit, targetPos, strParam, path)
    GotC.privateMessage(unit.playerId, "Villager roles:")
    for i,v in ipairs(GotC.VILLAGE_ROLES) do
        GotC.villageRoleDescription(unit.playerId, v)
    end
    GotC.privateMessage(unit.playerId, "Minion roles:")
    for i,v in ipairs(GotC.MINION_ROLES) do
        GotC.minionRoleDescription(unit.playerId, v)
    end
    GotC.privateMessage(unit.playerId, "Demon roles:")
    for i,v in ipairs(GotC.DEMON_ROLES) do
        GotC.demonRoleDescription(unit.playerId, v)
    end
    local role = GotC.getRole(unit.playerId)
    if GotC.isVillager(unit.playerId) then
        GotC.privateMessage(unit.playerId, "You are a villager. Your role is " .. role)
    end
    if GotC.isMinion(unit.playerId) then
        GotC.privateMessage(unit.playerId, "You are a minion. Your role is " .. role)
    end
    if GotC.isDemon(unit.playerId) then
        GotC.privateMessage(unit.playerId, "You are a demon. Your role is " .. role)
    end
end

function PrintRoles:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
    Wargroove.updateUnit(unit)
end

return PrintRoles
