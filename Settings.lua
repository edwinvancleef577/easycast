local E=EasyCast
local kinds={{"friendly","Freundlich"},{"hostile","Feindlich"}}
local types={{"spell","Zauber"},{"macro","Makro"},{"item","Item"},{"action","Aktion"},{"slot","Leiste"}}
local function note(parent,text,x,y,width)
    local f=E:Text(parent,11,text); f:SetTextColor(.65,.70,.64); f:SetWidth(width or 596); f:SetJustifyV("TOP"); E:Place(f,parent,x,y); return f
end
function E:CommitEdits()
    for _,r in ipairs(self.bindingRows or {}) do r.edit:ClearFocus() end
    for _,f in ipairs(self.tipEdits or {}) do f:ClearFocus() end
    for _,f in ipairs(self.worldEdits or {}) do f:ClearFocus() end
end
function E:RefreshSettings()
    if not self.window then return end
    if self.languageDropdown then self.languageDropdown:Refresh(); if self.db.language~=self.localePreference then self.languageApply:Show() else self.languageApply:Hide() end end
    self.mainDropdown:Refresh(); self.pageTitle:SetText(({options=E:L("Optionen"),casts=E:L("Zaubern"),tips=E:L("Tooltips")})[self.page])
    for key,p in pairs(self.pages) do if self.page==key then p:Show() else p:Hide() end end
    self:RefreshOptions(); self:RefreshRows(); self:RefreshTipSettings()
end
function E:ToggleSettings()
    if self.window:IsShown() then self.window:Hide()
    else self:RefreshSettings(); self.window:Show(); self:ReleaseWorldBindings() end
end
function E:RefreshOptions()
    for _,b in ipairs(self.optionToggles) do b:Refresh() end
    self.profileDropdown:Refresh()
    if self.selfModifier then self.selfModifier:Refresh() end
    if self.bypassModifier then self.bypassModifier:Refresh() end
    if self.enemyMode then self.enemyMode:Refresh() end
    if self.leftDragMode then self.leftDragMode:Refresh() end
    if self.clickMillis then self.clickMillis:SetText(tostring(math.floor(self.db.world.maxHold*1000+.5))) end
    if self.dragPixels then self.dragPixels:SetText(tostring(self.db.world.dragPixels)) end
    if self.profileNameFor~=self.db.profile then
        self.profileNameFor=self.db.profile; self.profileName:SetText(self.db.profile)
    end
