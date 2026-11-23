local Wargroove = require "wargroove/wargroove"
local UnitState = require "unit_state"
local Utils = require("utils")
local GotC = {}

GotC.DEBUG = false
GotC.p1StateUnitPos = { x = -51, y = -66 }
GotC.p2StateUnitPos = { x = -52, y = -66 }
GotC.p3StateUnitPos = { x = -53, y = -66 }
GotC.p4StateUnitPos = { x = -54, y = -66 }
GotC.LOG_STATE_KEY = "log"
GotC.LOG_PRINTED = false

GotC.VILLAGE_ROLES = {"Guardian", "Agent", "Fool", "Marksman", "Mystic", "Investigator", "Santa"}
GotC.MINION_ROLES = {"Spy", "Gravekeeper", "Burglar"}
GotC.DEMON_ROLES = {"Vampire", "Cultist", "Cheater"}
GotC.VILLAGE_ROLE_DESCRIPTIONS = {Guardian = "The other villager is invincible. You can still be killed",
                                  Agent = "The minion thinks you’re the demon instead of the real demon",
                                  Fool = "Whoever killed you, is killed first. If the game is not over when they are killed, you are killed too. If the player loses their commander by another player, they aren’t killed",
                                  Marksman = "Once per game, may kill another player on or before turn 10. If that player is not the demon, the villagers lose",
                                  Mystic = "Once per turn, may choose another player to confuse. You are disposable",
                                  Investigator = " Every turn on and after turn 5, may choose another player. The investigator sees either the role of the player (50% chance) or a random role (50% chance, 67% bad, 33% good)",
                                  Santa = "Every 5 turns, may choose another player to receive 900 gold on the next turn (aka turn 6)"}
GotC.MINION_ROLE_DESCRIPTIONS = {Spy = "Every turn on and after turn 5, may choose another player. The spy sees either the role of the player (50% chance) or a random role (50% chance, 100% good if random)",
                                 Gravekeeper = "The demon is invincible. If you are killed, the villagers win. You are no longer disposable",
                                 Burglar = "Every 5 turns, may choose another player. The chosen player loses 300 gold on their next turn and gives that gold to the Burglar"}
GotC.DEMON_ROLE_DESCRIPTIONS = {Vampire = "Once per game on or after turn 5, may choose another player, that player loses 300 gold on their next turn and gives it to the vampire",
                                Cultist = "Once per turn, may choose another player to confuse",
                                Cheater = "You know one of two players are your minion"}
GotC.CONCEPT_DESCRIPTIONS = {
    Invincible = "That player cannot lose via their stronghold, commander dying or other rules unless otherwise specified or they attempt to kill themselves. The stronghold will respawn instead. The commander will be lost forever",
    Confused = "If a player is confused, any action they attempt at the HQ (such as giving gold to another player) that has a target will have a random target instead. The confused player isn’t notified if they chose a different target. Confusion is then removed",
    Disposable = "If the player was killed by another player the game continues instead of ending and the player is eliminated. That player’s units are removed and all their structures are neutralized. If the player is invincible, they are not eliminated or killed and retain their units and structures",
    Killed = "If a player is killed, they are eliminated and the opposite team wins (The minion is usually disposable)"
}

function GotC.addExpectedGoldToPlayer(playerId, gold)
    local stateUnit = GotC.findUnitState(playerId)
    local currentValue = Wargroove.getUnitState(stateUnit, "expected_gold")
    if currentValue == nil then
        currentValue = 0
    else
        currentValue = tonumber(currentValue)
    end
    local expectedGold = currentValue + gold
    Wargroove.setUnitState(stateUnit, "expected_gold", expectedGold)
    Wargroove.updateUnit(stateUnit)
    Wargroove.updateConstantObjective("Player " .. tostring(playerId + 1) .. " might have " .. tostring(expectedGold) .. "G", 0, 0)
    Wargroove.showConstantObjective()
end

function GotC.getExpectedGoldFromPlayer(playerId)
    local stateUnit = GotC.findUnitState(playerId)
    local currentValue = Wargroove.getUnitState(stateUnit, "expected_gold")
    if currentValue == nil then
        currentValue = 0
    else
        currentValue = tonumber(currentValue)
    end
    return currentValue
end

