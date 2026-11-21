# Freewood-Loot

**Deutsch & English · German & English.** Autor · Author: Lacustat. Version 0.3.0 · Interface 16001 (World of Warcraft: Forever).

![loot](https://github.com/Lacustat/Freewood-OctoWoW-Bilder/blob/main/loot.jpg)

## Inhalt · Contents
- [Deutsch](#deutsch)
- [English](#english)
- [Tastenbelegung · Key bindings](#tastenbelegung--key-bindings)
- [Änderungen · Changes](#änderungen--changes)

## Deutsch

### Was ist das?
Eine Blacklist für Beute: gelistete Items nimmt das Addon mit und löscht sie mit deinem nächsten Klick in der Spielwelt. Forever erlaubt das Löschen nur durch einen Klick von dir.

### Funktionen
- Vorschlag bei vollen Taschen (seit 0.2.0, vorher im Levelplaner): Ab einer einstellbaren Zahl freier Plätze (Standard 2) zeigt ein Fenster die X günstigsten Items nach Händlerpreis (Standard 6, einstellbar 1–20; grau und weiß). Nie vorgeschlagen: Grün und besser, Quest-Items, Ruhestein, Werkzeuge, Handwerksmaterial, Rezepte, Reagenzien, Munition, Köcher, Taschen und Items ohne Verkaufspreis. Je Zeile ein Haken (nur dieses Mal abwählen) und „Nie“ (kommt auf die Liste „Nie vorschlagen“, das Fenster füllt mit dem nächsten Item auf). „Ja“ setzt die angehakten Items auf die Beute-Blacklist oder löscht nur diese Stapel einmal (Einstellung). Gelöscht wird wie immer mit den nächsten Klicks in die Spielwelt, ein Item pro Klick. Höchstens alle 5 Minuten, nicht im Kampf (danach). `/fwjunk` zeigt den Vorschlag sofort.
- Einstellungen (seit 0.2.0) im Reiter Beute über den Knopf „Einstellungen“ oben rechts (braucht Core 0.54.0; mit älterem Core stehen sie wie bisher unter Einstellungen > Module): Löschen an/aus, Beute aufheben, Chat-Meldung, Vorschlag an/aus, „ab freien Plätzen“, Anzahl, „auf die Blacklist setzen“ und die Liste „Nie vorschlagen“ (X = wieder vorschlagen). Steht ein Item auf beiden Listen, gewinnt die Blacklist; das sagt der Hinweis, die Markierung „(Blacklist)“ und eine Chat-Zeile.
- Listen, „Zuletzt erhalten“ und Protokoll gelten pro Charakter.
- Selbsttest mit `/fwloot test`.

### Abhängigkeiten
- Benötigt: `Freewood-Core`
- Optional: –

### Befehle
- `/fwloot`: Reiter öffnen
- `/fwjunk`: Vorschlag bei vollen Taschen sofort zeigen
- `/fwloot test`: Selbsttest

### Installation
Den Ordner `Freewood-Loot` nach `World of Warcraft\_forever_\Interface\AddOns\` kopieren. Neue Dateien lädt das Spiel erst nach einem kompletten Neustart; ein `/reload` genügt nur, wenn sich bestehende Dateien geändert haben. Fehler sichtbar machen: `/console scriptErrors 1`, danach `/reload`.

### Hinweise
Alles Neue ist, soweit nicht anders vermerkt, im Spiel noch nicht geprüft (getestet wurde in einer Simulation).

### Lizenz
GPL-3.0, siehe `LICENSE`.

---

## English

### What is it?
A blacklist for loot: the addon picks up listed items and deletes them with your next click in the world. Forever only allows deleting through a click of yours.

### Features
- Suggestion when bags are nearly full (since 0.2.0, before in the level planner): at a configurable number of free slots (default 2) a window shows the X cheapest items by vendor price (default 6, 1–20; grey and white). Never suggested: green and better, quest items, hearthstone, tools, trade goods, recipes, reagents, ammo, quivers, bags and items without a sell price. Each row has a tick (deselect this time only) and "Never" (goes on the list "Never suggest", the window refills with the next item). "Yes" puts the ticked items on the loot blacklist or deletes only these stacks once (setting). Deleting works as always with your next clicks into the game world, one item per click. At most every 5 minutes, not in combat (afterwards). `/fwjunk` shows the suggestion at once.
- Settings (since 0.2.0) in the Loot tab via the "Settings" button at the top right (needs Core 0.54.0; with an older Core they stay under Settings > Modules): deleting on/off, pick up loot, chat message, suggestion on/off, "at free slots", number, "put on the blacklist" and the list "Never suggest" (X = suggest again). If an item is on both lists, the blacklist wins; the note, the "(blacklist)" mark and a chat line say so.
- Lists, “recently received” and the protocol are per character.
- Self-test with `/fwloot test`.

### Dependencies
- Required: `Freewood-Core`
- Optional: –

### Commands
- `/fwloot`: open the tab
- `/fwjunk`: show the bags-full suggestion now
- `/fwloot test`: Selbsttest

### Installation
Copy the folder `Freewood-Loot` to `World of Warcraft\_forever_\Interface\AddOns\`. New files only load after a full game restart; a `/reload` is enough only when existing files changed. To see errors: `/console scriptErrors 1`, then `/reload`.

### Notes
Unless marked otherwise, everything new has not yet been verified in game (it was tested in a simulation).

### License
GPL-3.0, see `LICENSE`.

## Tastenbelegung · Key bindings
**DE:** Unter Optionen > Tastaturbelegung gibt es einen eigenen Abschnitt für dieses Modul. Dort lässt sich eine Taste zum Öffnen und Schließen des Reiters belegen (zum Beispiel J für die Gilde). Ist der Reiter schon offen, schließt dieselbe Taste das Fenster. Nach der Installation einmal das Spiel neu starten, damit die neue Datei Bindings.xml gelesen wird.
**EN:** Options > Key Bindings has its own section for this module. Bind a key to open and close the tab (for example J for the guild). If the tab is already open, the same key closes the window. Restart the game once after installing so the new Bindings.xml file is read.

## Änderungen · Changes
**0.3.0 DE:** Erklärungen als goldenes „i“ aus dem Core (braucht Core 0.58.0): „Item hinzufügen“ hinter der Überschrift (die Liste darunter rückt hoch), Hinweise der Einstellungen und des Taschen-voll-Vorschlags (Liste nutzen, „Nie vorschlagen“) hinter den Überschriften. Ungeprüft im Spiel. **EN:** explanations as the golden "i" from the Core (needs Core 0.58.0): "Add item" behind the heading (the list below moves up), notes of the settings and of the bag-full suggestion behind the headings. Unchecked in game.

**0.2.0 DE:** Vorschlag bei vollen Taschen aus dem Levelplaner übernommen (`LootJunk.lua`), mit Einstellungen, Liste „Nie vorschlagen“ und einmaligem Löschen ohne Blacklist; Einstellungen im Modul. Test `texlua tests/junk_test.lua`. Ungeprüft im Spiel. **EN:** Bags-full suggestion moved over from the level planner (`LootJunk.lua`), with settings, the list "Never suggest" and one-time deleting without the blacklist; settings inside the module. Test `texlua tests/junk_test.lua`. Unchecked in game.

**0.1.8 DE:** Die Item-Suche schließt jetzt die Reagenzientasche (Tasche 5, Kräuter und Erze) ein. Freie Plätze werden weiter nur in den normalen Taschen gezählt. Test `texlua tests/reagentbag_test.lua`. Ungeprüft im Spiel. **EN:** The item search now includes the reagent bag (bag 5, herbs and ores). Free slots are still counted in the normal bags only. Test `texlua tests/reagentbag_test.lua`. Unchecked in game.
