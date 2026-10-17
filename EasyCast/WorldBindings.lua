local E=EasyCast
E.worldActions={LeftButton="EASYCASTWORLD1",RightButton="EASYCASTWORLD2",MiddleButton="EASYCASTWORLD3",Button4="EASYCASTWORLD4",Button5="EASYCASTWORLD5"}
E.worldKeyNames={LeftButton="BUTTON1",RightButton="BUTTON2",MiddleButton="BUTTON3",Button4="BUTTON4",Button5="BUTTON5",MOUSEWHEELUP="MOUSEWHEELUP",MOUSEWHEELDOWN="MOUSEWHEELDOWN"}
E.contextBindings={}; E.contextIndex={}; E.managedBindings={}
function E:WorldActionKey(key,button)
    return string.sub(key,1,string.len(key)-string.len(button))..(self.worldKeyNames[button] or button)
end
function E:BindingOwnsMouse(button)
    if button~="LeftButton" and button~="RightButton" and button~="MiddleButton" and button~="Button4" and button~="Button5" then return false end
    if self.primaryPresses and self.primaryPresses[button] then return true end
    local pending=self.worldPending and self.worldPending[button]
    if pending and pending.source=="Tastenbindung" then return true end
    local actual=self:WorldActionKey(self:Key(button),button)
    local entry=self.contextBindings[actual]
    return entry and (entry.pressed or (GetBindingAction and GetBindingAction(actual)==entry.action)) and true or false
end
function E:AssignWorldKey(key,action)
    self:APIStart("SetBinding",key.." = "..tostring(action)); local ok=SetBinding(key,action); self:APIEnd(); return ok
end
function E:ReleaseWorldBindings()
    self:CancelNativeRun("Belegungen freigegeben")
    if self.CancelPrimaryPresses then self:CancelPrimaryPresses("Belegungen freigegeben") end
    if not SetBinding or not GetBindingAction then return end
    self.updatingWorldBindings=true
    for key,entry in pairs(self.contextBindings) do
        if GetBindingAction(key)==entry.action then self:AssignWorldKey(key,entry.original~="" and entry.original or nil) end
        if self.db.bindingRecovery then self.db.bindingRecovery[key]=nil end
    end
    self.contextBindings={}; self.contextIndex={}; self.updatingWorldBindings=nil
    self:CancelWorldClicks("Kontextbelegung freigegeben")
end
function E:RecoverBindings()
    if not SetBinding or not GetBindingAction then return end
    self.updatingWorldBindings=true
    for key,entry in pairs(self.db.bindingRecovery or {}) do
        if GetBindingAction(key)==entry.action then self:AssignWorldKey(key,entry.original~="" and entry.original or nil) end
    end
    self.db.bindingRecovery={}
    for button,action in pairs(self.worldActions) do for _,prefix in ipairs(self.modifiers) do
        local key=self:WorldActionKey(prefix..button,button)
        if GetBindingAction(key)==action then
            local old=(self.db.world.originalBindings or {})[key] or ""
            if old=="" and prefix=="" then
                if button=="LeftButton" then old="CAMERAORSELECTORMOVE" elseif button=="RightButton" then old="TURNORACTION" end
            end
            self:AssignWorldKey(key,old~="" and old or nil)
        end
    end end
    self.updatingWorldBindings=nil
end
function E:ImportLegacyContextKeys()
    -- 0.7.0-0.7.2 exposed these internal dispatch slots in WoW's binding menu.
    -- They identify no spell or permanent key, so import only the physical key.
    if not GetBindingKey or not GetBindingAction or not SetBinding then return end
    local found={}
    for i=1,216 do
        local action="EASYCASTCONTEXT"..i
        local a,b=GetBindingKey(action)
        if a then found[a]=action end; if b then found[b]=action end
    end
    local count=0; self.updatingWorldBindings=true
    self.db.legacyContextBindings=self.db.legacyContextBindings or {}
    for key,action in pairs(found) do
        if GetBindingAction(key)==action and not self.contextBindings[key] then
            self.db.legacyContextBindings[key]=action
            local base=string.upper(key)
            while string.find(base,"^ALT%-") or string.find(base,"^CTRL%-") or string.find(base,"^SHIFT%-") do base=string.gsub(base,"^[A-Z]+%-","") end
            self:AddKey(base)
            -- No previous user binding is knowable for a manual assignment.
            -- Preserve essential native camera inputs; clear other orphan slots
            -- for this session only. Never save the entire WoW binding table.
            local fallback=({BUTTON1="CAMERAORSELECTORMOVE",BUTTON2="TURNORACTION",MOUSEWHEELUP="CAMERAZOOMIN",MOUSEWHEELDOWN="CAMERAZOOMOUT"})[key]
            self:AssignWorldKey(key,fallback); count=count+1
        end
    end
    self.updatingWorldBindings=nil
    if count>0 then
        self:RefreshRows()
        self:Print("Alte Kontextbelegungen gefunden: unterstützte Tasten stehen unter Zaubern. Dort Sprüche zuweisen; frühere WoW-Belegungen bei Bedarf im WoW-Menü neu setzen.")
    end
