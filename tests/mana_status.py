"""Mana feedback without action slots, current rank/cost, and pooled icon reset."""
from mock_runtime import lua

lua.execute(r'''
local E=EasyCast
local info=E:Resolve("Heal(Rank 1)")
info.spellID=101
local mana,power=19,0
function UnitPowerType(unit) assert(unit=="player"); return power end
function UnitMana(unit) assert(unit=="player"); return mana end
E.diagnosticActions={}
local castCount=table.getn(calls)
-- Direct APIs work without action bars, preserving the selected rank.
function IsSpellUsable(id) assert(id==101); return 0,1 end
assert(E:BindingStatus("Heal(Rank 1)",info,"party1",1).reason=="Mana")
IsSpellUsable=function() return 0,0 end
assert(not E:BindingStatus("Heal(Rank 1)",info,"party1",1).invalid,"unusable is not automatically out of mana")
IsSpellUsable=nil
function IsUsableSpell(name) assert(name=="Heal(Rank 1)"); return nil,1 end
assert(E:BindingLacksMana("Heal(Rank 1)",info))
IsUsableSpell=nil
C_Spell={IsSpellUsable=function(id) assert(id==101); return false,true end}
assert(E:BindingLacksMana("Heal(Rank 1)",info))
C_Spell=nil
-- A missing/error result falls back to the localized tooltip header.
IsSpellUsable=function() error("unsupported API") end
for _,format in ipairs({"%d Mana","%d mana","%d de mana","%d ед. маны","마나 %d","%d点法力值","%1$d Mana"}) do
    MANA_COST=format
    local line=string.gsub(string.gsub(format,"%%1%$d","20"),"%%d","20")
    assert(E:ReadManaCost(line)==20,format)
    assert(E:ReadManaCost("Restores "..line)==nil,"description is not a cost")
end
MANA_COST="%d Mana"
assert(E:ReadManaCost("20% of base mana")==nil)
assert(E:ReadManaCost("20 Rage")==nil)
E:InvalidateManaCosts(); E.spellStatusQueue={}; E.nextSpellStatusScan=nil
assert(E:BindingLacksMana("Heal(Rank 1)",info)==nil,"unobserved cost remains unknown")
EasyCastSpellStatusScanTextLeft2=CreateFrame("FontString",nil,UIParent)
EasyCastSpellStatusScanTextLeft2:SetText("20 Mana")
E:UpdateSpellMetadata()
assert(E.spellManaCosts[info.cast]==20 and E:BindingLacksMana("Heal(Rank 1)",info))
mana=20; assert(not E:BindingLacksMana("Heal(Rank 1)",info),"exact cost is sufficient")
mana=21; assert(not E:BindingLacksMana("Heal(Rank 1)",info))
-- A free-cast buff must not leave a stale insufficient-mana indicator.
mana=0; EasyCastEvents:GetScript("OnEvent")(EasyCastEvents,"PLAYER_AURAS_CHANGED")
assert(E:BindingLacksMana("Heal(Rank 1)",info)==nil)
EasyCastSpellStatusScanTextLeft2:SetText("0 Mana")
fakeTime=fakeTime+1; E:UpdateSpellMetadata()
assert(E.spellManaCosts[info.cast]==0 and not E:BindingLacksMana("Heal(Rank 1)",info))
power=1; IsSpellUsable=function() return 0,1 end
assert(E:BindingLacksMana("Heal(Rank 1)",info)==nil,"rage is not mana")
power=0
assert(E:BindingLacksMana({type="macro",value="TestMacro"},info)==nil)
assert(E:BindingLacksMana({type="item",value="Potion"},info)==nil)
-- Target restrictions keep priority, then range, then the mana droplet.
E.spellRestrictions[info.cast]="self"; E.spellRangeLimits[info.cast]={min=0,max=40}
assert(E:BindingStatus("Heal(Rank 1)",info,"party1",0).reason=="Self")
assert(E:BindingStatus("Heal(Rank 1)",info,"player",0).reason=="RangeUp")
local status=E:BindingStatus("Heal(Rank 1)",info,"player",1)
assert(status.reason=="Mana" and status.invalid and status.lacksMana)
local cell=CreateFrame("Frame",nil,UIParent); cell.icon=cell:CreateTexture(); cell.icon:SetWidth(16)
function cell.icon:SetDesaturated(v) self.grey=v end
E:PaintBindingStatus(cell,status)
assert(cell.icon.grey and cell.icon.alpha==.3 and cell.statusLayer.manaBadge:IsShown() and not cell.statusLayer.badge:IsShown())
E:PaintBindingStatus(cell,{reason="RangeUp",invalid=true})
assert(not cell.statusLayer.manaBadge:IsShown() and cell.statusLayer.badge:IsShown())
E:PaintBindingStatus(cell,{})
assert(not cell.icon.grey and cell.icon.alpha==1 and not cell.statusLayer.manaBadge:IsShown())
assert(table.getn(calls)==castCount and currentTarget=="enemy","status reads never cast or change targets")
print("PASS: mana APIs, localized cost fallback, regeneration, cost-changing buffs, exact ranks, resource and action isolation, icon reuse")
''')