function GotC.marksmanChoose(playerId, targetPlayer, seed)
    local str = Utils.toStringNil(seed) .. " Marksman " .. tostring(Wargroove.getTurnNumber()) .. tostring(Wargroove.getCurrentPlayerId()) .. "1"
    if GotC.getConfused(playerId) then
        targetPlayer = (targetPlayer + Wargroove.randomInteger(str, 1, 4)) % 4
        str = str .. "2"
    end
    GotC.addToLog("Player " .. tostring(playerId + 1) .. " shot player " .. tostring(targetPlayer + 1))
    GotC.publicMessage("You hear a shot out in the distance")
    if not GotC.isDemon(targetPlayer) then
        GotC.evilWin()
    else
        GotC.attemptKill(targetPlayer, playerId)
        GotC.setConfused(playerId, false)
    end
end

function GotC.bankGold(playerId, sourcePlayer, gold, turnNumber)
    local stateUnit = GotC.findUnitState(playerId)
    local alreadyBanked = Wargroove.getUnitState(stateUnit, "bank_"..tostring(turnNumber))
    if alreadyBanked == nil then
        alreadyBanked = 0
    end
    Wargroove.setUnitState(stateUnit, "bank_"..tostring(turnNumber), tostring(gold + alreadyBanked))
    Wargroove.updateUnit(stateUnit)
    if sourcePlayer ~= nil then
        GotC.addToLog("Player " .. tostring(playerId + 1) .. " will gain " .. tostring(gold) .. " on turn " .. tostring(turnNumber) .. " caused by player " .. tostring(sourcePlayer + 1))
    else
        GotC.addToLog("Player " .. tostring(playerId + 1) .. " will gain " .. tostring(gold) .. " on turn " .. tostring(turnNumber))

    end
    GotC.setConfused(sourcePlayer, false, nil)
end

function GotC.applyBankedGold(playerId)
    local turnNumber = Wargroove.getTurnNumber()
    local stateUnit = GotC.findUnitState(playerId)
    local goldBank = Wargroove.getUnitState(stateUnit, "bank_"..tostring(turnNumber))
    if goldBank == nil then
        goldBank = 0
    else
        goldBank = tonumber(goldBank)
    end
    Wargroove.changeMoney(playerId, goldBank)
    Wargroove.setUnitState(stateUnit, "bank_"..tostring(turnNumber), tostring(0))
    Wargroove.updateUnit(stateUnit)
    if goldBank ~= 0 then
        GotC.privateMessage(playerId, "You gained " .. tostring(goldBank) .. " gold")
    end
end

