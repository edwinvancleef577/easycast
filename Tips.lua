local E=EasyCast
local media="Interface\\AddOns\\EasyCast\\Media\\"
local question="Interface\\Icons\\INV_Misc_QuestionMark"
function E:TipEntries(kind,unit,world,preview)
    kind=self:TipFaction(kind)
    if not self.diagnosticActions and not self.diagnosticScanDue then self:RequestDiagnosticActionScan() end
    local out={}; local prefix=preview and (self.tipPreviewModifier or "") or self:Key("")
    for _,button in ipairs(self:InputButtons()) do
        local key=prefix..button[1]; local value=self.db.bindings[kind][key]
        if value then
            local info=self:BindingInfo(value)
            local range=not preview and self:BindingRange(value,info,unit) or nil
            table.insert(out,{button=button[1],label=self:L(button[2]),inputLabel=self:KeyLabel(key),modifierLabel=self:KeyLabel(prefix),name=info and info.name or self:BindingLabel(value),icon=info and info.icon or question,range=range,status=not preview and self:BindingStatus(value,info,unit,range) or nil})
        end
    end
    if preview and table.getn(out)==0 then
        for i,b in ipairs({"LeftButton","RightButton","MiddleButton"}) do
            table.insert(out,{button=b,label=self:KeyLabel(b),name=E:L("Vorschau ")..i,icon=({"Interface\\Icons\\Spell_Holy_Heal","Interface\\Icons\\Spell_Nature_Lightning","Interface\\Icons\\Spell_Nature_HealingWaveGreater"})[i]})
        end
    end
    return out
end
function E:InputGlyph(button)
    local glyph=button=="Button4" and "Button5" or button=="Button5" and "Button4" or button
    return media..(self.worldKeyNames[button] and glyph or "Key")
end
function E:BuildTip(kind)
    local f=self:Box(UIParent,190,100,"EasyCastHint"..kind)
    f:SetFrameStrata("TOOLTIP"); f:SetMovable(true); f:EnableMouse(false)
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    f:RegisterForDrag("LeftButton")
    f.title=self:Text(f,12); f.title:SetPoint("TOPLEFT",f,"TOPLEFT",10,-9); f.title:SetWidth(170); f.title:SetHeight(16)
    f.subtitle=self:Text(f,9); f.subtitle:SetPoint("TOPLEFT",f,"TOPLEFT",10,-29); f.subtitle:SetWidth(170); f.subtitle:SetHeight(14); f.subtitle:SetTextColor(.65,.70,.64)
    f.line=f:CreateTexture(nil,"ARTWORK"); f.line:SetTexture(.46,.38,.23,1); f.line:SetWidth(170); f.line:SetHeight(1); f.line:SetPoint("TOPLEFT",f,"TOPLEFT",10,-47)
    f.rows={}; f.more=self:Text(f,9); f.more:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,8); f.more:SetTextColor(.65,.70,.64)
    f:SetScript("OnDragStart",function()
        if E.previewKind==kind and E.db.tips[kind].mode=="fixed" then f.dragging=true; f:StartMoving() end
    end)
    f:SetScript("OnDragStop",function()
        if not f.dragging then return end
        f:StopMovingOrSizing(); f.dragging=nil
        local x,y=f:GetCenter(); local cx,cy=UIParent:GetCenter(); local s=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
        local t=E.db.tips[kind]; t.x=math.floor(x*s-cx+.5); t.y=math.floor(y*s-cy+.5)
        t.positions.fixed={x=t.x,y=t.y}; E:PositionTip(kind); E:RefreshTipSettings()
    end)
    f:Hide(); return f
end
function E:ApplyTipAppearance(frame,settings)
    local backdrop=self:FrameValue(GameTooltip,"GetBackdrop")
    if type(backdrop)~="table" or not backdrop.bgFile or not backdrop.edgeFile then
        backdrop={bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}}
    end
    frame:SetBackdrop(backdrop)
    local r,g,b,alpha=.09,.09,.16,1
    if GameTooltip and GameTooltip.GetBackdropColor then
        local ok,a,c,d,e=pcall(GameTooltip.GetBackdropColor,GameTooltip)
        if ok and type(a)=="number" and type(c)=="number" and type(d)=="number" then r,g,b,alpha=a,c,d,e or 1 end
    end
    frame:SetBackdropColor(r,g,b,alpha)
    r,g,b,alpha=.7,.7,.7,1
    if GameTooltip and GameTooltip.GetBackdropBorderColor then
        local ok,a,c,d,e=pcall(GameTooltip.GetBackdropBorderColor,GameTooltip)
        if ok and type(a)=="number" and type(c)=="number" and type(d)=="number" then r,g,b,alpha=a,c,d,e or 1 end
    end
    frame:SetBackdropBorderColor(r,g,b,alpha)
    frame:SetAlpha(math.max(.05,math.min(1,(settings.opacity or 85)/100)))