end
function E:BuildOptions(p)
    self.optionToggles={}
    local function toggle(title,y,get,set,x,width)
        local b=E:ToggleButton(p,width or 596,title,get,set); E:Place(b,p,x or 16,y); table.insert(E.optionToggles,b)
    end
    toggle("EasyCast",14,function() return E.db.enabled end,function(v) E.db.enabled=v; E:RefreshWorldHooks(); E:RefreshWorldBindings(); E:RefreshTips() end,16,282)
    toggle(E:L("Bedienhilfen (500 ms)"),14,function() return E.db.helpTooltips end,function(v) E.db.helpTooltips=v; E:ResetControlHelp() end,330,282)
    toggle(E:L("Weltklicks"),54,function() return E.db.world.enabled end,function(v) E.db.world.enabled=v; E:RefreshWorldHooks(); E:RefreshWorldBindings(); E:RefreshTips() end)
    note(p,E:L("Links/Rechts: Kurzer Klick zaubert; Ziehen steuert die Kamera."),16,96)
    self.worldEdits={}
    local function number(label,x,field,factor,min,max)
        E:Heading(p,label,x,128)
        local edit=E:Place(E:Edit(p,74,26),p,x+151,120); table.insert(E.worldEdits,edit)
        edit:SetScript("OnEnterPressed",function() edit:ClearFocus() end)
        E:SetEditFocusLost(edit,function()
            local n=tonumber(edit:GetText())
            if n then E.db.world[field]=math.max(min,math.min(max,math.floor(n)))/factor end
            edit:SetText(tostring(math.floor(E.db.world[field]*factor+.5)))
            E:RefreshWorldBindings()
        end)
        return edit
    end
    self.clickMillis=number(E:L("Klick kürzer als (ms)"),16,"maxHold",1000,50,1000)
    self.dragPixels=number(E:L("Ziehen ab Weg (px)"),324,"dragPixels",1,1,50)
    note(p,E:L("Mitte, Maus 4/5 und Tastatur: Zauber beim Loslassen, ohne diese Grenzen."),16,158)
    E:Heading(p,E:L("Profile"),16,190)
    self.profileDropdown=E:Place(E:Dropdown(p,274,function()
        local out={}; for name in pairs(E.db.profiles) do table.insert(out,{name,name}) end
        if table.getn(out)==0 then table.insert(out,{E.db.profile,E.db.profile}) end
        table.sort(out,function(a,b) return a[1]<b[1] end); return out
    end,function() return E.db.profile end,function(v) E:CommitEdits(); E:LoadProfile(v) end),p,16,218)
    self.profileDropdown.rawLabels=true; self.profileDropdown:Refresh()
    self.profileName=E:Place(E:Edit(p,194),p,300,218); self.profileName:SetMaxLetters(48)
    self.profileSave=E:Place(E:Button(p,108,E:L("Speichern"),function()
        local name=E:Trim(E.profileName:GetText())
        if E:SaveProfile(name) then
            E.profileName:ClearFocus(); E.profileNameFor=nil; E:RefreshOptions()
            E.profileStatus:SetText(E:L("Profil „")..name..E:L("“ gespeichert.")); E:Print(E:L("Profil „")..name..E:L("“ gespeichert."))
        else E.profileStatus:SetText(E:L("Bitte einen Profilnamen eingeben (max. 48 Zeichen).")) end
    end),p,504,218)
    self.profileName:SetScript("OnEnterPressed",function() E.profileSave:GetScript("OnClick")() end)
    self.profileStatus=note(p,E:L("Änderungen bleiben beim Wechsel und bei /reload erhalten."),16,255)
    E:Heading(p,E:L("Feindlich · Welt"),16,284)
    self.enemyMode=E:Place(E:Dropdown(p,596,{
        {"select",E:L("Erst auswählen, dann zaubern")},{"direct",E:L("Direkt auswählen und zaubern")}
    },function() return E.db.world.enemyMode end,function(value)
        E:CommitEdits(); E:ReleaseWorldBindings(); E.db.world.enemyMode=value; E:RefreshWorldBindings(); E:RefreshRows(); E:RefreshTips()
    end),p,16,306)
    E:Heading(p,E:L("Welt · Selbstzauber"),16,354)
    E:Heading(p,E:L("EasyCast vorübergehend aussetzen"),324,354)
    local function choices(other)
        local list={{"none",E:L("Keine")},{"SHIFT-","Shift"},{"CTRL-",E:L("Strg")},{"ALT-","Alt"}}
        for _,c in ipairs(list) do if c[1]~="none" and c[1]==E.db.world[other] then
            c.disabled=true; c[2]="|cffff7777"..c[2]..E:L(" (bereits reserviert)|r"); c.helpText=E:L("Selbstzauber und Aussetzen benötigen verschiedene Zusatztasten.")
        end end
        return list
    end
    local function setModifier(field,value)
        E:CommitEdits(); E:ReleaseWorldBindings(); E.db.world[field]=value
        E:RefreshWorldBindings(); E:RefreshOptions(); E:RefreshRows(); E:RefreshTips()
    end
    self.selfModifier=E:Place(E:Dropdown(p,288,function() return choices("bypassModifier") end,
        function() return E.db.world.selfModifier end,function(value) setModifier("selfModifier",value) end),p,16,378)
    self.bypassModifier=E:Place(E:Dropdown(p,288,function() return choices("selfModifier") end,
        function() return E.db.world.bypassModifier end,function(value) setModifier("bypassModifier",value) end),p,324,378)
    note(p,E:L("Selbstzauber: freundliche Belegung auf dich.\nAussetzen: Taste halten, dann normal in WoW klicken (auch auf Unitframes)."),16,419)

end
function E:ReservedHostileModifier(value)
    return self:BypassRequested(value) or (self.bindKind=="hostile" and value~="" and value==self.db.world.selfModifier)
end
function E:BindingModifierChoices()
    local mods={}
    for _,v in ipairs(self.modifiers) do
        local reserved=v~="" and v==self.db.world.selfModifier
        local label=v=="" and E:L("Ohne Zusatztaste") or string.gsub(self:KeyLabel(v),"%+$","")
        if self:BypassRequested(v) then label="|cffff7777"..label..E:L(" (Aussetztaste)|r")
        elseif reserved then label="|cffff7777"..label..E:L(" (Selbstzaubertaste)|r") end
        table.insert(mods,{v,label,disabled=self:ReservedHostileModifier(v),helpText=self:BypassRequested(v) and E:L("Mit dieser Taste pausiert EasyCast in der Welt und auf Unitframes. Bestehende Belegungen bleiben gespeichert.") or E:L("Diese Zusatztaste ist in der Welt für Selbstzauber reserviert. Die Belegungen dafür stellst du unter Freundlich ein. Vorhandene feindliche Belegungen bleiben gespeichert.")})
    end
    return mods