function GotC.investigate(playerId, targetPlayer, seed)
    local str = Utils.toStringNil(seed) .. " Investigate " .. tostring(Wargroove.getTurnNumber()) .. tostring(Wargroove.getCurrentPlayerId()) .. "1"
    local rng = Wargroove.randomInteger(str, 1, 100)
    str = str .. "2"
    local role = ""
    if rng <= 50 then
        rng = Wargroove.randomInteger(str, 1, 100)
        str = str .. "3"
        if rng <= 33 then
            local i = Wargroove.randomInteger(str, 1, #GotC.VILLAGE_ROLES)
            str = str .. "4"
            role = GotC.VILLAGE_ROLES[i]
        else
            local evil = Utils.listMerge(GotC.MINION_ROLES, GotC.DEMON_ROLES)
            local i = Wargroove.randomInteger(str, 1, #evil)
            str = str .. "5"
            role = evil[i]
        end
    else
        role = GotC.getRole(targetPlayer)
    end
    GotC.addToLog("Player " .. tostring(playerId + 1) .. " investigated player " .. tostring(targetPlayer + 1) .. " and saw " .. role)
    GotC.privateMessage(playerId, "The investigated player is a " .. role)
    GotC.setConfused(playerId, false, nil)
end

function GotC.investigateSpy(playerId, targetPlayer, seed)
    local str = tostring(seed) .. " Spy " .. tostring(Wargroove.getTurnNumber()) .. tostring(Wargroove.getCurrentPlayerId()) .. "1"
    local rng = Wargroove.randomInteger(str, 1, 100)
    str = str .. "2"
    local role = ""
    if rng <= 50 then
        local i = Wargroove.randomInteger(str, 1, #GotC.VILLAGE_ROLES)
        str = str .. "3"
        role = GotC.VILLAGE_ROLES[i]
    else
        role = GotC.getRole(targetPlayer)
    end
    GotC.addToLog("Player " .. tostring(playerId + 1) .. " investigated " .. tostring(targetPlayer + 1) .. " and saw " .. role)
    GotC.privateMessage(playerId, "The investigated player is a " .. role)
    GotC.setConfused(playerId, false, nil)
end

function GotC.attemptKill(playerId, sourcePlayer, isCoKill)
    local isCommanderDead = isCoKill or false
    if GotC.getInvincible(playerId) and playerId ~= sourcePlayer then
        GotC.addToLog("Player " .. tostring(playerId + 1) .. " is invincible and was not killed by player " .. tostring(sourcePlayer + 1))
        return -1
    elseif GotC.getDisposable(playerId) and playerId ~= sourcePlayer then
        GotC.addToLog("Player " .. tostring(playerId + 1) .. " was disposable and was killed by player " .. tostring(sourcePlayer + 1))
        Wargroove.eliminate(playerId)
        return -2
    elseif GotC.getHeadless(playerId) and playerId ~= sourcePlayer and isCommanderDead then
        GotC.addToLog("Player " .. tostring(playerId + 1) .. " is CO immune and was not killed by player " .. tostring(sourcePlayer + 1))
        return -3
    elseif GotC.isDemon(playerId) then
        GotC.addToLog("Player " .. tostring(playerId + 1) .. ", the demon was killed by player " ..  tostring(sourcePlayer + 1))
        GotC.villagersWin()
    elseif GotC.isMinion(playerId) then
        GotC.addToLog("Player " .. tostring(playerId + 1) .. ", the minion was killed by player " ..  tostring(sourcePlayer + 1))
        GotC.villagersWin()
    elseif GotC.isVillager(playerId) then

        if GotC.getRole(playerId) == "Fool" and sourcePlayer ~= playerId then
            if GotC.attemptKill(sourcePlayer, playerId) ~= 0 then
                GotC.addToLog("Player " .. tostring(playerId + 1) .. ", a villager was killed by player " ..  tostring(sourcePlayer + 1))
                GotC.evilWin()
            end
        else
            GotC.evilWin()
        end
    end
    return 0
end

function GotC.villagersWin()
    Wargroove.setPlayerTeam(0, 3)
    for i = 0, 3 do
        GotC.addToLog("Player " .. tostring(i + 1) .. " was a " .. GotC.getRole(i))
        if GotC.isVillager(i) then
            Wargroove.setPlayerTeam(i, 0)
            Wargroove.giveVictory(i)
        end
    end
    GotC.addToLog("The villagers win!")
    GotC.printLog()
end

function GotC.evilWin()
    Wargroove.setPlayerTeam(0, 3)
    for i = 0, 3 do
        GotC.addToLog("Player " .. tostring(i + 1) .. " was a " .. GotC.getRole(i))
        if GotC.isMinion(i) or GotC.isDemon(i) then
            Wargroove.setPlayerTeam(i, 0)
            Wargroove.giveVictory(i)
        end
    end
    GotC.addToLog("The demon and the minion win!")
    GotC.printLog()
end

function GotC.isDemon(playerId)
    return Utils.listContains(GotC.DEMON_ROLES, GotC.getRole(playerId))
end

function GotC.isMinion(playerId)
    return Utils.listContains(GotC.MINION_ROLES, GotC.getRole(playerId))
end

function GotC.isVillager(playerId)
    return Utils.listContains(GotC.VILLAGE_ROLES, GotC.getRole(playerId))
end

function GotC.setRole(playerId, role, sourcePlayer)
    local stateUnit = GotC.findUnitState(playerId)
    Wargroove.setUnitState(stateUnit, "role", role)
    Wargroove.updateUnit(stateUnit)
    if sourcePlayer ~= nil then
        if sourcePlayer == playerId then
            GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is the " .. role)
        else
            GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " converted player " .. tostring(playerId + 1) .. " to the " .. role)
        end
    end
end

function GotC.getRole(playerId)
    local stateUnit = GotC.findUnitState(playerId)
    return Utils.toStringNil(Wargroove.getUnitState(stateUnit, "role"))
end

function GotC.setInvincible(playerId, isInvincible, sourcePlayer)
    local stateUnit = GotC.findUnitState(playerId)
    Wargroove.setUnitState(stateUnit, "invincible", tostring(isInvincible))
    Wargroove.updateUnit(stateUnit)
    if sourcePlayer ~= nil then
        if sourcePlayer == playerId then
            if isInvincible then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is invincible")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is no longer invincible")
            end
        else
            if isInvincible then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " made player " .. tostring(playerId + 1) .. " invincible")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " removed invincibility from player " .. tostring(playerId + 1))
            end
        end
    end
