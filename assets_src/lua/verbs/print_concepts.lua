local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local GotC = require "gotc"

local PrintConcepts = Verb:new()

function PrintConcepts:getMaximumRange(unit, endPos)
    return 0
end


function PrintConcepts:getTargetType()
    return "unit"
end

function PrintConcepts:canExecuteAnywhere(unit)
    return true
end


function PrintConcepts:execute(unit, targetPos, strParam, path)
    GotC.privateMessage(unit.playerId, "Terms:")
    GotC.conceptDescriptions(unit.playerId)
end

function PrintConcepts:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
    Wargroove.updateUnit(unit)
end

return PrintConcepts