end
function E:RefreshWorldBindings()
    if not self.db or self.updatingWorldBindings then return end
    self:ReleaseWorldBindings()
    if self.initialized then self:UpdateContextBindings() end
end
function E:InputContext(prefix,button)
    if self:BypassRequested() or self:BypassRequested(prefix) then return end
    if self.miniTest or self.bindingTest or self.runTest then return end
    if self.mouseTest then return end
    if self:BlessingTestVisible() then return end
    if self.keyCaptureActive then return end
    if not self.db.enabled or self.worldBlocked or self.traceRunning or self.traceCastingPaused or self.previewKind then return end
    if ChatFrameEditBox and ChatFrameEditBox:IsShown() then return end
    local focus=GetMouseFocus and GetMouseFocus()
    if focus and self:FrameValue(focus,"GetObjectType")=="EditBox" then return end
    local h=self.hovered
    if h and h.frame:IsVisible() then
        local f=focus; local depth=0
        while f and depth<8 do
            if f==h.frame then return h.unit,"frame",self:Kind(h.unit) end
            f=self:FrameValue(f,"GetParent"); depth=depth+1
        end
    end
    local unit,mode,reason,kind=self:ResolveWorldTarget(button,false,prefix)
    if unit then return unit,"world",kind end
end
function E:UpdateContextBindings()
    if self.runTest then return end
    if not self.db or not SetBinding or not GetBindingAction or self.updatingWorldBindings then return end
    if self:BypassRequested() then self:ReleaseWorldBindings(); return end
    local unit,context,kind=self:InputContext(); local desired={}; local index=0
    local typing=self:TextInputFocused()
    for _,b in ipairs(self:InputButtons()) do
        local button=b[1]
        if button~="LeftButton" and button~="RightButton" then for _,prefix in ipairs(self.modifiers) do
            local unit,context,kind=self:InputContext(prefix,button)
            index=index+1; local key=prefix..button; local actual=self:WorldActionKey(key,button)
            -- Physical buttons already use the unit frame's OnClick callback.
            local mouse=button=="MiddleButton" or button=="Button4" or button=="Button5"
            if unit and not self:IsRaidMarkerBinding(actual) and not (typing and not self.worldKeyNames[button]) and not (context=="frame" and mouse) and self.db.bindings[kind] and self:Resolve(self.db.bindings[kind][key]) then
                desired[actual]={index=index,action="EASYCASTCONTEXT"..index,key=key,button=button,unit=unit,context=context,kind=kind}
            end
        end end
    end
    self:AddPrimaryBindings(desired)
    if self.nativeRun then for key in pairs(self.nativeRun.saved) do desired[key]=nil end end
    self.updatingWorldBindings=true; self.db.bindingRecovery=self.db.bindingRecovery or {}
    for key,entry in pairs(self.contextBindings) do
        if entry.observedDown and ((entry.observedUp and GetTime()-entry.observedUp>.5) or GetTime()-entry.observedDown>60) then
            entry.observedDown=nil; entry.observedUp=nil
        end
        if entry.pressed and not entry.primary and GetTime()-entry.time>60 then entry.pressed=nil end
        if (entry.pressed or entry.observedDown) and not self:IsRaidMarkerBinding(key) and (not entry.primary or self:PrimaryEnabled()) and not (typing and not self.worldKeyNames[entry.button]) and self.db.enabled and not self.worldBlocked and not self.traceRunning and not self.traceCastingPaused then
            desired[key]=entry
        end
        if not desired[key] or GetBindingAction(key)~=entry.action then
            if entry.primary then
                local p=self.primaryPresses[entry.button]
                if p and p.entry==entry then self:AbortPrimaryPress(entry.button,"Kontextbindung entfernt / von außen geändert") end
            end
            if GetBindingAction(key)==entry.action then self:AssignWorldKey(key,entry.original~="" and entry.original or nil) end
            self.contextBindings[key]=nil; self.contextIndex[entry.index]=nil; self.db.bindingRecovery[key]=nil
            if desired[key] then desired[key]=nil end -- Respect external changes until a later context update.
        end
    end
    for key,want in pairs(desired) do
        local entry=self.contextBindings[key]
        if not entry then
            want.original=GetBindingAction(key) or ""
            self.db.bindingRecovery[key]={action=want.action,original=want.original}
            if self:AssignWorldKey(key,want.action) then entry=want; self.contextBindings[key]=entry
            else self.db.bindingRecovery[key]=nil end
        elseif not entry.pressed and not entry.observedDown then entry.unit=want.unit; entry.context=want.context; entry.kind=want.kind end
        if entry then self.contextIndex[entry.index]=entry end
    end
    self.updatingWorldBindings=nil
