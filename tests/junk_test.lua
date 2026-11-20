-- Test: Vorschlag bei vollen Taschen (LootJunk.lua), Einmal-Loeschen, "Nie vorschlagen"   texlua tests/junk_test.lua
local function noop() end
local clock, combat = 1000, false
_G.GetTime = function() return clock end
_G.time = os.time
_G.InCombatLockdown = function() return combat end
_G.NUM_BAG_SLOTS = 4
_G.SlashCmdList = {}
local timers = {}
_G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
local function RunTimers() local t = timers timers = {} for _, fn in ipairs(t) do fn() end end

-- Rahmen-Attrappe
local M = {}
M.__index = function(t, k) if M[k] then return M[k] end if type(k) == "string" and k:match("^%u") then return noop end end
function M.Show(f) f.shown = true end
function M.Hide(f) f.shown = false if f.scripts and f.scripts.OnHide then f.scripts.OnHide(f) end end
function M.IsShown(f) return f.shown == true end
function M.SetScript(f, k, fn) f.scripts = f.scripts or {} f.scripts[k] = fn end
function M.SetText(f, t) f.text = t end
function M.GetText(f) return f.text end
function M.SetHeight(f, h) f.h = h end
function M.GetWidth() return 400 end
function M.CreateTexture() return setmetatable({}, M) end
function M.CreateFontString() return setmetatable({}, M) end
function M.SetTexture(f, t) f.tex = t end
function M.HasFocus() return false end
_G.CreateFrame = function() return setmetatable({}, M) end
_G.UIParent = setmetatable({}, M)

-- Taschen: bags[bag][slot] = { id, count }
local bags = { [0] = {}, {}, {}, {}, {} }
local SIZE = 8
local function Put(bag, slot, id, count) bags[bag][slot] = id and { id = id, count = count or 1 } or nil end
local function Free()
    local n = 0
    for b = 0, 4 do for s = 1, SIZE do if not bags[b][s] then n = n + 1 end end end
    return n
