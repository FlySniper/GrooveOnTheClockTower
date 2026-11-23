local Events = require "initialized/events"
local Wargroove = require "wargroove/wargroove"
local UnitState = require "unit_state"
local Utils = require "utils"
local GotC = require "gotc"

local Actions = {}

function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    -- Unlisted actions
    dst["gotc_init"] = Actions.gotc_init
    dst["gotc_repeat"] = Actions.gotc_repeat
    dst["gotc_kill_commander"] = Actions.gotc_kill_commander
    dst["gotc_kill_hq"] = Actions.gotc_kill_hq
end

-- Local functions

local function removeElementFromListXY(lst, element)
    local i = 1
    while i <= #lst do
        local pos = lst[i]
        if pos.x == element.x and pos.y == element.y then
            table.remove(lst, i)
            break
        end
        i = i + 1
    end
end

local function removePositionsAroundElement(lst, element, distance)
    for x = -distance, distance do
        for y = -distance + math.abs(x), distance - math.abs(x) do
            removeElementFromListXY(lst, {x=element.x + x, y=element.y + y})
        end
    end
end

local function findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)

    return centre
end

local function findPlaceInLocation(location, unitClassId)
    local candidates = {}
    local centre = nil
    local positions = nil

    if location == nil then
        -- No location, use whole map
        local mapSize = Wargroove.getMapSize()
        positions = {}
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                table.insert(positions, { x = x, y = y })
            end
        end
        centre = { x = math.floor(mapSize.x / 2), y = math.floor(mapSize.y / 2) }
    else
        positions = location.positions
        centre = findCentreOfLocation(location)
    end

    -- All candidates
    for i, pos in ipairs(positions) do
        if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
            local dx = pos.x - centre.x
            local dy = pos.y - centre.y
            local dist = dx * dx + dy * dy
            table.insert(candidates, { pos = pos, dist = dist })
        end
    end

    -- Sort candidates
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    return candidates
end

function Actions.gotc_kill_commander(context)
    Actions.gotc_kill(context, true)
end

function Actions.gotc_kill_hq(context)
    Actions.gotc_kill(context, false)
end

function Actions.gotc_kill(context, isCoKilled)
    local turnNumber = Wargroove.getTurnNumber()
    local currentPlayer = Wargroove.getCurrentPlayerId()
    local targetPlayer = context:getPlayerId(0)
    local str = "Unit Lost " .. tostring(Wargroove.getTurnNumber()) .. tostring(Wargroove.getCurrentPlayerId()) .. "1"
    if GotC.attemptKill(targetPlayer, currentPlayer, isCoKilled) == -1 then
        local playerUnitState = GotC.findUnitState(targetPlayer)
        local positions = Utils.split(",", Wargroove.getUnitState(playerUnitState, "hq_locations"))
        for x=1,#positions,2 do
            local y = x + 1
            local hq = Wargroove.getUnitAtXY(positions[x], positions[y])
            print(tostring(positions[x]) .. "," .. tostring(positions[y]))
            if hq == nil then
                print("Spawning HQ")
                Wargroove.spawnUnit( targetPlayer, { x = positions[x], y = positions[y] }, "hq", false)
                local newHq = Wargroove.getUnitAt({ x = positions[x], y = positions[y] })
                Wargroove.updateUnit(newHq)
            end

        end
    end
end