end
function E:UpdateTip(kind,unit,preview,world)
    kind=self:TipContext(kind,world)
    local f=self.tips[kind]; local t=self:TipSettings(kind)
    local entries=self:TipEntries(kind,unit,world,preview)
    if table.getn(entries)==0 then f:Hide(); return end
    local maxWidth=UIParent:GetWidth()*UIParent:GetEffectiveScale()/f:GetEffectiveScale()-56
    local selfCast=not preview and world and self:SelfCastRequested() and self:SameUnit(unit,"player")
    local titleHeight=selfCast and 20 or 0
    local width,height=self:LayoutBindings(f,entries,t,maxWidth,8+titleHeight,8,preview and self.tipPreviewModifier or self:Key(""))
    f:SetWidth(math.max(t.width or 84,width+16,selfCast and 104 or 0)); f:SetHeight(height+16+titleHeight); self:ApplyTipAppearance(f,t)
    if selfCast then
        f.title:ClearAllPoints(); f.title:SetPoint("TOPLEFT",f,"TOPLEFT",8,-8)
        f.title:SetWidth(f:GetWidth()-16); f.title:SetJustifyH("CENTER"); f.title:SetText(E:L("Selbstzauber")); f.title:Show()
    else f.title:Hide() end
    f.subtitle:Hide(); f.line:Hide(); f.more:Hide()
    f:EnableMouse(preview and t.mode=="fixed" or false); self:PositionTip(kind); f:Show()
end
function E:RefreshTips()
    if self.UpdateSettingsPreview then self:UpdateSettingsPreview() end
    if self.miniTest or self.bindingTest or self:BypassRequested() then
        for _,tip in pairs(self.tips) do tip:Hide() end
        self:ClearCastFooter(); return
    end
    if not self.db or not self.tips then return end
    local unit=self:UnitFrameUnderMouse()
    local world,separate
    if not unit and self:IsWorldFocus() and self.db.world.enabled then unit,separate=self:WorldTipUnit(); world=true end
    local faction=self.db.enabled and self:Kind(unit)
    local kind=faction and self:TipContext(faction,world)
    for k,tip in pairs(self.tips) do
        local t=self:TipSettings(k)
        if self.previewKind==k and self.db.enabled and t.enabled then self:UpdateTip(k,nil,true)
        elseif not self.previewKind and kind==k and t.enabled and (t.style~="integrated" or self:HideDefaultTip(k) or (world and separate and self:SelfCastRequested())) then self:UpdateTip(k,unit,false,world)
        else tip:Hide() end
    end
    self:UpdateNativeTooltip()
end
function E:ClearCastFooter()
    local l=self.castFooterLayout
    -- Invalidate before native setters: another addon's size/hide callback
    -- may re-enter tooltip cleanup synchronously.
    self.castFooterLayout=nil
    if self.castFooter then self.castFooter:Hide() end
    if l and math.abs(l.tip:GetHeight()-l.height)<.1 then l.tip:SetHeight(l.base) end
    if l and l.width and math.abs(l.tip:GetWidth()-l.width)<.1 then l.tip:SetWidth(l.baseWidth) end
end
function E:ApplyCastFooter()
    if self.miniTest or self.bindingTest or self:BypassRequested() then self:ClearCastFooter(); return end
    if self.footerUpdating then return end
    self.footerUpdating=true
    local ok,err=pcall(self.UpdateCastFooterLayout,self)
    self.footerUpdating=nil
    if not ok then
        self.castFooterLayout=nil
        if self.castFooter then self.castFooter:Hide() end
        self:TestLog("TOOLTIP-FEHLER",tostring(err))
        if not self.footerErrorShown then self.footerErrorShown=true; self:Print(E:L("Tooltip-Aktualisierung fehlgeschlagen: ")..tostring(err)) end
    end
