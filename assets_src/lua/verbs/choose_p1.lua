local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local GotC = require "gotc"

local Choose_P1 = Verb:new()

Choose_P1.CHOSEN_PLAYER = 0

function Choose_P1:setChosenPlayer(playerId)
    self.CHOSEN_PLAYER = playerId
end
Choose_P1:setChosenPlayer(0)
function Choose_P1:getMaximumRange(unit, endPos)
    return 0
end


function Choose_P1:getTargetType()
    return "unit"
end

function Choose_P1:canExecuteAnywhere(unit)
    local turnNumber = Wargroove.getTurnNumber()
    local stateUnit = GotC.findUnitState(unit.playerId)
    local canChoose = Utils.toStringNil(Wargroove.getUnitState(stateUnit, "canChoose")) ~= "false"
    local lastChoice = Wargroove.getUnitState(stateUnit, "lastTurnChosen")
    if lastChoice == nil then
        lastChoice = 0
    else
        lastChoice = tonumber(lastChoice)
    end
    local role = GotC.getRole(unit.playerId)

    if (role == "Guardian" or role == "Agent" or role == "Fool" or role == "Gravekeeper" or role == "Cheater") then
        return false
    elseif role == "Marksman" and turnNumber > 10 then
        return false
    elseif role == "Investigator" and turnNumber < 5 then
        return false
    elseif role == "Santa" and (turnNumber % 5) ~= 0 then
        return false
    elseif role == "Spy" and turnNumber < 5 then
        return false
    elseif role == "Burglar" and (turnNumber % 5) ~= 0 then
        return false
    elseif role == "Vampire" and turnNumber < 5 then
        return false
    end
    return unit.playerId ~= self.CHOSEN_PLAYER and lastChoice < turnNumber and canChoose
end


function Choose_P1:execute(unit, targetPos, strParam, path)
    local turnNumber = Wargroove.getTurnNumber()
    local stateUnit = GotC.findUnitState(unit.playerId)
    Wargroove.setUnitState(stateUnit, "lastTurnChosen", tostring(turnNumber))
    Wargroove.updateUnit(stateUnit)

    local targetPlayer = self.CHOSEN_PLAYER
    if GotC.getConfused(unit.playerId) then
        local str = "Confuser " .. tostring(Wargroove.getTurnNumber()) .. tostring(Wargroove.getCurrentPlayerId()) .. "1"
        targetPlayer = (targetPlayer + Wargroove.randomInteger(str, 1, 3)) % 4
        str = str .. "2"
    end
    local role = GotC.getRole(unit.playerId)
    if role == "Marksman" then
        GotC.marksmanChoose(unit.playerId, targetPlayer)
    elseif role == "Investigator"  then
        GotC.investigate(unit.playerId, targetPlayer, "choose_p1")
    elseif role == "Santa" then
        GotC.bankGold(targetPlayer, unit.playerId, 900, turnNumber + 1)
    elseif role == "Spy" then
        GotC.investigateSpy(unit.playerId, targetPlayer, "choose_p1")
    elseif role == "Burglar" then
        GotC.bankGold(targetPlayer, unit.playerId, -300, turnNumber + 1)
        GotC.bankGold(unit.playerId, targetPlayer, 300, turnNumber + 1)
    elseif role == "Vampire" then
        GotC.bankGold(targetPlayer, unit.playerId, -300, turnNumber + 1)
        GotC.bankGold(unit.playerId, targetPlayer, 300, turnNumber + 1)
        local stateUnit = GotC.findUnitState(unit.playerId)
        Wargroove.setUnitState(stateUnit, "canChoose", "false")
        Wargroove.updateUnit(stateUnit)
    elseif role == "Mystic" or role == "Cultist" then
        GotC.setConfused(targetPlayer, true, unit.playerId)
    end
    GotC.setConfused(unit.playerId, false)
end

function Choose_P1:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
    Wargroove.updateUnit(unit)
end

return Choose_P1
