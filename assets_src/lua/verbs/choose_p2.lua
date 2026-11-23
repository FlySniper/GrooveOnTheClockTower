local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local GotC = require "gotc"
local Confuse_P1 = require "verbs/choose_p1"

local Confuse_P2 = Confuse_P1:new()

Confuse_P2:setChosenPlayer(1)


return Confuse_P2