end
function E:RefreshRows()
    if not self.bindingScroll then return end
    self.refreshingBindings=true; self:HideSpellSuggestions()
    if self:ReservedHostileModifier(self.bindModifier) then self.bindModifier="" end
    self.kindDropdown:Refresh(); self.modDropdown:Refresh()
    local buttons=self:InputButtons()
    for i,b in ipairs(buttons) do
        local r=self.bindingRows[i]
        if not r then r=self:CreateBindingRow(i); self.bindingRows[i]=r end
        r.button=b[1]; r.key=self.bindModifier..b[1]; r.kind=self.bindKind
        r.label:SetText(E:L(b[2])); local value=self.db.bindings[r.kind][r.key]
        r.actionType=type(value)=="table" and value.type or "spell"
        r.edit:SetText(self:BindingLabel(value)); r.type:Refresh(); r.action:Refresh()
        if r.actionType=="action" then r.edit:Hide(); r.action:Show() else r.edit:Show(); r.action:Hide() end
        local info=value and self:BindingInfo(value); r.icon:SetTexture(info and info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local conflict=self:WorldConflict(r.key,r.button)
        r.status:SetText(conflict and E:L("Auch WoW: ")..conflict..E:L(" · Belegung erlaubt") or (r.button=="LeftButton" and r.kind=="hostile" and (self.db.world.enemyMode=="direct" and E:L("Welt: Gegner direkt auswählen und zaubern") or E:L("Welt: anderer Gegner = auswählen · danach zaubern"))) or (r.button=="RightButton" and value and E:L("Welt: kurz = Zauber · ziehen = Kamera")) or value and E:L("Gespeichert") or E:L("Name eingeben oder Icon hier ablegen"))
        r.status:SetTextColor(conflict and .92 or .62,conflict and .72 or .7,.48)
        r:Show()
    end
    for i=table.getn(buttons)+1,table.getn(self.bindingRows) do self.bindingRows[i]:Hide() end
    local height=math.max(self.bindingViewHeight,table.getn(buttons)*60); self.bindingChild:SetHeight(height)
    self.scrollMax=math.max(0,height-self.bindingViewHeight); self:ScrollBindings(0)
    self:RefreshCopyControls()
    self.refreshingBindings=nil
end
function E:ModifierLabel(value)
    return value=="" and self:L("Ohne Zusatztaste") or string.gsub(self:KeyLabel(value),"%+$","")
end
function E:RefreshCopyControls()
    if not self.copyStatus then return end
    self.copySource:Refresh()
    self.copyStatus:SetText(self:L("Ersetzt die gesamte Belegung: %s · %s. Auch leere Einträge werden übernommen.",self:L(self.bindKind=="friendly" and "Freundlich" or "Feindlich"),self:ModifierLabel(self.bindModifier)))
end
function E:CopyBindingsFrom(source)
    local kind,destination=self.bindKind,self.bindModifier
    if kind~="friendly" and kind~="hostile" then return false end
    local sourceOK,destinationOK=false,false
    for _,v in ipairs(self.modifiers) do
        if v==source then sourceOK=true end
        if v==destination then destinationOK=true end
    end
    if not sourceOK or not destinationOK or self:ReservedHostileModifier(destination) then return false end
    if source==destination then
        self.copyStatus:SetText(self:L("Quelle und Ziel sind gleich; nichts geändert.")); return false
    end
    self:CommitEdits()
    -- Snapshot before replacing. Do not share action tables with the source.
    local bindings=self.db.bindings[kind]; local snapshot={}; local buttons=self:InputButtons()
    for _,button in ipairs(buttons) do snapshot[button[1]]=self:Copy(bindings[source..button[1]]) end
    self:ReleaseWorldBindings()
    for _,button in ipairs(buttons) do bindings[destination..button[1]]=snapshot[button[1]] end
    self:RefreshRows(); self:RefreshWorldBindings(); self:RefreshTips()
    self.copyStatus:SetText(self:L("Belegung kopiert: %s → %s (%s).",self:ModifierLabel(source),self:ModifierLabel(destination),self:L(kind=="friendly" and "Freundlich" or "Feindlich")))
    return true
end
function E:SaveRow(r)
    if r.actionType=="action" then return end
    local value=E:Trim(r.edit:GetText()); local a=value~="" and {type=r.actionType,value=value} or nil
    if self:SetAction(r.kind,r.key,a) then
        local info=a and self:BindingInfo(a); r.icon:SetTexture(info and info.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); r.status:SetText(E:L("Gespeichert")); r.status:SetTextColor(.56,.88,.63)
    else r.status:SetText(r.actionType=="macro" and E:L("Makroname nicht gefunden · bisherige Belegung bleibt") or r.actionType=="slot" and E:L("Aktionsplatz 1 bis 120 eingeben · bisherige Belegung bleibt") or E:L("Spruch nicht gelernt · bisherige Belegung bleibt")); r.status:SetTextColor(1,.5,.38) end
end
function E:ScrollBindings(delta)
    self:HideSpellSuggestions()
    local value=math.max(0,math.min(self.scrollMax or 0,(self.bindingScroll:GetVerticalScroll() or 0)-delta*45))
    self.bindingScroll:SetVerticalScroll(value)
    local bar=getglobal("EasyCastBindingScrollScrollBar")
    if bar then bar:SetMinMaxValues(0,self.scrollMax or 0); bar:SetValue(value) end
end
function E:CreateBindingRow(i)
    local r=self:Box(self.bindingChild,588,54); r.kind=self.bindKind; r.key=self.bindModifier..self:InputButtons()[i][1]; r.actionType="spell"; self:Place(r,self.bindingChild,0,(i-1)*60)
    r.label=self:Text(r,11); self:Place(r.label,r,10,12); r.label:SetWidth(106); r.label:SetHeight(22)
    r.type=self:Place(self:Dropdown(r,88,types,function() return r.actionType end,function(v)
        r.edit:ClearFocus(); r.actionType=v; r.edit:SetText("")
        if v=="action" then r.edit:Hide(); r.action:Show() else r.edit:Show(); r.action:Hide() end
        r.status:SetText(E:L("Neue Belegung wählen oder Namen eingeben"))
    end),r,118,6)
    r.drop=CreateFrame("Button",nil,r); self:RegisterHelp(r.drop,E:L("Belegung ablegen"),E:L("Ziehe einen Zauber, ein Item oder ein Makro aus seinem Fenster hierher. Alternativ den Namen rechts eingeben.")); r.drop:SetWidth(30); r.drop:SetHeight(30); self:Place(r.drop,r,216,4)
    r.icon=r.drop:CreateTexture(nil,"ARTWORK"); r.icon:SetAllPoints(r.drop)
    r.edit=self:Place(self:Edit(r,288,28),r,256,5)
    r.action=self:Place(self:Dropdown(r,288,self.actionChoices,function()
        local v=E.db.bindings[r.kind][r.key]; return type(v)=="table" and v.type=="action" and v.value or "target"
    end,function(v) E:SetAction(r.kind,r.key,{type="action",value=v}); E:RefreshRows() end),r,256,5)
    r.type.helpText=E:L("Wählt die Art dieser Belegung: gelernter Zauber, vorhandenes Makro, Item, Zielaktion oder Aktionsleistenplatz (1 bis 120). Danach den passenden Namen beziehungsweise die Platznummer eingeben.")
    r.action.helpText=E:L("Wählt eine Zielaktion: auswählen, das Ziel unterstützen, ihm folgen oder die aktuelle Auswahl aufheben.")
    r.edit:SetScript("OnEnterPressed",function() r.edit:ClearFocus() end)
    E:SetEditFocusLost(r.edit,function() E:SaveRow(r) end)
    E:AttachSpellSuggestions(r)
    local function receive()
        local payload=E:CursorBinding()
        if payload and E:SetAction(r.kind,r.key,payload) then
            r.edit:SetText(E:BindingLabel(payload)); r.actionType=payload.type
            if ClearCursor then ClearCursor() end; E:RefreshRows()
        else r.status:SetText(E:L("Kein unterstütztes Icon · Namen direkt eingeben")) end
    end
    r.drop:SetScript("OnReceiveDrag",receive); r.drop:SetScript("OnClick",receive); r.edit:SetScript("OnReceiveDrag",receive)
    self:Place(self:Button(r,28,"×",function() r.edit:SetText(""); E:SetAction(r.kind,r.key,nil); E:RefreshRows() end),r,552,6)
    r.status=self:Text(r,9); self:Place(r.status,r,118,37); r.status:SetWidth(458); r.status:SetHeight(12)
    for _,f in ipairs({r,r.edit,r.drop,r.type,r.action}) do f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function(a,b) E:ScrollBindings(b or (type(a)=="number" and a) or arg1 or 0) end) end
    return r