end
function EasyCast_ContextBinding(index,state)
    if not E.initialized then return end
    if E:BypassRequested() then E:ReleaseWorldBindings(); return end
    local e=E.contextIndex[index]
    if not e then E:TestLog("NATIVE EINGABE", "Kontext "..tostring(index).." / "..tostring(state).." ohne aktive Bindung"); return end
    if not E.worldKeyNames[e.button] and E:TextInputFocused() then
        e.pressed=nil; E.worldPending[e.button]=nil; E.worldHeld[e.button]=nil; E.worldHeldAt[e.button]=nil
        E:TestLog("EINGABE ABBRUCH",e.button.." · Tastatureingabe in Textfeld"); return
    end
    local phase=state=="up" and "up" or "down"
    if phase=="down" then
        local mouse=e.button=="MiddleButton" or e.button=="Button4" or e.button=="Button5"
        if mouse then
            -- A real mouse DOWN owns the new gesture even if only the observer
            -- state survived the previous release (e.pressed can already be nil).
            local p=E.worldPending[e.button]
            if e.pressed or p or E.worldHeld[e.button] then
                E:RecordWorldInput(e.button,"cancel","Tastenbindung","Neues natives DOWN; veralteter Mauszustand verworfen",nil,p and p.mode,p)
                if p then E.worldCounts.cancelled=E.worldCounts.cancelled+1 end
            end
            for _,old in pairs(E.contextBindings) do if old.button==e.button then old.pressed=nil end end
            E.worldPending[e.button]=nil; E.worldHeld[e.button]=nil; E.worldHeldAt[e.button]=nil; E.worldExpired[e.button]=nil
        end
        if e.pressed then return end -- Keyboard auto-repeat is not a fresh press.
        local unit,context,kind=E:InputContext(nil,e.button)
        local reason
        if not unit then local _,_,why=E:ResolveWorldTarget(e.button); reason=why or "Kein aktiver Eingabekontext"
        elseif E:Key(e.button)~=e.key then reason="Zusatztaste passt nicht zur Bindung"
        elseif context~=e.context or kind~=e.kind then reason="Eingabekontext seit Bindungszuordnung geändert" end
        if reason then E:RecordWorldInput(e.button,"down","Tastenbindung",reason,unit); return end
        e.pressed=true; e.time=GetTime(); e.identity=E:HoverIdentity(unit)
        if context=="world" then E:WorldInput("down",e.button,"Tastenbindung") end
        if e.button=="MOUSEWHEELUP" or e.button=="MOUSEWHEELDOWN" then EasyCast_ContextBinding(index,"up") end
    elseif e.pressed then
        e.pressed=nil
        if e.context=="world" then E:WorldInput("up",e.button,"Tastenbindung")
        else
            local unit,context=E:InputContext(nil,e.button); local saved=E:CachedHoverUnit(e.identity)
            if context=="frame" and saved and UnitIsUnit(unit,saved) and E:Key(e.button)==e.key then E:Dispatch(saved,e.button) end
        end
    else
        local p=E.worldPending[e.button]
        if p then
            E:RecordWorldInput(e.button,"up","Tastenbindung","Loslassen über andere Zusatztasten-Bindung; kein Zauber",nil,p.mode,p)
            E.worldCounts.cancelled=E.worldCounts.cancelled+1
            E.worldPending[e.button]=nil; E.worldHeld[e.button]=nil; E.worldHeldAt[e.button]=nil
            for _,old in pairs(E.contextBindings) do if old.button==e.button then old.pressed=nil end end
        else E:TestLog("NATIVE EINGABE",e.key.." / up ohne gespeichertes DOWN") end
    end
end
function EasyCast_WorldBinding(button,state)
    if E.initialized then E:WorldInput(state=="up" and "up" or "down",button,"Tastenbindung") end
end
