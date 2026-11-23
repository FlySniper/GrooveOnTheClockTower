local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local GotC = require "gotc"
local Confuse_P1 = require "verbs/choose_p1"

local Confuse_P4 = Confuse_P1:new()

Confuse_P4:setChosenPlayer(3)


return Confuse_P4