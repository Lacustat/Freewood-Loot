-- Freewood-Loot: Vorschlag zum Loeschen bei vollen Taschen (seit 0.2.0, vorher im Levelplaner)
--
-- Inhalt
--   1. Suche: die X guenstigsten Stapel nach Haendlerpreis (grau und weiss). Nie: gruen und besser, Quest-Items,
--      Ruhestein, Werkzeuge, Handwerksmaterial, Rezepte, Reagenzien, Munition, Koecher, Taschen, Items ohne Verkaufspreis
--      und Items auf der Liste "Nie vorschlagen".
--   2. Fenster: je Zeile ein Haken (nur dieses Mal abwaehlen) und "Nie" (nie mehr vorschlagen, Liste in den Einstellungen).
--      "Ja" merkt die angehakten Zeilen vor: auf die Beute-Blacklist (Einstellung an) oder nur einmal loeschen (aus).
--      Geloescht wird mit den naechsten Klicks in die Spielwelt, ein Item pro Klick (Vorgabe des Spiels).
--   3. Ausloeser: Taschen-Aenderung, hoechstens alle 5 Minuten, nicht im Kampf, ab "junkFree" freien Plaetzen.
--   4. /fwjunk: Vorschlag sofort zeigen.
--
-- Einstellungen (Loot.db.settings): junkAsk, junkFree (Standard 2), junkCount (Standard 6), junkBlacklist (Standard an).

local ADDON, NS = ...

local FW = _G.Freewood
local Loot = NS and NS.Loot
if not FW or not Loot then
    return
end

local G = _G
local Junk = {}
Loot.Junk = Junk
NS.Junk = Junk

Junk.MAX_COUNT = 20
Junk.MAX_FREE = 30
Junk.ASK_GAP = 300
-- Nie vorschlagen: Ruhestein, Werkzeuge, Angel
Junk.PROTECTED = { [6948] = true, [7005] = true, [2901] = true, [5956] = true, [6219] = true, [6256] = true, [6218] = true, [5060] = true }
-- Klassen, die nie vorgeschlagen werden: 1 Taschen, 5 Reagenzien, 6 Geschosse, 7 Handwerk, 9 Rezepte, 11 Koecher, 12 Quest
Junk.KEEP_CLASS = { [1] = true, [5] = true, [6] = true, [7] = true, [9] = true, [11] = true, [12] = true }

local function L(k, d) return (FW.L and FW.L[k]) or d end
local function S() return Loot.db and Loot.db.settings or {} end
local function Now() return G.GetTime and G.GetTime() or 0 end
local function InCombat() return G.InCombatLockdown and G.InCombatLockdown() and true or false end

local function Clamp(v, a, b, def)
    v = tonumber(v)
    if not v then return def end
    v = math.floor(v + 0.5)
    if v < a then return a end
    if v > b then return b end
    return v
end
function Junk.FreeLimit() return Clamp(S().junkFree, 0, Junk.MAX_FREE, 2) end
function Junk.Count() return Clamp(S().junkCount, 1, Junk.MAX_COUNT, 6) end
function Junk.On() return S().junkAsk ~= false end
function Junk.UseBlacklist() return S().junkBlacklist ~= false end

------------------------------------------------------------------------
-- 1. Suche
------------------------------------------------------------------------

local function BagCount() return tonumber(G.NUM_BAG_SLOTS) or 4 end

local function FreeIn(bag)
    local fn = (G.C_Container and G.C_Container.GetContainerNumFreeSlots) or G.GetContainerNumFreeSlots
    if type(fn) ~= "function" then return 0 end
    local ok, n = pcall(fn, bag)
    return (ok and tonumber(n)) or 0
end

-- freie Plaetze in den normalen Taschen (ohne Reagenzientasche)
function Junk.Free()
    local n = 0
    for bag = 0, BagCount() do n = n + FreeIn(bag) end
    return n
end

local function Info(id)
    return FW.Util and FW.Util.GetItem and FW.Util.GetItem(id) or nil
end

