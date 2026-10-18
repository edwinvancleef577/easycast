local E=EasyCast
local baseButton=E.Button
function E:Button(parent,width,text,callback)
    local b=baseButton(self,parent,width,text,callback)
    b.fill=b:CreateTexture(nil,"BACKGROUND"); b.fill:SetPoint("CENTER",b,"CENTER",0,0); b.fill:SetWidth(width-2); b.fill:SetHeight(24)
    b.top=b:CreateTexture(nil,"OVERLAY"); b.top:SetTexture("Interface\\Buttons\\WHITE8X8"); b.top:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2); b.top:SetWidth(width-4); b.top:SetHeight(1)
    b.bottom=b:CreateTexture(nil,"OVERLAY"); b.bottom:SetTexture("Interface\\Buttons\\WHITE8X8"); b.bottom:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",2,2); b.bottom:SetWidth(width-4); b.bottom:SetHeight(1)
    -- Same native normal/pushed statusbar surfaces as EasyThreat's buttons.
    b.sheen=b:CreateTexture(nil,"ARTWORK"); b.sheen:SetTexture("Interface\\TargetingFrame\\UI-StatusBar"); b.sheen:SetPoint("CENTER",b,"CENTER",0,0)
    b.downFace=b:CreateTexture(nil,"ARTWORK"); b.downFace:SetTexture("Interface\\TargetingFrame\\UI-StatusBar"); b.downFace:SetPoint("CENTER",b,"CENTER",0,0)
    b:SetNormalTexture(b.sheen); b:SetPushedTexture(b.downFace)
    b:SetHeight(24); b.label:SetFont(E:FontPath(),11)
    if b.label.SetShadowColor then b.label:SetShadowColor(0,0,0,.85); b.label:SetShadowOffset(1,-1) end
    local paint=b.Paint
    b.Paint=function()
        paint(); E:FitButtonLabel(b); local c=b.selected and {.16,.33,.20} or {.24,.21,.15}; local d=b.pressed and .65 or 1
        b.fill:SetTexture(c[1]*d,c[2]*d,c[3]*d,1)
        for _,texture in ipairs({b.fill,b.sheen,b.downFace}) do
            texture:SetWidth(math.max(1,b:GetWidth()-2)); texture:SetHeight(math.max(1,b:GetHeight()-2)); texture:SetAlpha(1)
        end
        b.sheen:SetVertexColor(c[1],c[2],c[3],1); b.downFace:SetVertexColor(c[1]*.65,c[2]*.65,c[3]*.65,1)
        if b.pressed then b.top:SetVertexColor(0,0,0,.65); b.bottom:SetVertexColor(1,.89,.64,.18)
        else b.top:SetVertexColor(1,.89,.64,.27); b.bottom:SetVertexColor(0,0,0,.70) end
    end
    b:SetScript("OnEnter",function() b.hover=true; b.Paint() end)
    b:SetScript("OnLeave",function() b.hover=nil; b.pressed=nil; b.Paint() end)
    b:SetScript("OnMouseDown",function() E:ResetControlHelp(); b.pressed=true; b.Paint() end)
    b:SetScript("OnMouseUp",function() b.pressed=nil; b.Paint() end)
    b:SetScript("OnShow",function() b.hover=nil; b.pressed=nil; b.Paint() end)
    b:SetScript("OnSizeChanged",function() b.Paint() end)
    b:RegisterForClicks("LeftButtonUp"); self:RegisterHelp(b); b.Paint(); return b
end
function E:Place(frame,parent,x,y) frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); return frame end
function E:Heading(parent,text,x,y)
    local f=self:Text(parent,12,text); f:SetTextColor(.9,.76,.43); self:Place(f,parent,x,y); return f
end
function E:ToggleButton(parent,width,title,get,set)
    local b
    b=self:Button(parent,width,"",function() set(not get()); b:Refresh() end)
    function b:Refresh() local on=get(); self.selected=on; self.helpTitle=type(title)=="function" and title() or title; self.label:SetText((type(title)=="function" and title() or title).."   ·   "..(on and E:L("AN") or E:L("AUS"))); self.Paint() end
    b:Refresh(); return b
end
function E:CloseDropdown()
    if self.dropdownLayer then self.dropdownLayer:Hide() end
    self.dropdownOwner=nil