end

function GotC.getInvincible(playerId)
    local stateUnit = GotC.findUnitState(playerId)
    return Utils.toStringNil(Wargroove.getUnitState(stateUnit, "invincible")) == "true"
end

function GotC.setDisposable(playerId, isDisposable, sourcePlayer)
    local stateUnit = GotC.findUnitState(playerId)
    Wargroove.setUnitState(stateUnit, "disposable", tostring(isDisposable))
    Wargroove.updateUnit(stateUnit)
    if sourcePlayer ~= nil then
        if sourcePlayer == playerId then
            if isDisposable then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is disposable")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is no longer disposable")
            end
        else
            if isDisposable then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " made player " .. tostring(playerId + 1) .. " disposable")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " removed disposable from player " .. tostring(playerId + 1))
            end
        end
    end
end

function GotC.getDisposable(playerId)
    local stateUnit = GotC.findUnitState(playerId)
    return Utils.toStringNil(Wargroove.getUnitState(stateUnit, "disposable")) == "true"
end

function GotC.setHeadless(playerId, isHeadless, sourcePlayer)
    local stateUnit = GotC.findUnitState(playerId)
    Wargroove.setUnitState(stateUnit, "headless", tostring(isHeadless))
    Wargroove.updateUnit(stateUnit)
    if sourcePlayer ~= nil then
        if sourcePlayer == playerId then
            if isHeadless then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is CO immune")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is no longer CO immune")
            end
        else
            if isHeadless then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " made player " .. tostring(playerId + 1) .. " CO immune")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " removed CO immune from player " .. tostring(playerId + 1))
            end
        end
    end
end

function GotC.getHeadless(playerId)
    local stateUnit = GotC.findUnitState(playerId)
    return Utils.toStringNil(Wargroove.getUnitState(stateUnit, "headless")) == "true"
end

function GotC.setConfused(playerId, isConfused, sourcePlayer)
    local stateUnit = GotC.findUnitState(playerId)
    Wargroove.setUnitState(stateUnit, "confused", tostring(isConfused))
    Wargroove.updateUnit(stateUnit)
    if sourcePlayer ~= nil then
        if sourcePlayer == playerId then
            if isConfused then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is confused")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " is no longer confused")
            end
        else
            if isConfused then
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " made player " .. tostring(playerId + 1) .. " confused")
            else
                GotC.addToLog("Player " .. tostring(sourcePlayer + 1) .. " removed confusion from player " .. tostring(playerId + 1))
            end
        end
    end
end

function GotC.getConfused(playerId)
    local stateUnit = GotC.findUnitState(playerId)
    return Utils.toStringNil(Wargroove.getUnitState(stateUnit, "confused")) == "true"
end

function GotC.addToLog(logEntry)
    local log = UnitState.getState(GotC.LOG_STATE_KEY)
    local turnNumber = Wargroove.getTurnNumber()
    if GotC.DEBUG then
        print("Turn " .. tostring(turnNumber) .. ": " .. logEntry)
    end
    if log == nil then
        UnitState.setState(GotC.LOG_STATE_KEY, "Turn " .. tostring(turnNumber) .. ": " .. logEntry)
    else
        UnitState.setState(GotC.LOG_STATE_KEY, log .. ";" .. "Turn " .. tostring(turnNumber) .. ": " .. logEntry)
    end
end

function GotC.printLog()
    local log = UnitState.getState(GotC.LOG_STATE_KEY)
    if log ~= nil and not GotC.LOG_PRINTED then
        local logArray = Utils.split(";", log)
        for i,logEntry in ipairs(logArray) do
            if logEntry ~= "0" then
                Wargroove.showDialogueBox("neutral", "generic_archer", logEntry, "", {}, "standard", true, "Storyteller")
            end
        end
    end
    GotC.LOG_PRINTED = true
end

