local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local GotC = require "gotc"

local PrintRole = Verb:new()

function PrintRole:getMaximumRange(unit, endPos)
    return 0
end


function PrintRole:getTargetType()
    return "unit"
end

function PrintRole:canExecuteAnywhere(unit)
    return true
end


function PrintRole:execute(unit, targetPos, strParam, path)
    local role = GotC.getRole(unit.playerId)
    if GotC.isVillager(unit.playerId) then
        GotC.privateMessage(unit.playerId, "You are a villager. Your role is " .. role)
        GotC.villageRoleDescription(unit.playerId, role)
    end
    if GotC.isMinion(unit.playerId) then
        GotC.privateMessage(unit.playerId, "You are a minion. Your role is " .. role)
        GotC.minionRoleDescription(unit.playerId, role)
    end
    if GotC.isDemon(unit.playerId) then
        GotC.privateMessage(unit.playerId, "You are a demon. Your role is " .. role)
        GotC.demonRoleDescription(unit.playerId, role)
    end
end

function PrintRole:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
    Wargroove.updateUnit(unit)
end

return PrintRole