end
function E:UpdateCastFooterLayout()
    local tip=GameTooltip
    if not self.db or not self.db.enabled or self.previewKind or not tip or not tip:IsShown() then self:ClearCastFooter(); return end
    local unit=self:NativeTooltipUnit(); local kind=self:Kind(unit)
    local scope=self:NativeTooltipScope(tip)
    local world=scope=="world"
    local context=kind and self:TipContext(kind,world); local t=context and self:TipSettings(context)
    if not t or not t.enabled or (scope and self:HideDefaultTip(kind,world)) or t.style~="integrated" then self:ClearCastFooter(); return end
    local _,separate=self:WorldTipUnit()
    if world and separate then self:ClearCastFooter(); return end
    if world and not self.db.world.enabled then self:ClearCastFooter(); return end
    local entries=self:TipEntries(kind,unit,world)
    if table.getn(entries)==0 then self:ClearCastFooter(); return end
    local f=self.castFooter
    if not f or f:GetParent()~=tip then
        f=CreateFrame("Frame",nil,tip); f:EnableMouse(false); f.icons={}; self.castFooter=f
        f.line=f:CreateTexture(nil,"ARTWORK"); f.line:SetTexture(.46,.38,.23,.7); f.line:SetHeight(1); f.line:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    end
    f:SetFrameStrata(tip:GetFrameStrata()); f:SetFrameLevel(tip:GetFrameLevel()+3)
    local old=self.castFooterLayout; local height=tip:GetHeight()
    local base=old and old.tip==tip and math.abs(height-old.height)<.1 and old.base or height
    local currentWidth=tip:GetWidth()
    local baseWidth=old and old.width and math.abs(currentWidth-old.width)<.1 and old.baseWidth or currentWidth
    local size=math.max(8,math.min(48,t.size or 16))
    local maxWidth=math.max(36,UIParent:GetWidth()*UIParent:GetEffectiveScale()/tip:GetEffectiveScale()-40)
    local used,contentHeight=self:LayoutBindings(f,entries,t,maxWidth,7,0,self:Key(""))
    local width=math.min(maxWidth,used); local extra=contentHeight+14
    f:SetAlpha(math.max(.05,math.min(1,(t.opacity or 85)/100)))
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",tip,"TOPLEFT",10,-base+3); f:SetWidth(width); f:SetHeight(extra); f:SetFrameLevel(tip:GetFrameLevel()+3); f.line:SetWidth(width)
    local expandedWidth=math.max(baseWidth,width+20)
    f:SetWidth(expandedWidth-20) -- center modifier caps within the final native tooltip
    if math.abs(tip:GetWidth()-expandedWidth)>.1 then tip:SetWidth(expandedWidth) end
    tip:SetHeight(base+extra)
    self.castFooterLayout={tip=tip,base=base,height=base+extra,baseWidth=baseWidth,width=expandedWidth}; f:Show()
end
function E:InitThreatBridge()
    local threat=EasyThreat
    if not threat or self.threatBridge==threat or type(threat.SafeTooltipUpdate)~="function" then return end
    self.threatBridge=threat
    local update=threat.SafeTooltipUpdate; local clear=threat.ClearThreatTooltip
    threat.SafeTooltipUpdate=function(obj,...)
        E:ClearCastFooter(); local a,b,c=update(obj,unpack(arg)); E:ApplyCastFooter(); return a,b,c
    end
    if clear then threat.ClearThreatTooltip=function(obj,...)
        E:ClearCastFooter(); return clear(obj,unpack(arg))
    end end
end

-- Independent sample frame: never takes ownership of the real GameTooltip.
function E:UpdateSettingsPreview()
    local f=self.settingsPreview
    if not f or not self.window:IsShown() or self.page~="tips" then return end
    local t=self:TipSettings(self.tipKind)
    local entries=self:TipEntries(self.tipKind,nil,false,true)
    local start=GetTime()-math.mod(GetTime(),8)
    for i,entry in ipairs(entries) do
        if i==1 then entry.status={cooldown={start=start,duration=8,remaining=8-math.mod(GetTime(),8)}}
        elseif i==2 then entry.status={invalid=true,reason="RangeUp"}
        elseif i==3 then entry.status={invalid=true,reason="Self"} end
    end
    local integrated=t.style=="integrated" and not self:HideDefaultTip(self.tipKind); local top=integrated and 43 or 8
    local width,height=self:LayoutBindings(f,entries,t,UIParent:GetWidth()-56,top,10,self.tipPreviewModifier)
    width=math.max(integrated and 190 or t.width,width+20); height=height+top+8
    f:SetWidth(width); f:SetHeight(height); self:ApplyTipAppearance(f,t)
    f.threat:SetWidth(width-20)
    if integrated then f.title:Show(); f.threat:Show() else f.title:Hide(); f.threat:Hide() end
    local scale=math.min(1,262/width,134/height); f:SetScale(scale)
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",self.tipPreviewArea,"TOPLEFT",10/scale,-10/scale); f:Show()
    self.tipPreviewNote:SetText((t.enabled and "" or E:L("Bereich ausgeblendet · "))..E:L("Vorschau")..(scale<.99 and E:L(" verkleinert") or E:L(" in Originalgröße")))
end