function GotC.announceRules()
    GotC.publicMessage("How to Play: Players are divided into two teams. There are 2 villagers and 2 evil characters, a minion and a demon. The villagers wish to kill an evil character. The demon and the minion wish to kill 1 villager. The minion is usually disposable, meaning the villagers usually have to kill the demon to win. The villagers don’t know who anyone is. The minion knows who the demon is. The demon doesn't know who anyone is. Every player has their own unique role. It is common courtesy to not start deducing who is who until turn 2 so everyone knows their roles.")
end

function GotC.conceptDescriptions(playerId)
    for k,v in pairs(GotC.CONCEPT_DESCRIPTIONS) do
        if GotC.DEBUG then
            print("PM Description: " .. k)
        end
        if Wargroove.isLocalPlayer(playerId) then
            Wargroove.showDialogueBox("neutral", "generic_archer", k .. ": " .. v, "", {}, "standard", true, "Storyteller")
        end
    end
end

function GotC.villageRoleDescription(playerId, role)
    if GotC.DEBUG then
        print("PM Description: " .. role)
    end
    if Wargroove.isLocalPlayer(playerId) then
        Wargroove.showDialogueBox("neutral", "generic_archer", role .. ": " .. GotC.VILLAGE_ROLE_DESCRIPTIONS[role], "", {}, "standard", true, "Storyteller")
    end
end

function GotC.minionRoleDescription(playerId, role)
    if GotC.DEBUG then
        print("PM Description: " .. role)
    end
    if Wargroove.isLocalPlayer(playerId) then
        Wargroove.showDialogueBox("neutral", "generic_archer", role .. ": " .. GotC.MINION_ROLE_DESCRIPTIONS[role], "", {}, "standard", true, "Storyteller")
    end
end

function GotC.demonRoleDescription(playerId, role)
    if GotC.DEBUG then
        print("PM Description: " .. role)
    end
    if Wargroove.isLocalPlayer(playerId) then
        Wargroove.showDialogueBox("neutral", "generic_archer", role .. ": " .. GotC.DEMON_ROLE_DESCRIPTIONS[role], "", {}, "standard", true, "Storyteller")
    end
end

function GotC.privateMessage(playerId, msg)
    if GotC.DEBUG then
        print("PM: " .. msg)
    end
    if Wargroove.isLocalPlayer(playerId) then
        Wargroove.showDialogueBox("neutral", "generic_archer", "Private: " .. msg, "", {}, "standard", true, "Storyteller")
    end
end

function GotC.publicMessage(msg)
    if GotC.DEBUG then
        print("Announce: " .. msg)
    end
    Wargroove.showDialogueBox("neutral", "generic_archer", "Announcement: " .. msg, "", {}, "standard", true, "Storyteller")
end

function GotC.findUnitState(playerId)
    if playerId == 1 then
        local unit = Wargroove.getUnitAt(GotC.p2StateUnitPos)
        if unit == nil then
            Wargroove.spawnUnit( -1, GotC.p2StateUnitPos, "soldier", true)
            unit = Wargroove.getUnitAt(GotC.p2StateUnitPos)
            Wargroove.updateUnit(unit)
        end
        return unit
    elseif playerId == 2 then
        local unit = Wargroove.getUnitAt(GotC.p3StateUnitPos)
        if unit == nil then
            Wargroove.spawnUnit( -1, GotC.p3StateUnitPos, "soldier", true)
            unit = Wargroove.getUnitAt(GotC.p3StateUnitPos)
            Wargroove.updateUnit(unit)
        end
        return unit
    elseif playerId == 3 then
        local unit = Wargroove.getUnitAt(GotC.p4StateUnitPos)
        if unit == nil then
            Wargroove.spawnUnit( -1, GotC.p4StateUnitPos, "soldier", true)
            unit = Wargroove.getUnitAt(GotC.p4StateUnitPos)
            Wargroove.updateUnit(unit)
        end
        return unit
    elseif playerId == 0 then
        local unit = Wargroove.getUnitAt(GotC.p1StateUnitPos)
        if unit == nil then
            Wargroove.spawnUnit( -1, GotC.p1StateUnitPos, "soldier", true)
            unit = Wargroove.getUnitAt(GotC.p1StateUnitPos)
            Wargroove.updateUnit(unit)
        end
        return unit
    end
    return nil
end

return GotC