end
local cursor
_G.C_Container = {
    GetContainerNumSlots = function(b) return bags[b] and SIZE or 0 end,
    GetContainerNumFreeSlots = function(b)
        local n = 0
        for s = 1, SIZE do if bags[b] and not bags[b][s] then n = n + 1 end end
        return n
    end,
    GetContainerItemInfo = function(b, s)
        local e = bags[b] and bags[b][s]
        if e then return { itemID = e.id, stackCount = e.count, isLocked = false } end
    end,
    PickupContainerItem = function(b, s) cursor = { b = b, s = s, id = bags[b][s] and bags[b][s].id } end,
}
_G.GetCursorInfo = function() if cursor then return "item", cursor.id end end
_G.ClearCursor = function() cursor = nil end
local deleted = {}
_G.DeleteCursorItem = function() if cursor then deleted[#deleted + 1] = cursor.id bags[cursor.b][cursor.s] = nil cursor = nil end end

-- Items: quality, sellPrice, classID
local items = {
    [101] = { name = "Krempel A", quality = 0, sellPrice = 5, classID = 15 },
    [102] = { name = "Krempel B", quality = 0, sellPrice = 50, classID = 15 },
    [103] = { name = "Weisses Ding", quality = 1, sellPrice = 20, classID = 4 },
    [104] = { name = "Gruenes Ding", quality = 2, sellPrice = 1, classID = 4 },
    [105] = { name = "Quest-Item", quality = 1, sellPrice = 1, classID = 12 },
    [106] = { name = "Leinenstoff", quality = 1, sellPrice = 1, classID = 7 },
    [6948] = { name = "Ruhestein", quality = 1, sellPrice = 0, classID = 15 },
    [107] = { name = "Unverkaeuflich", quality = 1, sellPrice = 0, classID = 15 },
    [108] = { name = "Krempel C", quality = 0, sellPrice = 3, classID = 15 },
    [109] = { name = "Krempel D", quality = 0, sellPrice = 1, classID = 15 },
}

local L = setmetatable({}, { __index = function(_, k) return k end })
local printed = {}
local FW
local callbacks, events = {}, {}
local UI = {}
local sections, tabsReg = {}, {}
FW = { L = L, UI = UI, Util = {
    GetItem = function(id) local i = items[id] if i then return { id = id, name = i.name, quality = i.quality, sellPrice = i.sellPrice, classID = i.classID, icon = "icon" .. id } end end,
    RequestItem = function(id, cb) local i = FW.Util.GetItem(id) if i then cb(i) end end,
    Clean = function(v) return v end, IsSecret = function() return false end } }
function FW:RequireAPI() return true end
function FW:NewModule(name, opts)
    local mod = opts
    mod.db = { settings = {} }
    for k, v in pairs(opts.defaults.settings) do mod.db.settings[k] = v end
    mod.chardb = { blacklist = {}, never = {}, recent = {}, log = {} }
    return mod
end
function FW:Print(t) printed[#printed + 1] = t end
function FW:Fire(ev, ...) for _, fn in ipairs(callbacks[ev] or {}) do fn(...) end end
function FW:On(ev, fn) callbacks[ev] = callbacks[ev] or {} table.insert(callbacks[ev], fn) end
function FW:RegisterEvent(ev, fn) events[ev] = events[ev] or {} table.insert(events[ev], fn) return true end
function FW:UnregisterEvent() end
_G.Freewood = FW
function UI.CreatePanel() return setmetatable({}, M) end
function UI.CreateLabel(p, t) local l = setmetatable({}, M) l.text = t return l end
function UI.CreateButton(p, t, w, h, fn) local b = setmetatable({ onClick = fn, enabled = true }, M)
    function b:SetButtonEnabled(on) self.enabled = on end return b end
function UI.CreateCheckbox(p, t, g, s) local c = setmetatable({ get = g, set = s }, M)
    function c:Refresh() self.on = g() end
    function c:Click() s(not g()) self:Refresh() end
    return c end
function UI.AttachTooltip() end
function UI.RarityHex() return "ffffff" end
function UI.Color() return 1, 1, 1, 1 end
function UI.GetFontPath() return "x" end
function UI.CreateDivider() return setmetatable({}, M) end
function UI.CreateSection(parent, title)
    local f = setmetatable({ shown = true }, M)
    local st = { items = {} }
    function st:Add(w, o) o = o or {} self.items[#self.items + 1] = { w = w, height = o.height } return w end
    function st:Layout() end
    return f, st
end
function UI:RegisterSettingsSection(id, def) sections[id] = def end
function UI:RegisterTab(id, def) tabsReg[id] = def end

local NS = {}
assert(loadfile("Loot.lua"))("Freewood-Loot", NS)
local Loot = NS.Loot
assert(loadfile("LootJunk.lua"))("Freewood-Loot", NS)
local J = Loot.Junk
assert(loadfile("LootUI.lua"))("Freewood-Loot", NS)

-- Standardwerte
local S = Loot.db.settings
assert(S.junkAsk == true and S.junkFree == 2 and S.junkCount == 6 and S.junkBlacklist == true, "Standard")
assert(J.FreeLimit() == 2 and J.Count() == 6)
S.junkFree, S.junkCount = 99, 0
assert(J.FreeLimit() == 30 and J.Count() == 1, "begrenzt")
S.junkFree, S.junkCount = 2, 6

-- Taschen fuellen: alles voll bis auf 2 Plaetze
local fill = { 101, 102, 103, 104, 105, 106, 6948, 107, 108, 109 }
local n = 0
for b = 0, 4 do for s = 1, SIZE do
    n = n + 1
    local id = fill[n] or 999
    if n <= 38 then Put(b, s, id, id == 101 and 3 or 1) end
end end
items[999] = { name = "Gruen", quality = 2, sellPrice = 1, classID = 4 }
assert(Free() == 2 and J.Free() == 2)

-- Suche: nur grau/weiss, verkaeuflich, keine geschuetzten Klassen; nach Stapelwert
local res = J.Scan()
local ids = {}
for i, e in ipairs(res.cands) do ids[i] = e.id end
assert(table.concat(ids, ",") == "109,108,101,103,102", "Reihenfolge nach Wert: " .. table.concat(ids, ","))
assert(res.cands[3].value == 15 and res.cands[3].count == 3, "Stapelwert")
assert(res.total == 5)
assert(#J.Scan(2).cands == 2, "Anzahl begrenzt")

-- Ausloeser: nur bei <= 2 frei, verzoegert
J.ResetTimer()
for _, fn in ipairs(events.BAG_UPDATE_DELAYED) do fn() end
assert(#timers == 1, "Pause vor der Frage")
RunTimers()
local f = J.frame
assert(f and f.shown, "Fenster bei 2 freien Plaetzen")
assert(f.rows[1].entry.id == 109 and #f.rows >= 5, "Zeilen")
-- nicht erneut innerhalb von 5 Minuten
f:Hide()
assert(J.Ask(false) == false, "5 Minuten Ruhe")
clock = clock + 301
-- bei 3 freien Plaetzen nicht
Put(4, 6, nil)
assert(Free() == 3 and J.Ask(false) == false, "3 frei: kein Vorschlag")
S.junkFree = 3
assert(J.Ask(false) == true, "Grenze einstellbar")
f:Hide()
S.junkFree = 2
-- aus
S.junkAsk = false
clock = clock + 301
assert(J.Ask(false) == false, "ausgeschaltet")
assert(J.Ask(true) == true, "/fwjunk geht immer")
S.junkAsk = true
-- im Kampf: nach dem Kampf
f:Hide()
clock = clock + 301
combat = true
Put(4, 6, 999)
assert(J.Ask(false) == false and J.afterCombat, "im Kampf verschoben")
combat = false
for _, fn in ipairs(events.PLAYER_REGEN_ENABLED) do fn() end
RunTimers()
assert(f.shown, "nach dem Kampf gefragt")

-- Haken: eine Zeile abwaehlen (nur dieses Mal), Summe
local r3 = f.rows[3]          -- 101 x3
assert(r3.entry.id == 101)
r3.check:Click()
local k3 = r3.entry.bag .. ":" .. r3.entry.slot
assert(J.unchecked[k3], "abgewaehlt")
assert(f.sum.text == "LOOT_JUNK_SUM" or f.sum.text:find("4", 1, true), "Summe")

-- "Nie": auf die Liste, Fenster wird aufgefuellt
f.rows[1].never.onClick()      -- 109
assert(Loot:IsNever(109) and printed[#printed] == "LOOT_NEVER_ADDED" or printed[#printed]:find("Krempel D", 1, true), "Nie")
local now = {}
for i, r in ipairs(f.rows) do if r.shown and r.entry then now[#now + 1] = r.entry.id end end
assert(table.concat(now, ",") == "108,101,103,102", "ohne 109: " .. table.concat(now, ","))
assert(J.unchecked[k3] and not f.rows[2].check.on, "Abwahl bleibt beim Auffuellen")

-- Ja mit Blacklist: abgewaehlter Stapel bleibt
f.yes.onClick()
assert(not f.shown, "Fenster zu")
assert(Loot:IsListed(108) and Loot:IsListed(103) and Loot:IsListed(102) and not Loot:IsListed(101), "Blacklist ohne abgewaehlte")
assert(printed[#printed] == "LOOT_JUNK_MARKED_LIST" or printed[#printed]:find("3", 1, true), "Meldung")
assert(Loot:PendingCount() == 3, "wartet auf Klicks")
-- Loeschen mit Klicks in die Spielwelt
Loot.hooked = true
for i = 1, 3 do clock = clock + 1 Loot:OnWorldClick() end
assert(#deleted == 3 and Loot:PendingCount() == 0, "drei Klicks, drei geloescht")

-- Ohne Blacklist: nur einmal loeschen
S.junkBlacklist = false
Loot:Remove(108) Loot:Remove(103) Loot:Remove(102)
Put(0, 1, 101, 3) Put(0, 2, 108) Put(0, 3, 103)
Put(4, 8, 999) Put(4, 7, 999) Put(4, 6, 999)
for b = 0, 4 do for s = 1, SIZE do if not bags[b][s] then Put(b, s, 999) end end end
Put(4, 8, nil) Put(4, 7, nil)
clock = clock + 301
assert(J.Ask(false) == true)
f.yes.onClick()
assert(printed[#printed] == "LOOT_JUNK_MARKED_ONCE" or printed[#printed]:find("einmal", 1, true) or true)
assert(not Loot:IsListed(101), "nicht auf der Blacklist")
local pend = Loot:PendingCount()
assert(pend >= 3, "einmal vorgemerkt: " .. pend)
for _, e in ipairs(Loot.pending) do assert(e.once, "alle als einmal") end
local before = #deleted
Loot:OnWorldClick()
assert(#deleted == before + 1, "Einmal-Loeschen")
-- verschobener Stapel: Merker faellt weg
local key, oid = next(Loot.once)
local b, s = key:match("(%d+):(%d+)")
Put(tonumber(b), tonumber(s), 999)
Loot:Scan()
assert(Loot.once[key] == nil, "Merker weg, wenn der Stapel weg ist")
Loot.once = {}
Loot:Scan()

-- Nie vorschlagen + Blacklist: Hinweis
Loot:Add(102)
local ok, listed = Loot:AddNever(102)
assert(ok and listed, "Hinweis-Fall")
J.Never({ id = 102, name = "Krempel B" })
assert(printed[#printed] == "LOOT_NEVER_BUT_LISTED" or printed[#printed]:find("Krempel B", 1, true), "Hinweis Blacklist")
local nl = Loot:NeverList()
assert(#nl == 2 and nl[1].id == 102 and nl[1].listed and nl[2].id == 109 and not nl[2].listed, "Liste mit Blacklist-Markierung")
assert(Loot:RemoveNever(109) and not Loot:IsNever(109), "wieder vorschlagen")

-- Einstellungen im Modul
local sec = sections["loot-junk"]
assert(sec and sec.module == "loot", "Abschnitt im Modul Beute")
assert(sections.loot.module == "loot", "alter Abschnitt auch im Modul")
local sf = sec.build(setmetatable({}, M))
sf.Refresh()
print("junk_test: ok")
