-- NOTE: This file is auto-generated. Any changes will be overwritten.

-- SPDX-FileCopyrightText: 2023 Wilhelm Schürmann <wimschuermann@googlemail.com>
--
-- SPDX-License-Identifier: MIT

-- The OoTMM logic is kept as-is, which means having global lowercase functions.
-- Disable warnings for this.
---@diagnostic disable: lowercase-global

-- This is for namespacing only, because EmoTracker doesn't seem to properly support require()
function _mm_logic()
    OOTMM_DEBUG = false

    local M = {
        EMO = EMO,
        AccessibilityLevel = AccessibilityLevel,
        Tracker = Tracker,
        OOTMM_DEBUG = OOTMM_DEBUG,
        MM_TIME_SLICES = MM_TIME_SLICES,
        MM_TIME_SLICES_INDEX = MM_TIME_SLICES_INDEX,
        PRICE_HELPER = PRICE_HELPER,
        os = os,
        pairs = pairs,
        ipairs = ipairs,
        new_node = new_node,
        print = print,
        setmetatable = setmetatable,
        string = string,
        tonumber = tonumber,
        tostring = tostring,
        table = table,
        debug = debug,
        assert = assert,
        error = error,
    }

    -- This is used for all items, events, settings, etc., but probably shouldn't be...
    setmetatable(M, {
        __index = function(table, key)
            if string.match(key, "^[A-Z0-9_]+$") then
                return tostring(key)
            else
                if OOTMM_DEBUG then
                    print("Unknown attribute accessed: " .. key)
                end

                return tostring(key)
            end
        end
    })

    local _ENV = M

    OOTMM_RUNTIME_ALL_TRICKS_ENABLED = false
    OOTMM_RUNTIME_ACCESSIBILITY = {}
    OOTMM_RUNTIME_CACHE = {}
    OOTMM_RUNTIME_STATE = {}
    SearchQueue = {}

    if not EMO then
        -- This is for testing only; items gets injected by tests
        function Tracker:ProviderCountForCode(code)
            local count = items[code]
            if count == nil then
                count = 0
            end
            return count
        end
    end

    local Queue = {}
    function Queue:new()
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o._queue = {}
        o._prioritizedQueue = {} -- "Priority Queue" is a commonly used data structure; this is not exactly that, hence "prioritized".
        return o
    end

    function Queue:push(node)
        if node.type == "event" then
            self:push_prioritized(node)
        else
            self:push_normal(node)
        end
    end

    function Queue:push_normal(node)
        table.insert(self._queue, node)
    end

    function Queue:push_prioritized(node)
        table.insert(self._prioritizedQueue, node)
    end

    function Queue:pop()
        local node = table.remove(self._prioritizedQueue)
        if not node then
            node = table.remove(self._queue)
        end

        return node
    end

    function Queue:is_empty()
        return #self._queue == 0 and #self._prioritizedQueue == 0
    end

    function Queue:clear()
        self._queue = {}
        self._prioritizedQueue = {}
    end

    function Queue:print()
        for _, node in pairs(self._prioritizedQueue) do
            print(node.name, node.type, node.child, node.adult)
        end
        for _, node in pairs(self._queue) do
            print(node.name, node.type, node.child, node.adult)
        end
    end

    function reset()
        OOTMM_RUNTIME_CACHE = {}
        OOTMM_RUNTIME_STATE = {
            -- Previously checked, available places (list of nodes, source: internal)
            ["places_available"] = {}, -- { "place_1": node_1, "place_2": node_2, ... }

            -- Available locations (list of nodes, source: internal)
            ["locations_available"] = {}, -- { "location_1": node_1, "location_2": node_2, ... }

            -- Previously seen and already active events (source: internal)
            ["events_active"] = {}, -- { "event_1": node_1, "event_2": node_2, ... }

            -- exits/events/locations that need to be revisited if a new event is found (source: internal)
            ["events_to_revisit"] = {}, -- { "event_name": { node1, node2, ...}, ... }

            -- custom "event items" - whenever these are encountered, their amount is increased and an event with the name "CUSTOM_EVENT_FOO:amount" is activated (source: internal)
            ["custom_event_items"] = {}, -- { "item_name": amount, ... }
        }
        SearchQueue = Queue:new()        -- List of nodes, source: internal and external
    end

    function get_reachable_events()
        return OOTMM_RUNTIME_STATE.events_active
    end

    OOTMM_ITEM_PREFIX = "MM"
    OOTMM_TRICK_PREFIX = "TRICK"
    OOTMM_GLITCH_PREFIX = "GLITCH"

    -- Inject things into the module's namespace
    function inject(stuff)
        for k, v in pairs(stuff) do
            M[k] = v
        end
    end

    -- "STRENGTH:3" ---> STRENGTH, 3
    -- "HOOKSHOT" ---> HOOKSHOT, 1
    local function parse_item_override(item)
        local min_count = 1

        if string.find(item, ":") then
            item, min_count = string.match(item, "([^:]+):?(%d+)")
        end

        return item, assert(tonumber(min_count))
    end

    OOTMM_HAS_OVERRIDES = {
        ["HOOKSHOT:2"] = "LONGSHOT",
        ["SCALE:2"] = "GOLDSCALE",
        ["STRENGTH:2"] = "STRENGTH2",
        ["STRENGTH:3"] = "STRENGTH3",
        ["WALLET:0"] = "WALLET0",
        ["WALLET:1"] = "WALLET1",
        ["WALLET:2"] = "WALLET2",
        ["WALLET:3"] = "WALLET3",
        ["SONG_GORON_HALF:2"] = "SONG_GORON",
        ["STONE_EMERALD"] = "SPIRITUAL_STONE:1",  -- FIXME: This is entirely arbitrary; if individual stones end up being relevant,
        ["STONE_RUBY"] = "SPIRITUAL_STONE:2",     -- FIXME: this will need to be changed to something more sensible or the
        ["STONE_SAPPHIRE"] = "SPIRITUAL_STONE:3", -- FIXME: has_spiritual_stones() macro will have to be adjusted on the fly.
        ["MEDALLION_FIRE"] = "NOCTURNE_MED:1",
        ["MEDALLION_WATER"] = "NOCTURNE_MED:2",
        ["MEDALLION_SPIRIT"] = "LACS_MED:1",
        ["MEDALLION_SHADOW"] = "LACS_MED:2",
        ["OCARINA:2"] = "OCARINA2",
    }
    OOTMM_HAS_PREFIXES = {
        ["setting"] = true,
        ["TRICK"] = true,
        ["EVENT"] = true,
        ["OOT"] = true,
        ["MM"] = true,
    }
    local CUSTOM_EVENT_ITEMS = {
        ["RUPEE_SILVER_BOTW"] = true,
        ["RUPEE_SILVER_DC"] = true,
        ["RUPEE_SILVER_GANON_FIRE"] = true,
        ["RUPEE_SILVER_GANON_FOREST"] = true,
        ["RUPEE_SILVER_GANON_LIGHT"] = true,
        ["RUPEE_SILVER_GANON_SHADOW"] = true,
        ["RUPEE_SILVER_GANON_SPIRIT"] = true,
        ["RUPEE_SILVER_GANON_WATER"] = true,
        ["RUPEE_SILVER_GTG_LAVA"] = true,
        ["RUPEE_SILVER_GTG_SLOPES"] = true,
        ["RUPEE_SILVER_GTG_WATER"] = true,
        ["RUPEE_SILVER_IC_BLOCK"] = true,
        ["RUPEE_SILVER_IC_SCYTHE"] = true,
        ["RUPEE_SILVER_SHADOW_BLADES"] = true,
        ["RUPEE_SILVER_SHADOW_PIT"] = true,
        ["RUPEE_SILVER_SHADOW_SCYTHE"] = true,
        ["RUPEE_SILVER_SHADOW_SPIKES"] = true,
        ["RUPEE_SILVER_SPIRIT_ADULT"] = true,
        ["RUPEE_SILVER_SPIRIT_BOULDERS"] = true,
        ["RUPEE_SILVER_SPIRIT_CHILD"] = true,
        ["RUPEE_SILVER_SPIRIT_LOBBY"] = true,
        ["RUPEE_SILVER_SPIRIT_SUN"] = true,
    }
    function has(item, min_count, use_prefix)
        if use_prefix == nil then
            use_prefix = true
        end

        if CUSTOM_EVENT_ITEMS[item] then
            min_count = min_count or 1
            return event("CUSTOM_EVENT_" .. item .. ":" .. tostring(min_count))
        end

        if min_count and OOTMM_HAS_OVERRIDES[item .. ":" .. min_count] then
            item, min_count = parse_item_override(OOTMM_HAS_OVERRIDES[item .. ":" .. min_count])
        elseif min_count == nil and OOTMM_HAS_OVERRIDES[item] then
            item, min_count = parse_item_override(OOTMM_HAS_OVERRIDES[item])
        end

        local prefix = string.match(item, "^([^_]+)_")
        if prefix and OOTMM_HAS_PREFIXES[prefix] then
            -- These are already prefixed as needed
            use_prefix = false
        end

        local count = 0
        if use_prefix then
            -- Function got called from raw converted logic without an item prefix.
            -- EmoTracker knows these items as "OOT_*"" / "MM_*"
            count = get_tracker_count(OOTMM_ITEM_PREFIX .. "_" .. item)
        else
            count = get_tracker_count(item)
        end

        if not min_count then
            return count > 0
        else
            return count >= min_count
        end
    end

    -- Tracker:ProviderCountForCode() calls are excruciatingly slow, this caches the results.
    function get_tracker_count(item_code)
        if OOTMM_DEBUG then
            return Tracker:ProviderCountForCode(item_code)
        end

        local cache_key = "RAW:" .. item_code

        if OOTMM_RUNTIME_CACHE[cache_key] == nil then
            OOTMM_RUNTIME_CACHE[cache_key] = Tracker:ProviderCountForCode(item_code)
        end

        return OOTMM_RUNTIME_CACHE[cache_key]
    end

    function renewable(item)
        -- FIXME: Make sure this is actually OK!
        return has(item)
    end

    function license(item)
        -- FIXME: Make sure this is actually OK!
        return has(item)
    end

    OOTMM_RUNTIME_CURRENT_AGE = "child"
    function age(x)
        return OOTMM_RUNTIME_CURRENT_AGE == x
    end

    function set_age(age)
        if age == "child" or age == "adult" then
            OOTMM_RUNTIME_CURRENT_AGE = age
        else
            error("Invalid age: " .. age)
        end
    end

    OOTMM_ACCESS_LEVELS = {
        -- NOTE: Don't rely on these indexes, they are entirely arbitrary and might change.
        [0] = AccessibilityLevel.None,
        [1] = AccessibilityLevel.SequenceBreak,
        [2] = AccessibilityLevel.Normal,
        [AccessibilityLevel.None] = 0,
        [AccessibilityLevel.SequenceBreak] = 1,
        [AccessibilityLevel.Normal] = 2,
    }
    function update_accessibility(reachable, accessibility)
        -- FIXME: This is currently unused; might be useful in find_available_locations()

        -- These values are used by EmoTracker to color the map squares.
        --
        -- reachable:
        --   0: unreachable
        --   1: reachable
        -- accessibility:
        --   AccessibilityLevel.None (red)
        --   AccessibilityLevel.SequenceBreak (yellow)
        --   AccessibilityLevel.Normal (green)

        if reachable > OOTMM_RUNTIME_ACCESSIBILITY["reachable"] then
            OOTMM_RUNTIME_ACCESSIBILITY["reachable"] = reachable
            OOTMM_RUNTIME_ACCESSIBILITY["accessibility"] = accessibility
        elseif reachable == OOTMM_RUNTIME_ACCESSIBILITY["reachable"] and OOTMM_ACCESS_LEVELS[accessibility] > OOTMM_ACCESS_LEVELS[OOTMM_RUNTIME_ACCESSIBILITY["accessibility"]] then
            OOTMM_RUNTIME_ACCESSIBILITY["accessibility"] = accessibility
        end

        return reachable, accessibility
    end

    function get_trick_mode()
        if OOTMM_RUNTIME_ALL_TRICKS_ENABLED then
            return "all"
        else
            return "selected"
        end
    end

    -- Yet another global with  side effects...
    function set_trick_mode(mode)
        if mode == "all" then
            OOTMM_RUNTIME_ALL_TRICKS_ENABLED = true
        elseif mode == "selected" then
            OOTMM_RUNTIME_ALL_TRICKS_ENABLED = false
        else
            error("Invalid trick mode: " .. mode)
        end
    end

    function trick(x)
        return has(OOTMM_TRICK_PREFIX .. "_" .. x) or OOTMM_RUNTIME_ALL_TRICKS_ENABLED
    end

    function glitch(x)
        return has(OOTMM_GLITCH_PREFIX .. "_" .. x) or OOTMM_RUNTIME_ALL_GLITCHES_ENABLED
    end

    -- Events are active if they CAN LOGICALLY BE reached, not when they HAVE BEEN reached.
    -- Checks show up as green when you actually need to do other things first,
    -- and the sequence of tasks necessary is not obvious unless you're intimately familiar
    -- with the randomizer's logic.
    --
    -- These are used to override the default behavior, and make the tracker more
    -- user friendly.
    OOTMM_EVENT_OVERRIDES = {
        ["OOT"] = {
            ["ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["BOMBCHUS"] = { ["type"] = "has" },
            ["BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["MALON"] = { ["type"] = "has" },
            ["MEET_ZELDA"] = { ["type"] = "has" },
            ["MM_ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["MM_BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["NUTS"] = { ["type"] = "return", ["value"] = false },
            ["MM_NUTS"] = { ["type"] = "return", ["value"] = false },
            ["STICKS"] = { ["type"] = "return", ["value"] = false },
            ["MM_STICKS"] = { ["type"] = "return", ["value"] = false },
            ["SEEDS"] = { ["type"] = "return", ["value"] = true },
        },
        ["MM"] = {
            ["ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["BOMBCHUS"] = { ["type"] = "has" },
            ["BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["BOMBER_CODE"] = { ["type"] = "has" },
            ["FROG_1"] = { ["type"] = "has" },
            ["FROG_2"] = { ["type"] = "has" },
            ["FROG_3"] = { ["type"] = "has" },
            ["FROG_4"] = { ["type"] = "has" },
            ["NUTS"] = { ["type"] = "return", ["value"] = false },
            ["OOT_NUTS"] = { ["type"] = "return", ["value"] = false },
            ["SEAHORSE"] = { ["type"] = "has" },
            ["STICKS"] = { ["type"] = "return", ["value"] = false },
            ["OOT_STICKS"] = { ["type"] = "return", ["value"] = false },
            ["OOT_ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["OOT_BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["ZORA_EGGS_BARREL_MAZE"] = { ["type"] = "has" },
            ["ZORA_EGGS_HOOKSHOT_ROOM"] = { ["type"] = "has" },
            ["ZORA_EGGS_LONE_GUARD"] = { ["type"] = "has" },
            ["ZORA_EGGS_PINNACLE_ROCK"] = { ["type"] = "has" },
            ["ZORA_EGGS_TREASURE_ROOM"] = { ["type"] = "has" },
        },
    }
    function event(x)
        local override = OOTMM_EVENT_OVERRIDES[OOTMM_ITEM_PREFIX][x]
        if override then
            if override["type"] == "return" then
                return override["value"]
            elseif override["type"] == "has" then
                return has("EVENT_" .. OOTMM_ITEM_PREFIX .. '_' .. x)
            end
        end

        if OOTMM_RUNTIME_STATE.events_active[x] then
            return true
        else
            -- Save the event to a lovely global variable so we can have some side effects in the side effects affecting side effects.
            -- Note that we just care about the events queried for, not whether they're active.
            -- We also don't care about the overrides above, since those don't change during runtime.
            OOTMM_RUNTIME_STATE["_check_rule_events_used"][x] = true
            return false
        end
    end

    function cond(x, y, z)
        if x then
            return y
        else
            return z
        end
    end

    local OOTMM_SETTING_OVERRIDES = {
        ["childWallets"] = true,
        ["progressiveShieldsMm_progressive"] = false,
        ["progressiveShieldsOot_progressive"] = false,
        ["progressiveSwordsOot_goron"] = true,
        ["progressiveSwordsOot_progressive"] = false,
        ["erBoss_none"] = true,
        ["erDungeons_none"] = true,
        ["erIndoors_none"] = true,
        ["erRegions_none"] = true,
        ["erIkanaCastle"] = false,
    }
    function setting(name, state)
        -- Settings are made available as Tracker items, e.g. for
        -- setting(crossWarpMm, full) -> check if has(setting_crossWarpMm_full)
        local item_name = name
        if state then
            item_name = name .. "_" .. state
        end

        if OOTMM_SETTING_OVERRIDES[item_name] ~= nil then
            return OOTMM_SETTING_OVERRIDES[item_name]
        end

        -- EmoTracker knows boolean settings as progressive items with codes "setting_name_true" and "setting_name_false"
        if not state then
            item_name = item_name .. "_true"
        end

        return has("setting_" .. item_name)
    end

    OOTMM_SPECIAL_ACCESS_CASES = {
        ["BRIDGE"] = true,
        ["LACS"] = true,
        ["MAJORA"] = true,
        ["MOON"] = true,
    }
    function special(case)
        if not OOTMM_SPECIAL_ACCESS_CASES[case] then
            print("Unknown special name: " .. case)
            return false
        end

        local item_names = {
            "OOT_SPIRITUAL_STONE",
            "OOT_MEDALLION",
            "MM_BOSS_REMAIN",
            "OOT_GS_TOKEN",
            "MM_GS_TOKEN_SWAMP",
            "MM_GS_TOKEN_OCEAN",
            "MM_STRAY_FAIRY_TOWN",
            "MM_STRAY_FAIRY_WF",
            "MM_STRAY_FAIRY_SH",
            "MM_STRAY_FAIRY_GB",
            "MM_STRAY_FAIRY_ST",
            "MM_MASK_REGULAR",
            "MM_MASK_TRANSFORM",
            "OOT_MASK",
        }

        local sum = 0
        for _, item_name in pairs(item_names) do
            local setting_name = "setting_" .. case .. "_" .. item_name

            if get_tracker_count(setting_name) == 1 then
                sum = sum + get_tracker_count(item_name)
            end
        end

        local needed = get_tracker_count(case)

        return sum >= needed
    end

    function masks(amount)
        return get_tracker_count(OOTMM_ITEM_PREFIX .. "_" .. "MASK") >= amount
    end

    function oot_time(x)
        -- FIXME
        return true
    end

    local OOTMM_RUNTIME_CURRENT_TIME = nil
    function mm_time(case, time)
        OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] = true

        if OOTMM_DEBUG then
            print("case", case, "time", time, "index", MM_TIME_SLICES_INDEX[time], "earliest_time",
                OOTMM_RUNTIME_CURRENT_TIME)
        end
        local r = _mm_time(case, time)
        if OOTMM_DEBUG then
            print("mm_time:", case, time, r)
        end
        return r
    end

    function _mm_time(case, time)
        -- Return whether the current time index fits the given case.
        -- The current index is yet another global variable which is "set elsewhere(tm)".
        if OOTMM_RUNTIME_CURRENT_TIME == nil then
            error("Current time slice not set!")
        end

        if OOTMM_RUNTIME_CURRENT_TIME == -1 then
            -- Special case for check_rule()'s event collection
            return false
        end

        if case == "at" then
            return OOTMM_RUNTIME_CURRENT_TIME == MM_TIME_SLICES_INDEX[time]
        elseif case == "before" then
            return MM_TIME_SLICES_INDEX[time] > OOTMM_RUNTIME_CURRENT_TIME
        elseif case == "after" then
            return MM_TIME_SLICES_INDEX[time] <= OOTMM_RUNTIME_CURRENT_TIME
        else
            print(case)
            error("Invalid case: " .. case)
        end
    end

    local function set_time(time_index)
        OOTMM_RUNTIME_CURRENT_TIME = time_index
    end

    local OOTMM_RANGE_TO_SETTING = {
        OOT_SHOPS = "priceOotShops",
        OOT_SCRUBS = "priceOotScrubs",
        MM_SHOPS = "priceMmShops",
        MM_SHOPS_EX = "priceMmShops",
        MM_TINGLE = "priceMmTingle",
    }
    function price(range, id, value)
        local price = PRICE_HELPER.default_prices[id + PRICE_HELPER.range_index[range]]

        if not OOTMM_RANGE_TO_SETTING[range] then
            print("price(): Unknown range " .. range)
        end

        if OOTMM_RANGE_TO_SETTING[range] then
            if setting(OOTMM_RANGE_TO_SETTING[range], "affordable") then
                price = 10
            elseif setting(OOTMM_RANGE_TO_SETTING[range], "weighted") then
                price = 0
            elseif setting(OOTMM_RANGE_TO_SETTING[range], "random") then
                price = 0
            elseif not setting(OOTMM_RANGE_TO_SETTING[range], "vanilla") then
                return true
            end
        end

        return price <= value
    end

    function trace(event, line)
        local s = debug.getinfo(2).short_src
        print(s .. ":" .. line)
    end

    -- We need to be able to inject new places into already running find() calls.
    -- We also need to be able to do this in any direction, i.e. from OOT into MM
    -- and vice versa, at any time, and without having to worry about the order.
    -- Lua is pass by reference (by value, but the value is a reference), so we
    -- can just pass the whole state into the find() function every time it is called.

    -- Additionally, we need places in the queue and "restart if event activated" lists to know whether
    -- they were reached as child or adult for easier continuation.

    -- TODO: Turn these into class methods instead, maybe?
    local function add_event_queue_entry(event_queue, event_name, node)
        if not event_queue[event_name] then
            event_queue[event_name] = {}
        end

        table.insert(event_queue[event_name], node)
    end

    local function check_event_queue_entries(event_queue, event_name)
        if not event_queue[event_name] then
            return
        end

        for _, node in pairs(event_queue[event_name]) do
            -- TODO: This might lead to HUGE queues, there's definitely room for optimization here!
            SearchQueue:push(node)
        end

        event_queue[event_name] = nil
    end

    local function add_active_event(node)
        OOTMM_RUNTIME_STATE.events_active[node.name] = node
    end

    -- Update node in-place if "other" is better.
    -- This is yet another big no-no, but it fits in nicely with the other no-nos littered all over this codebase.
    local function update_node_if_better(node, other)
        local other_is_better = false

        -- update if other is better
        -- "better" means it is a lower number if both are numbers,
        -- or it is a number when the local value is nil
        if other.child ~= nil and ((node.child == nil) or (other.child < node.child)) then
            -- other can be reached earlier as child
            node.child = other.child
            other_is_better = true
        end
        if other.adult ~= nil and ((node.adult == nil) or (other.adult < node.adult)) then
            -- other can be reached earlier as adult
            node.adult = other.adult
            other_is_better = true
        end

        return other_is_better
    end

    local CUSTOM_EVENT_ITEMS_LOCATIONS = {
        ["Bottom of the Well SR 1"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 2"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 3"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 4"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 5"] = "RUPEE_SILVER_BOTW",
        ["Ganon Castle SR Fire Back Right"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Black Pillar"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Far Right"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Front Right"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Forest Back Middle"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Back Right"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Center Left"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Center Right"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Front"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Light Alcove Left"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Alcove Right"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Center Left"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Center Right"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Center Top"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Spirit Back Left"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Back Right"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Center Bottom"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Center Midair"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Front Right"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Gerudo Training Grounds SR Lava Back Center"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Back Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Back Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Front Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Front Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Slope Back"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Center"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Front Above"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Front Left"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Front Right"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Water 1"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 2"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 3"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 4"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 5"] = "RUPEE_SILVER_GTG_WATER",
        ["Ice Cavern SR Blocks Alcove"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Back Left"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Back Right"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Center"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Front Left"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Scythe Back"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Center Left"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Center Right"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Left"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Midair"] = "RUPEE_SILVER_IC_SCYTHE",
        ["MQ Dodongo Cavern SR Beamos"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Crate"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Upper Corner High"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Upper Corner Low"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Vines"] = "RUPEE_SILVER_DC",
        ["MQ Ganon Castle SR Fire Back-Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire Center-Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire Front-Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire High Above Lava"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire Under Pillar"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Shadow Back-Center"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Back-Left"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Front-Center"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Front-Right"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Middle"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Water Above Ground"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Alcove"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Deep Hole"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Shallow Hole"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Under Alcove"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Gerudo Training Grounds SR Lava Back-Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Back-Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Center"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Front"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Front-Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Front-Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Slopes Front"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Front-Left"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Front-Right"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Middle"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Top Right"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Water Bottom-Right"] = "RUPEE_SILVER_GTG_WATER",
        ["MQ Gerudo Training Grounds SR Water Center"] = "RUPEE_SILVER_GTG_WATER",
        ["MQ Gerudo Training Grounds SR Water Top-Left"] = "RUPEE_SILVER_GTG_WATER",
        ["MQ Shadow Temple SR Invisible Blades Ground 1"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 2"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 3"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 4"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 5"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 6"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 7"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 8"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 9"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Time Block"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Pit Back"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Front"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Midair High"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Midair Low"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Right"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Scythe 1"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 2"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 3"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 4"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 5"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Spikes Center Ground"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Center Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Center Platforms"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Front Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Left Corner"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Left Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Left Wall"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Right Back Wall"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Right Ground"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Right Lateral Wall"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Spirit Temple SR Adult Bottom"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Bottom-Center"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Center-Top"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Skulltula"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Top"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Lobby After Water Near Door"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby After Water Near Stairs"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby In Water"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby Rock Left"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby Rock Right"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["Shadow Temple SR Pit 1"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 2"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 3"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 4"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 5"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Scythe 1"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 2"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 3"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 4"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 5"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Spikes Back Left"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Center"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Front Left"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Right"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Spirit Temple SR Boulders 1"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 2"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 3"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 4"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 5"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Child 1"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 2"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 3"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 4"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 5"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Sun 1"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 2"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 3"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 4"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 5"] = "RUPEE_SILVER_SPIRIT_SUN",
    }
    local function check_rule(node, earliest_time, used_events)
        -- Check the rule and return its result as well as all used events.
        OOTMM_RUNTIME_STATE["_check_rule_events_used"] = {}
        OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] = false

        if earliest_time == nil then
            earliest_time = 1
        end

        -- Find the earliest time for which the rule is true by iterating over all possible times, starting at the previous earliest_time.
        set_time(earliest_time)
        local result = node.rule()

        -- Make sure we're actually allowed to stay in this time slice.
        -- node.mm_stay is a dict with time slice keys with further rules for each of them.
        -- If node.mm_stay is nil, or node.mm_stay[earliest_time] is nil, there are no restrictions.
        -- if node.mm_stay[earliest_time]() is true, we can stay.
        -- If node.mm_stay[earliest_time]() is false, we're not allowed to stay.
        -- if node.mm_stay then
        --     print("mm_stay", earliest_time, node.mm_stay)
        --     for k, v in pairs(node.mm_stay) do
        --         print(k, v)
        --     end
        --     -- -- print("mm_stay", earliest_time, node.mm_stay[earliest_time])
        -- end

        local can_stay = (not node.mm_stay or not node.mm_stay[MM_TIME_SLICES[earliest_time]] or node.mm_stay[MM_TIME_SLICES[earliest_time]]())
        result = result and can_stay

        -- FIXME: If this is false because of an mm_stay rule, we should not try to increase earliest_time in the loop below, but abort here! (this is fixed, but doesn't actually fix the logic - there's a new problem now!)

        -- FIXME: We'll probably need to start saving all time slices for which the current place/location/whatever is true. Keeping track of only the earliest one is not enough anymore ever since "stay" was added to the randomizer's logic.

        while can_stay and not result and OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] and earliest_time < #MM_TIME_SLICES do
            earliest_time = earliest_time + 1
            set_time(earliest_time)
            result = node.rule()
            can_stay = (not node.mm_stay or not node.mm_stay[MM_TIME_SLICES[earliest_time]] or node.mm_stay[MM_TIME_SLICES[earliest_time]]())
            result = result and can_stay
        end

        -- Try to find events used even for rules like this (an exit):
        --   ["Near Romani Ranch"] = function () return after(DAY3_AM_06_00) or can_use_keg() end,
        -- where, if can_use_keg() is true, the time at which we can reach "Near Romani Ranch" could be earlier than DAY3_AM_06_00.
        -- This means that this node will have to revisited once the BUY_KEG event is active, but if we first reach this
        -- node at DAY3_AM_06_00, we will never trigger the BUY_KEG event check.
        --
        -- TODO: Make sure there is no combination of rules for which this STILL won't return used events...
        set_time(-1)                 -- Make all time checks return false
        local _ignored = node.rule() -- We don't care about the result, we just want to check which events were used.

        if not result then
            earliest_time = nil
        end

        if used_events == nil then
            used_events = {}
        end

        for k, _ in pairs(OOTMM_RUNTIME_STATE["_check_rule_events_used"]) do
            used_events[k] = true
        end

        -- Handle special "custom event items"
        if result and CUSTOM_EVENT_ITEMS_LOCATIONS[node.name] then
            local item = CUSTOM_EVENT_ITEMS_LOCATIONS[node.name]
            local amount = OOTMM_RUNTIME_STATE["custom_event_items"][item] or 0
            amount = amount + 1

            OOTMM_RUNTIME_STATE["custom_event_items"][item] = amount

            -- Add custom event to the queue so normal event handling takes care of the rest
            SearchQueue:push(new_node({
                type = "event",
                name = "CUSTOM_EVENT_" .. item .. ":" .. amount,
                child = 1, -- FIXME: This is questionable at best...
                adult = 1, -- FIXME: Also questionable...
                rule = function() return true end
            }))
        end

        -- TODO: Saving tricks, we could probably save a lot of time here by not starting from scratch for sequence breaks?
        return result, earliest_time, used_events, OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"]
    end

    local function get_logic(name)
        return logic[name]
    end

    function search()
        -- Run until a new event is found, or all places have been checked.
        -- Only searching until a new event is found will lead to slightly lowered runtime, because we need to add
        -- fewer places/locations to the queue in total. Whether it's actually measurably faster is questionable,
        -- but we'll do it anyway.

        -- If the incoming node is an exit node, run its checks for the ages the node has been seen as. Save that info, then add it to any exits/events/locations for the new place if node.rule() is true.
        -- If we don't save the info, but instead add two nodes for any exit that is valid for both child and adult, nothing breaks. It's just a bit more work later on.

        local result = {
            -- ["events_found"] = {},     -- newly found events (possibly some for different worlds!)
            ["activated_nodes"] = {},                                          -- newly active nodes, possibly for different worlds!
            ["places_available"] = OOTMM_RUNTIME_STATE.places_available,       -- all available places for this logic module
            ["locations_available"] = OOTMM_RUNTIME_STATE.locations_available, -- all available locations for this logic module
            ["events_active"] = OOTMM_RUNTIME_STATE.events_active,             -- all known active events for this logic module
        }

        local current = SearchQueue:pop()
        while current ~= nil do
            local events_used = {}
            local active = { child = false, adult = false, }
            local earliest_child = nil       -- earliest time index at which this node's rule() is true; nil otherwise
            local earliest_adult = nil
            local mm_time_used_child = false -- true if rule() made use of mm_time
            local mm_time_used_adult = false

            if current.child then
                set_age("child")
                active.child, earliest_child, events_used, mm_time_used_child = check_rule(current, current.child,
                    events_used)
            end
            if current.adult then
                set_age("adult")
                active.adult, earliest_adult, events_used, mm_time_used_adult = check_rule(current, current.adult,
                    events_used)
            end

            if active.child or active.adult then
                local activated_current = new_node(current)
                activated_current.child = earliest_child
                activated_current.adult = earliest_adult
                table.insert(result["activated_nodes"], activated_current)
                if current.type == "exit" then
                    local place_logic = get_logic(current.name) -- can be nil!
                    local saved_place = result.places_available[current.name]
                    if place_logic and (saved_place == nil or update_node_if_better(saved_place, activated_current)) then
                        for new_type, new_rules in pairs(place_logic) do
                            if new_type ~= "exits" and new_type ~= "events" and new_type ~= "locations" then
                                -- Ignore anything but these three; they're special cases.
                                -- At the time of writing, the only other type is "mm_stay",
                                -- but reversing this rule would potentially lead to problems
                                -- in the future.
                                goto continue
                            end
                            for new_name, new_rule in pairs(new_rules) do
                                local node = new_node(activated_current)
                                node.type = string.sub(new_type, 1, -2) -- exits -> exit; events -> event; locations -> location
                                node.name = new_name
                                node.rule = new_rule
                                node.child = earliest_child
                                node.adult = earliest_adult
                                node.mm_stay = place_logic["stay"] -- nil is fine here

                                SearchQueue:push(node)
                            end
                            ::continue::
                        end
                    end
                    if saved_place == nil then
                        -- This will mark "OOT Foo" / "MM Bar" as available, too.
                        -- That is not correct, but we can just ignore that for now because places_available is never actually passed to the EmoTracker layer.
                        result.places_available[current.name] = activated_current
                    end
                elseif current.type == "event" then
                    add_active_event(activated_current)
                    check_event_queue_entries(OOTMM_RUNTIME_STATE["events_to_revisit"], current.name)
                    -- break -- TODO: Maybe reactivate this for speed of event juggling?
                elseif current.type == "location" then
                    -- Setting the location to the current node will allow for "upgrades",
                    -- i.e. when encountering a location as adult that has only been reached as child before.
                    -- Keeping this info is not strictly necessary, but it's nice for debugging.
                    local prev = result.locations_available[current.name]
                    if prev then
                        update_node_if_better(prev, activated_current)
                    else
                        result.locations_available[current.name] = activated_current
                    end
                end
            end

            -- FIXME: Handle "both failed" and "only one of them failed" cases.
            --        For now, just re-check the whole node for all used events regardless of age().
            if not active.child or not active.adult or (mm_time_used_child and earliest_child > 1) or (mm_time_used_adult and earliest_adult > 1) then
                -- If events were checked during rule application, make sure to revisit
                -- this node if any of them get activated later.
                for event_name, _ in pairs(events_used) do
                    add_event_queue_entry(OOTMM_RUNTIME_STATE["events_to_revisit"], event_name, current)
                end
            end

            current = SearchQueue:pop()
        end

        return result
    end

    	function can_play_sun()
		return can_play(SONG_SUN) or can_play(SHARED_SONG_SUN)
	end

	function can_play_time()
		return can_play(SONG_TIME) or can_play(SHARED_SONG_TIME)
	end

	function can_play_epona()
		return can_play(SONG_EPONA) or can_play(SHARED_SONG_EPONA)
	end

	function can_play_storms()
		return can_play(SONG_STORMS) or can_play(SHARED_SONG_STORMS)
	end

	function soul_octorok()
		return soul(SOUL_OCTOROK) or soul(SHARED_SOUL_OCTOROK)
	end

	function soul_wallmaster()
		return soul(SOUL_WALLMASTER) or soul(SHARED_SOUL_WALLMASTER)
	end

	function soul_dodongo()
		return soul(SOUL_DODONGO) or soul(SHARED_SOUL_DODONGO)
	end

	function soul_keese()
		return soul(SOUL_KEESE) or soul(SHARED_SOUL_KEESE)
	end

	function soul_tektite()
		return soul(SOUL_TEKTITE) or soul(SHARED_SOUL_TEKTITE)
	end

	function soul_peahat()
		return soul(SOUL_PEAHAT) or soul(SHARED_SOUL_PEAHAT)
	end

	function soul_lizalfos_dinalfos()
		return soul(SOUL_LIZALFOS_DINALFOS) or soul(SHARED_SOUL_LIZALFOS_DINALFOS)
	end

	function soul_skulltula()
		return soul(SOUL_SKULLTULA) or soul(SHARED_SOUL_SKULLTULA)
	end

	function soul_armos()
		return soul(SOUL_ARMOS) or soul(SHARED_SOUL_ARMOS)
	end

	function soul_deku_baba()
		return soul(SOUL_DEKU_BABA) or soul(SHARED_SOUL_DEKU_BABA)
	end

	function soul_deku_scrub()
		return soul(SOUL_DEKU_SCRUB) or soul(SHARED_SOUL_DEKU_SCRUB)
	end

	function soul_bubble()
		return soul(SOUL_BUBBLE) or soul(SHARED_SOUL_BUBBLE)
	end

	function soul_beamos()
		return soul(SOUL_BEAMOS) or soul(SHARED_SOUL_BEAMOS)
	end

	function soul_redead_gibdo()
		return soul(SOUL_REDEAD_GIBDO) or soul(SHARED_SOUL_REDEAD_GIBDO)
	end

	function soul_skullwalltula()
		return soul(SOUL_SKULLWALLTULA) or soul(SHARED_SOUL_SKULLWALLTULA)
	end

	function soul_shell_blade()
		return soul(SOUL_SHELL_BLADE) or soul(SHARED_SOUL_SHELL_BLADE)
	end

	function soul_like_like()
		return soul(SOUL_LIKE_LIKE) or soul(SHARED_SOUL_LIKE_LIKE)
	end

	function soul_iron_knuckle()
		return soul(SOUL_IRON_KNUCKLE) or soul(SHARED_SOUL_IRON_KNUCKLE)
	end

	function soul_freezard()
		return soul(SOUL_FREEZARD) or soul(SHARED_SOUL_FREEZARD)
	end

	function soul_wolfos()
		return soul(SOUL_WOLFOS) or soul(SHARED_SOUL_WOLFOS)
	end

	function soul_guay()
		return soul(SOUL_GUAY) or soul(SHARED_SOUL_GUAY)
	end

	function soul_flying_pot()
		return soul(SOUL_FLYING_POT) or soul(SHARED_SOUL_FLYING_POT)
	end

	function soul_floormaster()
		return soul(SOUL_FLOORMASTER) or soul(SHARED_SOUL_FLOORMASTER)
	end

	function at(x)
		return mm_time('at', x)
	end

	function after(x)
		return mm_time('after', x)
	end

	function before(x)
		return mm_time('before', x)
	end

	function between(a, b)
		return after(a) and before(b)
	end

	function is_day1()
		return before(NIGHT1_PM_06_00)
	end

	function is_day2()
		return after(DAY2_AM_06_00) and before(NIGHT2_PM_06_00)
	end

	function is_day3()
		return after(DAY3_AM_06_00) and before(NIGHT3_PM_06_00)
	end

	function is_day()
		return is_day1() or is_day2() or is_day3()
	end

	function is_night1()
		return after(NIGHT1_PM_06_00) and before(DAY2_AM_06_00)
	end

	function is_night2()
		return after(NIGHT2_PM_06_00) and before(DAY3_AM_06_00)
	end

	function is_night3()
		return after(NIGHT3_PM_06_00)
	end

	function is_night()
		return is_night1() or is_night2() or is_night3()
	end

	function first_day()
		return before(DAY2_AM_06_00)
	end

	function second_day()
		return after(DAY2_AM_06_00) and before(DAY3_AM_06_00)
	end

	function final_day()
		return after(DAY3_AM_06_00)
	end

	function midnight()
		return after(NIGHT1_AM_12_00) and before(DAY2_AM_06_00) or (after(NIGHT2_AM_12_00) and before(DAY3_AM_06_00)) or after(NIGHT3_AM_12_00)
	end

	function has_bottle()
		return has('BOTTLE_EMPTY') or has('BOTTLE_POTION_RED') or has('BOTTLE_MILK') or event('GOLD_DUST_USED') or has('BOTTLE_CHATEAU')
	end

	function has_ocarina_n(x)
		return has('OCARINA', x) or has('SHARED_OCARINA', x)
	end

	function has_ocarina()
		return cond(setting('sharedOcarina'), cond(setting('fairyOcarinaMm'), has_ocarina_n(1), has_ocarina_n(2)), has_ocarina_n(1))
	end

	function can_play(song)
		return has_ocarina() and has(song)
	end

	function can_break_boulders()
		return has_explosives() or has_mask_goron()
	end

	function can_use_lens()
		return can_use_lens_strict() or trick('MM_LENS')
	end

	function can_use_lens_strict()
		return has_magic() and (has('LENS') or has('SHARED_LENS'))
	end

	function has_explosives()
		return has_bombs() or has('MASK_BLAST') or has_bombchu()
	end

	function can_use_fire_arrows()
		return has_magic() and has_arrows() and (has('ARROW_FIRE') or has('SHARED_ARROW_FIRE'))
	end

	function can_use_ice_arrows()
		return has_magic() and has_arrows() and (has('ARROW_ICE') or has('SHARED_ARROW_ICE'))
	end

	function can_use_light_arrows()
		return has_magic() and has_arrows() and (has('ARROW_LIGHT') or has('SHARED_ARROW_LIGHT'))
	end

	function can_use_keg()
		return event('BUY_KEG')
	end

	function has_mirror_shield()
		return cond(setting('progressiveShieldsMm', 'progressive'), has('SHIELD', 2), has('SHIELD_MIRROR'))
	end

	function can_use_elegy()
		return can_play(SONG_EMPTINESS)
	end

	function can_use_elegy2()
		return can_play(SONG_EMPTINESS) and (has_mask_zora() or has_mask_goron())
	end

	function can_use_elegy3()
		return can_play(SONG_EMPTINESS) and has_mask_zora() and has_mask_goron()
	end

	function has_bomb_bag()
		return has('BOMB_BAG') or has('SHARED_BOMB_BAG')
	end

	function has_bombchu()
		return has_bomb_bag() and (renewable(BOMBCHU) or renewable(BOMBCHU_5) or renewable(BOMBCHU_10) or renewable(BOMBCHU_20))
	end

	function has_beans()
		return event('MAGIC_BEANS_PALACE') or (license(MAGIC_BEAN) and renewable(MAGIC_BEAN))
	end

	function has_weapon()
		return has('SWORD') or has('GREAT_FAIRY_SWORD')
	end

	function can_use_beans()
		return has_beans() and (has_bottle() or can_play_storms())
	end

	function scarecrow_hookshot_short()
		return has_ocarina() and can_hookshot_short()
	end

	function scarecrow_hookshot()
		return has_ocarina() and can_hookshot()
	end

	function goron_fast_roll()
		return has_mask_goron() and has_magic()
	end

	function can_use_deku_bubble()
		return has('MASK_DEKU') and has_magic()
	end

	function has_weapon_range()
		return has_arrows() or can_hookshot_short() or has_mask_zora() or can_use_deku_bubble()
	end

	function has_paper()
		return has('DEED_LAND') or has('DEED_SWAMP') or has('DEED_MOUNTAIN') or has('DEED_OCEAN') or has('LETTER_TO_KAFEI') or has('LETTER_TO_MAMA')
	end

	function can_fight()
		return has_weapon() or has_mask_zora() or has_mask_goron()
	end

	function has_goron_song_half()
		return cond(setting('progressiveGoronLullaby', 'progressive'), has('SONG_GORON_HALF'), has('SONG_GORON'))
	end

	function has_goron_song()
		return cond(setting('progressiveGoronLullaby', 'progressive'), has('SONG_GORON_HALF', 2), has('SONG_GORON'))
	end

	function can_lullaby_half()
		return has_ocarina() and has_goron_song_half() and has_mask_goron()
	end

	function can_lullaby()
		return has_ocarina() and has_goron_song() and has_mask_goron()
	end

	function has_shield()
		return renewable(SHIELD_HERO) or has_mirror_shield()
	end

	function can_activate_crystal()
		return can_break_boulders() or has_weapon() or has_arrows() or can_hookshot_short() or has('MASK_DEKU') or has_mask_zora()
	end

	function can_evade_gerudo()
		return has_arrows() or can_hookshot_short() or has_mask_zora() or has('MASK_STONE')
	end

	function has_hot_water_mtn()
		return event('GORON_GRAVEYARD_HOT_WATER') or event('TWIN_ISLANDS_HOT_WATER')
	end

	function has_hot_water_distance()
		return can_play(SONG_SOARING) and (event('GORON_GRAVEYARD_HOT_WATER') or event('TWIN_ISLANDS_HOT_WATER') or event('WELL_HOT_WATER'))
	end

	function has_hot_water_er()
		return (event('GORON_GRAVEYARD_HOT_WATER') or event('TWIN_ISLANDS_HOT_WATER') or event('WELL_HOT_WATER')) and er_enabled()
	end

	function can_goron_bomb_jump()
		return trick('MM_GORON_BOMB_JUMP') and has_mask_goron() and (has_bombs() or trick_keg_explosives())
	end

	function can_hookshot_n(x)
		return has('HOOKSHOT', x) or has('SHARED_HOOKSHOT', x)
	end

	function can_hookshot_short()
		return can_hookshot_n(1)
	end

	function can_hookshot()
		return cond(setting('shortHookshotMm'), can_hookshot_n(2), can_hookshot_n(1))
	end

	function has_blue_potion()
		return has_bottle() and renewable(POTION_BLUE)
	end

	function has_red_potion()
		return has_bottle() and (event('RED_POTION') or renewable(POTION_RED) or renewable(BOTTLE_POTION_RED))
	end

	function has_green_potion()
		return has_bottle() and renewable(POTION_GREEN)
	end

	function has_milk()
		return has_bottle() and (renewable(MILK) or renewable(BOTTLE_MILK))
	end

	function has_red_or_blue_potion()
		return has_red_potion() or has_blue_potion()
	end

	function trick_keg_explosives()
		return can_use_keg() and trick('MM_KEG_EXPLOSIVES')
	end

	function trick_sht_fireless()
		return (has_hot_water_distance() and has('OWL_SNOWHEAD') or has_hot_water_er()) and trick('MM_SHT_FIRELESS')
	end

	function trick_sht_fireless_er()
		return has_hot_water_er() and trick('MM_SHT_FIRELESS')
	end

	function can_reset_time_on_moon()
		return can_play_time() or (setting('majoraChild', 'none') and event('MAJORA') and trick('MM_MAJORA_LOGIC'))
	end

	function can_reset_time()
		return can_play_time() or (event('MAJORA') and trick('MM_MAJORA_LOGIC'))
	end

	function has_sticks()
		return event('STICKS') or renewable(STICK) or renewable(SHARED_STICK) or renewable(SHARED_STICKS_5) or renewable(SHARED_STICKS_10) or (setting('sharedNutsSticks') and event('OOT_STICKS'))
	end

	function has_nuts()
		return event('NUTS') or renewable(NUT) or renewable(NUTS_5) or renewable(NUTS_10) or renewable(SHARED_NUT) or renewable(SHARED_NUTS_5) or renewable(SHARED_NUTS_10) or (setting('sharedNutsSticks') and event('OOT_NUTS'))
	end

	function has_bow()
		return has('BOW') or has('SHARED_BOW')
	end

	function has_arrows()
		return has_bow() and (event('ARROWS') or renewable(ARROWS_10) or renewable(ARROWS_30) or renewable(ARROWS_40) or renewable(SHARED_ARROWS_5) or renewable(SHARED_ARROWS_10) or renewable(SHARED_ARROWS_30) or renewable(SHARED_ARROWS_40))
	end

	function has_bombs()
		return has_bomb_bag() and (event('BOMBS') or renewable(BOMBS_5) or renewable(BOMBS_10) or renewable(BOMBS_20) or renewable(BOMBS_30) or renewable(SHARED_BOMBS_5) or renewable(SHARED_BOMBS_10) or renewable(SHARED_BOMBS_20) or renewable(SHARED_BOMBS_30))
	end

	function has_magic()
		return (has('MAGIC_UPGRADE') or has('SHARED_MAGIC_UPGRADE')) and (event('MAGIC') or has_green_potion() or has_blue_potion() or event('CHATEAU'))
	end

	function has_double_magic()
		return (has('MAGIC_UPGRADE', 2) or has('SHARED_MAGIC_UPGRADE', 2)) and (event('MAGIC') or has_green_potion() or has_blue_potion() or event('CHATEAU'))
	end

	function has_rupees()
		return event('RUPEES')
	end

	function has_zora_egg()
		return event('ZORA_EGGS_HOOKSHOT_ROOM') or event('ZORA_EGGS_BARREL_MAZE') or event('ZORA_EGGS_LONE_GUARD') or event('ZORA_EGGS_TREASURE_ROOM') or event('ZORA_EGGS_PINNACLE_ROCK')
	end

	function has_chateau()
		return has_bottle() and (renewable(CHATEAU) or renewable(BOTTLE_CHATEAU))
	end

	function has_big_poe()
		return event('WELL_BIG_POE')
	end

	function can_kill_baba_nuts()
		return soul_deku_baba() and (can_fight() or has('MASK_DEKU') or can_hookshot_short() or has_explosives() or has_arrows())
	end

	function can_kill_baba_sticks()
		return soul_deku_baba() and (can_fight() or has('MASK_DEKU') or can_hookshot_short() or has_explosives() or has_arrows())
	end

	function can_kill_baba_both_sticks()
		return soul_deku_baba() and (has_weapon() or has('MASK_DEKU'))
	end

	function bombers1()
		return event('BOMBERS_NORTH1') and event('BOMBERS_EAST1') and event('BOMBERS_WEST1')
	end

	function bombers2()
		return event('BOMBERS_NORTH2') and event('BOMBERS_EAST2') and event('BOMBERS_WEST2')
	end

	function bombers3()
		return event('BOMBERS_NORTH3') and event('BOMBERS_EAST3') and event('BOMBERS_WEST3')
	end

	function has_wallet(n)
		return cond(setting('childWallets'), has('WALLET', n) or has('SHARED_WALLET', n), has('WALLET', n - 1) or has('SHARED_WALLET', n - 1))
	end

	function can_use_wallet(n)
		return has_rupees() and has_wallet(n)
	end

	function wallet_price(range, id)
		return price(range, id, 0) or (has_rupees() and (price(range, id, 99) and has_wallet(1) or (price(range, id, 200) and has_wallet(2)) or (price(range, id, 500) and has_wallet(3)) or (setting('colossalWallets') and price(range, id, 999) and has_wallet(4)) or (setting('bottomlessWallets') and price(range, id, 9999) and has_wallet(5))))
	end

	function shop_price(id)
		return wallet_price(MM_SHOPS, id)
	end

	function shop_ex_price(id)
		return wallet_price(MM_SHOPS_EX, id)
	end

	function tingle_price(id)
		return wallet_price(MM_TINGLE, id)
	end

	function boss_key(x)
		return setting('bossKeyShuffleMm', 'removed') or has(x)
	end

	function small_keys(x, count)
		return setting('smallKeyShuffleMm', 'removed') or has(x, count)
	end

	function has_mask_bunny()
		return has('MASK_BUNNY') or has('SHARED_MASK_BUNNY')
	end

	function has_mask_truth()
		return has('MASK_TRUTH') or has('SHARED_MASK_TRUTH')
	end

	function has_mask_keaton()
		return has('MASK_KEATON') or has('SHARED_MASK_KEATON')
	end

	function has_mask_zora()
		return has('MASK_ZORA') or has('SHARED_MASK_ZORA')
	end

	function has_mask_goron()
		return has('MASK_GORON') or has('SHARED_MASK_GORON')
	end

	function er_enabled()
		return not setting('erDungeons', 'none') or not setting('erIndoors', 'none') or (not setting('erRegions', 'none')) or (not setting('erBoss', 'none'))
	end

	function soul(x)
		return not setting('enemySoulsMm') or has(x)
	end


    logic = {
    ["Ancient Castle of Ikana"] = {
        ["exits"] = {
            ["Ikana Castle Exterior"] = function () return true end,
            ["Ancient Castle of Ikana Interior"] = function () return can_reset_time() end,
        },
    },
    ["Ancient Castle of Ikana Interior"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana"] = function () return true end,
            ["Ancient Castle of Ikana Interior North"] = function () return can_use_fire_arrows() end,
            ["Ancient Castle of Ikana Interior South"] = function () return can_use_fire_arrows() end,
            ["Ancient Castle of Ikana Behind Block"] = function () return has_mirror_shield() and event('IKANA_CASTLE_LIGHT2') or can_use_light_arrows() end,
        },
    },
    ["Ancient Castle of Ikana Interior North"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return true end,
            ["Ancient Castle of Ikana Interior North 2"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Ancient Castle of Ikana Interior North 2"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior North"] = function () return has('MASK_DEKU') end,
            ["Ancient Castle of Ikana Roof Exterior"] = function () return can_use_lens() end,
        },
    },
    ["Ancient Castle of Ikana Roof Exterior"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT"] = function () return cond(setting('erIkanaCastle'), has('MASK_DEKU'), true) end,
            ["IKANA_CASTLE_LIGHT2"] = function () return can_use_keg() end,
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Interior North 2"] = function () return true end,
            ["Ancient Castle of Ikana Roof Interior"] = function () return can_goron_bomb_jump() end,
            ["Ikana Castle Exterior"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana HP"] = function () return (has_arrows() or can_hookshot_short()) and has('MASK_DEKU') end,
        },
    },
    ["Ancient Castle of Ikana Interior South"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return true end,
            ["Ancient Castle of Ikana Wizzrobe"] = function () return has_mirror_shield() and event('IKANA_CASTLE_LIGHT') or can_use_light_arrows() end,
        },
    },
    ["Ancient Castle of Ikana Wizzrobe"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior South"] = function () return soul(SOUL_WIZZROBE) and can_use_light_arrows() end,
            ["Ancient Castle of Ikana Roof Interior"] = function () return soul(SOUL_WIZZROBE) and (can_fight() or has_arrows()) end,
        },
    },
    ["Ancient Castle of Ikana Roof Interior"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT2"] = function () return can_use_keg() end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return event('IKANA_CASTLE_LIGHT2') end,
            ["Ancient Castle of Ikana Wizzrobe"] = function () return true end,
            ["Ancient Castle of Ikana Roof Exterior"] = function () return trick('MM_IKANA_ROOF_PARKOUR') end,
        },
    },
    ["Ancient Castle of Ikana Behind Block"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return can_use_light_arrows() end,
            ["Ancient Castle of Ikana Pre-Boss"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Pre-Boss"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Behind Block"] = function () return true end,
            ["Ancient Castle of Ikana Throne Room"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Throne Room"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana After Boss"] = function () return soul(SOUL_IGOS) and has_mirror_shield() and can_use_fire_arrows() and can_fight() end,
        },
    },
    ["Ancient Castle of Ikana After Boss"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Pre-Boss"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Song Emptiness"] = function () return true end,
        },
    },
    ["Beneath the Well Entrance"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
            ["Beneath the Well North Section"] = function () return can_reset_time() and has('MASK_GIBDO') and soul_redead_gibdo() and has_blue_potion() end,
            ["Beneath the Well East Section"] = function () return can_reset_time() and has('MASK_GIBDO') and soul_redead_gibdo() and has_beans() end,
        },
    },
    ["Beneath the Well North Section"] = {
        ["events"] = {
            ["WELL_HOT_WATER"] = function () return event('FISH') and (has_explosives() or has_mask_zora() or trick_keg_explosives() or trick('MM_WELL_HSW')) end,
            ["WATER"] = function () return true end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return event('WATER') and (can_use_fire_arrows() or has_sticks()) end,
            ["BOMBS"] = function () return event('WATER') and (can_use_fire_arrows() or has_sticks()) end,
            ["RUPEES"] = function () return event('WATER') and (can_fight() or has_weapon_range() or has_explosives()) end,
        },
        ["locations"] = {
            ["Beneath the Well Keese Chest"] = function () return event('WATER') and event('BUGS') and can_use_lens() end,
        },
    },
    ["Beneath the Well East Section"] = {
        ["events"] = {
            ["STICKS"] = function () return can_kill_baba_sticks() end,
            ["WATER"] = function () return has_bottle() end,
            ["RUPEES"] = function () return can_fight() or has_weapon_range() or has_explosives() end,
        },
        ["exits"] = {
            ["Beneath the Well Entrance"] = function () return true end,
            ["Beneath the Well Middle Section"] = function () return has('MASK_GIBDO') and soul_redead_gibdo() and event('FISH') end,
            ["Beneath the Well Cow Hall"] = function () return has('MASK_GIBDO') and soul_redead_gibdo() and has_nuts() end,
        },
    },
    ["Beneath the Well Cow Hall"] = {
        ["events"] = {
            ["WELL_BIG_POE"] = function () return has_bombs() and has_weapon_range() end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["locations"] = {
            ["Beneath the Well Cow"] = function () return (event('WELL_HOT_WATER') or (has_hot_water_distance() and has('OWL_IKANA_CANYON')) or has_hot_water_er()) and can_play_epona() end,
        },
    },
    ["Beneath the Well Middle Section"] = {
        ["events"] = {
            ["STICKS"] = function () return can_kill_baba_both_sticks() end,
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Beneath the Well East Section"] = function () return true end,
            ["Beneath the Well Final Hall"] = function () return event('WELL_BIG_POE') end,
        },
        ["locations"] = {
            ["Beneath the Well Skulltulla Chest"] = function () return has('MASK_GIBDO') and soul_redead_gibdo() and event('BUGS') end,
        },
    },
    ["Beneath the Well Final Hall"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_fight() or has_weapon_range() or has_explosives() end,
            ["BUGS"] = function () return can_use_fire_arrows() or (event('WELL_BIG_POE') and has_sticks()) end,
        },
        ["exits"] = {
            ["Beneath the Well Middle Section"] = function () return true end,
            ["Beneath the Well Sun Block"] = function () return has('MASK_GIBDO') and soul_redead_gibdo() and has_milk() end,
        },
        ["locations"] = {
            ["Beneath the Well Skulltulla Chest"] = function () return has('MASK_GIBDO') and soul_redead_gibdo() and has_bottle() end,
        },
    },
    ["Beneath the Well Sun Block"] = {
        ["exits"] = {
            ["Beneath the Well Final Hall"] = function () return true end,
            ["Beneath the Well End"] = function () return has_mirror_shield() or can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Beneath the Well Mirror Shield"] = function () return can_use_fire_arrows() or event('WELL_BIG_POE') end,
        },
    },
    ["Beneath the Well End"] = {
        ["exits"] = {
            ["Beneath the Well Sun Block"] = function () return can_reset_time() and can_use_light_arrows() end,
            ["Ikana Castle Exterior"] = function () return true end,
        },
    },
    ["Great Bay Temple"] = {
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return can_reset_time() end,
            ["Zora Cape Peninsula"] = function () return can_hookshot() end,
        },
    },
    ["Great Bay Temple Entrance"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return true end,
            ["Great Bay Temple Water Wheel"] = function () return true end,
            ["Great Bay Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_GYORG') end,
        },
        ["locations"] = {
            ["Great Bay Temple Entrance Chest"] = function () return has_sticks() or can_use_fire_arrows() end,
        },
    },
    ["Great Bay Temple Water Wheel"] = {
        ["events"] = {
            ["GB_WATER_WHEEL"] = function () return event('GB_PIPE_RED') and event('GB_PIPE_RED2') and can_hookshot() end,
        },
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return true end,
            ["Great Bay Temple Central Room"] = function () return has_mask_zora() or (has_mask_goron() and trick('MM_GBT_WATERWHEEL_GORON')) end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Water Wheel Platform"] = function () return has_mask_zora() or (has('MASK_GREAT_FAIRY') and (has_arrows() or can_hookshot())) end,
            ["Great Bay Temple SF Water Wheel Skulltula"] = function () return soul_skulltula() end,
        },
    },
    ["Great Bay Temple Central Room"] = {
        ["exits"] = {
            ["Great Bay Temple Water Wheel"] = function () return true end,
            ["Great Bay Temple Map Room"] = function () return true end,
            ["Great Bay Temple Red Pipe 1"] = function () return true end,
            ["Great Bay Temple Green Pipe 1"] = function () return can_use_ice_arrows() end,
            ["Great Bay Temple Compass Room"] = function () return event('GB_WATER_WHEEL') end,
            ["Great Bay Temple Pre-Boss"] = function () return event('GB_WATER_WHEEL') end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Central Room Barrel"] = function () return true end,
            ["Great Bay Temple SF Central Room Underwater Pot"] = function () return has_mask_zora() or (has_arrows() and has('MASK_GREAT_FAIRY')) end,
        },
    },
    ["Great Bay Temple Map Room"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Baba Room"] = function () return true end,
            ["Great Bay Temple Red Pipe 2"] = function () return can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Great Bay Temple Map"] = function () return true end,
            ["Great Bay Temple SF Map Room Pot"] = function () return true end,
        },
    },
    ["Great Bay Temple Baba Room"] = {
        ["exits"] = {
            ["Great Bay Temple Compass Room"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Baba Chest"] = function () return soul(SOUL_BIO_BABA) end,
        },
    },
    ["Great Bay Temple Compass Room"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Baba Room"] = function () return true end,
            ["Great Bay Temple Central Room"] = function () return true end,
            ["Great Bay Temple Boss Key Room"] = function () return can_use_ice_arrows() and can_use_fire_arrows() end,
            ["Great Bay Temple Green Pipe 2"] = function () return event('GB_WATER_WHEEL') end,
        },
        ["locations"] = {
            ["Great Bay Temple Compass"] = function () return true end,
            ["Great Bay Temple Compass Room Underwater"] = function () return true end,
            ["Great Bay Temple SF Compass Room Pot"] = function () return true end,
        },
    },
    ["Great Bay Temple Red Pipe 1"] = {
        ["events"] = {
            ["GB_PIPE_RED"] = function () return soul_octorok() and can_use_ice_arrows() end,
        },
        ["exits"] = {
            ["Great Bay Temple Ice Arrow Room"] = function () return small_keys(SMALL_KEY_GB, 1) end,
        },
    },
    ["Great Bay Temple Ice Arrow Room"] = {
        ["events"] = {
            ["MAGIC"] = function () return soul(SOUL_CHUCHU) and (has_weapon() or has_mask_zora() or has('MASK_DEKU') or has_explosives()) end,
        },
        ["exits"] = {
            ["Great Bay Temple Red Pipe 1"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Ice Arrow"] = function () return soul(SOUL_WART) end,
        },
    },
    ["Great Bay Temple Red Pipe 2"] = {
        ["events"] = {
            ["GB_PIPE_RED2"] = function () return soul(SOUL_CHUCHU) and can_use_ice_arrows() end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Map Room"] = function () return true end,
        },
    },
    ["Great Bay Temple Boss Key Room"] = {
        ["events"] = {
            ["FROG_4"] = function () return has('MASK_DON_GERO') and soul(SOUL_GEKKO) end,
        },
        ["exits"] = {
            ["Great Bay Temple Compass Room"] = function () return soul(SOUL_GEKKO) end,
        },
        ["locations"] = {
            ["Great Bay Temple Boss Key"] = function () return soul(SOUL_GEKKO) end,
        },
    },
    ["Great Bay Temple Green Pipe 1"] = {
        ["events"] = {
            ["GB_PIPE_GREEN"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Central Room"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 1 Chest"] = function () return can_hookshot() end,
        },
    },
    ["Great Bay Temple Green Pipe 2"] = {
        ["exits"] = {
            ["Great Bay Temple Green Pipe 3"] = function () return can_use_ice_arrows() and can_use_fire_arrows() end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 2 Lower Chest"] = function () return can_hookshot() or (can_use_ice_arrows() and can_hookshot_short()) end,
            ["Great Bay Temple Green Pipe 2 Upper Chest"] = function () return can_hookshot() and can_use_ice_arrows() and can_use_fire_arrows() end,
        },
    },
    ["Great Bay Temple Green Pipe 3"] = {
        ["events"] = {
            ["GB_PIPE_GREEN2"] = function () return can_use_ice_arrows() and can_use_fire_arrows() end,
        },
        ["exits"] = {
            ["Great Bay Temple Green Pipe 2"] = function () return true end,
            ["Great Bay Temple Map Room"] = function () return can_use_fire_arrows() and can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 3 Chest"] = function () return can_use_ice_arrows() and can_use_fire_arrows() and can_hookshot() end,
            ["Great Bay Temple SF Green Pipe 3 Barrel"] = function () return true end,
        },
    },
    ["Great Bay Temple Pre-Boss"] = {
        ["exits"] = {
            ["Great Bay Temple Central Room"] = function () return true end,
            ["Great Bay Temple Boss Access"] = function () return boss_key(BOSS_KEY_GB) and event('GB_PIPE_GREEN') and event('GB_PIPE_GREEN2') end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Pre-Boss Above Water"] = function () return can_use_ice_arrows() or (has('MASK_GREAT_FAIRY') and (has_arrows() or can_hookshot())) end,
            ["Great Bay Temple SF Pre-Boss Underwater"] = function () return true end,
        },
    },
    ["Great Bay Temple Boss Access"] = {
        ["exits"] = {
            ["Great Bay Temple Boss"] = function () return true end,
        },
    },
    ["Great Bay Temple Boss"] = {
        ["exits"] = {
            ["Great Bay Temple After Boss"] = function () return soul(SOUL_GYORG) and (has_magic() and (has_mask_zora() and has_arrows() or has('MASK_FIERCE_DEITY'))) end,
        },
    },
    ["Great Bay Temple After Boss"] = {
        ["events"] = {
            ["BOSS_GREAT_BAY"] = function () return true end,
        },
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Boss HC"] = function () return true end,
            ["Great Bay Temple Boss"] = function () return true end,
        },
    },
    ["Moon"] = {
        ["exits"] = {
            ["Moon Trial Deku Entrance"] = function () return can_reset_time_on_moon() and masks(1) end,
            ["Moon Trial Goron Entrance"] = function () return can_reset_time_on_moon() and masks(2) end,
            ["Moon Trial Zora"] = function () return can_reset_time_on_moon() and masks(3) end,
            ["Moon Trial Link Entrance"] = function () return can_reset_time_on_moon() and masks(4) end,
            ["Moon Boss"] = function () return setting('majoraChild', 'none') or (setting('majoraChild', 'custom') and special(MAJORA)) end,
        },
        ["locations"] = {
            ["Moon Fierce Deity Mask"] = function () return can_reset_time_on_moon() and masks(20) and event('MOON_TRIAL_DEKU') and event('MOON_TRIAL_GORON') and event('MOON_TRIAL_ZORA') and event('MOON_TRIAL_LINK') end,
        },
    },
    ["Moon Trial Deku Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Deku Exit"] = function () return has('MASK_DEKU') end,
        },
        ["locations"] = {
            ["Moon Trial Deku HP"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Moon Trial Deku Exit"] = {
        ["events"] = {
            ["MOON_TRIAL_DEKU"] = function () return true end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Deku Entrance"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Moon Trial Goron Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Goron Exit"] = function () return goron_fast_roll() end,
        },
        ["locations"] = {
            ["Moon Trial Goron HP"] = function () return goron_fast_roll() end,
        },
    },
    ["Moon Trial Goron Exit"] = {
        ["events"] = {
            ["MOON_TRIAL_GORON"] = function () return true end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Goron Entrance"] = function () return goron_fast_roll() end,
        },
    },
    ["Moon Trial Zora"] = {
        ["events"] = {
            ["MOON_TRIAL_ZORA"] = function () return has_mask_zora() end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
        },
        ["locations"] = {
            ["Moon Trial Zora HP"] = function () return has_mask_zora() end,
        },
    },
    ["Moon Trial Link Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Link Dinalfos Fight"] = function () return true end,
        },
    },
    ["Moon Trial Link Dinalfos Fight"] = {
        ["exits"] = {
            ["Moon Trial Link Entrance"] = function () return soul_lizalfos_dinalfos() and (can_fight() or can_use_deku_bubble() or has_arrows()) end,
            ["Moon Trial Link Rest 1"] = function () return soul_lizalfos_dinalfos() and (can_fight() or can_use_deku_bubble() or has_arrows()) end,
        },
    },
    ["Moon Trial Link Rest 1"] = {
        ["exits"] = {
            ["Moon Trial Link Dinalfos Fight"] = function () return true end,
            ["Moon Trial Link Garo Fight"] = function () return true end,
        },
    },
    ["Moon Trial Link Garo Fight"] = {
        ["exits"] = {
            ["Moon Trial Link Rest 1"] = function () return soul(SOUL_GARO) and (has_weapon() or has_mask_goron() or can_use_deku_bubble() or has_arrows()) end,
            ["Moon Trial Link Rest 2"] = function () return soul(SOUL_GARO) and (has_weapon() or has_mask_goron() or can_use_deku_bubble() or has_arrows()) and can_hookshot_short() end,
        },
        ["locations"] = {
            ["Moon Trial Link Garo Master Chest"] = function () return soul(SOUL_GARO) and (can_fight() or can_use_deku_bubble() or has_arrows()) and can_hookshot_short() end,
        },
    },
    ["Moon Trial Link Rest 2"] = {
        ["exits"] = {
            ["Moon Trial Link Garo Fight"] = function () return true end,
            ["Moon Trial Link Iron Knuckle Fight"] = function () return true end,
        },
    },
    ["Moon Trial Link Iron Knuckle Fight"] = {
        ["exits"] = {
            ["Moon Trial Link Rest 2"] = function () return soul_iron_knuckle() and (has_weapon() or has_mask_goron() or has_bombs()) end,
            ["Moon Trial Link Rest 3"] = function () return soul_iron_knuckle() and (has_weapon() or has_mask_goron() or has_bombs()) and has_bombchu() and has_arrows() end,
        },
        ["locations"] = {
            ["Moon Trial Link Iron Knuckle Chest"] = function () return soul_iron_knuckle() and (has_weapon() or has_mask_goron() or has_bombs()) end,
        },
    },
    ["Moon Trial Link Rest 3"] = {
        ["exits"] = {
            ["Moon Trial Link Iron Knuckle Fight"] = function () return true end,
            ["Moon Trial Link Exit"] = function () return has_bombchu() and can_use_fire_arrows() end,
        },
        ["locations"] = {
            ["Moon Trial Link HP"] = function () return true end,
        },
    },
    ["Moon Trial Link Exit"] = {
        ["events"] = {
            ["MOON_TRIAL_LINK"] = function () return true end,
        },
        ["exits"] = {
            ["Moon Trial Link Rest 3"] = function () return true end,
            ["Moon"] = function () return true end,
        },
    },
    ["Moon Boss"] = {
        ["events"] = {
            ["MAJORA_PHASE_1"] = function () return has_arrows() or has_mask_zora() or (has('MASK_FIERCE_DEITY') and has_magic()) end,
            ["MAJORA"] = function () return not setting('goal', 'triforce') and event('MAJORA_PHASE_1') and (has_weapon() or has_mask_zora() or (has('MASK_FIERCE_DEITY') and has_magic())) end,
        },
    },
    ["Ocean Spider House"] = {
        ["exits"] = {
            ["Ocean Spider House Front"] = function () return can_reset_time() and (has_explosives() or trick_keg_explosives()) end,
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Ocean Spider House Wallet"] = function () return has('GS_TOKEN_OCEAN', 30) end,
        },
    },
    ["Ocean Spider House Front"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ocean Spider House"] = function () return true end,
            ["Ocean Spider House Back"] = function () return can_hookshot_short() or can_goron_bomb_jump() end,
        },
        ["locations"] = {
            ["Ocean Skulltula Entrance Right Wall"] = function () return can_hookshot_short() end,
            ["Ocean Skulltula Entrance Left Wall"] = function () return can_hookshot_short() end,
            ["Ocean Skulltula Entrance Web"] = function () return can_hookshot_short() or (can_use_fire_arrows() and has_mask_zora()) end,
        },
    },
    ["Ocean Spider House Back"] = {
        ["locations"] = {
            ["Ocean Skulltula 2nd Room Ceiling Edge"] = function () return can_hookshot_short() or has_mask_zora() end,
            ["Ocean Skulltula 2nd Room Ceiling Plank"] = function () return can_hookshot_short() or has_mask_zora() end,
            ["Ocean Skulltula 2nd Room Jar"] = function () return true end,
            ["Ocean Skulltula 2nd Room Webbed Hole"] = function () return can_hookshot_short() end,
            ["Ocean Skulltula 2nd Room Behind Skull 1"] = function () return can_hookshot_short() or has_mask_zora() end,
            ["Ocean Skulltula 2nd Room Behind Skull 2"] = function () return true end,
            ["Ocean Skulltula 2nd Room Webbed Pot"] = function () return true end,
            ["Ocean Skulltula 2nd Room Upper Pot"] = function () return true end,
            ["Ocean Skulltula 2nd Room Lower Pot"] = function () return true end,
            ["Ocean Skulltula Library Hole Behind Picture"] = function () return can_hookshot() end,
            ["Ocean Skulltula Library Hole Behind Cabinet"] = function () return can_hookshot_short() end,
            ["Ocean Skulltula Library On Corner Bookshelf"] = function () return true end,
            ["Ocean Skulltula Library Behind Picture"] = function () return can_hookshot_short() or has_arrows() or has_mask_zora() or can_use_deku_bubble() end,
            ["Ocean Skulltula Library Behind Bookcase 1"] = function () return true end,
            ["Ocean Skulltula Library Behind Bookcase 2"] = function () return true end,
            ["Ocean Skulltula Library Ceiling Edge"] = function () return can_hookshot_short() or has_mask_zora() end,
            ["Ocean Skulltula Colored Skulls Chandelier 1"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Chandelier 2"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Chandelier 3"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Behind Picture"] = function () return can_hookshot_short() or has_mask_zora() or (has_mask_goron() and (has_arrows() or can_use_deku_bubble())) end,
            ["Ocean Skulltula Colored Skulls Pot"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Ceiling Edge"] = function () return can_hookshot_short() or has_mask_zora() end,
            ["Ocean Spider House Chest HP"] = function () return has_arrows() and (has('MASK_CAPTAIN') or trick('MM_CAPTAIN_SKIP')) end,
            ["Ocean Skulltula Storage Room Behind Boat"] = function () return true end,
            ["Ocean Skulltula Storage Room Ceiling Web"] = function () return can_use_fire_arrows() and (can_hookshot_short() or has_mask_zora()) end,
            ["Ocean Skulltula Storage Room Behind Crate"] = function () return can_hookshot_short() or has_mask_zora() or (has_mask_goron() and (has_arrows() or can_use_deku_bubble() or has_explosives() or trick_keg_explosives())) end,
            ["Ocean Skulltula Storage Room Crate"] = function () return true end,
            ["Ocean Skulltula Storage Room Jar"] = function () return can_hookshot_short() end,
        },
    },
    ["GLOBAL"] = {
        ["exits"] = {
            ["OOT SONGS"] = function () return setting('crossWarpOot') and has_ocarina() end,
            ["SOARING"] = function () return can_play(SONG_SOARING) end,
        },
    },
    ["Tingle Town"] = {
        ["locations"] = {
            ["Tingle Map Clock Town"] = function () return tingle_price(0) end,
            ["Tingle Map Woodfall"] = function () return tingle_price(1) end,
        },
    },
    ["Tingle Swamp"] = {
        ["locations"] = {
            ["Tingle Map Woodfall"] = function () return tingle_price(2) end,
            ["Tingle Map Snowhead"] = function () return tingle_price(3) end,
        },
    },
    ["Tingle Mountain"] = {
        ["locations"] = {
            ["Tingle Map Snowhead"] = function () return tingle_price(4) end,
            ["Tingle Map Ranch"] = function () return tingle_price(5) end,
        },
    },
    ["Tingle Ranch"] = {
        ["locations"] = {
            ["Tingle Map Ranch"] = function () return tingle_price(6) end,
            ["Tingle Map Great Bay"] = function () return tingle_price(7) end,
        },
    },
    ["Tingle Great Bay"] = {
        ["locations"] = {
            ["Tingle Map Great Bay"] = function () return tingle_price(8) end,
            ["Tingle Map Ikana"] = function () return tingle_price(9) end,
        },
    },
    ["Tingle Ikana"] = {
        ["locations"] = {
            ["Tingle Map Ikana"] = function () return tingle_price(10) end,
            ["Tingle Map Clock Town"] = function () return tingle_price(11) end,
        },
    },
    ["SOARING"] = {
        ["exits"] = {
            ["Owl Clock Town"] = function () return has('OWL_CLOCK_TOWN') end,
            ["Owl Milk Road"] = function () return has('OWL_MILK_ROAD') end,
            ["Owl Swamp"] = function () return has('OWL_SOUTHERN_SWAMP') end,
            ["Owl Woodfall"] = function () return has('OWL_WOODFALL') end,
            ["Owl Mountain"] = function () return has('OWL_MOUNTAIN_VILLAGE') end,
            ["Owl Snowhead"] = function () return has('OWL_SNOWHEAD') end,
            ["Owl Great Bay"] = function () return has('OWL_GREAT_BAY') end,
            ["Owl Zora Cape"] = function () return has('OWL_ZORA_CAPE') end,
            ["Owl Ikana"] = function () return has('OWL_IKANA_CANYON') end,
            ["Owl Stone Tower"] = function () return has('OWL_STONE_TOWER') end,
        },
    },
    ["Owl Clock Town"] = {
        ["exits"] = {
            ["Clock Town South"] = function () return can_reset_time() end,
            ["OOT Market"] = function () return true end,
            ["Clock Tower Roof"] = function () return after(NIGHT3_AM_12_00) end,
        },
        ["locations"] = {
            ["Clock Town Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Milk Road"] = {
        ["exits"] = {
            ["Milk Road"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Milk Road Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Swamp"] = {
        ["exits"] = {
            ["Swamp Front"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Southern Swamp Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Woodfall"] = {
        ["exits"] = {
            ["Woodfall Shrine"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Woodfall Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Mountain"] = {
        ["exits"] = {
            ["Mountain Village"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Mountain Village Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Snowhead"] = {
        ["exits"] = {
            ["Snowhead Entrance"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Snowhead Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Great Bay"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Great Bay Coast Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Zora Cape"] = {
        ["exits"] = {
            ["Zora Cape Peninsula"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Zora Cape Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Ikana"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Ikana Canyon Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Stone Tower"] = {
        ["exits"] = {
            ["Stone Tower Top"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Stone Tower Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Oath to Order"] = {
        ["locations"] = {
            ["Oath to Order"] = function () return true end,
        },
    },
    ["Clock Town"] = {
        ["exits"] = {
            ["GLOBAL"] = function () return true end,
            ["Clock Town South"] = function () return can_reset_time() end,
            ["Clock Tower Roof"] = function () return after(NIGHT3_AM_12_00) end,
            ["Owl Clock Town"] = function () return true end,
        },
        ["locations"] = {
            ["Initial Song of Healing"] = function () return true end,
            ["Clock Town Platform HP"] = function () return true end,
        },
    },
    ["Clock Town South"] = {
        ["events"] = {
            ["CLOCK_TOWN_SCRUB"] = function () return has('MOON_TEAR') end,
            ["MAIL_LETTER"] = function () return has('LETTER_TO_KAFEI') and before(DAY2_AM_11_30) end,
        },
        ["exits"] = {
            ["OOT Market"] = function () return true end,
            ["Termina Field"] = function () return true end,
            ["Clock Town South Upper West"] = function () return true end,
            ["Clock Town South Lower West"] = function () return true end,
            ["Clock Town South Upper East"] = function () return true end,
            ["Clock Town South Lower East"] = function () return true end,
            ["Clock Town North"] = function () return true end,
            ["Laundry Pool"] = function () return true end,
            ["Clock Tower Roof"] = function () return after(NIGHT3_AM_12_00) end,
            ["Owl Clock Town"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town South Chest Lower"] = function () return can_hookshot() or (has('MASK_DEKU') and event('CLOCK_TOWN_SCRUB')) or trick('MM_SCT_NOTHING') or can_goron_bomb_jump() end,
            ["Clock Town South Chest Upper"] = function () return (can_hookshot() or (has('MASK_DEKU') and event('CLOCK_TOWN_SCRUB')) or (can_goron_bomb_jump() and can_hookshot_short())) and final_day() end,
            ["Clock Town Platform HP"] = function () return true end,
            ["Clock Town Business Scrub"] = function () return event('CLOCK_TOWN_SCRUB') end,
            ["Clock Town Post Box"] = function () return has('MASK_POSTMAN') end,
        },
    },
    ["Clock Town South Upper West"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town South Lower West"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town South Upper East"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town South Lower East"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town North"] = {
        ["events"] = {
            ["HIDE_SEEK1"] = function () return has_weapon_range() and first_day() end,
            ["HIDE_SEEK2"] = function () return has_weapon_range() and second_day() end,
            ["HIDE_SEEK3"] = function () return has_weapon_range() and final_day() end,
            ["BOMBERS_NORTH1"] = function () return event('HIDE_SEEK1') end,
            ["BOMBERS_NORTH2"] = function () return event('HIDE_SEEK2') end,
            ["BOMBERS_NORTH3"] = function () return event('HIDE_SEEK3') end,
            ["BOMBER_CODE"] = function () return bombers1() or bombers2() or bombers3() end,
            ["SAKON_BOMB_BAG"] = function () return can_fight() and before(NIGHT1_AM_12_00) end,
            ["SAKON_BOOM"] = function () return (has_arrows() or can_hookshot_short()) and before(NIGHT1_AM_12_00) end,
            ["MAIL_LETTER"] = function () return has('LETTER_TO_KAFEI') and before(DAY2_AM_11_30) end,
            ["PICTURE_TINGLE"] = function () return has('PICTOGRAPH_BOX') and is_day() end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South"] = function () return true end,
            ["Clock Town East"] = function () return true end,
            ["Clock Town Fairy Fountain"] = function () return true end,
            ["Deku Playground"] = function () return true end,
            ["Tingle Town"] = function () return has_weapon_range() and is_day() end,
        },
        ["locations"] = {
            ["Clock Town Tree HP"] = function () return true end,
            ["Clock Town Bomber Notebook"] = function () return event('BOMBER_CODE') or event('GUESS_BOMBER') end,
            ["Clock Town Blast Mask"] = function () return event('SAKON_BOMB_BAG') end,
            ["Clock Town Keaton HP"] = function () return has_mask_keaton() end,
        },
    },
    ["Clock Town West"] = {
        ["events"] = {
            ["BOMBERS_WEST1"] = function () return event('HIDE_SEEK1') end,
            ["BOMBERS_WEST2"] = function () return event('HIDE_SEEK2') end,
            ["BOMBERS_WEST3"] = function () return event('HIDE_SEEK3') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South Upper West"] = function () return true end,
            ["Clock Town South Lower West"] = function () return true end,
            ["Bomb Shop"] = function () return true end,
            ["Trading Post"] = function () return true end,
            ["Curiosity Shop"] = function () return after(NIGHT1_PM_10_00) and before(DAY2_AM_06_00) or (after(NIGHT2_PM_10_00) and before(DAY3_AM_06_00)) or after(NIGHT3_PM_10_00) end,
            ["Post Office"] = function () return after(DAY1_PM_03_00) and before(NIGHT1_AM_12_00) or (event('MAIL_LETTER') and after(NIGHT2_PM_06_00) and before(NIGHT2_AM_12_00)) or is_night3() end,
            ["Swordsman School"] = function () return first_day() or second_day() or (after(DAY3_AM_06_00) and before(NIGHT3_PM_11_00)) or after(NIGHT3_AM_12_00) end,
            ["Lottery"] = function () return is_day() or (event('PLAY_LOTTERY') and (before(NIGHT1_PM_11_00) or (after(NIGHT2_PM_06_00) and before(NIGHT2_PM_11_00)) or (after(NIGHT3_PM_06_00) and before(NIGHT3_PM_11_00)))) end,
        },
        ["locations"] = {
            ["Clock Town Bank Reward 1"] = function () return can_use_wallet(1) end,
            ["Clock Town Bank Reward 2"] = function () return can_use_wallet(2) end,
            ["Clock Town Bank Reward 3"] = function () return can_use_wallet(3) end,
            ["Clock Town Rosa Sisters HP"] = function () return has('MASK_KAMARO') and (is_night1() or is_night2()) end,
        },
    },
    ["Clock Town East"] = {
        ["events"] = {
            ["GUESS_BOMBER"] = function () return trick('MM_BOMBER_SKIP') end,
            ["BOMBERS_EAST1"] = function () return event('HIDE_SEEK1') end,
            ["BOMBERS_EAST2"] = function () return event('HIDE_SEEK2') end,
            ["BOMBERS_EAST3"] = function () return event('HIDE_SEEK3') end,
            ["MAIL_LETTER"] = function () return has('LETTER_TO_KAFEI') and before(DAY2_AM_11_30) end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South Upper East"] = function () return true end,
            ["Clock Town South Lower East"] = function () return true end,
            ["Mayor's Office"] = function () return after(DAY1_AM_10_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_10_00) and before(NIGHT2_PM_08_00)) or after(DAY3_AM_10_00) end,
            ["Town Archery"] = function () return before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00)) end,
            ["Chest Game"] = function () return before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00)) end,
            ["Honey & Darling Game"] = function () return before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00)) end,
            ["Stock Pot Inn"] = function () return has('ROOM_KEY') or between(DAY1_AM_08_00, NIGHT1_PM_08_00) or between(DAY2_AM_08_00, NIGHT2_PM_08_00) or after(DAY3_AM_08_00) end,
            ["Stock Pot Inn Roof"] = function () return has('MASK_DEKU') end,
            ["Milk Bar"] = function () return after(DAY1_AM_10_00) and before(NIGHT1_PM_09_00) or (after(DAY2_AM_10_00) and before(NIGHT2_PM_09_00)) or (after(DAY3_AM_10_00) and before(NIGHT3_PM_09_00)) or (has('MASK_ROMANI') and (after(NIGHT1_PM_10_00) and before(NIGHT1_AM_05_00)) or (after(NIGHT2_PM_10_00) and before(NIGHT2_AM_05_00)) or after(NIGHT3_PM_10_00)) end,
            ["Astral Observatory Passage"] = function () return event('BOMBER_CODE') or trick('MM_BOMBER_SKIP') end,
        },
        ["locations"] = {
            ["Clock Town Silver Rupee Chest"] = function () return true end,
            ["Clock Town Postman Hat"] = function () return event('POSTMAN_FREEDOM') and before(NIGHT3_AM_05_00) end,
        },
    },
    ["Astral Observatory Passage"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Astral Observatory Junction"] = function () return true end,
        },
        ["locations"] = {
            ["Astral Observatory Passage Chest"] = function () return has_explosives() or trick_keg_explosives() end,
        },
    },
    ["Astral Observatory Junction"] = {
        ["exits"] = {
            ["Astral Observatory Passage"] = function () return true end,
            ["Astral Observatory"] = function () return true end,
        },
    },
    ["Laundry Pool"] = {
        ["events"] = {
            ["FROG_1"] = function () return has('MASK_DON_GERO') end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town South"] = function () return true end,
            ["Kafei Hideout"] = function () return event('MAIL_LETTER') and (after(DAY2_PM_02_00) and before(NIGHT2_PM_10_00)) or (event('MEET_KAFEI') and (after(DAY3_PM_01_00) and before(NIGHT3_PM_10_00))) end,
        },
        ["locations"] = {
            ["Clock Town Guru Guru Mask Bremen"] = function () return is_night1() or is_night2() end,
            ["Clock Town Stray Fairy"] = function () return is_day() end,
        },
    },
    ["Clock Town Fairy Fountain"] = {
        ["exits"] = {
            ["Clock Town North"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Great Fairy"] = function () return has('STRAY_FAIRY_TOWN') end,
            ["Clock Town Great Fairy Alt"] = function () return has('STRAY_FAIRY_TOWN') and (has('MASK_DEKU') or has_mask_goron() or has_mask_zora()) end,
        },
    },
    ["Clock Tower Roof"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play_time() end,
        },
        ["exits"] = {
            ["Moon"] = function () return can_play(SONG_ORDER) and special(MOON) end,
        },
        ["locations"] = {
            ["Clock Tower Roof Skull Kid Ocarina"] = function () return has_weapon_range() and can_play_time() end,
            ["Clock Tower Roof Skull Kid Song of Time"] = function () return has_weapon_range() and can_play_time() end,
        },
    },
    ["Bomb Shop"] = {
        ["events"] = {
            ["BUY_KEG"] = function () return has_mask_goron() and has('POWDER_KEG') and can_use_wallet(1) end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Bomb Shop Item 1"] = function () return shop_price(0) end,
            ["Bomb Shop Item 2"] = function () return shop_price(1) end,
            ["Bomb Shop Bomb Bag"] = function () return shop_price(2) end,
            ["Bomb Shop Bomb Bag 2"] = function () return event('SAKON_BOMB_BAG') and shop_price(3) end,
        },
    },
    ["Trading Post"] = {
        ["events"] = {
            ["SCARECROW"] = function () return has_ocarina() end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Trading Post Item 1"] = function () return shop_price(5) and before(NIGHT3_PM_09_00) end,
            ["Trading Post Item 2"] = function () return shop_price(6) and before(NIGHT3_PM_09_00) end,
            ["Trading Post Item 3"] = function () return shop_price(7) and before(NIGHT3_PM_09_00) end,
            ["Trading Post Item 4"] = function () return shop_price(8) and before(NIGHT3_PM_09_00) end,
            ["Trading Post Item 5"] = function () return shop_price(9) and before(NIGHT3_PM_09_00) end,
            ["Trading Post Item 6"] = function () return shop_price(10) and before(NIGHT3_PM_09_00) end,
            ["Trading Post Item 7"] = function () return shop_price(11) and before(NIGHT3_PM_09_00) end,
            ["Trading Post Item 8"] = function () return shop_price(12) and before(NIGHT3_PM_09_00) end,
        },
    },
    ["Curiosity Shop"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Bomb Shop Bomb Bag 2"] = function () return shop_ex_price(0) and is_night3() end,
            ["Curiosity Shop All-Night Mask"] = function () return (event('SAKON_BOMB_BAG') or event('SAKON_BOOM')) and shop_price(4) and is_night3() end,
        },
    },
    ["Kafei Hideout"] = {
        ["events"] = {
            ["MEET_KAFEI"] = function () return event('MAIL_LETTER') and before(DAY3_AM_06_00) end,
        },
        ["exits"] = {
            ["Laundry Pool"] = function () return true end,
        },
        ["locations"] = {
            ["Kafei Hideout Pendant of Memories"] = function () return event('MAIL_LETTER') and (before(DAY3_AM_06_00) or event('SAKON_BOMB_BAG') or event('SAKON_BOOM')) end,
            ["Kafei Hideout Owner Reward 1"] = function () return event('MEET_KAFEI') and between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
            ["Kafei Hideout Owner Reward 2"] = function () return event('MEET_KAFEI') and between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
        },
    },
    ["Post Office"] = {
        ["events"] = {
            ["POSTMAN_FREEDOM"] = function () return has('LETTER_TO_MAMA') and is_night3() end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Post Office HP"] = function () return (has_mask_bunny() or trick('MM_POST_OFFICE_GAME')) and (after(DAY1_PM_03_00) and before(NIGHT1_AM_12_00) or (event('MAIL_LETTER') and after(NIGHT2_PM_06_00) and before(NIGHT2_AM_12_00))) end,
        },
    },
    ["Swordsman School"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Swordsman School HP"] = function () return has('SWORD') and can_use_wallet(1) and before(NIGHT3_PM_11_00) end,
        },
    },
    ["Lottery"] = {
        ["events"] = {
            ["PLAY_LOTTERY"] = function () return is_day() and can_use_wallet(1) end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
    },
    ["Mayor's Office"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Mayor's Office Kafei's Mask"] = function () return after(DAY1_AM_10_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_10_00) and before(NIGHT2_PM_08_00)) end,
            ["Mayor's Office HP"] = function () return has('MASK_COUPLE') and (after(DAY1_AM_10_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_10_00) and before(NIGHT2_PM_08_00)) or (after(DAY3_AM_10_00) and before(NIGHT3_PM_06_00))) end,
        },
    },
    ["Milk Bar"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Milk Bar Troupe Leader Mask"] = function () return has('MASK_ROMANI') and has_ocarina() and has('MASK_DEKU') and has_mask_zora() and has_mask_goron() and (after(NIGHT1_PM_10_00) and before(NIGHT1_AM_05_00) or (after(NIGHT2_PM_10_00) and before(NIGHT2_AM_05_00))) end,
            ["Milk Bar Madame Aroma Bottle"] = function () return has('MASK_KAFEI') and has('LETTER_TO_MAMA') and (after(NIGHT3_PM_06_00) and before(NIGHT3_PM_09_00) or after(NIGHT3_PM_10_00)) end,
            ["Milk Bar Purchase Milk"] = function () return has('MASK_ROMANI') and can_use_wallet(1) and (after(NIGHT1_PM_10_00) and before(DAY2_AM_06_00) or (after(NIGHT2_PM_10_00) and before(DAY3_AM_06_00)) or (after(NIGHT3_PM_06_00) and before(NIGHT3_PM_09_00)) or after(NIGHT3_PM_10_00)) end,
            ["Milk Bar Purchase Chateau"] = function () return has('MASK_ROMANI') and can_use_wallet(2) and (after(NIGHT1_PM_10_00) and before(DAY2_AM_06_00) or (after(NIGHT2_PM_10_00) and before(DAY3_AM_06_00)) or (after(NIGHT3_PM_06_00) and before(NIGHT3_PM_09_00)) or after(NIGHT3_PM_10_00)) end,
        },
    },
    ["Town Archery"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Town Archery Reward 1"] = function () return has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00))) end,
            ["Town Archery Reward 2"] = function () return has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00))) end,
        },
    },
    ["Chest Game"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Chest Game HP"] = function () return has_mask_goron() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or is_day3()) end,
        },
    },
    ["Honey & Darling Game"] = {
        ["events"] = {
            ["HD_REWARD_1"] = function () return has_bomb_bag() and before(NIGHT1_PM_10_00) end,
            ["HD_REWARD_2"] = function () return has_bomb_bag() and after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00) end,
            ["HD_REWARD_3"] = function () return (has_bow() or can_use_deku_bubble()) and is_day3() end,
        },
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Honey & Darling Reward 1"] = function () return can_use_wallet(1) and (event('HD_REWARD_1') or event('HD_REWARD_2') or event('HD_REWARD_3')) end,
            ["Honey & Darling Reward 2"] = function () return can_use_wallet(1) and has_bow() and event('HD_REWARD_1') and event('HD_REWARD_2') and event('HD_REWARD_3') end,
        },
    },
    ["Stock Pot Inn"] = {
        ["events"] = {
            ["SETUP_MEET"] = function () return has('MASK_KAFEI') and after(DAY1_PM_01_45) and before(NIGHT1_PM_09_00) end,
            ["MEET_ANJU"] = function () return event('SETUP_MEET') and (has('MASK_DEKU') or has('ROOM_KEY')) end,
            ["DELIVER_PENDANT"] = function () return has('PENDANT_OF_MEMORIES') and (after(DAY2_AM_06_00) and before(NIGHT2_PM_09_00) or (after(DAY3_AM_06_00) and before(DAY3_AM_11_30))) end,
            ["BUGS"] = function () return has_bottle() end,
            ["FISH"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Stock Pot Inn Roof"] = function () return true end,
        },
        ["locations"] = {
            ["Stock Pot Inn Guest Room Chest"] = function () return has('ROOM_KEY') end,
            ["Stock Pot Inn Staff Room Chest"] = function () return is_night3() end,
            ["Stock Pot Inn Room Key"] = function () return after(DAY1_PM_01_45) and before(DAY1_PM_04_00) end,
            ["Stock Pot Inn Letter to Kafei"] = function () return cond(setting('erIndoors', 'none'), event('MEET_ANJU') and (has('ROOM_KEY') or has('MASK_DEKU')), event('MEET_ANJU')) end,
            ["Stock Pot Inn Couple's Mask"] = function () return event('SUN_MASK') and event('DELIVER_PENDANT') and event('MEET_ANJU') and after(NIGHT3_AM_04_00) end,
            ["Stock Pot Inn Grandma HP 1"] = function () return has('MASK_ALL_NIGHT') and (is_day1() or is_day2()) end,
            ["Stock Pot Inn Grandma HP 2"] = function () return has('MASK_ALL_NIGHT') and (is_day1() or is_day2()) end,
            ["Stock Pot Inn ??? HP"] = function () return has_paper() and midnight() end,
        },
    },
    ["Stock Pot Inn Roof"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Stock Pot Inn"] = function () return true end,
        },
    },
    ["Deku Playground"] = {
        ["events"] = {
            ["DEKU_REWARD_1"] = function () return after(DAY1_AM_06_00) and before(NIGHT1_AM_12_00) end,
            ["DEKU_REWARD_2"] = function () return after(DAY2_AM_06_00) and before(NIGHT2_AM_12_00) end,
            ["DEKU_REWARD_3"] = function () return after(DAY3_AM_06_00) and before(NIGHT3_AM_12_00) end,
        },
        ["exits"] = {
            ["Clock Town North"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Playground Reward 1"] = function () return has('MASK_DEKU') and can_use_wallet(1) and (event('DEKU_REWARD_1') or event('DEKU_REWARD_2') or event('DEKU_REWARD_3')) end,
            ["Deku Playground Reward 2"] = function () return has('MASK_DEKU') and can_use_wallet(1) and event('DEKU_REWARD_1') and event('DEKU_REWARD_2') and event('DEKU_REWARD_3') end,
        },
    },
    ["Astral Observatory"] = {
        ["events"] = {
            ["SCRUB_TELESCOPE"] = function () return true end,
            ["TEAR_TELESCOPE"] = function () return true end,
            ["SCARECROW"] = function () return has_ocarina() end,
        },
        ["exits"] = {
            ["Astral Observatory Junction"] = function () return true end,
            ["Astral Observatory Balcony"] = function () return true end,
        },
    },
    ["Astral Observatory Balcony"] = {
        ["exits"] = {
            ["Termina Field"] = function () return can_use_beans() or (can_goron_bomb_jump() and has_bombs()) end,
            ["Astral Observatory"] = function () return true end,
        },
        ["locations"] = {
            ["Astral Observatory Moon Tear"] = function () return event('TEAR_TELESCOPE') end,
        },
    },
    ["Termina Field"] = {
        ["events"] = {
            ["STICKS"] = function () return can_kill_baba_both_sticks() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["MAGIC"] = function () return soul(SOUL_CHUCHU) end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town South"] = function () return true end,
            ["Clock Town North"] = function () return true end,
            ["Clock Town East"] = function () return true end,
            ["Clock Town West"] = function () return true end,
            ["Road to Southern Swamp"] = function () return true end,
            ["Behind Large Icicles"] = function () return has_arrows() or (has_hot_water_distance() and has('OWL_CLOCK_TOWN')) or has_hot_water_er() end,
            ["Milk Road"] = function () return true end,
            ["Great Bay Fence"] = function () return can_play_epona() or (can_goron_bomb_jump() and has_bombs()) end,
            ["Road to Ikana Front"] = function () return true end,
            ["Astral Observatory Balcony"] = function () return has('MASK_DEKU') or (can_goron_bomb_jump() and has_bombs()) end,
            ["Grass Grotto"] = function () return true end,
            ["Peahat Grotto"] = function () return true end,
            ["Bio Baba Grotto"] = function () return can_break_boulders() end,
            ["Dodongo Grotto"] = function () return true end,
            ["Pillar Grotto"] = function () return true end,
            ["Scrub Grotto"] = function () return true end,
            ["Termina Field Cow Grotto"] = function () return has_explosives() end,
            ["Swamp Gossip Grotto"] = function () return true end,
            ["Mountain Gossip Grotto"] = function () return true end,
            ["Ocean Gossip Grotto"] = function () return can_break_boulders() end,
            ["Canyon Gossip Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Water Chest"] = function () return has_mask_zora() end,
            ["Termina Field Tall Grass Chest"] = function () return true end,
            ["Termina Field Tree Stump Chest"] = function () return can_hookshot_short() or can_use_beans() end,
            ["Termina Field Kamaro Mask"] = function () return can_play(SONG_HEALING) and midnight() end,
        },
    },
    ["Grass Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Tall Grass Grotto"] = function () return true end,
        },
    },
    ["Peahat Grotto"] = {
        ["events"] = {
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Peahat Grotto"] = function () return soul_peahat() and (can_fight() or has_arrows() or has('MASK_DEKU')) and is_day() end,
        },
    },
    ["Bio Baba Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Bio Baba Grotto"] = function () return has_mask_zora() end,
        },
    },
    ["Dodongo Grotto"] = {
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Dodongo Grotto"] = function () return soul_dodongo() and (has_weapon() or has_explosives() or has_mask_goron() or has_arrows()) end,
        },
    },
    ["Pillar Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Pillar Grotto"] = function () return true end,
        },
    },
    ["Scrub Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Scrub"] = function () return event('SCRUB_TELESCOPE') and can_use_wallet(2) end,
        },
    },
    ["Termina Field Cow Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Cow Front"] = function () return can_play_epona() end,
            ["Termina Field Cow Back"] = function () return can_play_epona() end,
        },
    },
    ["Swamp Gossip Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
            ["SWAMP_SONG"] = function () return has_ocarina() and (has_mask_goron() and has_goron_song() or (has('MASK_DEKU') and has('SONG_AWAKENING')) or (has_mask_zora() and has('SONG_ZORA'))) end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
        },
    },
    ["Mountain Gossip Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return has_bottle() end,
            ["MOUNTAIN_SONG"] = function () return has_ocarina() and (has_mask_goron() and has_goron_song() or (has('MASK_DEKU') and has('SONG_AWAKENING')) or (has_mask_zora() and has('SONG_ZORA'))) end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
        },
    },
    ["Ocean Gossip Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
            ["OCEAN_SONG"] = function () return has_ocarina() and (has_mask_goron() and has_goron_song() or (has('MASK_DEKU') and has('SONG_AWAKENING')) or (has_mask_zora() and has('SONG_ZORA'))) end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
        },
    },
    ["Canyon Gossip Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
            ["CANYON_SONG"] = function () return has_ocarina() and (has_mask_goron() and has_goron_song() or (has('MASK_DEKU') and has('SONG_AWAKENING')) or (has_mask_zora() and has('SONG_ZORA'))) end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
        },
    },
    ["Road to Southern Swamp"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
            ["WATER"] = function () return has_bottle() end,
            ["PICTURE_TINGLE"] = function () return has('PICTOGRAPH_BOX') end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
            ["Termina Field"] = function () return true end,
            ["Swamp Archery"] = function () return before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00)) end,
            ["Road to Southern Swamp Grotto"] = function () return true end,
            ["Tingle Swamp"] = function () return has_weapon_range() end,
        },
        ["locations"] = {
            ["Road to Southern Swamp HP"] = function () return has_weapon_range() end,
        },
    },
    ["Swamp Archery"] = {
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Archery Reward 1"] = function () return has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00))) end,
            ["Swamp Archery Reward 2"] = function () return has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_10_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_10_00))) end,
        },
    },
    ["Road to Southern Swamp Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Southern Swamp Grotto"] = function () return true end,
        },
    },
    ["Swamp Front"] = {
        ["events"] = {
            ["FROG_3"] = function () return has('MASK_DON_GERO') end,
            ["PICTURE_SWAMP"] = function () return has('PICTOGRAPH_BOX') end,
            ["PICTURE_BIG_OCTO"] = function () return has('PICTOGRAPH_BOX') and soul_octorok() end,
            ["STICKS"] = function () return true end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["WATER"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
            ["Tourist Information"] = function () return true end,
            ["Swamp Back"] = function () return event('BOAT_RIDE') or event('CLEAN_SWAMP') or has_mask_zora() or (has('MASK_DEKU') and (has_arrows() or can_hookshot_short())) end,
            ["Swamp Potion Shop"] = function () return true end,
            ["Woods of Mystery"] = function () return true end,
            ["Owl Swamp"] = function () return true end,
        },
        ["locations"] = {
            ["Southern Swamp HP"] = function () return has('DEED_LAND') and has('MASK_DEKU') or (trick('MM_SOUTHERN_SWAMP_SCRUB_HP_GORON') and has_mask_goron()) end,
            ["Southern Swamp Scrub Deed"] = function () return has('DEED_LAND') end,
            ["Southern Swamp Scrub Shop"] = function () return has('MASK_DEKU') and can_use_wallet(1) end,
        },
    },
    ["Swamp Back"] = {
        ["events"] = {
            ["PICTURE_SWAMP"] = function () return has('PICTOGRAPH_BOX') end,
            ["PICTURE_BIG_OCTO"] = function () return has('PICTOGRAPH_BOX') and soul_octorok() end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return event('BOAT_RIDE') or event('CLEAN_SWAMP') or has_mask_zora() or ((has_arrows() or can_hookshot()) and (has('MASK_DEKU') or has_mask_goron())) end,
            ["Deku Palace Front"] = function () return true end,
            ["Near Swamp Spider House"] = function () return has('MASK_DEKU') or has_mask_zora() or event('CLEAN_SWAMP') end,
            ["Swamp Canopy Back"] = function () return event('CLEAN_SWAMP') end,
        },
    },
    ["Near Swamp Spider House"] = {
        ["exits"] = {
            ["Swamp Spider House"] = function () return has_sticks() or has_arrows() end,
            ["Swamp Back"] = function () return has('MASK_DEKU') or has_mask_zora() or event('CLEAN_SWAMP') end,
            ["Near Swamp Grotto"] = function () return has('MASK_DEKU') or has_mask_zora() or event('CLEAN_SWAMP') end,
        },
    },
    ["Near Swamp Grotto"] = {
        ["events"] = {
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return (has_arrows() or can_hookshot()) and has_mask_goron() end,
            ["Near Swamp Spider House"] = function () return has('MASK_DEKU') or has_mask_zora() or event('CLEAN_SWAMP') end,
            ["Southern Swamp Grotto"] = function () return true end,
        },
    },
    ["Southern Swamp Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Near Swamp Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Southern Swamp Grotto"] = function () return true end,
        },
    },
    ["Tourist Information"] = {
        ["events"] = {
            ["BOAT_RIDE"] = function () return event('PICTURE_SWAMP') or event('KOUME') end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
            ["Swamp Back"] = function () return event('BOAT_RIDE') end,
        },
        ["locations"] = {
            ["Tourist Information Pictobox"] = function () return event('KOUME') end,
            ["Tourist Information Boat Archery"] = function () return event('KOUME') and event('CLEAN_SWAMP') and has_bow() end,
            ["Tourist Information Tingle Picture"] = function () return event('PICTURE_TINGLE') or event('PICTURE_DEKU_KING') end,
        },
    },
    ["Woods of Mystery"] = {
        ["events"] = {
            ["KOUME"] = function () return has_red_or_blue_potion() end,
            ["MEET_KOUME"] = function () return true end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
            ["Woods of Mystery Grotto"] = function () return second_day() end,
        },
        ["locations"] = {
            ["Swamp Potion Shop Kotake"] = function () return true end,
        },
    },
    ["Woods of Mystery Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Woods of Mystery"] = function () return second_day() end,
        },
        ["locations"] = {
            ["Woods of Mystery Grotto"] = function () return true end,
        },
    },
    ["Swamp Potion Shop"] = {
        ["events"] = {
            ["RED_POTION"] = function () return event('MEET_KOUME') end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Potion Shop Item 1"] = function () return event('MUSHROOM') and shop_price(13) and (first_day() or event('MEET_KOUME')) end,
            ["Swamp Potion Shop Item 2"] = function () return shop_price(14) and (first_day() or event('MEET_KOUME')) end,
            ["Swamp Potion Shop Item 3"] = function () return shop_price(15) and (first_day() or event('MEET_KOUME')) end,
        },
    },
    ["Deku Palace Front"] = {
        ["events"] = {
            ["PICTURE_BIG_OCTO"] = function () return soul_octorok() and has('MASK_DEKU') and has('PICTOGRAPH_BOX') end,
            ["NUTS"] = function () return soul_deku_baba() and (has('MASK_DEKU') or (event('CLEAN_SWAMP') and (can_fight() or has_arrows() or has_explosives() or can_hookshot_short()))) end,
        },
        ["exits"] = {
            ["Swamp Back"] = function () return true end,
            ["Deku Palace Cliff"] = function () return has('MASK_DEKU') end,
            ["Near Deku Shrine"] = function () return event('CLEAN_SWAMP') end,
            ["Deku Palace Main"] = function () return has('MASK_DEKU') or trick('MM_PALACE_GUARD_SKIP') end,
            ["Deku Palace Upper"] = function () return (event('CLEAN_SWAMP') or has('MASK_DEKU')) and can_use_beans() end,
        },
    },
    ["Deku Palace Main"] = {
        ["exits"] = {
            ["Deku Palace Throne"] = function () return true end,
            ["Deku Palace Front"] = function () return true end,
            ["Deku Palace Grotto"] = function () return true end,
            ["Deku Palace Upper"] = function () return trick('MM_PALACE_BEAN_SKIP') end,
        },
        ["locations"] = {
            ["Deku Palace HP"] = function () return true end,
        },
    },
    ["Deku Palace Upper"] = {
        ["events"] = {
            ["MAGIC"] = function () return has('MASK_DEKU') end,
        },
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
            ["Deku Palace Near Cage"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Deku Palace Throne"] = {
        ["events"] = {
            ["PICTURE_DEKU_KING"] = function () return has('PICTOGRAPH_BOX') and has('MASK_DEKU') end,
            ["RETURN_PRINCESS"] = function () return event('DEKU_PRINCESS') and has('MASK_DEKU') end,
        },
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
        },
    },
    ["Deku Palace Near Cage"] = {
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
            ["Deku Palace Upper"] = function () return has('MASK_DEKU') and soul_deku_scrub() end,
            ["Deku Palace Cage"] = function () return true end,
        },
    },
    ["Deku Palace Cage"] = {
        ["exits"] = {
            ["Deku Palace Near Cage"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Palace Sonata of Awakening"] = function () return has('MASK_DEKU') and has_ocarina() end,
        },
    },
    ["Deku Palace Grotto"] = {
        ["events"] = {
            ["MAGIC_BEANS_PALACE"] = function () return can_use_wallet(1) end,
            ["ARROWS"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["WATER"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Palace Grotto Chest"] = function () return can_use_beans() or can_hookshot() or (can_hookshot_short() and trick('MM_SHORT_HOOK_HARD')) end,
        },
    },
    ["Deku Palace Cliff"] = {
        ["exits"] = {
            ["Deku Palace Front"] = function () return has('MASK_DEKU') or event('CLEAN_SWAMP') end,
            ["Swamp Canopy Front"] = function () return true end,
        },
    },
    ["Swamp Canopy Front"] = {
        ["exits"] = {
            ["Near Swamp Grotto"] = function () return true end,
            ["Deku Palace Cliff"] = function () return true end,
            ["Swamp Canopy Back"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Swamp Canopy Back"] = {
        ["exits"] = {
            ["Swamp Back"] = function () return has('MASK_DEKU') or has_mask_zora() or event('CLEAN_SWAMP') end,
            ["Woodfall"] = function () return true end,
            ["Swamp Canopy Front"] = function () return has('MASK_DEKU') end,
        },
        ["locations"] = {
            ["Southern Swamp Song of Soaring"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Woodfall"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Swamp Canopy Back"] = function () return true end,
            ["Woodfall Shrine"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or event('CLEAN_SWAMP')) end,
            ["Woodfall Temple Princess Jail"] = function () return event('CLEAN_SWAMP') and event('OPEN_WOODFALL_TEMPLE') end,
        },
        ["locations"] = {
            ["Woodfall Entrance Chest"] = function () return has('MASK_DEKU') or can_hookshot() or event('CLEAN_SWAMP') end,
            ["Woodfall HP Chest"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or event('CLEAN_SWAMP')) or can_hookshot() end,
            ["Woodfall Near Owl Chest"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or event('CLEAN_SWAMP')) or (event('CLEAN_SWAMP') and can_hookshot()) end,
        },
    },
    ["Woodfall Front of Temple"] = {
        ["exits"] = {
            ["Woodfall Temple"] = function () return true end,
            ["Woodfall Shrine"] = function () return has('MASK_DEKU') end,
            ["Woodfall"] = function () return event('CLEAN_SWAMP') end,
        },
    },
    ["Woodfall Shrine"] = {
        ["events"] = {
            ["OPEN_WOODFALL_TEMPLE"] = function () return has('MASK_DEKU') and can_play(SONG_AWAKENING) end,
            ["STICKS"] = function () return true end,
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or event('CLEAN_SWAMP')) or event('CLEAN_SWAMP') end,
            ["Woodfall Near Fairy Fountain"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or event('CLEAN_SWAMP')) end,
            ["Woodfall Front of Temple"] = function () return event('OPEN_WOODFALL_TEMPLE') end,
            ["Owl Woodfall"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Near Owl Chest"] = function () return has('MASK_DEKU') or can_hookshot() end,
        },
    },
    ["Woodfall Near Fairy Fountain"] = {
        ["exits"] = {
            ["Woodfall"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or event('CLEAN_SWAMP')) or event('CLEAN_SWAMP') end,
            ["Woodfall Shrine"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or event('CLEAN_SWAMP')) end,
            ["Woodfall Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Near Owl Chest"] = function () return can_hookshot() end,
        },
    },
    ["Woodfall Fairy Fountain"] = {
        ["exits"] = {
            ["Woodfall Near Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Great Fairy"] = function () return has('STRAY_FAIRY_WF', 15) end,
        },
    },
    ["Near Deku Shrine"] = {
        ["exits"] = {
            ["Deku Palace Front"] = function () return event('CLEAN_SWAMP') or has('MASK_DEKU') end,
            ["Deku Shrine"] = function () return true end,
        },
    },
    ["Deku Shrine"] = {
        ["exits"] = {
            ["Near Deku Shrine"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Shrine Mask of Scents"] = function () return event('RETURN_PRINCESS') and has_weapon_range() end,
        },
    },
    ["Behind Large Icicles"] = {
        ["exits"] = {
            ["Termina Field"] = function () return has_arrows() or has_hot_water_mtn() or has_hot_water_er() end,
            ["Mountain Village Path Lower"] = function () return true end,
        },
    },
    ["Mountain Village Path Lower"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() end,
            ["MAGIC"] = function () return event('BOSS_SNOWHEAD') end,
        },
        ["exits"] = {
            ["Behind Large Icicles"] = function () return true end,
            ["Mountain Village Path Upper"] = function () return can_break_boulders() or can_use_fire_arrows() or event('BOSS_SNOWHEAD') end,
        },
    },
    ["Mountain Village Path Upper"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Mountain Village Path Lower"] = function () return can_break_boulders() or can_use_fire_arrows() or event('BOSS_SNOWHEAD') end,
            ["Mountain Village"] = function () return true end,
        },
    },
    ["Mountain Village"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return event('BOSS_SNOWHEAD') or ((can_break_boulders() or can_use_fire_arrows()) and (second_day() or final_day())) or ((can_break_boulders() or can_use_fire_arrows()) and can_use_light_arrows() and first_day()) end,
        },
        ["exits"] = {
            ["Mountain Village Path Upper"] = function () return true end,
            ["Twin Islands"] = function () return true end,
            ["Near Goron Graveyard"] = function () return can_use_lens_strict() or trick('MM_DARMANI_WALL') or (event('BOSS_SNOWHEAD') and (has_mask_goron() or has_mask_zora())) end,
            ["Path to Snowhead Front"] = function () return true end,
            ["Blacksmith"] = function () return true end,
            ["Near Village Grotto"] = function () return event('BOSS_SNOWHEAD') and has_mask_goron() end,
            ["Owl Mountain"] = function () return true end,
        },
        ["locations"] = {
            ["Mountain Village Waterfall Chest"] = function () return event('BOSS_SNOWHEAD') and can_use_lens() end,
            ["Mountain Village Don Gero Mask"] = function () return event('GORON_FOOD') end,
            ["Mountain Village Frog Choir HP"] = function () return event('BOSS_SNOWHEAD') and event('FROG_1') and event('FROG_2') and event('FROG_3') and event('FROG_4') end,
        },
    },
    ["Near Village Grotto"] = {
        ["exits"] = {
            ["Mountain Village Grotto"] = function () return true end,
            ["Mountain Village"] = function () return true end,
            ["Near Goron Graveyard"] = function () return has_mask_goron() end,
        },
    },
    ["Mountain Village Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["BUGS"] = function () return has_bottle() end,
            ["FISH"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Near Village Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Mountain Village Tunnel Grotto"] = function () return true end,
        },
    },
    ["Blacksmith"] = {
        ["events"] = {
            ["BLACKSMITH_ENABLED"] = function () return event('BOSS_SNOWHEAD') or can_use_fire_arrows() or has_hot_water_mtn() or has_hot_water_er() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE')) end,
            ["GOLD_DUST_USED"] = function () return can_use_wallet(2) and has('BOTTLED_GOLD_DUST') and event('BLACKSMITH_ENABLED') end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
        },
        ["locations"] = {
            ["Blacksmith Razor Blade"] = function () return can_use_wallet(2) and event('BLACKSMITH_ENABLED') end,
            ["Blacksmith Gilded Sword"] = function () return event('GOLD_DUST_USED') end,
        },
    },
    ["Twin Islands"] = {
        ["events"] = {
            ["PICTURE_TINGLE"] = function () return has('PICTOGRAPH_BOX') end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return can_use_light_arrows() or event('BOSS_SNOWHEAD') end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Goron Village"] = function () return true end,
            ["Near Goron Race"] = function () return has_mask_goron() or scarecrow_hookshot() end,
            ["Near Ramp Grotto"] = function () return has_mask_goron() end,
            ["Twin Islands Frozen Grotto"] = function () return can_use_fire_arrows() or event('BOSS_SNOWHEAD') or has_hot_water_mtn() or has_hot_water_er() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE')) end,
            ["Tingle Mountain"] = function () return has_weapon_range() end,
        },
        ["locations"] = {
            ["Twin Islands Underwater Chest 1"] = function () return event('BOSS_SNOWHEAD') and has_mask_zora() end,
            ["Twin Islands Underwater Chest 2"] = function () return event('BOSS_SNOWHEAD') and has_mask_zora() end,
            ["Goron Elder"] = function () return (has_mask_goron() and (can_use_fire_arrows() or has_hot_water_mtn() or has_hot_water_er() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE')))) and (first_day() or second_day()) end,
        },
    },
    ["Twin Islands Ramp Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["BUGS"] = function () return has_bottle() end,
            ["FISH"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Near Ramp Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Twin Islands Ramp Grotto Chest"] = function () return true end,
        },
    },
    ["Twin Islands Frozen Grotto"] = {
        ["events"] = {
            ["TWIN_ISLANDS_HOT_WATER"] = function () return has_bottle() end,
            ["WATER"] = function () return has_bottle() end,
            ["STICKS"] = function () return can_kill_baba_sticks() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
        },
        ["locations"] = {
            ["Twin Islands Frozen Grotto Chest"] = function () return has_explosives() or trick_keg_explosives() or (trick('MM_KEG_EXPLOSIVES') and event('POWDER_KEG_TRIAL')) end,
        },
    },
    ["Near Goron Race"] = {
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
            ["Goron Race"] = function () return can_use_keg() or event('POWDER_KEG_TRIAL') end,
            ["Near Ramp Grotto"] = function () return true end,
        },
    },
    ["Near Ramp Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
            ["Twin Islands Ramp Grotto"] = function () return has_explosives() or trick_keg_explosives() or (trick('MM_KEG_EXPLOSIVES') and event('POWDER_KEG_TRIAL')) end,
        },
    },
    ["Goron Village"] = {
        ["events"] = {
            ["POWDER_KEG_TRIAL"] = function () return (event('BOSS_SNOWHEAD') or can_use_fire_arrows()) and has_mask_goron() end,
            ["BUY_KEG"] = function () return event('POWDER_KEG_TRIAL') and has('POWDER_KEG') and can_use_wallet(2) end,
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["NUTS"] = function () return true end,
            ["STICKS"] = function () return true end,
            ["RUPEES"] = function () return can_break_boulders() or can_use_fire_arrows() or can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
            ["Front of Lone Peak Shrine"] = function () return true end,
            ["Goron Shrine"] = function () return first_day() or has_mask_goron() end,
        },
        ["locations"] = {
            ["Goron Village HP"] = function () return has('DEED_SWAMP') and has('MASK_DEKU') end,
            ["Goron Village Scrub Deed"] = function () return has('DEED_SWAMP') and has('MASK_DEKU') end,
            ["Goron Village Scrub Bomb Bag"] = function () return has_mask_goron() and can_use_wallet(2) end,
            ["Goron Powder Keg"] = function () return event('POWDER_KEG_TRIAL') end,
        },
    },
    ["Front of Lone Peak Shrine"] = {
        ["exits"] = {
            ["Goron Village"] = function () return can_use_lens() end,
            ["Lone Peak Shrine"] = function () return true end,
        },
    },
    ["Lone Peak Shrine"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Front of Lone Peak Shrine"] = function () return true end,
        },
        ["locations"] = {
            ["Lone Peak Shrine Lens Chest"] = function () return true end,
            ["Lone Peak Shrine Boulder Chest"] = function () return has_explosives() or trick_keg_explosives() end,
            ["Lone Peak Shrine Invisible Chest"] = function () return can_use_lens() end,
        },
    },
    ["Near Goron Graveyard"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return event('BOSS_SNOWHEAD') end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Goron Graveyard"] = function () return true end,
            ["Near Village Grotto"] = function () return event('BOSS_SNOWHEAD') end,
        },
    },
    ["Goron Graveyard"] = {
        ["events"] = {
            ["GORON_GRAVEYARD_HOT_WATER"] = function () return has_bottle() and has_mask_goron() end,
            ["WATER"] = function () return has_bottle() and has_mask_goron() end,
        },
        ["exits"] = {
            ["Near Goron Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Graveyard Mask"] = function () return can_use_lens_strict() and can_play(SONG_HEALING) end,
        },
    },
    ["Goron Shrine"] = {
        ["events"] = {
            ["GORON_FOOD"] = function () return goron_fast_roll() and (can_use_fire_arrows() or can_lullaby_half()) end,
            ["STICKS"] = function () return true end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Goron Village"] = function () return true end,
            ["Goron Shop"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Baby"] = function () return has_mask_goron() and can_lullaby_half() end,
        },
    },
    ["Goron Shop"] = {
        ["exits"] = {
            ["Goron Shrine"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Shop Item 1"] = function () return shop_price(16) end,
            ["Goron Shop Item 2"] = function () return shop_price(17) end,
            ["Goron Shop Item 3"] = function () return shop_price(18) end,
        },
    },
    ["Path to Snowhead Front"] = {
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Path to Snowhead Middle"] = function () return goron_fast_roll() end,
        },
    },
    ["Path to Snowhead Middle"] = {
        ["exits"] = {
            ["Path to Snowhead Front"] = function () return true end,
            ["Path to Snowhead Back"] = function () return true end,
        },
        ["locations"] = {
            ["Path to Snowhead HP"] = function () return can_use_lens() and scarecrow_hookshot() end,
        },
    },
    ["Path to Snowhead Back"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_break_boulders() end,
        },
        ["exits"] = {
            ["Path to Snowhead Middle"] = function () return goron_fast_roll() end,
            ["Snowhead Entrance"] = function () return true end,
            ["Path to Snowhead Grotto"] = function () return has_explosives() or trick_keg_explosives() end,
        },
    },
    ["Path to Snowhead Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["BUGS"] = function () return has_bottle() end,
            ["FISH"] = function () return has_bottle() end,
            ["MUSHROOM"] = function () return has_bottle() and has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Path to Snowhead Back"] = function () return true end,
        },
        ["locations"] = {
            ["Path to Snowhead Grotto"] = function () return true end,
        },
    },
    ["Snowhead Entrance"] = {
        ["events"] = {
            ["OPEN_SNOWHEAD_TEMPLE"] = function () return can_lullaby() or (event('BOSS_SNOWHEAD') and has_mask_goron()) end,
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Path to Snowhead Back"] = function () return true end,
            ["Snowhead"] = function () return event('OPEN_SNOWHEAD_TEMPLE') end,
            ["Snowhead Near Fairy Fountain"] = function () return event('OPEN_SNOWHEAD_TEMPLE') end,
            ["Owl Snowhead"] = function () return true end,
        },
    },
    ["Snowhead"] = {
        ["exits"] = {
            ["Snowhead Entrance"] = function () return true end,
            ["Snowhead Temple"] = function () return true end,
            ["Snowhead Near Fairy Fountain"] = function () return event('BOSS_SNOWHEAD') end,
        },
    },
    ["Snowhead Near Fairy Fountain"] = {
        ["events"] = {
            ["MAGIC"] = function () return event('OPEN_SNOWHEAD_TEMPLE') and can_break_boulders() or event('BOSS_SNOWHEAD') end,
            ["RUPEES"] = function () return (event('OPEN_SNOWHEAD_TEMPLE') or event('BOSS_SNOWHEAD')) and can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Snowhead Entrance"] = function () return true end,
            ["Snowhead"] = function () return event('BOSS_SNOWHEAD') end,
            ["Snowhead Fairy Fountain"] = function () return true end,
        },
    },
    ["Snowhead Fairy Fountain"] = {
        ["exits"] = {
            ["Snowhead Near Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Great Fairy"] = function () return has('STRAY_FAIRY_SH', 15) end,
        },
    },
    ["Goron Race"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Near Goron Race"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Race Reward"] = function () return event('BOSS_SNOWHEAD') and goron_fast_roll() end,
        },
    },
    ["Milk Road"] = {
        ["events"] = {
            ["PICTURE_TINGLE"] = function () return has('PICTOGRAPH_BOX') end,
            ["RUPEES"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Gorman Track Front"] = function () return true end,
            ["Owl Milk Road"] = function () return true end,
            ["Near Romani Ranch"] = function () return after(DAY3_AM_06_00) or can_use_keg() end,
            ["Behind Gorman Fence"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or final_day() end,
            ["Tingle Ranch"] = function () return has_weapon_range() end,
        },
    },
    ["Near Romani Ranch"] = {
        ["exits"] = {
            ["Milk Road"] = function () return after(DAY3_AM_06_00) or can_use_keg() end,
            ["Romani Ranch"] = function () return true end,
        },
    },
    ["Romani Ranch"] = {
        ["events"] = {
            ["ALIENS"] = function () return before(NIGHT1_AM_02_30) and has_arrows() end,
            ["ARROWS"] = function () return true end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Near Romani Ranch"] = function () return true end,
            ["Cucco Shack"] = function () return after(DAY1_AM_06_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_08_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_08_00)) end,
            ["Doggy Racetrack"] = function () return after(DAY1_AM_06_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_08_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_08_00)) end,
            ["Stables"] = function () return true end,
            ["Ranch House"] = function () return after(DAY1_AM_06_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_08_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_08_00)) end,
        },
        ["locations"] = {
            ["Romani Ranch Epona Song"] = function () return before(NIGHT1_PM_06_00) end,
            ["Romani Ranch Aliens"] = function () return before(NIGHT1_AM_02_30) and has_arrows() end,
            ["Romani Ranch Cremia Escort"] = function () return event('ALIENS') end,
        },
    },
    ["Cucco Shack"] = {
        ["events"] = {
            ["RUPEES"] = function () return has_weapon_range() or has_weapon() or can_break_boulders() end,
        },
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Cucco Shack Bunny Mask"] = function () return has('MASK_BREMEN') and (after(DAY1_AM_06_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_08_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_08_00))) end,
        },
    },
    ["Doggy Racetrack"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Doggy Racetrack Chest"] = function () return (can_use_beans() or has_mask_zora() or can_hookshot_short() or trick('MM_DOG_RACE_CHEST_NOTHING')) and (after(DAY1_AM_06_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_08_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_08_00))) end,
            ["Doggy Racetrack HP"] = function () return can_use_wallet(1) and has_mask_truth() and (after(DAY1_AM_06_00) and before(NIGHT1_PM_08_00) or (after(DAY2_AM_06_00) and before(NIGHT2_PM_08_00)) or (after(DAY3_AM_06_00) and before(NIGHT3_PM_08_00))) end,
        },
    },
    ["Stables"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Romani Ranch Barn Cow Left"] = function () return (before(NIGHT1_AM_02_30) or event('ALIENS')) and can_play_epona() end,
            ["Romani Ranch Barn Cow Right Front"] = function () return (before(NIGHT1_AM_02_30) or event('ALIENS')) and can_play_epona() end,
            ["Romani Ranch Barn Cow Right Back"] = function () return (before(NIGHT1_AM_02_30) or event('ALIENS')) and can_play_epona() end,
        },
    },
    ["Ranch House"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
    },
    ["Great Bay Fence"] = {
        ["exits"] = {
            ["Termina Field"] = function () return can_play_epona() or (can_goron_bomb_jump() and has_bombs()) end,
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Great Bay Coast"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BUGS"] = function () return has_bottle() end,
            ["FISH"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Fisher's Hut"] = function () return true end,
            ["Great Bay Fence"] = function () return true end,
            ["Great Bay Coast Fortress"] = function () return has_mask_zora() end,
            ["Pinnacle Rock Entrance"] = function () return true end,
            ["Laboratory"] = function () return true end,
            ["Zora Cape"] = function () return true end,
            ["Ocean Spider House"] = function () return true end,
            ["Tingle Great Bay"] = function () return can_hookshot() or has_arrows() end,
            ["Great Bay Grotto"] = function () return true end,
            ["GBC Near Cow Grotto"] = function () return can_hookshot() end,
            ["Owl Great Bay"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Coast Zora Mask"] = function () return can_play(SONG_HEALING) end,
            ["Great Bay Coast HP"] = function () return can_use_beans() and scarecrow_hookshot() end,
            ["Great Bay Coast Fisherman HP"] = function () return can_use_wallet(1) and can_hookshot_short() and event('BOSS_GREAT_BAY') and (after(DAY1_AM_07_00) and before(NIGHT1_AM_04_00) or (after(DAY2_AM_07_00) and before(NIGHT2_AM_04_00)) or (after(DAY3_AM_07_00) and before(NIGHT3_AM_04_00))) end,
        },
    },
    ["Great Bay Coast Fortress"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return has_mask_zora() end,
            ["Pirate Fortress"] = function () return true end,
        },
    },
    ["Great Bay Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["BUGS"] = function () return has_bottle() end,
            ["FISH"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Coast Fisherman Grotto"] = function () return true end,
        },
    },
    ["GBC Near Cow Grotto"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
            ["Great Bay Cow Grotto"] = function () return true end,
        },
    },
    ["Great Bay Cow Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Coast Cow Front"] = function () return can_play_epona() end,
            ["Great Bay Coast Cow Back"] = function () return can_play_epona() end,
        },
    },
    ["Fisher's Hut"] = {
        ["events"] = {
            ["SEAHORSE"] = function () return event('PHOTO_GERUDO') and has_bottle() end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Pinnacle Rock Entrance"] = {
        ["exits"] = {
            ["Pinnacle Rock"] = function () return has_mask_zora() and (event('SEAHORSE') or trick('MM_NO_SEAHORSE')) end,
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Pinnacle Rock"] = {
        ["events"] = {
            ["ZORA_EGGS_PINNACLE_ROCK"] = function () return has_mask_zora() and has_bottle() end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Pinnacle Rock Entrance"] = function () return true end,
        },
        ["locations"] = {
            ["Pinnacle Rock Chest 1"] = function () return has_mask_zora() end,
            ["Pinnacle Rock Chest 2"] = function () return has_mask_zora() end,
            ["Pinnacle Rock HP"] = function () return soul(SOUL_DEEP_PYTHON) and has_mask_zora() and event('SEAHORSE') end,
        },
    },
    ["Laboratory"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Laboratory Zora Song"] = function () return event('ZORA_EGGS_HOOKSHOT_ROOM') and event('ZORA_EGGS_BARREL_MAZE') and event('ZORA_EGGS_LONE_GUARD') and event('ZORA_EGGS_TREASURE_ROOM') and event('ZORA_EGGS_PINNACLE_ROCK') and has_mask_zora() and has_ocarina() end,
            ["Laboratory Fish HP"] = function () return has_bottle() end,
        },
    },
    ["Zora Cape"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return (can_fight() or has_explosives() or has_arrows()) and is_night() end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
            ["Zora Cape Near Hall"] = function () return has_mask_zora() end,
            ["Zora Cape Peninsula"] = function () return has_mask_zora() or trick('MM_ZORA_HALL_HUMAN') end,
            ["Waterfall Cliffs"] = function () return can_hookshot() end,
            ["Great Bay Near Fairy Fountain"] = function () return can_hookshot() end,
            ["Zora Cape Grotto"] = function () return can_break_boulders() end,
        },
        ["locations"] = {
            ["Zora Cape Underwater Chest"] = function () return has_mask_zora() end,
            ["Zora Cape Waterfall HP"] = function () return has_mask_zora() end,
        },
    },
    ["Zora Cape Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Cape Grotto"] = function () return true end,
        },
    },
    ["Great Bay Near Fairy Fountain"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return true end,
            ["Great Bay Fairy Fountain"] = function () return has_explosives() or trick_keg_explosives() end,
        },
    },
    ["Great Bay Fairy Fountain"] = {
        ["exits"] = {
            ["Great Bay Near Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Great Fairy"] = function () return has('STRAY_FAIRY_GB', 15) end,
        },
    },
    ["Waterfall Cliffs"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return true end,
            ["Waterfall Rapids"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Cape Ledge Chest 1"] = function () return can_hookshot() end,
            ["Zora Cape Ledge Chest 2"] = function () return can_hookshot() end,
        },
    },
    ["Waterfall Rapids"] = {
        ["exits"] = {
            ["Waterfall Cliffs"] = function () return true end,
        },
        ["locations"] = {
            ["Waterfall Rapids Beaver Race 1"] = function () return has_mask_zora() end,
            ["Waterfall Rapids Beaver Race 2"] = function () return has_mask_zora() end,
        },
    },
    ["Zora Cape Near Hall"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return has_mask_zora() end,
            ["Zora Hall Entrance"] = function () return has_mask_zora() end,
        },
    },
    ["Zora Hall Entrance"] = {
        ["exits"] = {
            ["Zora Cape Near Hall"] = function () return has_mask_zora() end,
            ["Zora Hall"] = function () return true end,
        },
    },
    ["Zora Hall"] = {
        ["exits"] = {
            ["Zora Hall Entrance"] = function () return true end,
            ["Zora Cape Peninsula"] = function () return true end,
            ["Zora Shop"] = function () return true end,
            ["Tijo's Room"] = function () return has_mask_zora() end,
            ["Japas' Room"] = function () return has_mask_zora() end,
            ["Evan's Room"] = function () return has_mask_zora() end,
            ["Lulu's Room"] = function () return has_mask_zora() end,
        },
        ["locations"] = {
            ["Zora Hall Scene Lights"] = function () return can_use_fire_arrows() end,
        },
    },
    ["Zora Shop"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Shop Item 1"] = function () return shop_price(19) end,
            ["Zora Shop Item 2"] = function () return shop_price(20) end,
            ["Zora Shop Item 3"] = function () return shop_price(21) end,
        },
    },
    ["Tijo's Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
    },
    ["Japas' Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
    },
    ["Evan's Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Hall Evan HP"] = function () return has_ocarina() end,
        },
    },
    ["Lulu's Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Hall Scrub HP"] = function () return trick('MM_ZORA_HALL_SCRUB_HP_NO_DEKU') and (has_mask_goron() or has_mask_zora()) or (has_mask_goron() and has('MASK_DEKU') and has('DEED_MOUNTAIN')) end,
            ["Zora Hall Scrub Shop"] = function () return has_mask_zora() and can_use_wallet(1) end,
            ["Zora Hall Scrub Deed"] = function () return has('DEED_MOUNTAIN') and has_mask_goron() end,
        },
    },
    ["Zora Cape Peninsula"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return has_mask_zora() or trick('MM_ZORA_HALL_HUMAN') end,
            ["Zora Hall"] = function () return true end,
            ["Great Bay Temple"] = function () return has_mask_zora() and can_hookshot() and can_play(SONG_ZORA) end,
            ["Owl Zora Cape"] = function () return true end,
        },
    },
    ["Behind Gorman Fence"] = {
        ["exits"] = {
            ["Milk Road"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or final_day() end,
            ["Gorman Track Back"] = function () return true end,
        },
    },
    ["Gorman Track Front"] = {
        ["exits"] = {
            ["Milk Road"] = function () return true end,
            ["Gorman Track Back"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) end,
        },
        ["locations"] = {
            ["Gorman Track Garo Mask"] = function () return can_play_epona() and can_use_wallet(1) and is_day() end,
            ["Gorman Track Milk Purchase"] = function () return can_use_wallet(1) and is_day() end,
        },
    },
    ["Gorman Track Back"] = {
        ["exits"] = {
            ["Behind Gorman Fence"] = function () return true end,
            ["Gorman Track Front"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) end,
        },
    },
    ["Road to Ikana Front"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Road to Ikana Grotto"] = function () return has_mask_goron() end,
            ["Road to Ikana Center"] = function () return can_play_epona() or (can_goron_bomb_jump() and has_bombs()) end,
        },
        ["locations"] = {
            ["Road to Ikana Chest"] = function () return can_hookshot() or (can_hookshot_short() and trick('MM_SHORT_HOOK_HARD')) end,
        },
    },
    ["Road to Ikana Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
        },
        ["exits"] = {
            ["Road to Ikana Front"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Ikana Grotto"] = function () return true end,
        },
    },
    ["Road to Ikana Center"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() end,
        },
        ["exits"] = {
            ["Road to Ikana Front"] = function () return can_play_epona() or (can_goron_bomb_jump() and has_bombs()) end,
            ["Road to Ikana Top"] = function () return (has('MASK_GARO') or has('MASK_GIBDO')) and (can_hookshot() or (can_hookshot_short() and trick('MM_SHORT_HOOK_HARD'))) end,
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Ikana Stone Mask"] = function () return can_use_lens_strict() and has_red_or_blue_potion() end,
        },
    },
    ["Ikana Graveyard"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Road to Ikana Center"] = function () return true end,
            ["Ikana Graveyard Grotto"] = function () return has_explosives() or trick_keg_explosives() end,
            ["Beneath The Graveyard Night 1"] = function () return has('MASK_CAPTAIN') and is_night1() end,
            ["Beneath The Graveyard Night 2"] = function () return has('MASK_CAPTAIN') and is_night2() end,
            ["Beneath The Graveyard Night 3"] = function () return has('MASK_CAPTAIN') and is_night3() end,
        },
        ["locations"] = {
            ["Ikana Graveyard Captain Mask"] = function () return soul(SOUL_CAPTAIN_KEETA) and can_play(SONG_AWAKENING) and has_arrows() and can_fight() end,
        },
    },
    ["Ikana Graveyard Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Graveyard Grotto"] = function () return true end,
        },
    },
    ["Beneath The Graveyard Night 1"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Graveyard Chest"] = function () return soul(SOUL_BAD_BAT) and (can_fight() or has_explosives() or has_arrows() or can_hookshot_short() or has('MASK_DEKU')) end,
            ["Beneath The Graveyard Song of Storms"] = function () return soul_iron_knuckle() and ((can_fight() or has_explosives()) and (has_sticks() or can_use_fire_arrows())) end,
        },
    },
    ["Beneath The Graveyard Night 2"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Graveyard HP"] = function () return soul_iron_knuckle() and ((has_explosives() or (trick_keg_explosives() and can_fight())) and can_use_lens()) end,
        },
    },
    ["Beneath The Graveyard Night 3"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_fight() or has_weapon_range() or has_explosives() end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Graveyard Dampe Chest"] = function () return has_weapon_range() and is_night3() end,
        },
    },
    ["Road to Ikana Top"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() end,
        },
        ["exits"] = {
            ["Road to Ikana Center"] = function () return true end,
            ["Ikana Valley"] = function () return true end,
        },
    },
    ["Ikana Valley"] = {
        ["exits"] = {
            ["Road to Ikana Top"] = function () return true end,
            ["Ikana Canyon"] = function () return (can_use_ice_arrows() or trick('MM_ICELESS_IKANA')) and can_hookshot() end,
            ["Secret Shrine"] = function () return true end,
            ["Sakon Hideout"] = function () return event('MEET_KAFEI') and at(NIGHT3_PM_06_00) end,
            ["Ikana Valley Grotto"] = function () return true end,
            ["Swamp Front"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Valley Scrub Rupee"] = function () return has('DEED_OCEAN') and has_mask_zora() end,
            ["Ikana Valley Scrub HP"] = function () return has('DEED_OCEAN') and has_mask_zora() and has('MASK_DEKU') end,
            ["Ikana Valley Scrub Shop"] = function () return can_use_wallet(2) end,
        },
    },
    ["Ikana Valley Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Valley Grotto"] = function () return true end,
        },
    },
    ["Sakon Hideout"] = {
        ["events"] = {
            ["SUN_MASK"] = function () return (can_fight() or has_explosives() or has_arrows()) and soul_deku_baba() and soul_wolfos() end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
        },
    },
    ["Ikana Canyon"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
            ["Ikana Fairy Fountain"] = function () return true end,
            ["Ikana Spring Water Cave"] = function () return true end,
            ["Music Box House"] = function () return event('IKANA_CURSE_LIFTED') and (has_explosives() or has('MASK_STONE')) end,
            ["Ghost Hut"] = function () return true end,
            ["Beneath the Well Entrance"] = function () return true end,
            ["Ikana Castle Entrance"] = function () return true end,
            ["Stone Tower"] = function () return true end,
            ["Tingle Ikana"] = function () return has_weapon_range() end,
            ["Owl Ikana"] = function () return true end,
        },
    },
    ["Ikana Fairy Fountain"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Great Fairy"] = function () return has('STRAY_FAIRY_ST', 15) end,
        },
    },
    ["Ikana Spring Water Cave"] = {
        ["events"] = {
            ["IKANA_CURSE_LIFTED"] = function () return can_play_storms() end,
        },
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
    },
    ["Music Box House"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Music Box House Gibdo Mask"] = function () return can_play(SONG_HEALING) end,
        },
    },
    ["Ghost Hut"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Ghost Hut HP"] = function () return (has_arrows() or can_hookshot_short() or can_use_deku_bubble()) and can_use_wallet(1) end,
        },
    },
    ["Ikana Castle Entrance"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT_ENTRANCE"] = function () return can_activate_crystal() end,
        },
        ["exits"] = {
            ["Ikana Castle Exterior"] = function () return has_mirror_shield() and event('IKANA_CASTLE_LIGHT_ENTRANCE') or can_use_light_arrows() end,
            ["Ikana Canyon"] = function () return true end,
        },
    },
    ["Ikana Castle Exterior"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Beneath the Well End"] = function () return true end,
            ["Ikana Castle Entrance"] = function () return can_use_light_arrows() end,
            ["Ancient Castle of Ikana"] = function () return true end,
        },
    },
    ["Stone Tower"] = {
        ["events"] = {
            ["RUPEES"] = function () return (can_use_elegy3() or (can_use_elegy2() and trick('MM_ONE_MASK_STONE_TOWER'))) and scarecrow_hookshot() end,
        },
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
            ["Stone Tower Top"] = function () return (can_use_elegy3() or (can_use_elegy2() and trick('MM_ONE_MASK_STONE_TOWER'))) and can_hookshot() end,
        },
    },
    ["Stone Tower Top"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return has_mask_goron() end,
        },
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
            ["Stone Tower Front of Temple"] = function () return can_use_elegy() end,
            ["Stone Tower Top Inverted"] = function () return can_use_elegy() and can_use_light_arrows() end,
            ["Owl Stone Tower"] = function () return true end,
        },
    },
    ["Stone Tower Front of Temple"] = {
        ["events"] = {
            ["MAGIC"] = function () return has_mask_goron() or has_mask_zora() or (scarecrow_hookshot() and can_fight()) end,
            ["BOMBS"] = function () return has_mask_goron() or has_mask_zora() or (scarecrow_hookshot() and can_fight()) end,
            ["ARROWS"] = function () return has_mask_goron() or has_mask_zora() or (scarecrow_hookshot() and can_fight()) end,
            ["RUPEES"] = function () return has_mask_goron() or has_mask_zora() or (scarecrow_hookshot() and can_fight()) end,
        },
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
            ["Stone Tower Top"] = function () return can_use_elegy3() end,
            ["Stone Tower Top Inverted"] = function () return can_use_elegy() and can_use_light_arrows() end,
            ["Stone Tower Temple"] = function () return true end,
        },
    },
    ["Stone Tower Top Inverted"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted"] = function () return true end,
            ["Stone Tower Top"] = function () return can_use_light_arrows() end,
            ["Stone Tower Top Inverted Upper"] = function () return can_use_beans() end,
        },
    },
    ["Stone Tower Top Inverted Upper"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_use_beans() end,
            ["BOMBS"] = function () return can_use_beans() end,
            ["RUPEES"] = function () return can_use_beans() end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Stone Tower Top Inverted"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Inverted Chest 1"] = function () return true end,
            ["Stone Tower Inverted Chest 2"] = function () return true end,
            ["Stone Tower Inverted Chest 3"] = function () return true end,
        },
    },
    ["Pirate Fortress"] = {
        ["exits"] = {
            ["Great Bay Coast Fortress"] = function () return has_mask_zora() end,
            ["Pirate Fortress Entrance"] = function () return can_reset_time() end,
        },
    },
    ["Pirate Fortress Entrance"] = {
        ["events"] = {
            ["PHOTO_GERUDO"] = function () return has('PICTOGRAPH_BOX') end,
        },
        ["exits"] = {
            ["Pirate Fortress"] = function () return true end,
            ["Pirate Fortress Sewers"] = function () return has_mask_zora() and has_mask_goron() end,
            ["Pirate Fortress Entrance Balcony"] = function () return can_hookshot() or (can_hookshot_short() and trick('MM_PFI_BOAT_HOOK')) end,
            ["Pirate Fortress Entrance Lookout"] = function () return can_hookshot_short() and trick('MM_PFI_BOAT_HOOK') end,
        },
        ["locations"] = {
            ["Pirate Fortress Entrance Chest 1"] = function () return has_mask_zora() end,
            ["Pirate Fortress Entrance Chest 2"] = function () return has_mask_zora() end,
            ["Pirate Fortress Entrance Chest 3"] = function () return has_mask_zora() end,
        },
    },
    ["Pirate Fortress Entrance Balcony"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers End"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Sewers"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers End"] = function () return has_mask_zora() end,
        },
        ["locations"] = {
            ["Pirate Fortress Sewers Chest 1"] = function () return has_mask_zora() end,
            ["Pirate Fortress Sewers Chest 2"] = function () return has_mask_zora() end,
            ["Pirate Fortress Sewers Chest 3"] = function () return has_mask_zora() end,
            ["Pirate Fortress Sewers HP"] = function () return has_mask_zora() end,
        },
    },
    ["Pirate Fortress Sewers End"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return has_mask_zora() end,
            ["Pirate Fortress Entrance Balcony"] = function () return true end,
        },
    },
    ["Pirate Fortress Interior"] = {
        ["events"] = {
            ["RUPEES"] = function () return has_weapon_range() or has_explosives() or has_weapon() end,
        },
        ["exits"] = {
            ["Pirate Fortress Entrance Balcony"] = function () return true end,
            ["Pirate Fortress Hookshot Room Upper"] = function () return can_evade_gerudo() end,
            ["Pirate Fortress Hookshot Room Lower"] = function () return true end,
            ["Pirate Fortress Lone Guard Entry"] = function () return can_hookshot_short() end,
            ["Pirate Fortress Barrel Maze Entry"] = function () return can_hookshot_short() end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Lower Chest"] = function () return true end,
            ["Pirate Fortress Interior Upper Chest"] = function () return can_hookshot() end,
        },
    },
    ["Pirate Fortress Hookshot Room Upper"] = {
        ["events"] = {
            ["FORTRESS_BEEHIVE"] = function () return has_arrows() or can_use_deku_bubble() end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Hookshot Room Lower"] = {
        ["events"] = {
            ["FORTRESS_BEEHIVE"] = function () return has('MASK_STONE') and can_hookshot_short() and (has_arrows() or can_use_deku_bubble()) end,
            ["ZORA_EGGS_HOOKSHOT_ROOM"] = function () return can_hookshot_short() and has_mask_zora() and has_bottle() and event('FORTRESS_BEEHIVE') end,
        },
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Hookshot"] = function () return event('FORTRESS_BEEHIVE') end,
        },
    },
    ["Pirate Fortress Barrel Maze Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["Pirate Fortress Entrance Lookout"] = function () return true end,
            ["Pirate Fortress Barrel Maze"] = function () return true end,
        },
    },
    ["Pirate Fortress Entrance Lookout"] = {
        ["exits"] = {
            ["Pirate Fortress Barrel Maze Entry"] = function () return true end,
            ["Pirate Fortress Entrance"] = function () return true end,
        },
    },
    ["Pirate Fortress Barrel Maze"] = {
        ["exits"] = {
            ["Pirate Fortress Barrel Maze Entry"] = function () return true end,
            ["Pirate Fortress Barrel Maze Aquarium"] = function () return can_fight() and can_evade_gerudo() end,
        },
    },
    ["Pirate Fortress Barrel Maze Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_BARREL_MAZE"] = function () return can_hookshot_short() and has_mask_zora() and has_bottle() end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Barrel Maze"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Barrel Maze Exit"] = function () return true end,
        },
    },
    ["Pirate Fortress Barrel Maze Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Barrel Maze Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["Pirate Fortress Lone Guard"] = function () return true end,
            ["Pirate Fortress Treasure Room Entry"] = function () return can_hookshot() end,
        },
    },
    ["Pirate Fortress Lone Guard"] = {
        ["exits"] = {
            ["Pirate Fortress Lone Guard Aquarium"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Lone Guard Entry"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_LONE_GUARD"] = function () return can_hookshot_short() and has_mask_zora() and has_bottle() end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Lone Guard"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Lone Guard Exit"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Aquarium"] = function () return has_mask_zora() and can_hookshot_short() end,
        },
    },
    ["Pirate Fortress Lone Guard Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Lone Guard Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room"] = {
        ["exits"] = {
            ["Pirate Fortress Treasure Room Aquarium"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room Entry"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Silver Rupee Chest"] = function () return can_evade_gerudo() end,
        },
    },
    ["Pirate Fortress Treasure Room Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_TREASURE_ROOM"] = function () return can_hookshot_short() and has_mask_zora() and has_bottle() end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Treasure Room"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room Exit"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Treasure Room Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Secret Shrine"] = {
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
            ["Secret Shrine Entrance"] = function () return can_reset_time() end,
        },
    },
    ["Secret Shrine Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["NUTS"] = function () return true end,
            ["WATER"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Secret Shrine Main"] = function () return can_use_light_arrows() end,
        },
    },
    ["Secret Shrine Main"] = {
        ["events"] = {
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Secret Shrine Boss Dinalfos"] = function () return true end,
            ["Secret Shrine Boss Wizzrobe"] = function () return true end,
            ["Secret Shrine Boss Wart"] = function () return true end,
            ["Secret Shrine Boss Garo Master"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine HP Chest"] = function () return event('SECRET_SHRINE_DINALFOS') and event('SECRET_SHRINE_WIZZROBE') and event('SECRET_SHRINE_WART') and event('SECRET_SHRINE_GARO') end,
        },
    },
    ["Secret Shrine Boss Dinalfos"] = {
        ["events"] = {
            ["SECRET_SHRINE_DINALFOS"] = function () return soul_lizalfos_dinalfos() end,
        },
        ["locations"] = {
            ["Secret Shrine Dinalfos Chest"] = function () return event('SECRET_SHRINE_DINALFOS') end,
        },
    },
    ["Secret Shrine Boss Wizzrobe"] = {
        ["events"] = {
            ["SECRET_SHRINE_WIZZROBE"] = function () return soul(SOUL_WIZZROBE) end,
        },
        ["locations"] = {
            ["Secret Shrine Wizzrobe Chest"] = function () return event('SECRET_SHRINE_WIZZROBE') end,
        },
    },
    ["Secret Shrine Boss Wart"] = {
        ["events"] = {
            ["SECRET_SHRINE_WART"] = function () return soul(SOUL_WART) end,
        },
        ["locations"] = {
            ["Secret Shrine Wart Chest"] = function () return event('SECRET_SHRINE_WART') end,
        },
    },
    ["Secret Shrine Boss Garo Master"] = {
        ["events"] = {
            ["SECRET_SHRINE_GARO"] = function () return soul(SOUL_GARO) end,
        },
        ["locations"] = {
            ["Secret Shrine Garo Master Chest"] = function () return event('SECRET_SHRINE_GARO') end,
        },
    },
    ["Snowhead Temple"] = {
        ["exits"] = {
            ["Snowhead Temple Entrance"] = function () return can_reset_time() end,
            ["Snowhead"] = function () return true end,
        },
    },
    ["Snowhead Temple Entrance"] = {
        ["exits"] = {
            ["Snowhead Temple"] = function () return true end,
            ["Snowhead Temple Main"] = function () return has_mask_goron() or has_mask_zora() end,
            ["Snowhead Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_GOHT') end,
        },
    },
    ["Snowhead Temple Main"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Entrance"] = function () return true end,
            ["Snowhead Temple Compass Room"] = function () return small_keys(SMALL_KEY_SH, 3) or ((has_explosives() or trick_keg_explosives()) and small_keys(SMALL_KEY_SH, 2)) end,
            ["Snowhead Temple Bridge Front"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return can_use_fire_arrows() or trick_sht_fireless() end,
        },
    },
    ["Snowhead Temple Bridge Front"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Main"] = function () return true end,
            ["Snowhead Temple Bridge Back"] = function () return goron_fast_roll() or can_hookshot() end,
        },
        ["locations"] = {
            ["Snowhead Temple Bridge Room"] = function () return soul_freezard() and can_hookshot_short() end,
            ["Snowhead Temple SF Bridge Under Platform"] = function () return (has_arrows() or can_hookshot()) and has('MASK_GREAT_FAIRY') end,
            ["Snowhead Temple SF Bridge Pillar"] = function () return can_use_lens() and (has_arrows() or can_hookshot_short()) and has('MASK_GREAT_FAIRY') end,
        },
    },
    ["Snowhead Temple Bridge Back"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room"] = function () return true end,
            ["Snowhead Temple Bridge Front"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Bridge Room"] = function () return soul_freezard() and can_use_fire_arrows() end,
            ["Snowhead Temple SF Bridge Under Platform"] = function () return has_weapon_range() and has('MASK_GREAT_FAIRY') end,
        },
    },
    ["Snowhead Temple Map Room"] = {
        ["exits"] = {
            ["Snowhead Temple Bridge Back"] = function () return true end,
            ["Snowhead Temple Map Room Upper"] = function () return can_use_fire_arrows() end,
        },
        ["locations"] = {
            ["Snowhead Temple Map"] = function () return true end,
            ["Snowhead Temple SF Map Room"] = function () return true end,
        },
    },
    ["Snowhead Temple Map Room Upper"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return goron_fast_roll() end,
            ["Snowhead Temple Fire Arrow"] = function () return goron_fast_roll() or (can_use_lens() and scarecrow_hookshot() and has('MASK_DEKU')) end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return can_use_fire_arrows() or (trick_sht_fireless() and scarecrow_hookshot() and has_mask_goron()) or trick_sht_fireless_er() end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return can_use_lens() and scarecrow_hookshot() end,
        },
        ["locations"] = {
            ["Snowhead Temple Map Alcove"] = function () return can_use_lens() or can_hookshot() end,
            ["Snowhead Temple Central Room Alcove"] = function () return scarecrow_hookshot() and can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 1"] = {
        ["exits"] = {
            ["Snowhead Temple Bridge Back"] = function () return true end,
            ["Snowhead Temple Center Level 0"] = function () return true end,
            ["Snowhead Temple Block Room"] = function () return true end,
            ["Snowhead Temple Pillars Room"] = function () return can_use_fire_arrows() or trick_sht_fireless() end,
            ["Snowhead Temple Map Room Upper"] = function () return scarecrow_hookshot() end,
        },
    },
    ["Snowhead Temple Pillars Room"] = {
        ["events"] = {
            ["SNOWHEAD_RAISE_PILLAR"] = function () return has_mask_goron() and (can_use_fire_arrows() or (event('SHT_STICK_RUN') and trick('MM_SHT_STICKS_RUN'))) end,
        },
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Pillars Room"] = function () return soul_freezard() end,
        },
    },
    ["Snowhead Temple Center Level 0"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Bottom"] = function () return has_mask_goron() end,
        },
    },
    ["Snowhead Temple Block Room"] = {
        ["events"] = {
            ["SNOWHEAD_PUSH_BLOCK"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["Snowhead Temple Block Room Upper"] = function () return can_hookshot_short() or (event('SNOWHEAD_PUSH_BLOCK') and has_mask_zora()) end,
        },
        ["locations"] = {
            ["Snowhead Temple Block Room"] = function () return true end,
        },
    },
    ["Snowhead Temple Block Room Upper"] = {
        ["exits"] = {
            ["Snowhead Temple Block Room"] = function () return true end,
            ["Snowhead Temple Compass Room"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Block Room Ledge"] = function () return event('SNOWHEAD_PUSH_BLOCK') end,
        },
    },
    ["Snowhead Temple Compass Room"] = {
        ["exits"] = {
            ["Snowhead Temple Main"] = function () return small_keys(SMALL_KEY_SH, 3) or ((has_explosives() or trick_keg_explosives()) and small_keys(SMALL_KEY_SH, 2)) end,
            ["Snowhead Temple Block Room Upper"] = function () return can_use_fire_arrows() or trick_sht_fireless() or can_hookshot_short() or can_goron_bomb_jump() end,
            ["Snowhead Temple Icicles"] = function () return has_explosives() or trick_keg_explosives() end,
        },
        ["locations"] = {
            ["Snowhead Temple Compass"] = function () return true end,
            ["Snowhead Temple Compass Room Ledge"] = function () return can_use_fire_arrows() or trick_sht_fireless() end,
            ["Snowhead Temple SF Compass Room Crate"] = function () return ((can_use_fire_arrows() or trick_sht_fireless()) or can_hookshot_short()) and (has_explosives() or has_mask_goron()) or (has('MASK_GREAT_FAIRY') and (has_bombs() or trick_keg_explosives())) or can_goron_bomb_jump() end,
        },
    },
    ["Snowhead Temple Icicles"] = {
        ["exits"] = {
            ["Snowhead Temple Compass Room"] = function () return has_explosives() or trick_keg_explosives() end,
            ["Snowhead Temple Dual Switches"] = function () return small_keys(SMALL_KEY_SH, 3) or ((has_explosives() or trick_keg_explosives()) and small_keys(SMALL_KEY_SH, 2)) end,
        },
        ["locations"] = {
            ["Snowhead Temple Icicle Room Alcove"] = function () return can_use_lens() end,
            ["Snowhead Temple Icicle Room"] = function () return (has_arrows() or has_mask_zora() or can_use_lens()) and can_break_boulders() or (can_hookshot_short() and (has_explosives() or trick_keg_explosives())) end,
        },
    },
    ["Snowhead Temple Dual Switches"] = {
        ["exits"] = {
            ["Snowhead Temple Icicles"] = function () return small_keys(SMALL_KEY_SH, 3) or ((has_explosives() or trick_keg_explosives()) and small_keys(SMALL_KEY_SH, 2)) end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Dual Switches"] = function () return can_use_lens() and has_arrows() and has('MASK_GREAT_FAIRY') end,
        },
    },
    ["Snowhead Temple Center Level 2 Dual"] = {
        ["exits"] = {
            ["Snowhead Temple Dual Switches"] = function () return true end,
            ["Snowhead Temple Map Room Upper"] = function () return goron_fast_roll() or can_hookshot() end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
    },
    ["Snowhead Temple Fire Arrow"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return goron_fast_roll() or (can_use_lens() and scarecrow_hookshot() and has('MASK_DEKU')) end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return can_hookshot() end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Fire Arrow"] = function () return soul(SOUL_WIZZROBE) end,
            ["Snowhead Temple Central Room Alcove"] = function () return scarecrow_hookshot() and can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 3 Snow"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return true end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return has_mask_goron() or can_hookshot() end,
            ["Snowhead Temple Snow Room"] = function () return small_keys(SMALL_KEY_SH, 3) end,
            ["Snowhead Temple Fire Arrow"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Alcove"] = function () return can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 3 Iced"] = {
        ["events"] = {
            ["SHT_STICK_RUN"] = function () return has_sticks() end,
        },
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return has_weapon() or has_mask_zora() or has_mask_goron() end,
            ["Snowhead Temple Fire Arrow"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return has_mask_goron() or can_hookshot() end,
            ["Snowhead Temple Center Level 4"] = function () return event('SNOWHEAD_RAISE_PILLAR') end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Alcove"] = function () return can_use_lens() end,
        },
    },
    ["Snowhead Temple Snow Room"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 3 Snow"] = function () return small_keys(SMALL_KEY_SH, 3) end,
            ["Snowhead Temple Dinolfos Room"] = function () return can_use_fire_arrows() or trick_sht_fireless_er() end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Snow Room"] = function () return can_use_lens() and (has_arrows() or can_hookshot_short()) and has('MASK_GREAT_FAIRY') end,
        },
    },
    ["Snowhead Temple Dinolfos Room"] = {
        ["exits"] = {
            ["Snowhead Temple Snow Room"] = function () return can_use_fire_arrows() or trick_sht_fireless_er() end,
            ["Snowhead Temple Boss Key Room"] = function () return event('SNOWHEAD_RAISE_PILLAR') end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return true end,
            ["Snowhead Temple Center Level 4"] = function () return trick('MM_SHT_PILLARLESS') and (can_use_fire_arrows() or has_bombs()) end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Dinolfos 1"] = function () return soul_lizalfos_dinalfos() end,
            ["Snowhead Temple SF Dinolfos 2"] = function () return soul_lizalfos_dinalfos() end,
        },
    },
    ["Snowhead Temple Boss Key Room"] = {
        ["exits"] = {
            ["Snowhead Temple Dinolfos Room"] = function () return event('SNOWHEAD_RAISE_PILLAR') end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return event('SNOWHEAD_RAISE_PILLAR') end,
            ["Snowhead Temple Center Level 4"] = function () return trick('MM_SHT_PILLARLESS') and (can_use_fire_arrows() or has_bombs()) end,
        },
        ["locations"] = {
            ["Snowhead Temple Boss Key"] = function () return soul(SOUL_WIZZROBE) end,
        },
    },
    ["Snowhead Temple Center Level 4"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return true end,
            ["Snowhead Temple Boss Access"] = function () return goron_fast_roll() and boss_key(BOSS_KEY_SH) end,
            ["Snowhead Temple Boss Key Room"] = function () return has_mask_goron() end,
            ["Snowhead Temple Dinolfos Room"] = function () return has_mask_goron() end,
        },
    },
    ["Snowhead Temple Boss Access"] = {
        ["exits"] = {
            ["Snowhead Temple Boss"] = function () return true end,
        },
    },
    ["Snowhead Temple Boss"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple After Boss"] = function () return soul(SOUL_GOHT) and can_use_fire_arrows() end,
        },
    },
    ["Snowhead Temple After Boss"] = {
        ["events"] = {
            ["BOSS_SNOWHEAD"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Boss HC"] = function () return true end,
            ["Snowhead Temple Boss"] = function () return true end,
        },
    },
    ["Stone Tower Temple"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return can_reset_time() end,
            ["Stone Tower Front of Temple"] = function () return true end,
        },
    },
    ["Stone Tower Temple Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple"] = function () return true end,
            ["Stone Tower Temple West"] = function () return true end,
            ["Stone Tower Temple Water Room"] = function () return can_use_light_arrows() or event('STONE_TOWER_EAST_ENTRY_BLOCK') end,
        },
        ["locations"] = {
            ["Stone Tower Temple Entrance Chest"] = function () return has_arrows() end,
            ["Stone Tower Temple Entrance Switch Chest"] = function () return event('STONE_TOWER_ENTRANCE_CHEST_SWITCH') end,
        },
    },
    ["Stone Tower Temple West"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return true end,
            ["Stone Tower Temple West Garden"] = function () return can_play(SONG_EMPTINESS) and has_mask_goron() and (has_explosives() or trick_keg_explosives()) end,
        },
    },
    ["Stone Tower Temple West Garden"] = {
        ["events"] = {
            ["STONE_TOWER_WEST_GARDEN_LIGHT"] = function () return has_explosives() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Under West Garden"] = function () return true end,
            ["Stone Tower Temple Center Ledge"] = function () return small_keys(SMALL_KEY_ST, 4) or (small_keys(SMALL_KEY_ST, 3) and has_mask_zora()) end,
        },
    },
    ["Stone Tower Temple Under West Garden"] = {
        ["exits"] = {
            ["Stone Tower Temple West Garden"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Under West Garden Ledge Chest"] = function () return can_hookshot() end,
            ["Stone Tower Temple Under West Garden Lava Chest"] = function () return soul_armos() and (event('STONE_TOWER_WEST_GARDEN_LIGHT') and has_mirror_shield() or can_use_light_arrows()) end,
            ["Stone Tower Temple Map"] = function () return event('STONE_TOWER_WEST_GARDEN_LIGHT') and has_mirror_shield() or can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Center Ledge"] = {
        ["exits"] = {
            ["Stone Tower Temple West Garden"] = function () return small_keys(SMALL_KEY_ST, 4) or (small_keys(SMALL_KEY_ST, 3) and has_mask_goron() and (has_explosives() or trick_keg_explosives()) and can_play(SONG_EMPTINESS)) end,
            ["Stone Tower Temple Center"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Center Sun Block Chest"] = function () return (has_mask_zora() or has('MASK_DEKU') or has_explosives() or (has_magic() and (has_weapon() and has('SPIN_UPGRADE'))) or has('SWORD', 3) or has('GREAT_FAIRY_SWORD') or can_use_ice_arrows()) and can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Center"] = {
        ["exits"] = {
            ["Stone Tower Temple Water Room"] = function () return has_mask_zora() end,
            ["Stone Tower Temple Center Ledge"] = function () return has_mask_zora() end,
            ["Stone Tower Temple Water Bridge"] = function () return can_goron_bomb_jump() and can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Stone Tower Temple Center Across Water Chest"] = function () return soul(SOUL_DEXIHAND) or has_mask_zora() end,
        },
    },
    ["Stone Tower Temple Water Room"] = {
        ["events"] = {
            ["STONE_TOWER_WATER_CHEST_SWITCH"] = function () return has_mask_zora() end,
            ["STONE_TOWER_EAST_ENTRY_BLOCK"] = function () return has_mirror_shield() or can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Center"] = function () return has_mask_zora() end,
            ["Stone Tower Temple Mirrors Room"] = function () return small_keys(SMALL_KEY_ST, 4) end,
            ["Stone Tower Temple Entrance"] = function () return event('STONE_TOWER_EAST_ENTRY_BLOCK') end,
        },
        ["locations"] = {
            ["Stone Tower Temple Compass"] = function () return event('STONE_TOWER_EAST_ENTRY_BLOCK') end,
            ["Stone Tower Temple Water Sun Switch Chest"] = function () return has_mask_zora() and event('STONE_TOWER_WATER_CHEST_SUN') end,
        },
    },
    ["Stone Tower Temple Mirrors Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Water Room"] = function () return small_keys(SMALL_KEY_ST, 4) end,
            ["Stone Tower Temple Wind Room"] = function () return has_mask_goron() and has_mirror_shield() or can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Stone Tower Temple Mirrors Room Center Chest"] = function () return has_mask_goron() and has_mirror_shield() or can_use_light_arrows() end,
            ["Stone Tower Temple Mirrors Room Right Chest"] = function () return has_mask_goron() and has_mirror_shield() or can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Wind Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Light Arrow Room"] = function () return has('MASK_DEKU') or can_use_light_arrows() end,
            ["Stone Tower Temple Mirrors Room"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Wind Room Ledge Chest"] = function () return has('MASK_DEKU') end,
            ["Stone Tower Temple Wind Room Jail Chest"] = function () return (has('MASK_DEKU') or can_use_light_arrows()) and has_mask_goron() end,
        },
    },
    ["Stone Tower Temple Light Arrow Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Before Water Bridge"] = function () return soul(SOUL_GARO) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Light Arrow"] = function () return soul(SOUL_GARO) end,
        },
    },
    ["Stone Tower Temple Before Water Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Water Bridge"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Before Water Bridge Chest"] = function () return event('STONE_TOWER_BRIDGE_CHEST_SWITCH') or (has_explosives() or trick_keg_explosives()) end,
        },
    },
    ["Stone Tower Temple Water Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return true end,
            ["Stone Tower Temple Center"] = function () return can_goron_bomb_jump() end,
            ["Stone Tower Temple Center Ledge"] = function () return (can_goron_bomb_jump() and (has_bombs() or (small_keys(SMALL_KEY_ST, 3) and trick_keg_explosives()))) and can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Stone Tower Temple Water Bridge Chest"] = function () return soul(SOUL_EYEGORE) end,
        },
    },
    ["Stone Tower Temple Inverted"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Entrance"] = function () return can_reset_time() end,
            ["Stone Tower Top Inverted"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted"] = function () return true end,
            ["Stone Tower Temple Inverted East"] = function () return can_use_light_arrows() end,
            ["Stone Tower Temple Inverted Entrance Ledge"] = function () return trick('MM_ISTT_ENTRY_JUMP') and (has_bombs() or trick_keg_explosives()) end,
            ["Stone Tower Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_TWINMOLD') end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Entrance Chest"] = function () return can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Inverted East"] = {
        ["events"] = {
            ["STONE_TOWER_WATER_CHEST_SUN"] = function () return can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Entrance"] = function () return can_use_light_arrows() end,
            ["Stone Tower Temple Inverted East Ledge"] = function () return has('MASK_DEKU') end,
            ["Stone Tower Temple Inverted East Bridge"] = function () return has('MASK_DEKU') or trick('MM_ISTT_EYEGORE') end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted East Lower Chest"] = function () return has('MASK_DEKU') and can_use_fire_arrows() end,
            ["Stone Tower Temple Inverted East Upper Chest"] = function () return has('MASK_DEKU') and can_use_elegy() and event('STONE_TOWER_WATER_CHEST_SWITCH') end,
        },
    },
    ["Stone Tower Temple Inverted East Bridge"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted East"] = function () return true end,
            ["Stone Tower Temple Inverted Center Bridge"] = function () return trick('MM_ISTT_EYEGORE') and (has_mask_zora() and has_bombs() or (has_shield() and has_explosives())) end,
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return trick('MM_ISTT_EYEGORE') end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted East Middle Chest"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted East Ledge"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted East"] = function () return true end,
            ["Stone Tower Temple Inverted East Bridge"] = function () return true end,
            ["Stone Tower Temple Inverted Wizzrobe"] = function () return (soul(SOUL_CHUCHU) or (trick('MM_ISTT_CHUCHU_LESS') and (has_chateau() or has_blue_potion() or has_green_potion() or has_double_magic()))) and can_use_light_arrows() and cond(trick('MM_ISTT_ENTRY_JUMP'), small_keys(SMALL_KEY_ST, 4), small_keys(SMALL_KEY_ST, 3)) end,
        },
    },
    ["Stone Tower Temple Inverted Wizzrobe"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Wizzrobe Ledge"] = function () return soul(SOUL_WIZZROBE) and can_hookshot_short() end,
            ["Stone Tower Temple Inverted East Ledge"] = function () return soul(SOUL_WIZZROBE) and (can_use_light_arrows() and small_keys(SMALL_KEY_ST, 3)) or (can_goron_bomb_jump() and has_bombs() and small_keys(SMALL_KEY_ST, 4)) end,
        },
    },
    ["Stone Tower Temple Inverted Wizzrobe Ledge"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Wizzrobe"] = function () return true end,
            ["Stone Tower Temple Inverted Death Armos Maze"] = function () return has('MASK_DEKU') end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Wizrobe Chest"] = function () return soul(SOUL_WIZZROBE) end,
        },
    },
    ["Stone Tower Temple Inverted Death Armos Maze"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Center"] = function () return true end,
            ["Stone Tower Temple Inverted Wizzrobe Ledge"] = function () return has('MASK_DEKU') end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Under Wizrobe Chest"] = function () return can_use_elegy() end,
        },
    },
    ["Stone Tower Temple Inverted Center"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return has('MASK_DEKU') and has_weapon_range() end,
            ["Stone Tower Temple Inverted Entrance Ledge"] = function () return true end,
            ["Stone Tower Temple Inverted Death Armos Maze"] = function () return true end,
            ["Stone Tower Temple Inverted Center Bridge"] = function () return trick('MM_ISTT_EYEGORE') and can_use_light_arrows() and can_hookshot() end,
        },
    },
    ["Stone Tower Temple Inverted Boss Key Room"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
            ["BOMBS"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Center"] = function () return has('MASK_DEKU') end,
            ["Stone Tower Temple Inverted Center Bridge"] = function () return trick('MM_ISTT_EYEGORE') and can_use_light_arrows() and can_hookshot() end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Boss Key"] = function () return soul(SOUL_GOMESS) and can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Inverted Entrance Ledge"] = {
        ["events"] = {
            ["STONE_TOWER_ENTRANCE_CHEST_SWITCH"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Center Bridge"] = function () return small_keys(SMALL_KEY_ST, 4) and can_hookshot() end,
            ["Stone Tower Temple Inverted Center"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Center Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Pre-Boss"] = function () return soul(SOUL_EYEGORE) end,
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return trick('MM_ISTT_EYEGORE') and (has_mask_goron() or (has_explosives() or (trick_keg_explosives() and can_hookshot() and small_keys(SMALL_KEY_ST, 4)))) end,
            ["Stone Tower Temple Inverted Center"] = function () return trick('MM_ISTT_EYEGORE') and (has_mask_goron() or (has_explosives() or (trick_keg_explosives() and can_hookshot()))) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Giant Mask"] = function () return soul(SOUL_EYEGORE) end,
        },
    },
    ["Stone Tower Temple Inverted Pre-Boss"] = {
        ["events"] = {
            ["STONE_TOWER_BRIDGE_CHEST_SWITCH"] = function () return can_activate_crystal() end,
            ["BOMBS"] = function () return can_hookshot_short() end,
            ["ARROWS"] = function () return can_hookshot_short() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Boss Access"] = function () return can_hookshot_short() and boss_key(BOSS_KEY_ST) end,
        },
    },
    ["Stone Tower Temple Boss Access"] = {
        ["exits"] = {
            ["Stone Tower Temple Boss"] = function () return true end,
        },
    },
    ["Stone Tower Temple Boss"] = {
        ["exits"] = {
            ["Stone Tower After Boss"] = function () return soul(SOUL_TWINMOLD) and (has_magic() and (has('MASK_GIANT') and has('SWORD') or has('MASK_FIERCE_DEITY'))) end,
        },
    },
    ["Stone Tower After Boss"] = {
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Boss HC"] = function () return true end,
            ["Stone Tower Boss"] = function () return true end,
        },
    },
    ["Swamp Spider House"] = {
        ["exits"] = {
            ["Near Swamp Spider House"] = function () return true end,
            ["Swamp Spider House Main"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Swamp Spider House Mask of Truth"] = function () return has('GS_TOKEN_SWAMP', 30) end,
        },
    },
    ["Swamp Spider House Main"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return has_arrows() end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Swamp Spider House"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Skulltula Main Room Near Ceiling"] = function () return can_hookshot_short() or has_mask_zora() or (has('MASK_DEKU') and (has_arrows() or has_magic() or (has_bombs() or has_bombchu() or trick_keg_explosives()))) end,
            ["Swamp Skulltula Main Room Lower Right Soft Soil"] = function () return has_bottle() end,
            ["Swamp Skulltula Main Room Lower Left Soft Soil"] = function () return has_bottle() end,
            ["Swamp Skulltula Main Room Upper Soft Soil"] = function () return has_bottle() end,
            ["Swamp Skulltula Main Room Upper Pillar"] = function () return true end,
            ["Swamp Skulltula Main Room Pillar"] = function () return true end,
            ["Swamp Skulltula Main Room Water"] = function () return true end,
            ["Swamp Skulltula Main Room Jar"] = function () return true end,
            ["Swamp Skulltula Gold Room Near Ceiling"] = function () return can_hookshot_short() or has_mask_zora() or can_use_beans() end,
            ["Swamp Skulltula Gold Room Pillar"] = function () return true end,
            ["Swamp Skulltula Gold Room Wall"] = function () return true end,
            ["Swamp Skulltula Tree Room Hive"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Tree Room Grass 1"] = function () return true end,
            ["Swamp Skulltula Tree Room Grass 2"] = function () return true end,
            ["Swamp Skulltula Tree Room Tree 1"] = function () return true end,
            ["Swamp Skulltula Tree Room Tree 2"] = function () return true end,
            ["Swamp Skulltula Tree Room Tree 3"] = function () return true end,
            ["Swamp Skulltula Monument Room Lower Wall"] = function () return can_hookshot_short() or has_mask_zora() or (can_use_beans() and can_break_boulders()) end,
            ["Swamp Skulltula Monument Room On Monument"] = function () return true end,
            ["Swamp Skulltula Monument Room Crate 1"] = function () return true end,
            ["Swamp Skulltula Monument Room Crate 2"] = function () return true end,
            ["Swamp Skulltula Monument Room Torch"] = function () return true end,
            ["Swamp Skulltula Gold Room Hive"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Pot Room Hive 1"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Pot Room Hive 2"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Pot Room Behind Vines"] = function () return has_weapon() end,
            ["Swamp Skulltula Pot Room Pot 1"] = function () return true end,
            ["Swamp Skulltula Pot Room Pot 2"] = function () return true end,
            ["Swamp Skulltula Pot Room Jar"] = function () return true end,
            ["Swamp Skulltula Pot Room Wall"] = function () return true end,
        },
    },
    ["Woodfall Temple"] = {
        ["exits"] = {
            ["Woodfall Front of Temple"] = function () return true end,
            ["Woodfall Temple Entrance"] = function () return can_reset_time() end,
        },
    },
    ["Woodfall Temple Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return has_weapon_range() end,
        },
        ["exits"] = {
            ["Woodfall Temple"] = function () return true end,
            ["Woodfall Temple Main"] = function () return has('MASK_DEKU') or can_hookshot_short() end,
            ["Woodfall Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_ODOLWA') end,
        },
        ["locations"] = {
            ["Woodfall Temple Entrance Chest"] = function () return has('MASK_DEKU') or can_hookshot_short() end,
            ["Woodfall Temple SF Entrance"] = function () return true end,
        },
    },
    ["Woodfall Temple Main"] = {
        ["events"] = {
            ["WOODFALL_TEMPLE_MAIN_FLOWER"] = function () return can_use_fire_arrows() end,
            ["STICKS"] = function () return soul_deku_baba() end,
            ["NUTS"] = function () return soul_deku_baba() and (has('MASK_DEKU') or has_arrows() or has_explosives() or can_fight()) end,
            ["BOMBS"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple Entrance"] = function () return true end,
            ["Woodfall Temple Water Room"] = function () return true end,
            ["Woodfall Temple Maze"] = function () return small_keys(SMALL_KEY_WF, 1) end,
            ["Woodfall Temple Main Ledge"] = function () return event('WOODFALL_TEMPLE_MAIN_FLOWER') or event('WOODFALL_TEMPLE_MAIN_LADDER') or can_hookshot_short() end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Main Pot"] = function () return true end,
            ["Woodfall Temple SF Main Deku Baba"] = function () return soul_deku_baba() end,
        },
    },
    ["Woodfall Temple Water Room"] = {
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Map Room"] = function () return has('MASK_DEKU') or can_hookshot_short() or can_use_ice_arrows() or event('WOODFALL_TEMPLE_MAIN_FLOWER') end,
            ["Woodfall Temple Water Room Upper"] = function () return has_arrows() and has('MASK_DEKU') end,
        },
        ["locations"] = {
            ["Woodfall Temple Water Chest"] = function () return has('MASK_DEKU') or can_hookshot() or (can_hookshot_short() and event('WOODFALL_TEMPLE_MAIN_FLOWER')) or can_use_ice_arrows() end,
            ["Woodfall Temple SF Water Room Beehive"] = function () return has_arrows() or can_use_deku_bubble() or (has('MASK_GREAT_FAIRY') and (has_bombs() or has_bombchu() or has_mask_zora() or can_hookshot())) end,
        },
    },
    ["Woodfall Temple Map Room"] = {
        ["exits"] = {
            ["Woodfall Temple Water Room"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Map"] = function () return soul(SOUL_SNAPPER) and (has('MASK_DEKU') or has_explosives() or has_mask_goron()) end,
        },
    },
    ["Woodfall Temple Maze"] = {
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Compass Room"] = function () return has_sticks() or can_use_fire_arrows() end,
            ["Woodfall Temple Dark Room"] = function () return has_sticks() or can_use_fire_arrows() end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Maze Skulltula"] = function () return soul_skulltula() and (can_fight() or has_arrows() or can_use_deku_bubble() or has_explosives()) end,
            ["Woodfall Temple SF Maze Beehive"] = function () return has_weapon_range() end,
            ["Woodfall Temple SF Maze Bubble"] = function () return has('MASK_GREAT_FAIRY') and (has_arrows() or can_hookshot_short()) or event('WOODFALL_TEMPLE_MAIN_FLOWER') end,
        },
    },
    ["Woodfall Temple Compass Room"] = {
        ["exits"] = {
            ["Woodfall Temple Maze"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Compass"] = function () return soul(SOUL_DRAGONFLY) end,
        },
    },
    ["Woodfall Temple Dark Room"] = {
        ["exits"] = {
            ["Woodfall Temple Maze"] = function () return has_sticks() or has_arrows() end,
            ["Woodfall Temple Pits Room"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Dark Chest"] = function () return soul(SOUL_BOE) end,
        },
    },
    ["Woodfall Temple Pits Room"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Dark Room"] = function () return true end,
            ["Woodfall Temple Main Ledge"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Woodfall Temple Main Ledge"] = {
        ["events"] = {
            ["WOODFALL_TEMPLE_MAIN_FLOWER"] = function () return has_arrows() end,
            ["WOODFALL_TEMPLE_MAIN_LADDER"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Pits Room"] = function () return true end,
            ["Woodfall Temple Pre-Boss"] = function () return has_arrows() end,
        },
        ["locations"] = {
            ["Woodfall Temple Center Chest"] = function () return has('MASK_DEKU') end,
            ["Woodfall Temple SF Main Bubble"] = function () return true end,
        },
    },
    ["Woodfall Temple Water Room Upper"] = {
        ["exits"] = {
            ["Woodfall Temple Main Ledge"] = function () return true end,
            ["Woodfall Temple Water Room"] = function () return true end,
            ["Woodfall Temple Bow Room"] = function () return true end,
            ["Woodfall Temple Boss Key Room"] = function () return has_arrows() and has('MASK_DEKU') end,
        },
    },
    ["Woodfall Temple Bow Room"] = {
        ["exits"] = {
            ["Woodfall Temple Water Room Upper"] = function () return can_fight() or has_arrows() end,
        },
        ["locations"] = {
            ["Woodfall Temple Bow"] = function () return soul_lizalfos_dinalfos() and (can_fight() or has_arrows()) end,
        },
    },
    ["Woodfall Temple Boss Key Room"] = {
        ["events"] = {
            ["FROG_2"] = function () return has('MASK_DON_GERO') and soul(SOUL_GEKKO) end,
        },
        ["exits"] = {
            ["Woodfall Temple Water Room Upper"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Boss Key Chest"] = function () return soul(SOUL_GEKKO) end,
        },
    },
    ["Woodfall Temple Pre-Boss"] = {
        ["exits"] = {
            ["Woodfall Temple Boss Access"] = function () return boss_key(BOSS_KEY_WF) and (can_hookshot() or has('MASK_DEKU')) end,
            ["Woodfall Temple Main Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Pre-Boss Bottom Right"] = function () return true end,
            ["Woodfall Temple SF Pre-Boss Left"] = function () return has('MASK_DEKU') or has('MASK_GREAT_FAIRY') end,
            ["Woodfall Temple SF Pre-Boss Top Right"] = function () return true end,
            ["Woodfall Temple SF Pre-Boss Pillar"] = function () return has('MASK_DEKU') or has('MASK_GREAT_FAIRY') end,
        },
    },
    ["Woodfall Temple Princess Jail"] = {
        ["events"] = {
            ["DEKU_PRINCESS"] = function () return has_bottle() and has_weapon() end,
        },
        ["exits"] = {
            ["Woodfall"] = function () return true end,
        },
    },
    ["Woodfall Temple Boss Access"] = {
        ["exits"] = {
            ["Woodfall Temple Boss"] = function () return true end,
        },
    },
    ["Woodfall Temple Boss"] = {
        ["exits"] = {
            ["Woodfall Temple After Boss"] = function () return soul(SOUL_ODOLWA) and (has('MASK_FIERCE_DEITY') and has_magic() or (has_arrows() and can_fight())) end,
        },
    },
    ["Woodfall Temple After Boss"] = {
        ["events"] = {
            ["CLEAN_SWAMP"] = function () return true end,
        },
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Boss Container"] = function () return true end,
            ["Woodfall Temple Boss"] = function () return true end,
        },
    },
}

    return M
end
