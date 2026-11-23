local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local OldTeleportBeam = require "verbs/groove_teleport_beam"
local GotC = require "gotc"

local TeleportBeam = GrooveVerb:new()

local costMultiplier = { 1.0, 0.0 }

function TeleportBeam.init()
    TeleportBeam.oldExecute = OldTeleportBeam.execute
    OldTeleportBeam.execute = TeleportBeam.execute
end

function getCost(tier, cost)
    return math.floor(cost * costMultiplier[tier] + 0.5)
end

function TeleportBeam:execute(unit, targetPos, strParam, path)
    local tier = OldTeleportBeam:getCurrentGrooveTier(unit)
    local uc = Wargroove.getUnitClass(strParam)
    GotC.addExpectedGoldToPlayer(unit.playerId, -getCost(tier, uc.cost))
    TeleportBeam:oldExecute(unit, targetPos, strParam, path)
end


return TeleportBeam
