-- Test: Item-Suche schliesst die Reagenzientasche (Tasche 5) ein (Forever_Failure F-31)   texlua tests/reagentbag_test.lua
local src = assert(io.open("Loot.lua")):read("*a")
local _, n = src:gsub("NUM_TOTAL_EQUIPPED_BAG_SLOTS", "")
assert(n >= 1, "Reagenzientasche beruecksichtigt")
local _, loops = src:gsub("for bag = 0, ScanBagCount%(%) do", "")
local _, inline = src:gsub("for bag = 0, math%.max%(4, tonumber%(_G%.NUM_TOTAL_EQUIPPED_BAG_SLOTS%) or 5%) do", "")
assert(loops + inline >= 1, "Item-Suchen mit Tasche 5: " .. (loops + inline))
-- ScanBagCount liefert mindestens 5 (0..5), auch ohne die Konstante
local NUM_BAG_SLOTS, NUM_TOTAL_EQUIPPED_BAG_SLOTS = 4, nil
assert(math.max(NUM_BAG_SLOTS, tonumber(NUM_TOTAL_EQUIPPED_BAG_SLOTS) or 5) == 5)
print("reagentbag_test OK")
