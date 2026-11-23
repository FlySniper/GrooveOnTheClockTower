local Wargroove = require "wargroove/wargroove"
local Utils = {}

function Utils.shuffle(lst, str)
    for i = #lst, 2, -1 do
        local j = Wargroove.randomInteger(str, 1, i)
        str = str .. tostring(i) .. "A"
        lst[i], lst[j] = lst[j], lst[i]
    end
end

function Utils.listContains(lst, value)
    for i = 1,#lst do
        if (lst[i] == value) then
            return true
        end
    end
    return false
end

function Utils.listMerge(lst1, lst2)
    local merged = {}
    for i = 1,#lst1 do
        table.insert(merged, lst1[i])
    end
    for j = 1,#lst2 do
        table.insert(merged, lst2[j])
    end
    return merged
end

function Utils.toStringNil(var)
    if var == nil then
        return "nil"
    end
    return tostring(var)
end

function Utils.revealFoW()
    local mapSize = Wargroove.getMapSize()
    local area = {}
    for x = 0, mapSize.x - 1 do
        for y = 0, mapSize.y - 1 do
            if x == 0 and y == 0 then
            elseif x == 0 and y == (mapSize.y - 1) then
            elseif x == (mapSize.x - 1) and y == 0 then
            elseif x == (mapSize.x - 1) and y == (mapSize.y - 1) then
            else
                table.insert(area, {x = x, y = y})
            end
        end
    end
    print(Utils.toStringNil(Wargroove.setLocationArea(0, area)))
    Wargroove.revealFogOfWar(0, 0, true)
    Wargroove.revealFogOfWar(1, 0, true)
    Wargroove.revealFogOfWar(2, 0, true)
    Wargroove.revealFogOfWar(3, 0, true)
end

-- Source: http://lua-users.org/wiki/MakingLuaLikePhp
-- Credit: http://richard.warburton.it/
function Utils.split(div,str)
    if (div=='') then return false end
    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1))
        pos = sp + 1
    end
    table.insert(arr,string.sub(str,pos))
    return arr
end

return Utils