end
function E:BuildCasts(p)
    self.bindingRows={}; self.bindKind="friendly"; self.bindModifier=""; self.bindingViewHeight=218
    self.kindDropdown=self:Place(self:Dropdown(p,288,kinds,function() return E.bindKind end,function(v) E:CommitEdits(); E.bindKind=v; E:RefreshRows() end),p,16,14)
    self.modDropdown=self:Place(self:Dropdown(p,288,function() return E:BindingModifierChoices() end,function() return E.bindModifier end,function(v)
        if E:ReservedHostileModifier(v) then return end
        E:CommitEdits(); E.bindModifier=v; E:RefreshRows()
    end),p,324,14)
    note(p,E:L("Name eingeben oder Icon aus Zauberbuch, Makrofenster oder Tasche ablegen."),16,56)
    local scroll=CreateFrame("ScrollFrame","EasyCastBindingScroll",p,"UIPanelScrollFrameTemplate"); self.bindingScroll=scroll
    self:RegisterScrollHelp("EasyCastBindingScroll")
    scroll:SetWidth(590); scroll:SetHeight(self.bindingViewHeight); self:Place(scroll,p,16,84)
    local child=CreateFrame("Frame",nil,scroll); child:SetWidth(590); child:SetHeight(420); scroll:SetScrollChild(child); self.bindingChild=child
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(a,b) E:ScrollBindings(b or (type(a)=="number" and a) or arg1 or 0) end)
    local key=self:Place(self:Edit(p,80),p,16,318); self.keyName=key; key:SetMaxLetters(16)
    self.keyAdd=self:Place(self:Button(p,136,E:L("Taste hinzufügen"),function() E:AddKeyFromSettings(key:GetText()) end),p,106,318)
    self.keyCaptureButton=self:Place(self:Button(p,118,E:L("Taste erfassen"),function() E:StartKeyCapture() end),p,252,318)
    key:SetScript("OnEnterPressed",function() E:AddKeyFromSettings(key:GetText()) end)
    key:SetScript("OnKeyDown",function(a,b)
        local k=b or (type(a)=="string" and a) or arg1
        if k and string.find(k,"^F%d+$") then key:SetText(k) end
    end)
    note(p,E:L("Taste eintippen oder erfassen.\nZusatztasten oben auswählen."),384,317,228)
    self.copySourceModifier=""
    self.copyBindings=E:Place(E:Button(p,174,E:L("Kopieren von"),function() E:CopyBindingsFrom(E.copySourceModifier) end),p,16,374)
    self.copySource=E:Place(E:Dropdown(p,412,function()
        local out={}; for _,v in ipairs(E.modifiers) do table.insert(out,{v,E:ModifierLabel(v)}) end; return out
    end,function() return E.copySourceModifier end,function(v)
        E.copySourceModifier=v; E:RefreshCopyControls()
    end),p,200,374)
    self.copyStatus=note(p,"",16,414)
    self:RefreshCopyControls()

