local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"

local Triggers = {}

function Triggers.getGotCInit()
    local trigger = {}
    trigger.id =  "GotC Init"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "start_of_match"
    trigger.players = { 1, 0, 0, 0, 0, 0, 0, 0 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.actions, { id = "gotc_init", parameters = { }, enabled = true })
    
    return trigger
end

function Triggers.getGotCRepeat()
    local trigger = {}
    trigger.id =  "GotC Repeat"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 0, 0, 0, 0 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "start_of_turn", parameters = { }, enabled = true  })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" }, enabled = true })
    table.insert(trigger.actions, { id = "gotc_repeat", parameters = { }, enabled = true })

    return trigger
end

function Triggers.getGotCStrongholdKill()
    local trigger = {}
    trigger.id =  "GotC Stronghold Kill"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 0, 0, 0, 0 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "unit_lost", parameters = { "hq", "current", "-1" }, enabled = true })
    table.insert(trigger.actions, { id = "gotc_kill_hq", parameters = { "current" }, enabled = true })

    return trigger
end

function Triggers.getGotCCOKill()
    local trigger = {}
    trigger.id =  "GotC CO Kill"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 0, 0, 0, 0 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "unit_lost", parameters = { "*commander", "current", "-1" }, enabled = true })
    table.insert(trigger.actions, { id = "gotc_kill_commander", parameters = { "current" }, enabled = true })

    return trigger
end

return Triggers