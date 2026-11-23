local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldRecruit = require "verbs/recruit"
local Utils = require "utils"
local UnitState = require "unit_state"
local GotC = require "gotc"

local Recruit = Verb:new()


function Recruit.init()
    Recruit.oldExecute = OldRecruit.execute
    OldRecruit.execute = Recruit.execute
end

function Recruit:execute(unit, targetPos, strParam, path)

    local uc = Wargroove.getUnitClass(strParam)
    local recruiter = Wargroove.getUnitClass(unit.unitClassId, unit.id)

    local recruitDiscount = 1.0
    if Wargroove.isInList(strParam, unit.recruitDiscounts) then
        recruitDiscount = unit.recruitDiscountMultiplier
    end

    local unitCost = -(uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount)
    Recruit:oldExecute(unit, targetPos, strParam, path)
    GotC.addExpectedGoldToPlayer(unit.playerId, unitCost)
end


return Recruit
