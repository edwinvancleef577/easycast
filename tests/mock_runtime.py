"""Behavior checks with a small WoW API double; not an in-client certification."""
from pathlib import Path
import os, json
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
frames={}; calls={}; messages={}; savedTarget=nil; currentTarget="enemy"
units={player="me",party1="ally",pet="pet",mouseover="enemy"}
fakeTime=0; mouseX=800; mouseY=400; bindingAction=""; nativeBindings={BUTTON1="CAMERAORSELECTORMOVE",BUTTON2="TURNORACTION"}; inCombat=false
function GetTime() return fakeTime end
function GetBindingAction(key) return bindingAction~="" and bindingAction or (nativeBindings[key] or "") end
function SetBinding(key,action) nativeBindings[key]=action; return true end
function UnitAffectingCombat() return inCombat end
mods={}; spellBook={{"Heal","Rank 1"},{"Heal","Rank 2"},{"Smite","Rank 1"}}
function getglobal(k) return _G[k] end
function setglobal(k,v) _G[k]=v end
function IsAltKeyDown() return mods.alt end
function IsControlKeyDown() return mods.ctrl end
function IsShiftKeyDown() return mods.shift end
function UnitID(u) if u=="target" then return currentTarget end return units[u] end
function UnitExists(u) return UnitID(u)~=nil end
function UnitIsUnit(a,b) return UnitID(a)~=nil and UnitID(a)==UnitID(b) end
function UnitCanAttack(a,b) return UnitID(b)=="enemy" end
function UnitIsFriend(a,b) return UnitID(b) and UnitID(b)~="enemy" end
function UnitName(u) return UnitID(u) end
function GetSpellName(i) if spellBook[i] then return unpack(spellBook[i]) end end
function GetSpellTexture(i) return "texture"..i end
function IsPassiveSpell() return false end
function TargetUnit(u) savedTarget=currentTarget; currentTarget=UnitID(u) end
function TargetLastTarget() currentTarget,savedTarget=savedTarget,currentTarget end
function ClearTarget() currentTarget=nil end
function CastSpellByName(name)
 table.insert(calls,{spell=name,unit=currentTarget})
 if failCast then error("cast test error") end
end
function SpellIsTargeting() return targeting end
function SpellStopTargeting() targeting=nil end
function GetCursorPosition() return mouseX,mouseY end
function GetMouseFocus() return mouseFocus or PlayerFrame end
STANDARD_TEXT_FONT="font"; UISpecialFrames={}; SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,m) table.insert(messages,m) end}
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:SetText(s)
 self.text=s
 if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return self.text or "" end
function methods:SetOwner(owner) self.owner=owner end
function methods:GetOwner() return self.owner end
function methods:SetUnit(unit) self.unit=unit end
function methods:GetUnit() return UnitName(self.unit),self.unit end
function methods:SetSpell(a,b) self.unit=nil; self.spellArgs={a,b} end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width or 100 end
function methods:GetHeight() return self.height or 100 end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:GetCenter() return 512,384 end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return 1 end
function methods:GetObjectType() return self.kind end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:Show()
 local was=self.shown; self.shown=true
 if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
 local was=self.shown; self.shown=false
 if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:ClearFocus()
 if self.focus then self.focus=nil; if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end end
end
function methods:SetPoint(...) self.point={...} end
function methods:RegisterEvent(ev) self.events[ev]=true end
function methods:CreateTexture() return CreateFrame("Texture",nil,self) end
function methods:CreateFontString() return CreateFrame("FontString",nil,self) end
local noop=function() end
for _,n in ipairs({"SetFont","SetTextColor","SetJustifyH","SetBackdrop","SetBackdropColor",
 "SetBackdropBorderColor","EnableMouse","SetAutoFocus","SetMaxLetters","SetTextInsets",
 "SetFrameStrata","SetMovable","SetClampedToScreen","RegisterForDrag","RegisterForClicks",
 "SetTexture","SetHighlightTexture","SetFrameLevel","StartMoving","StopMovingOrSizing",
 "ClearAllPoints","SetAllPoints","AddLine","SetMultiLine","SetScrollChild","SetFocus","HighlightText"}) do methods[n]=noop end
function CreateFrame(kind,name,parent,template)
 -- Keep the initial child layer when a parent is raised later. This models
 -- the reported client instead of assuming live inheritance on every getter.
 local level=parent and parent:GetFrameLevel()+1 or 0
 local strata=parent and parent.GetFrameStrata and parent:GetFrameStrata() or "MEDIUM"
 local f=setmetatable({name=name,kind=kind,parent=parent,scripts={},events={},shown=true,level=level,strata=strata}, {__index=methods})
 if name then _G[name]=f end
 table.insert(frames,f); return f
end
UIParent=CreateFrame("Frame","UIParent")
WorldFrame=CreateFrame("Frame","WorldFrame",UIParent)
Minimap=CreateFrame("Frame","Minimap",UIParent)
GameTooltip=CreateFrame("Frame","GameTooltip",UIParent)
PlayerFrame=CreateFrame("Button","PlayerFrame",UIParent)
TargetFrame=CreateFrame("Button","TargetFrame",UIParent)
PartyMemberFrame1=CreateFrame("Button","PartyMemberFrame1",UIParent)

normalActions={}; nativeStarts=0; nativeStops=0
function CameraOrSelectOrMoveStart()
 nativeStarts=nativeStarts+1; cameraLook=true; nativeHover=units.mouseover; units.mouseover=nil