end
function E:AddKeyFromSettings(key)
    self:CommitEdits()
    local added,reason,existing=self:AddKey(key)
    if not added and reason~="existing" then self:Print(reason); return false end
    key=existing or self:NormalizeKey(key)
    self.keyName:ClearFocus(); self.keyName:SetText(""); self:RefreshRows()
    for i,r in ipairs(self.bindingRows) do
        if r.button==key then
            local top=(i-1)*60; local scroll=self.bindingScroll:GetVerticalScroll() or 0
            if top<scroll then scroll=top elseif top+54>scroll+self.bindingViewHeight then scroll=top+54-self.bindingViewHeight end
            self.bindingScroll:SetVerticalScroll(scroll); self:ScrollBindings(0)
            if r.actionType~="action" then r.edit:SetFocus() end
            self:Print(key..(added and E:L(" hinzugefügt") or E:L(" ist bereits vorhanden"))..E:L(" · jetzt die gewünschte Belegung eintragen."))
            break
        end
    end
    self:RefreshWorldBindings(); return true
end
function E:StopKeyCapture()
    self.keyCaptureActive=nil; self.capturedKey=nil
    if self.keyCapture then self.keyCapture:EnableKeyboard(false); self.keyCapture:Hide() end
end
function E:StartKeyCapture()
    self:CommitEdits(); self:CloseDropdown()
    for _,edit in ipairs(self.editBoxes or {}) do edit:ClearFocus() end
    if not self.keyCapture then
        local f=self:Box(self.window,420,144,"EasyCastKeyCapture"); self.keyCapture=f
        f:SetPoint("CENTER",self.window,"CENTER",0,0); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(self.window:GetFrameLevel()+40); f:EnableMouse(true)
        self:Heading(f,E:L("Taste erfassen"),16,14)
        f.message=note(f,"",16,43,388)
        self:Place(self:Button(f,160,E:L("Abbrechen"),function() E:StopKeyCapture() end),f,130,106)
        f:SetScript("OnKeyDown",function(a,b)
            local key=b or (type(a)=="string" and a) or arg1
            if not E.keyCaptureActive or not key then return end
            if key=="ESCAPE" then E:StopKeyCapture(); return end
            if E.capturedKey or key=="LSHIFT" or key=="RSHIFT" or key=="LCTRL" or key=="RCTRL" or key=="LALT" or key=="RALT" then return end
            local valid=E:NormalizeKey(key)
            if valid then E.capturedKey=valid; f.message:SetText(valid..E:L(" erkannt · Taste loslassen zum Übernehmen."))
            else f.message:SetText(E:L("Diese Taste wird nicht unterstützt.\nAndere Taste drücken oder Esc zum Abbrechen.")) end
        end)
        f:SetScript("OnKeyUp",function(a,b)
            local key=b or (type(a)=="string" and a) or arg1
            if E.keyCaptureActive and key==E.capturedKey then E:StopKeyCapture(); E:AddKeyFromSettings(key) end
        end)
        f:SetScript("OnHide",function() E.keyCaptureActive=nil; E.capturedKey=nil; f:EnableKeyboard(false) end)
    end
    self.keyCaptureActive=true; self.capturedKey=nil; self:ReleaseWorldBindings()
    self.keyCapture.message:SetText(E:L("Taste drücken und loslassen, z. B. F6 oder F.\nZusatztasten gelten wie oben gewählt. Esc bricht ab."))
    self.keyCapture:EnableKeyboard(true); self.keyCapture:Show()
end
local function visible(widget,on)
    if not widget then return end
    if on then widget:Show() else widget:Hide() end
    if widget.caption then visible(widget.caption,on) end