-- Darf dieses Item vorgeschlagen werden? Rueckgabe: info oder nil
function Junk.Allowed(id, quality)
    if not id or Junk.PROTECTED[id] or Loot:IsNever(id) then return nil end
    local info = Info(id)
    if not info then return nil end
    local q = quality or info.quality or 1
    if q > 1 then return nil end
    local class = tonumber(info.classID)
    if class and Junk.KEEP_CLASS[class] then return nil end
    if info.type == "Quest" then return nil end
    local name = type(info.name) == "string" and info.name:lower() or ""
    if name:find("hearthstone", 1, true) or name:find("ruhestein", 1, true) then return nil end
    if (tonumber(info.sellPrice) or 0) <= 0 then return nil end
    return info
end

-- { cands = { { bag, slot, id, count, name, value, icon, quality } }, free, total }
-- cands: die X guenstigsten (nach Gesamtwert des Stapels); total = Zahl aller moeglichen
function Junk.Scan(limit)
    limit = limit or Junk.Count()
    local all = {}
    for bag = 0, BagCount() do
        for slot = 1, Loot.NumSlots(bag) do
            local id, count, locked = Loot.SlotItem(bag, slot)
            if id and not locked and not Loot:IsListed(id) then
                local info = Junk.Allowed(id)
                if info then
                    count = count or 1
                    all[#all + 1] = { bag = bag, slot = slot, id = id, count = count, name = info.name or ("#" .. id),
                        value = (tonumber(info.sellPrice) or 0) * count, icon = info.icon, quality = info.quality or 1 }
                end
            end
        end
    end
    table.sort(all, function(a, b)
        if a.value ~= b.value then return a.value < b.value end
        if a.id ~= b.id then return a.id < b.id end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    local res = { cands = {}, free = Junk.Free(), total = #all }
    for i = 1, math.min(limit, #all) do res.cands[i] = all[i] end
    return res
end

function Junk.Money(c)
    c = math.floor((tonumber(c) or 0) + 0.5)
    if G.GetCoinTextureString then
        local ok, s = pcall(G.GetCoinTextureString, c)
        if ok and type(s) == "string" then return s end
    end
    local g, s, k = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
    if g > 0 then return string.format("%dg %ds %dc", g, s, k) end
    if s > 0 then return string.format("%ds %dc", s, k) end
    return k .. "c"
end

------------------------------------------------------------------------
-- 2. Fenster
------------------------------------------------------------------------

local UI = FW.UI
local frame
local ROW_H = 24
local current            -- letztes Suchergebnis
Junk.unchecked = {}      -- ["Tasche:Platz"] = true: nur dieses Mal abgewaehlt

local function Key(e) return e.bag .. ":" .. e.slot end

-- Vormerken: Rueckgabe Zahl der vorgemerkten Stapel
function Junk.Mark(res)
    res = res or current
    local n = 0
    local useList = Junk.UseBlacklist()
    for _, e in ipairs(res and res.cands or {}) do
        if not Junk.unchecked[Key(e)] then
            if useList then
                local ok, why = Loot:Add(e.id)
                if ok or why == "already" then n = n + 1 end
            elseif Loot:MarkOnce(e.bag, e.slot, e.id) then
                n = n + 1
            end
        end
    end
    if n > 0 then
        local msg = useList and L("LOOT_JUNK_MARKED_LIST", "%d marked (loot blacklist). They are deleted with your next clicks into the game world, one item per click.")
            or L("LOOT_JUNK_MARKED_ONCE", "%d marked to delete once. They are deleted with your next clicks into the game world, one item per click.")
        FW:Print(string.format(msg, n))
        if not (S().enabled) then FW:Print(L("LOOT_JUNK_DISABLED", "Note: deleting is switched off in the Loot settings.")) end
    end
    return n
end

-- Nie mehr vorschlagen (Knopf "Nie" in einer Zeile)
function Junk.Never(e)
    local ok, listed = Loot:AddNever(e.id, e.name)
    if not ok then return false end
    if listed then
        FW:Print(string.format(L("LOOT_NEVER_BUT_LISTED", "%s is never suggested again, but it is on the loot blacklist and is still deleted automatically."), tostring(e.name)))
    else
        FW:Print(string.format(L("LOOT_NEVER_ADDED", "%s is never suggested again (list in the Loot settings)."), tostring(e.name)))
    end
    return true
end

local function IconOf(e)
    return e.icon or (G.GetItemIcon and select(2, pcall(G.GetItemIcon, e.id))) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function Row(i)
    local r = frame.rows[i]
    if r then return r end
    r = G.CreateFrame("Frame", nil, frame)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -(58 + (i - 1) * ROW_H))
    r:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -(58 + (i - 1) * ROW_H))
    r.check = UI.CreateCheckbox(r, "", function() return r.entry and not Junk.unchecked[Key(r.entry)] end, function(on)
        if r.entry then Junk.unchecked[Key(r.entry)] = (not on) or nil end
        Junk.UpdateAsk()
    end)
    r.check:SetWidth(22)
    r.check:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(ROW_H - 4, ROW_H - 4)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.icon:SetPoint("LEFT", r, "LEFT", 26, 0)
    r.never = UI.CreateButton(r, L("LOOT_JUNK_NEVER", "Never"), 50, 20, function()
        if r.entry and Junk.Never(r.entry) then Junk.Refill() end
    end, "ghost")
    r.never:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    UI.AttachTooltip(r.never, function() return L("LOOT_JUNK_NEVER_TIP", "Never suggest again") end,
        function() return L("LOOT_JUNK_NEVER_TIP2", "The item is put on the list \"Never suggest\" (Loot settings).") end)
    r.cost = UI.CreateLabel(r, "", { size = 11, color = "textDim", justify = "RIGHT" })
    r.cost:SetPoint("RIGHT", r.never, "LEFT", -8, 0)
    r.cost:SetWidth(96)
    r.text = UI.CreateLabel(r, "", { size = 12 })
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    r.text:SetPoint("RIGHT", r.cost, "LEFT", -6, 0)
    r.text:SetWordWrap(false)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        if self.entry and G.GameTooltip then
            G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if G.GameTooltip.SetBagItem then pcall(G.GameTooltip.SetBagItem, G.GameTooltip, self.entry.bag, self.entry.slot)
            else pcall(G.GameTooltip.SetItemByID, G.GameTooltip, self.entry.id) end
            G.GameTooltip:Show()
        end
    end)
    r:SetScript("OnLeave", function() if G.GameTooltip then G.GameTooltip:Hide() end end)
    frame.rows[i] = r
    return r
