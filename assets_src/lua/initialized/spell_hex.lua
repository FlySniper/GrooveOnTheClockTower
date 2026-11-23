local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldSpellHex = require "verbs/spell_hex"
local GotC = require "gotc"

local SpellHex = Verb:new()

function SpellHex.init()
    SpellHex.oldExecute = OldSpellHex.execute
    SpellHex.calculateSpellCost = OldSpellHex.calculateSpellCost
    OldSpellHex.execute = SpellHex.execute
end

function SpellHex:execute(unit, targetPos, strParam, path)
    GotC.addExpectedGoldToPlayer(unit.playerId, -OldSpellHex:calculateSpellCost(unit))
    SpellHex:oldExecute(unit, targetPos, strParam, path)
end


return SpellHex