end
function E:RefreshTipSettings()
    if not self.tipControls then return end
    local t=self.db.tips[self.tipKind]; local a=self.db.tipAppearance
    for _,c in ipairs(self.tipControls) do c:Refresh() end
    for field,edit in pairs(self.tipNumbers) do edit:SetText(tostring((field=="x" or field=="y") and t[field] or a[field])) end
    local separate=a.style=="separate" or self:HideDefaultTip(self.tipKind)
    visible(self.tipWidth,separate); visible(self.tipNative,true)
    visible(self.tipIconGap,a.labelMode~="off")
    for _,c in ipairs(self.tipPositionControls) do visible(c,separate and t.enabled) end
    self.previewButton.selected=self.previewKind==self.tipKind; self.previewButton.Paint()
    self:UpdateSettingsPreview()
end
function E:BuildTooltipSettings(p)
    self.tipKind="friendly"; self.tipControls={}; self.tipEdits={}; self.tipNumbers={}; self.tipPositionControls={}; self.tipPreviewModifier=""
    local function add(c,x,y) E:Place(c,p,x,y); table.insert(E.tipControls,c); return c end
    local function appearance() return E.db.tipAppearance end
    local function setting() return E.db.tips[E.tipKind] end
    local function refresh()
        E:ClearCastFooter(); E:RefreshTipSettings(); E:RefreshTips()
    end
    self.tipStyle=add(self:Dropdown(p,282,{{"separate",E:L("Eigenes Tooltip")},{"integrated",E:L("Im WoW-Tooltip")}},function() return appearance().style end,function(v)
        E:CommitEdits(); appearance().style=v; E.previewKind=nil
        if v=="integrated" then appearance().columns=math.max(2,appearance().columns) end
        refresh()
    end),16,14)
    self.tipLayout=add(self:Dropdown(p,282,{{"horizontal",E:L("Horizontal · links nach rechts")},{"vertical",E:L("Vertikal · oben nach unten")}},function() return appearance().layout end,function(v) appearance().layout=v; refresh() end),330,14)
    self.tipLabels=add(self:Dropdown(p,282,{{"off",E:L("Beschriftung: Aus")},{"text",E:L("Beschriftung: Text darüber")},{"icon",E:L("Beschriftung: Eingabesymbol links")}},function() return appearance().labelMode end,function(v) appearance().labelMode=v; refresh() end),16,48)
    self.tipColumns=add(self:Dropdown(p,282,function()
        local out={}
        if appearance().layout=="horizontal" then
            for _,i in ipairs({1,2,3,4,5,6,7,8,9,10,12,16,27}) do table.insert(out,{i,E:L("Max. ")..i..E:L(" Einträge pro Zeile")}) end
        else
            for i=appearance().style=="integrated" and 2 or 1,3 do table.insert(out,{i,E:L(i==1 and "%d Spalte" or "%d Spalten",i)}) end
        end
        return out
    end,function() return appearance().layout=="horizontal" and appearance().perRow or appearance().columns end,function(v)
        if appearance().layout=="horizontal" then appearance().perRow=v else appearance().columns=v end
        refresh()
    end),330,48)
    local function numeric(label,field,x,y,min,max,labelWidth,width)
        local heading=E:Heading(p,label,x,y+7)
        local edit=E:Place(E:Edit(p,width or 54),p,x+labelWidth,y); edit.caption=heading
        table.insert(E.tipEdits,edit); E.tipNumbers[field]=edit
        edit:SetScript("OnEnterPressed",function() edit:ClearFocus() end)
        E:SetEditFocusLost(edit,function()
            local t=(field=="x" or field=="y") and setting() or appearance()
            local n=tonumber(edit:GetText()); if n then t[field]=math.max(min,math.min(max,math.floor(n))) end
            edit:SetText(tostring(t[field])); refresh()
        end)
        E:RegisterHelp(edit,label,E:L("Wert eingeben und mit Enter oder durch Verlassen des Feldes übernehmen."))
        return edit
    end
    self.tipSize=numeric(E:L("Icon"), "size",16,87,8,48,54,48)
    self.tipGap=numeric(E:L("Abstand"), "gap",126,87,0,16,83,48)
    self.tipIconGap=numeric(E:L("Abstand zum Icon"), "iconGap",264,87,0,32,133,56)
    self.tipOpacity=numeric(E:L("Deckkraft %"), "opacity",16,121,5,100,97,48)
    self.tipWidth=numeric(E:L("Min. Breite"), "width",330,121,36,500,90,73)
    self.tipContext=add(self:Dropdown(p,596,{{"friendly",E:L("Freundlich · Einheitenrahmen")},{"hostile",E:L("Feindlich · Einheitenrahmen")},{"friendlyWorld",E:L("Freundlich · Welt")},{"hostileWorld",E:L("Feindlich · Welt")}},function() return E.tipKind end,function(v)
        E:CommitEdits(); E.tipKind=v; E.previewKind=nil; refresh()
    end),16,157)
    self.tipEnabled=add(self:ToggleButton(p,282,E:L("Belegungshilfe"),function() return setting().enabled end,function(v) setting().enabled=v; E.previewKind=nil; refresh() end),16,198)
    self.tipNative=add(self:ToggleButton(p,282,E:L("WoW-Einheitentooltip"),function() return not E:HideDefaultTip(E.tipKind) end,function(v)
        if E.tipKind=="friendlyWorld" or E.tipKind=="hostileWorld" then setting().hideWorld=not v else setting().hideFrames=not v end
        refresh()
    end),16,232)
    local function position(c) table.insert(E.tipPositionControls,c); return c end
    self.tipMode=position(add(self:Dropdown(p,282,{{"cursor",E:L("Position: an der Maus")},{"fixed",E:L("Position: fest am Bildschirm")}},function() return setting().mode end,function(v) E:CommitEdits(); E:SetTipMode(E.tipKind,v); refresh() end),16,266))
    self.tipX=position(numeric("X", "x",16,300,-4000,4000,26,84))
    self.tipY=position(numeric("Y", "y",174,300,-4000,4000,26,98))
    self.previewButton=position(self:Place(self:Button(p,174,E:L("Position zeigen / ziehen"),function() E:CommitEdits(); E:TogglePreview(E.tipKind) end),p,16,339))
    position(self:Place(self:Button(p,98,E:L("Zurücksetzen"),function()
        local t=setting(); local friendly=E:TipFaction(E.tipKind)=="friendly"
        t.x=t.mode=="fixed" and (friendly and -320 or 320) or 24
        t.y=t.mode=="fixed" and 0 or (friendly and -22 or -110)
        t.positions[t.mode]={x=t.x,y=t.y}; refresh()
    end),p,200,339))
    local mods={}; for _,v in ipairs(self.modifiers) do table.insert(mods,{v,v=="" and E:L("Vorschau: ohne Zusatztaste") or E:L("Vorschau: ")..string.gsub(self:KeyLabel(v),"%+$","")}) end
    self.tipPreviewChoice=add(self:Dropdown(p,282,mods,function() return E.tipPreviewModifier end,function(v) E.tipPreviewModifier=v; refresh() end),330,198)
    self.tipPreviewArea=self:Place(self:Box(p,282,154),p,330,232)
    self.tipPreviewArea:EnableMouse(false)
    self.settingsPreview=self:Box(self.tipPreviewArea,100,100); self.settingsPreview:EnableMouse(false)
    self.settingsPreview.title=self:Text(self.settingsPreview,11,E:L("Beispiel-Einheit"))
    self.settingsPreview.title:SetPoint("TOPLEFT",self.settingsPreview,"TOPLEFT",10,-8)
    self.settingsPreview.threat=self.settingsPreview:CreateTexture(nil,"ARTWORK")
    self.settingsPreview.threat:SetTexture(.65,.42,.1,1)
    self.settingsPreview.threat:SetPoint("TOPLEFT",self.settingsPreview,"TOPLEFT",10,-26); self.settingsPreview.threat:SetHeight(6)
    self.tipPreviewNote=note(p,"",330,393,282)
    note(p,E:L("Grau + Symbol: nicht passend. Kopf = nur selbst; Pfeil hoch = zu weit.\nVorschau: Reichweite und Cooldown sind simuliert."),16,416)