end
function E:OpenDropdown(button)
    if self.dropdownOwner==button then self:CloseDropdown(); return end
    if not self.dropdownLayer then
        local layer=CreateFrame("Button","EasyCastDropdownLayer",UIParent); layer:SetAllPoints(UIParent); layer:SetFrameStrata("FULLSCREEN_DIALOG"); layer:EnableMouse(true)
        layer:SetScript("OnClick",function() E:CloseDropdown() end); self.dropdownLayer=layer
        table.insert(UISpecialFrames,"EasyCastDropdownLayer")
        layer:SetScript("OnHide",function() E.dropdownOwner=nil end)
        self.dropdownMenu=self:Box(layer,180,100); self.dropdownMenu.rows={}; self.dropdownMenu:EnableMouse(true)
    end
    local menu=self.dropdownMenu; local choices=type(button.options)=="function" and button.options() or button.options
    local owner=button; local directTest=false
    while owner do
        if owner==self.clickTestWindow then directTest=true; break end
        owner=owner:GetParent()
    end
    self.dropdownLayer:SetFrameStrata(directTest and "TOOLTIP" or "FULLSCREEN_DIALOG")
    self.dropdownOwner=button; self.dropdownLayer:SetFrameLevel(directTest and 520 or self.window:GetFrameLevel()+20); menu:SetFrameLevel(self.dropdownLayer:GetFrameLevel()+1)
    menu:SetScale(self.window:GetEffectiveScale()/UIParent:GetEffectiveScale()); menu:SetWidth(button:GetWidth()); menu:SetHeight(table.getn(choices)*26+8)
    menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-3)
    if menu.SetClampedToScreen then menu:SetClampedToScreen(true) end
    for i,option in ipairs(choices) do
        local row=menu.rows[i]
        if not row then row=self:Button(menu,button:GetWidth()-8,"",nil); menu.rows[i]=row end
        row.dropdownRow=true; row:SetWidth(button:GetWidth()-8); row.fill:SetWidth(button:GetWidth()-10); row.top:SetWidth(button:GetWidth()-12); row.bottom:SetWidth(button:GetWidth()-12)
        row:ClearAllPoints(); self:Place(row,menu,4,4+(i-1)*26); row.label:SetText(button.rawLabels and option[2] or E:L(option[2])); row.selected=option[1]==button.value(); row.Paint()
        row.helpTitle=option[2]; row.helpText=E:L("Wählt diese Einstellung: ")..option[2]..".\n"..(E:ControlHelpText(button) or ""); E:ResetControlHelp()
        local value=option[1]; local disabled=option.disabled
        row.choiceDisabled=disabled
        if disabled then row.helpText=option.helpText or E:L("Diese Auswahl ist reserviert und kann hier nicht gewählt werden.") end
        row:SetScript("OnClick",function() if disabled then return end; E:CloseDropdown(); button.choose(value); button:Refresh() end); row:Show()
    end
    for i=table.getn(choices)+1,table.getn(menu.rows) do menu.rows[i]:Hide() end
    self:SetFrameTreeLayer(self.dropdownLayer,directTest and "TOOLTIP" or "FULLSCREEN_DIALOG",directTest and 520 or self.window:GetFrameLevel()+20)
    self.dropdownLayer:Show(); menu:Show()
end
function E:Dropdown(parent,width,options,value,choose)
    local b; b=self:Button(parent,width,"",function() E:OpenDropdown(b) end)
    b.options=options; b.value=value; b.choose=choose; b.label:SetWidth(width-34); b.label:SetJustifyH("LEFT"); b.label:ClearAllPoints(); b.label:SetPoint("LEFT",b,"LEFT",10,0)
    b.arrow=b:CreateTexture(nil,"OVERLAY"); b.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up"); b.arrow:SetWidth(20); b.arrow:SetHeight(20); b.arrow:SetPoint("RIGHT",b,"RIGHT",-4,0)
    function b:Refresh()
        local label=tostring(self.value() or ""); local choices=type(self.options)=="function" and self.options() or self.options
        for _,option in ipairs(choices) do if option[1]==self.value() then label=option[2]; break end end
        self.label:SetText(self.rawLabels and label or E:L(label)); E:FitButtonLabel(self)
    end
    b:Refresh(); return b
end
