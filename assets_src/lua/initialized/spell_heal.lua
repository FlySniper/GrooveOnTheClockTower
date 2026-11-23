local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldSpellHeal = require "verbs/spell_heal"
local GotC = require "gotc"

local SpellHeal = Verb:new()

function SpellHeal.init()
    SpellHeal.oldExecute = OldSpellHeal.execute
    OldSpellHeal.execute = SpellHeal.execute
end

function SpellHeal:execute(unit, targetPos, strParam, path)
    GotC.addExpectedGoldToPlayer(unit.playerId, -OldSpellHeal:calculateSpellCost(unit))
    SpellHeal:oldExecute(unit, targetPos, strParam. path)
end

return SpellHeal