end

local function Build()
    local f = UI.CreatePanel(G.UIParent, "bg", "gold")
    f:SetSize(440, 200)
    f:SetPoint("CENTER", G.UIParent, "CENTER", 0, 140)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    f.title = UI.CreateLabel(f, L("LOOT_JUNK_TITLE", "Bags nearly full"), { font = "heading", size = 15, color = "goldLight" })
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
    f.head = UI.CreateLabel(f, "", { size = 12, color = "textDim" })
    f.head:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -36)
    f.head:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -36)
    f.rows = {}
    f.sum = UI.CreateLabel(f, "", { size = 12 })
    f.hint = UI.CreateLabel(f, "", { size = 11, color = "textDim", justifyV = "TOP" })
    f.hint:SetWordWrap(true)
    f.yes = UI.CreateButton(f, L("LOOT_YES_BTN", "Yes"), 120, 28, function()
        local res = current      -- vor dem Schliessen merken (OnHide leert current)
        f:Hide()
        Junk.Mark(res)
    end, "primary")
    f.yes:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 14)
    f.no = UI.CreateButton(f, L("LOOT_NO_BTN", "No"), 120, 28, function() f:Hide() end, "default")
    f.no:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 14)
    f:SetScript("OnHide", function() current = nil end)
    G.FreewoodLootJunkPrompt = f
    if G.UISpecialFrames then table.insert(G.UISpecialFrames, "FreewoodLootJunkPrompt") end
    Junk.frame = f
    return f
end

-- Summe und Knopf "Ja" nach den Haken
function Junk.UpdateAsk()
    if not (frame and current) then return end
    local n, sum = 0, 0
    for _, e in ipairs(current.cands) do
        if not Junk.unchecked[Key(e)] then n, sum = n + 1, sum + e.value end
    end
    frame.sum:SetText(string.format(L("LOOT_JUNK_SUM", "Selected: %d, sell value together %s"), n, Junk.Money(sum)))
    if frame.yes.SetButtonEnabled then frame.yes:SetButtonEnabled(n > 0) end
