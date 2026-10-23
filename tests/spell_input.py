"""Autocomplete and persisted spell identity across locale, rank and profile changes."""
from mock_runtime import lua

lua.execute(r'''
local E=EasyCast
-- IDs available only through hyperlinks; names and book slots are not IDs.
spellBook={{"Holy Light","Rank 1"},{"Holy Light","Rank 2"},{"Attack",""},{"Flash of Light","Rank 1"}}
local ids={635,639,6603,19750}
function GetSpellLink(slot,book) return "|Hspell:"..ids[slot].."|h[spell]|h" end
E.db.spellAliases={}
E.db.bindings.friendly.LeftButton="Holy Light"
E.db.profiles.Stored={bindings={friendly={RightButton={type="spell",value="Holy Light(Rank 1)"}}}}
assert(E:RefreshSpells())
local highest=E.db.bindings.friendly.LeftButton
local exact=E.db.profiles.Stored.bindings.friendly.RightButton
assert(highest.spellID==639 and highest.highest)
assert(exact.spellID==635 and not exact.highest)
assert(E:SpellSuggestions("")[1]==nil)
local options=E:SpellSuggestions("light")
assert(table.getn(options)==2 and options[1].label=="Flash of Light")
assert(table.getn(E:SpellSuggestions("Holy Light("))==2)
assert(E:SpellSuggestions("Holy")[1].icon=="texture2","bare name chooses highest rank")
-- Retain the binding alone, with no alias cache, across language and book order changes.
E.db.spellAliases={}
spellBook={{"Angriff",""},{"Heiliges Licht","Rang 1"},{"Heiliges Licht","Rang 2"},{"Heiliges Licht","Rang 3"}}
ids={6603,635,639,647}; E:RefreshSpells()
assert(E:BindingInfo(highest).spellID==647 and E:BindingLabel(highest)=="Heiliges Licht")
assert(E:BindingInfo(exact).spellID==635 and E:BindingLabel(exact)=="Heiliges Licht(Rang 1)")
local cast=E.CastSpellOnUnit
E.CastSpellOnUnit=function(_,unit,spell) assert(unit=="player" and spell.spellID==647); return true end
assert(E:Cast("player",highest),"casting retains ID, not just the old name")
E.CastSpellOnUnit=cast
for _,locale in ipairs({"enUS","deDE","frFR","esES","ptBR","ruRU","koKR","zhCN"}) do
    E.db.language=locale; E:InitLocale(); assert(E:BindingInfo(highest).spellID==647)
end
-- Unlearned IDs must not silently map to another spell by name or slot.
spellBook={{"Holy Light","Rank 1"}}; ids={9000}; E:RefreshSpells()
assert(not E:BindingInfo(exact))
-- Stock clients retain name-based behavior without invented IDs.
GetSpellLink=nil; E.db.spellAliases={}; spellBook={{"Heal","Rank 1"},{"Heal","Rank 2"},{"Smite","Rank 1"}}
E:RefreshSpells(); E:SetAction("friendly","LeftButton",{type="spell",value="Heal"})
assert(not E.db.bindings.friendly.LeftButton.spellID and E:BindingInfo(E.db.bindings.friendly.LeftButton).slot==2)
-- Exercise typing and acceptance through real edit/popup scripts.
E.bindKind="friendly"; E.bindModifier=""; E:RefreshRows()
local row=E.bindingRows[1]
local function typeText(text)
    row.edit.focus=true; row.edit:GetScript("OnEditFocusGained")(); row.edit:SetText(text)
end
typeText("He")
local popup=E.spellSuggestions
assert(popup:IsShown() and popup.buttons[1].choice.label=="Heal")
assert(E:BindingLabel(E.db.bindings.friendly.LeftButton)=="Heal","typing does not replace saved binding")
row.edit:GetScript("OnTabPressed")()
assert(row.edit:GetText()=="Heal" and not popup:IsShown() and not E.focusedEdit)
typeText("Smi"); popup.buttons[1]:GetScript("OnMouseDown")()
assert(E:BindingLabel(E.db.bindings.friendly.LeftButton)=="Smite" and not popup:IsShown())
typeText("He"); E:ScrollBindings(-1); assert(not popup:IsShown(),"scroll hides detached suggestions")
row.actionType="macro"; typeText("He"); assert(not popup:IsShown(),"no spell suggestions for macros")
row.actionType="spell"; typeText("He"); row.edit:ClearFocus(); popup:GetScript("OnUpdate")()
assert(not popup:IsShown() and E:BindingLabel(E.db.bindings.friendly.LeftButton)=="Smite","invalid partial input preserves binding")
print("PASS: cached spell suggestions, UI acceptance, explicit ranks, stable IDs, profile migration, all menu languages and stock fallback")
''')
