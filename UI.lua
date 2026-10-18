local E=EasyCast
local white="Interface\\Buttons\\WHITE8X8"
function E:SetFrameTreeLayer(frame,strata,level)
    frame:SetFrameStrata(strata); frame:SetFrameLevel(level)
    -- Older clients may retain the creation-time layer of existing children.
    -- Raising only the backdrop frame can cover its own buttons/edit boxes.
    if frame.GetChildren then
        for _,child in ipairs({frame:GetChildren()}) do
            self:SetFrameTreeLayer(child,strata,level+1)
        end
    end
end
function E:RaiseDiagnostics(frame,probe)
    self:SetFrameTreeLayer(frame,"TOOLTIP",probe and 500 or 600)
end
function E:Text(parent,size,text)
    local f=parent:CreateFontString(nil,"OVERLAY")
    f:SetFont(E:FontPath(),size or 12)
    f:SetTextColor(0.93,0.90,0.80); f:SetJustifyH("LEFT")
    f:SetText(text or ""); return f
end
function E:Box(parent,w,h,name,kind)
    local f=CreateFrame(kind or "Frame",name,parent)
    f:SetWidth(w); f:SetHeight(h)
    f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    f:SetBackdropColor(0.045,0.051,0.046,0.96)
    f:SetBackdropBorderColor(0.46,0.38,0.23,1)
    return f
end
function E:Button(parent,w,text,callback)
    local f=self:Box(parent,w,26,nil,"Button")
    f.label=self:Text(f,12,text); f.label:SetPoint("CENTER",f,"CENTER",0,0)
    local function paint()
        local factor=f.pressed and 0.65 or 1
        local c=f.selected and {0.16,0.33,0.20} or {0.24,0.21,0.15}
        f:SetBackdropColor(c[1]*factor,c[2]*factor,c[3]*factor,1)
        if f.hover then f:SetBackdropBorderColor(0.88,0.72,0.35,1)
        else f:SetBackdropBorderColor(0.46,0.38,0.23,1) end
    end
    f.Paint=paint
    f:SetScript("OnEnter",function() f.hover=true; paint() end)
    f:SetScript("OnLeave",function() f.hover=nil; f.pressed=nil; paint() end)
    f:SetScript("OnMouseDown",function() f.pressed=true; paint() end)
    f:SetScript("OnMouseUp",function() f.pressed=nil; paint() end)
    f:SetScript("OnShow",function() f.pressed=nil; f.hover=nil; paint() end)
    f:SetScript("OnClick",callback); paint(); return f
end
function E:SetEditFocusLost(edit,callback)
    edit:SetScript("OnEditFocusLost",function(...)
        if E.focusedEdit==edit then E.focusedEdit=nil end
        if callback then return callback(unpack(arg)) end
    end)
end
function E:TextInputFocused()
    if self.keyCaptureActive then return true end
    if ChatFrameEditBox and ChatFrameEditBox:IsShown() then return true end
    if type(GetCurrentKeyBoardFocus)=="function" then
        local ok,frame=pcall(GetCurrentKeyBoardFocus)
        if ok and frame and self:FrameValue(frame,"IsVisible")~=false then return true end
    end
    for _,edit in ipairs(self.editBoxes or {}) do
        if edit:IsVisible() then
            local focus=self:FrameValue(edit,"HasFocus")
            if focus or (focus==nil and self.focusedEdit==edit) then return true end
        end
    end
    return false
end
function E:Edit(parent,w,h)
    local f=CreateFrame("EditBox",nil,parent)
    f:SetWidth(w); f:SetHeight(h or 28)
    f:SetFont(E:FontPath(),12)
    f:SetAutoFocus(false); f:SetMaxLetters(160)
    f:SetTextInsets(8,8,2,2)
    f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
    f:SetBackdropColor(0.025,0.03,0.025,1); f:SetBackdropBorderColor(0.40,0.36,0.24,1)
    f:SetScript("OnEscapePressed",function() f:ClearFocus() end)
    self.editBoxes=self.editBoxes or {}; table.insert(self.editBoxes,f)
    self:SetEditFocusLost(f)
    f:SetScript("OnEditFocusGained",function()
        E.focusedEdit=f
        if E.initialized then E:UpdateContextBindings() end
    end)
    return f
end
function E:PositionTip(kind)
    local tip=self.tips[kind]; if tip.dragging then return end
    local x,y=GetCursorPosition(); local scale=UIParent:GetEffectiveScale()
    local anchor,px,py=self:TooltipPoint(kind,x/scale,y/scale)
    tip:ClearAllPoints()
    if anchor=="CENTER" then tip:SetPoint("CENTER",UIParent,"CENTER",px,py)
    else tip:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",px,py) end
end
function E:TogglePreview(kind)
    if not self.db.enabled or not self.db.tips[kind].enabled then
        self.previewKind=nil; self:RefreshTips(); self:RefreshTipSettings(); self:Print(E:L("Für die Vorschau EasyCast und die Belegungshilfe dieser Gruppe einschalten.")); return
    end
    self.previewKind=self.previewKind~=kind and kind or nil
    self:RefreshTips(); self:RefreshTipSettings()
end
function E:InitMinimap()
    if not Minimap then return end
    local b=CreateFrame("Button","EasyCastMinimapButton",Minimap)
    b:SetWidth(32); b:SetHeight(32); b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    local icon=b:CreateTexture(nil,"BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\EasyCast\\Media\\Icon")
    icon:SetWidth(22); icon:SetHeight(22); icon:SetPoint("CENTER",b,"CENTER",0,0)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local border=b:CreateTexture(nil,"OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(54); border:SetHeight(54); border:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:RegisterForDrag("LeftButton")
    local function position()
        local rad=E.db.minimapAngle*math.pi/180
        b:ClearAllPoints(); b:SetPoint("CENTER",Minimap,"CENTER",math.cos(rad)*80,math.sin(rad)*80)
    end
    b:SetScript("OnClick",function() E:ToggleSettings() end)
    b:SetScript("OnDragStart",function()
        b.helpDragging=true; E:ResetControlHelp()
        b:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition(); local cx,cy=Minimap:GetCenter()
            local s=Minimap:GetEffectiveScale(); local dx,dy=x/s-cx,y/s-cy
            local a
            if dx==0 then a=dy>=0 and math.pi/2 or -math.pi/2
            else a=math.atan(dy/dx); if dx<0 then a=a+math.pi end end
            E.db.minimapAngle=a*180/math.pi; position()
        end)
    end)
    b:SetScript("OnDragStop",function() b.helpDragging=nil; b:SetScript("OnUpdate",nil) end)
    self:RegisterHelp(b,"EasyCast",E:L("Klick öffnet oder schließt die Einstellungen. Ziehen verschiebt das Symbol an der Minimap."))
    position(); self.minimap=b
end