end

function Junk.Show(res)
    if not UI then return false end
    if not frame then frame = Build() end
    current = res
    frame.head:SetText(string.format(L("LOOT_JUNK_HEAD", "Bags nearly full (%s free). The %d cheapest items:"), tostring(res.free), #res.cands))
    local n = #res.cands
    for i = 1, math.max(n, #frame.rows) do
        local e = res.cands[i]
        if e then
            local r = Row(i)
            r.entry = e
            r.icon:SetTexture(IconOf(e))
            local hex = UI.RarityHex and UI.RarityHex(e.quality) or "ffffff"
            r.text:SetText("|cff" .. hex .. tostring(e.name) .. "|r" .. (e.count > 1 and ("  |cff9a9aa3x" .. e.count .. "|r") or ""))
            r.cost:SetText(Junk.Money(e.value))
            r.check:Refresh()
            r:Show()
        elseif frame.rows[i] then
            frame.rows[i].entry = nil
            frame.rows[i]:Hide()
        end
    end
    local y = 58 + n * ROW_H + 6
    frame.sum:ClearAllPoints()
    frame.sum:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -y)
    frame.hint:ClearAllPoints()
    frame.hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -(y + 20))
    frame.hint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -(y + 20))
    frame.hint:SetText(Junk.UseBlacklist() and L("LOOT_JUNK_HINT_LIST", "Yes: the ticked items go on the loot blacklist (also deleted automatically in future). Deleted with your next clicks into the game world, one item per click.")
        or L("LOOT_JUNK_HINT_ONCE", "Yes: the ticked stacks are deleted once (not on the blacklist). Deleted with your next clicks into the game world, one item per click."))
    frame:SetHeight(y + 20 + 44 + 52)
    Junk.UpdateAsk()
    frame:Show()
    return true
end

-- nach "Nie": neu suchen und das Fenster mit dem naechsten guenstigsten Item auffuellen
function Junk.Refill()
    if not (frame and frame:IsShown()) then return end
    local res = Junk.Scan()
    if #res.cands == 0 then frame:Hide() return end
    Junk.Show(res)
end

------------------------------------------------------------------------
-- 3. Ausloeser
------------------------------------------------------------------------

local lastAsk = -1000
function Junk.Ask(force)
    if not force and not Junk.On() then return false end
    local now = Now()
    if not force and now - lastAsk < Junk.ASK_GAP then return false end
    if InCombat() then
        Junk.afterCombat = true
        return false
    end
    if frame and frame:IsShown() and not force then return false end
    local res = Junk.Scan()
    if not force and res.free > Junk.FreeLimit() then return false end
    if #res.cands == 0 then
        if force then FW:Print(L("LOOT_JUNK_NONE", "Nothing to suggest for deleting.")) end
        return false
    end
    Junk.unchecked = {}
    if Junk.Show(res) then
        lastAsk = now
        return true
    end
    return false
end
function Junk.ResetTimer() lastAsk = -1000 end

local waiting = false
function Junk.OnBags()
    if waiting or not Junk.On() then return end
    if Junk.Free() > Junk.FreeLimit() then return end
    if G.C_Timer and G.C_Timer.After then
        waiting = true
        G.C_Timer.After(2, function()
            waiting = false
            pcall(Junk.Ask, false)
        end)
    else
        pcall(Junk.Ask, false)
    end
end

FW:RegisterEvent("BAG_UPDATE_DELAYED", function() Junk.OnBags() end)
FW:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    if Junk.afterCombat then
        Junk.afterCombat = false
        Junk.OnBags()
    end
end)

------------------------------------------------------------------------
-- 4. Befehl
------------------------------------------------------------------------

G.SLASH_FREEWOODJUNK1 = "/fwjunk"
G.SlashCmdList = G.SlashCmdList or {}
G.SlashCmdList.FREEWOODJUNK = function() Junk.Ask(true) end