end
function E:RefreshDiagnosticIndicator()
    if self.diagnosticToggle then self.diagnosticToggle:Refresh() end
    if not self.recordingIndicator then return end
    visible(self.recordingIndicator,self.db.diagnostics)
end
function E:ShowDiagnosticsPanel()
    local f=self.diagnosticsPanel
    if not f then
        f=self:Box(UIParent,440,282,"EasyCastDiagnostics"); self.diagnosticsPanel=f
        f:SetPoint("CENTER",self.window,"CENTER",0,0); f:EnableMouse(true)
        E:Heading(f,E:L("Diagnose"),16,14)
        local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetWidth(28); close:SetHeight(28)
        close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-3,-3); close:SetScript("OnClick",function() f:Hide() end); self:RegisterHelp(close,E:L("Schließen"))
        self.diagnosticToggle=self:Place(self:ToggleButton(f,408,E:L("Begleitdiagnose"),function() return E.db.diagnostics end,function(v) E:SetDiagnostics(v) end),f,16,48)
        local choices={
            {E:L("Bericht öffnen"),function() E:ShowTestReport() end}, {E:L("Mausanzeige"),function() E:ToggleProbe() end},
            {E:L("Live prüfen"),function() E:SetDiagnostics(true); if not E.probe or not E.probe:IsShown() then E:ToggleProbe() end; E.probePaused=nil; E:UpdateProbe() end},
            {E:L("Tastenbindung testen"),function() E:ShowBindingTest() end},
            {E:L("Blessing: A / B"),function() E:ShowClickTest("might") end}, {E:L("Mini-Klickfläche"),function() E:ShowMiniTest() end},
            {"Laufen testen",function() E:ShowRunTest() end}, {"F-Tasten prüfen",function() E:ShowFunctionKeyReport() end}
        }
        for i,c in ipairs(choices) do
            local callback=c[2]
            self:Place(self:Button(f,196,c[1],function() f:Hide(); callback() end),f,16+math.mod(i-1,2)*212,86+math.floor((i-1)/2)*36)
        end
        note(f,E:L("Aufnahme läuft auch bei geschlossenem Fenster weiter.\nOben am Bildschirm kannst du sie jederzeit stoppen."),16,238,408)
        table.insert(UISpecialFrames,"EasyCastDiagnostics")
    end
    self:RaiseDiagnostics(f); self.diagnosticToggle:Refresh(); f:Show()