end
function CameraOrSelectOrMoveStop()
 nativeStops=nativeStops+1; cameraLook=false; units.mouseover=nativeHover
 if currentTarget~=nativeHover then
  currentTarget=nativeHover
  if EasyCastEvents then EasyCastEvents:GetScript("OnEvent")(EasyCastEvents,"PLAYER_TARGET_CHANGED") end
 end
end
function TurnOrActionStart() cameraLook=true; nativeHover=units.mouseover; units.mouseover=nil end
function TurnOrActionStop() cameraLook=false; units.mouseover=nativeHover end
function IsMouselooking() return cameraLook end
function RunBinding(action,state)
 table.insert(normalActions,{action=action,state=state})
 if action=="CAMERAORSELECTORMOVE" then
  if state=="up" then CameraOrSelectOrMoveStop() else CameraOrSelectOrMoveStart() end
 elseif action=="TURNORACTION" then
  if state=="up" then TurnOrActionStop() else TurnOrActionStart() end
 end
end

nativeLeftStart=CameraOrSelectOrMoveStart; nativeLeftStop=CameraOrSelectOrMoveStop
nativeRightStart=TurnOrActionStart; nativeRightStop=TurnOrActionStop
originalClicks=0
PartyMemberFrame1:SetScript("OnClick",function() originalClicks=originalClicks+1 end)
''')

lua.execute(r'''
local m=getmetatable(UIParent).__index
function m:SetScale(s) self.scale=s end
function m:GetChildren()
 local children={}
 for _,child in ipairs(frames) do
  if child.parent==self and child.kind~="Texture" and child.kind~="FontString" then table.insert(children,child) end
 end
 return unpack(children)
end
function m:SetFrameLevel(v) self.level=v end
function m:GetFrameLevel() return self.level or (self.parent and self.parent:GetFrameLevel()+1) or 0 end
function m:SetFrameStrata(v) self.strata=v end
function m:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
function m:GetScale() return self.scale or 1 end
function m:HasFocus() return self.focus end
function m:SetFocus()
 for _,f in ipairs(frames) do if f~=self and f.focus then f:ClearFocus() end end
 local old=self.focus; self.focus=true
 if not old and self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end
end
function m:EnableKeyboard(v) self.keyboard=v end
function m:GetVerticalScroll() return self.scroll or 0 end
function m:SetVerticalScroll(v) self.scroll=v end
function m:SetValue(v) self.value=v end
function m:SetMinMaxValues(a,b) self.min=a; self.max=b end
function m:GetTop() return 550 end
function m:GetBottom() return 0 end
function m:GetLeft() return 10 end
function m:GetRight() return 690 end
function m:SetJustifyV() end
function m:SetPlayerBuff(i) self.unit=nil; self.buff=i end
function m:EnableMouseWheel(v) self.wheel=v end
function m:SetVertexColor(...) self.color={...} end
function m:SetTexture(...) self.texture={...} end
function m:SetAlpha(a) self.alpha=a end
function m:SetBackdrop(b) self.backdrop=b end
function m:GetBackdrop() return self.backdrop end
function m:GetBackdropColor() return .06,.06,.09,1 end
function m:GetBackdropBorderColor() return .7,.7,.7,1 end
function m:SetTexCoord() end
function m:ClearLines() self.unit=nil; self.height=100 end
function m:SetNormalTexture() end
function m:SetPushedTexture() end
function m:SetTextColor(...) self.textColor={...} end
function m:SetBackdropColor(...) self.bgColor={...} end
function m:SetFont(path,size) self.fontSize=size end
UIParent:SetWidth(1280); UIParent:SetHeight(900)
GameTooltip:SetWidth(260); GameTooltip:SetHeight(100); GameTooltip:Hide()
GameTooltipTextLeft1=CreateFrame("FontString","GameTooltipTextLeft1",GameTooltip)
function PickupSpell(i,book) cursorKind="spell" end
function PickupMacro(i) cursorKind="macro" end
function PickupContainerItem(b,s) cursorKind="item" end
function ClearCursor() cursorKind=nil end
function CursorHasSpell() return cursorKind=="spell" end
function CursorHasItem() return cursorKind=="item" end
function CursorHasMacro() return cursorKind=="macro" end
macros={{"TestMacro","macro-icon","/cast Heal"}}
function GetMacroInfo(i) if macros[i] then return unpack(macros[i]) end end
function GetContainerNumSlots(b) return b==0 and 1 or 0 end
function GetContainerItemLink(b,s) if b==0 and s==1 then return "item:123:0 [Potion]" end end
function GetContainerItemInfo(b,s) return "potion-icon" end
function UseContainerItem(b,s) table.insert(calls,{item=true,unit=currentTarget}) end
function AssistUnit(u) table.insert(calls,{action="assist",unit=UnitID(u)}) end
function FollowUnit(u) table.insert(calls,{action="follow",unit=UnitID(u)}) end
ChatFrameEditBox=CreateFrame("EditBox","ChatFrameEditBox",UIParent); ChatFrameEditBox:Hide()
function ChatEdit_SendText(edit) table.insert(calls,{macro=edit:GetText(),unit=currentTarget}); if failMacro then error("macro failed") end end
''')
if os.environ.get("EC_TEST_LOCALE"):
    lua.execute("function GetLocale() return " + json.dumps(os.environ["EC_TEST_LOCALE"]) + " end")
if os.environ.get("EC_TEST_LANGUAGE"):
    lua.execute("EasyCastDB={language=" + json.dumps(os.environ["EC_TEST_LANGUAGE"]) + "}")
for name in (ROOT / "EasyCast.toc").read_text().splitlines():
    if name.endswith(".lua"):
        lua.execute((ROOT / name).read_text(), name=name)
lua.execute("EasyCast:Initialize()")
