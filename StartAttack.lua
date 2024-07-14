SLASH_FINDATTACK1 = "/findattack"
SLASH_STARTATTACK1 = "/startattack"
SLASH_STOPATTACK1 = "/stopattack"

local printImpl = print or function(text) --pfui has its own global print function so we can use that one
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

local function print(msg)
    printImpl("|cffFFC125[StartAttack] " .. msg)
end

local _cachedAttackSpellActionbarSlot
local function findAttackSpellAndCacheIt()
    if _cachedAttackSpellActionbarSlot ~= nil then
        return _cachedAttackSpellActionbarSlot
    end

    for slot = 1, 120 do
        if IsAttackAction(slot) then
            _cachedAttackSpellActionbarSlot = slot
            return _cachedAttackSpellActionbarSlot
        end
    end

    return nil
end

local function isCurrentTargetAliveAndHostile()
    return UnitExists("target")
            and not UnitIsDeadOrGhost("target")
            and not UnitIsFriend("player", "target")
end

local function tryRelocateAttackSpellAndCacheIt()
    _cachedAttackSpellActionbarSlot = nil -- invalidate cache

    return findAttackSpellAndCacheIt() ~= nil
end

local function startAttackImpl()
    if IsCurrentAction(_cachedAttackSpellActionbarSlot) then
        return
    end
    
    if not IsAttackAction(_cachedAttackSpellActionbarSlot) and not tryRelocateAttackSpellAndCacheIt() then
        print("Attack-spell not found in any of the actionbars! Did you remove it completely from them?")
        return
    end

    if not isCurrentTargetAliveAndHostile() then
        TargetNearestEnemy() -- 00 workaround
        if not isCurrentTargetAliveAndHostile() then
            -- no alive hostile targets left around
            return
        end
    end

    UseAction(_cachedAttackSpellActionbarSlot)
    
    -- 00 after killing a hostile target the default logic of start-attack has trouble picking the next hostile target laying around
    --    by doing the targeting ourselves this problem is solved 
end

local function stopAttackImpl()
    if not IsCurrentAction(_cachedAttackSpellActionbarSlot) then
        return
    end

    UseAction(_cachedAttackSpellActionbarSlot)
end

local findTheAttackSpellOnlyOnce_thenStartAttack = function()
    local found = findAttackSpellAndCacheIt() ~= nil
    if not found then
        print("Attack-spell not found in any of the actionbars!")
        return
    end

    startAttackImpl()
    findTheAttackSpellOnlyOnce_thenStartAttack = startAttackImpl
end

local findTheAttackSpellOnlyOnce_thenStopAttack = function()
    local found = findAttackSpellAndCacheIt() ~= nil
    if not found then
        print("Attack-spell not found in any of the actionbars!")
        return
    end

    stopAttackImpl()
    findTheAttackSpellOnlyOnce_thenStopAttack = stopAttackImpl
end

function SlashCmdList.FINDATTACK()
    local attackSpell = findAttackSpellAndCacheIt()
    if attackSpell == nil then
        print("Attack-spell not found in any of the actionbars!")
        return
    end

    print("Found attack-spell at " .. tostring(attackSpell))
end

function SlashCmdList.STARTATTACK()
    findTheAttackSpellOnlyOnce_thenStartAttack()
end

function SlashCmdList.STOPATTACK()
    findTheAttackSpellOnlyOnce_thenStopAttack()
end