function Actions.gotc_repeat(context)
    local turnNumber = Wargroove.getTurnNumber()
    local currentPlayer = Wargroove.getCurrentPlayerId()
    local mapSize = Wargroove.getMapSize()
    local str = "Repeat " .. tostring(Wargroove.getTurnNumber()) .. tostring(Wargroove.getCurrentPlayerId()) .. "1"
    local role = GotC.getRole(currentPlayer)
    -- This accounts for the spare HQ in the corner. It shouldn't produce an extra 100 gold.
    Wargroove.changeMoney(currentPlayer, -100)
    Utils.revealFoW()
    if turnNumber == 1 then
        if Wargroove.isLocalPlayer(currentPlayer) then
            if GotC.isMinion(currentPlayer) then
                GotC.privateMessage(currentPlayer, "You are a minion! Your role is " .. role)
                GotC.minionRoleDescription(currentPlayer, role)
            elseif GotC.isDemon(currentPlayer) then
                GotC.privateMessage(currentPlayer, "You are the demon! Your role is " .. role)
                GotC.demonRoleDescription(currentPlayer, role)
            elseif GotC.isVillager(currentPlayer) then
                GotC.privateMessage(currentPlayer, "You are a Villager! Your role is " .. role)
                GotC.villageRoleDescription(currentPlayer, role)
            end
        end
    end
    if turnNumber == 1 and GotC.isMinion(currentPlayer) and Wargroove.isLocalPlayer(currentPlayer) then
        local demon = -1
        local agent = -1
        for i = 0,3 do
            if GotC.isDemon(i) then
                demon = i
            elseif GotC.getRole(i) == "Agent" then
                agent = i
            end
        end
        if agent ~= -1 then
            GotC.privateMessage(currentPlayer, "Your demon is player " .. tostring(agent + 1))
        else
            GotC.privateMessage(currentPlayer, "Your demon is player " .. tostring(demon + 1))
        end
    end

    if turnNumber == 1 and role == "Cheater" and Wargroove.isLocalPlayer(currentPlayer) then
        local minon = -1
        local villagers = {}

        for i = 0,3 do
            if GotC.isMinion(i) then
                minon = i
            elseif GotC.isVillager(i) then
                table.insert(villagers, i)
            end
        end
        local index = Wargroove.randomInteger(str, 1, #villagers)
        local villager = villagers[index]
        local mix = {minon, villager}
        local seed = "Cheater shuffle " .. tostring(turnNumber) .. tostring(currentPlayer)
        Utils.shuffle(mix, seed)
        GotC.privateMessage(currentPlayer, "Either player " .. tostring(mix[1] + 1) .. " or " .. tostring(mix[2] + 1) .. " is a minion. The other is a villager")
    end
    GotC.applyBankedGold(currentPlayer)
    local hqs = Wargroove.getAllUnitsOfType(currentPlayer, "hq")
    local cities = Wargroove.getAllUnitsOfType(currentPlayer, "city")
    local fortifiedCities = Wargroove.getAllUnitsOfType(currentPlayer, "fortified_city")
    local goldHqs = ((#hqs) - 1) * 100
    local goldCities = (#cities) * 100
    local goldFortifiedCities = (#fortifiedCities) * 200
    GotC.addExpectedGoldToPlayer(currentPlayer, goldHqs + goldCities + goldFortifiedCities)
    for i,v in ipairs(hqs) do
        if v.pos.x == 0 and v.pos.y == 0 then
        elseif v.pos.x == 0 and v.pos.y == mapSize.y - 1 then
        elseif v.pos.x == mapSize.x - 1 and v.pos.y == 0 then
        elseif v.pos.x == mapSize.x - 1 and v.pos.y == mapSize.y - 1 then
        else
            v.hadTurn = true
            Wargroove.updateUnit(v)
        end
    end
end

function Actions.gotc_init(context)
    Utils.revealFoW()
    GotC.announceRules()
    local str = "Init 1"
    local ingameRoles = {}
    local villageCopy = {}
    for i,v in ipairs(GotC.VILLAGE_ROLES) do
        table.insert(villageCopy, v)
    end
    local index = Wargroove.randomInteger(str, 1, #villageCopy)
    str = str .. "2"
    table.insert(ingameRoles, table.remove(villageCopy, index))
    index = Wargroove.randomInteger(str, 1, #villageCopy)
    str = str .. "3"
    table.insert(ingameRoles, villageCopy[index])

    table.insert(ingameRoles, GotC.MINION_ROLES[Wargroove.randomInteger(str, 1, #GotC.MINION_ROLES)])
    str = str .. "4"
    table.insert(ingameRoles, GotC.DEMON_ROLES[Wargroove.randomInteger(str, 1, #GotC.DEMON_ROLES)])
    str = str .. "5"
    Utils.shuffle(ingameRoles, str)
    str = str .. "6"
    local demon = -1
    for i,v in ipairs(ingameRoles) do
        local hqs = Wargroove.getAllUnitsOfType(i - 1, "hq")
        local stateString = ""
        for j,hq in ipairs(hqs) do
            if j ==1 then
                stateString = tostring(hq.pos.x) .. "," .. tostring(hq.pos.y)
            else
                stateString = stateString .. "," .. tostring(hq.pos.x) .. "," .. tostring(hq.pos.y)
            end
        end
        local playerUnitState = GotC.findUnitState(i - 1)
        Wargroove.setUnitState(playerUnitState, "hq_locations", stateString)
        Wargroove.updateUnit(playerUnitState)
        local currentGold = Wargroove.getMoney(i - 1)
        GotC.addExpectedGoldToPlayer(i - 1, currentGold)
        GotC.setRole(i - 1, v, i - 1)
        if GotC.isDemon(i - 1) then
            demon = i - 1
        elseif GotC.isMinion(i - 1) then
            GotC.setDisposable(i - 1, true, nil)
        end
    end

    for i = 0,3 do
        local role = GotC.getRole(i)
        if role == "Guardian" then
            for j = 0,3 do
                if GotC.isVillager(j) and i ~= j then
                    GotC.setInvincible(j, true, i)
                end
            end
        elseif role == "Gravekeeper" then
            GotC.setDisposable(i, false, i)
            GotC.setInvincible(demon, true, i)
        elseif role == "Mystic" then
            GotC.setDisposable(i, true, i)
        elseif role == "Fool" then
            GotC.setHeadless(i, true, i)
        end
    end
end

return Actions