end
function E:InitSettings()
    local f=CreateFrame("Frame","EasyCastSettings",UIParent); self.window=f; f:SetWidth(680); f:SetHeight(590); f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true)
    f:SetScale(math.min(1,UIParent:GetHeight()/650,UIParent:GetWidth()/720))
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
    f:SetPoint("CENTER",UIParent,"CENTER",self.db.window.x,self.db.window.y); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() f:StartMoving() end); f:SetScript("OnDragStop",function() f:StopMovingOrSizing(); local x,y=f:GetCenter(); local cx,cy=UIParent:GetCenter(); local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale(); E.db.window.x=x*scale-cx; E.db.window.y=y*scale-cy end)
    f:SetScript("OnHide",function() E:StopKeyCapture(); E:CommitEdits(); E:SaveProfile(E.db.profile); E:CloseDropdown(); E.previewKind=nil; E:RefreshTips() end)
    table.insert(UISpecialFrames,"EasyCastSettings")
    local header=f:CreateTexture(nil,"ARTWORK"); header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header"); header:SetWidth(256); header:SetHeight(64); header:SetPoint("TOP",f,"TOP",0,12)
    local title=self:Text(f,16,"EasyCast"); title:SetPoint("CENTER",header,"CENTER",0,12); title:SetTextColor(.9,.76,.43)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); self:RegisterHelp(close,E:L("Schließen"),E:L("Schließt die Einstellungen und speichert das aktive Profil.")); close:SetWidth(32); close:SetHeight(32); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-5,-5); close:SetScript("OnClick",function() f:Hide() end)
    self.page="options"; self.pageTitle=self:Heading(f,E:L("Optionen"),28,58)
    self.mainDropdown=self:Place(self:Dropdown(f,224,{{"options",E:L("Optionen")},{"casts",E:L("Zaubern")},{"tips","Tooltips"}},function() return E.page end,function(v) E:StopKeyCapture(); E:CommitEdits(); E.previewKind=nil; E.page=v; E:RefreshSettings(); E:RefreshTips() end),f,426,49)
    self.pageTitle:Hide()
    self.languageDropdown=self:Place(self:Dropdown(f,188,self.languageOptions,function() return E.db.language end,function(value) E.db.language=value; E:RefreshSettings() end),f,28,49)
    self.languageApply=self:Place(self:Button(f,184,self:L("Anwenden / Reload"),function() E:ApplyLanguage() end),f,228,49)
    self.languageDropdown.helpTitle=self:L("Sprache")
    self.languageDropdown.helpText=self:L("Wählt die Sprache der EasyCast-Oberfläche. Automatisch folgt dem Client in einer der acht unterstützten Sprachen, sonst Englisch. Zauber- und Makronamen bleiben in der Sprache deines Clients. Anwenden lädt die Oberfläche neu; Diagnoseberichte bleiben vorerst Deutsch.")
    self.languageApply.helpText=self:L("Speichert die Einstellungen und lädt die Oberfläche neu, um die Sprache anzuwenden. Außerhalb des Kampfes verwenden.")
    self.pages={}
    for _,key in ipairs({"options","casts","tips"}) do self.pages[key]=self:Place(self:Box(f,628,455),f,26,90) end
    self:BuildOptions(self.pages.options); self:BuildCasts(self.pages.casts); self:BuildTooltipSettings(self.pages.tips)
    note(f,self.version..E:L("  ·  /ec  ·  Enter oder Feld verlassen speichert"),29,558,480)
    self:Place(self:Button(f,112,E:L("Diagnose …"),function() E:ShowDiagnosticsPanel() end),f,530,551)
    self.recordingIndicator=self:Button(UIParent,166,E:L("Aufnahme · Stop"),function() E:SetDiagnostics(false) end)
    self.recordingIndicator:SetPoint("TOP",UIParent,"TOP",0,-12); self.recordingIndicator:SetFrameStrata("HIGH")
    self.recordingIndicator.helpText=E:L("Die Diagnose zeichnet auf. Klick beendet die Aufnahme und bewahrt den Bericht auf.")
    self:RefreshDiagnosticIndicator()
    self:AttachSettingsHelp(); self:RefreshSettings(); f:Hide()
end
