-- Real left/right binding callbacks. WorldFrame observations never cast.
local E=EasyCast
E.primaryPresses={}
E.cameraHeld={}
-- Camera ownership outlives the binding/press that started it. Releases are
-- observed before any target, modifier, UI or diagnostic-mode early return.
function E:CameraInput(button,phase,observedOnly)
    if button~="LeftButton" and button~="RightButton" then return end
    if phase=="down" and self.nativeRun and self.nativeRun.released then
        -- Another physical event can arrive before the next rendered frame.
        -- The previous UP has finished; never treat a fresh click as running.
        self:RestoreNativeRun(); self:UpdateContextBindings()
    end
    if phase=="down" then
        self.cameraHeld[button]=true
        -- WorldFrame / mouseover events can precede the binding callback. Keep
        -- the installed binding alive through that gap, without casting here.
        local actual=self:WorldActionKey(self:Key(button),button)
        local entry=self.contextBindings[actual]
        if entry and entry.primary and GetBindingAction(actual)==entry.action then
            entry.observedDown=entry.observedDown or GetTime(); entry.observedUp=nil
        end
        local other=button=="LeftButton" and "RightButton" or "LeftButton"
        if self.cameraHeld[other] then
            self.cameraChord=true
            for _,p in pairs(self.primaryPresses) do p.cancelled="Beide Maustasten"; p.cameraTried=true end
        end
    elseif phase=="up" then
        self.cameraHeld[button]=nil
        for _,entry in pairs(self.contextBindings) do
            if entry.primary and entry.button==button and entry.observedDown then
                entry.observedUp=GetTime()
            end
        end
        if self.ownedCamera then self:StopOwnedCamera("Mouse-up "..button) end
        if not self.cameraHeld.LeftButton and not self.cameraHeld.RightButton then self.cameraChord=nil end
    end
    self:NativeRunInput(button,phase,observedOnly)
end
function E:StopOwnedCamera(reason)
    local c=self.ownedCamera
    if not c or c.inStop then return end
    if not c.stopping then self:TestLog("KAMERA ENDE",reason or "Kamerageste beendet") end
    c.stopping=true
    for _,p in pairs(self.primaryPresses) do
        p.cancelled=reason or "Kamera beendet"; p.cameraTried=true; p.cameraStop=nil
    end
    if c.press then c.press.cancelled=reason or "Kamera beendet"; c.press.cameraStop=nil end
    c.lastStop=GetTime()
    c.inStop=true
    local ok=self:PrimaryCameraCall("MouselookStop")
    c.inStop=nil
    -- Retain ownership if the stop fails, so the watchdog/escape can retry.
    if ok and not (IsMouselooking and IsMouselooking()) then
        self.ownedCamera=nil
        if self.cameraGuard then self.cameraGuard:Hide() end
    end
end
function E:StartOwnedCamera(p,button,allowChord)
    if self.ownedCamera or (self.cameraChord and not allowChord) then return end
    if not self.cameraGuard then
        local f=CreateFrame("Frame","EasyCastCameraGuard",UIParent)
        f:SetWidth(1); f:SetHeight(1); f:EnableMouse(false); f:Hide()
        table.insert(UISpecialFrames,"EasyCastCameraGuard")
        f:SetScript("OnHide",function() E:StopOwnedCamera("Escape / Kamera-Not-Aus") end)
        self.cameraGuard=f
    end
    self.ownedCamera={press=p,button=button,time=GetTime()}
    p.cameraStop="MouselookStop"; p.cameraRequested=true
    self.cameraGuard:Show()
    if not self:PrimaryCameraCall("MouselookStart") then self:StopOwnedCamera("Kamerastart fehlgeschlagen") end
end
function E:WatchOwnedCamera()
    if IsMouseButtonDown then
        for _,button in ipairs({"LeftButton","RightButton"}) do
            if self.cameraHeld[button] and self:PhysicalMouseState(button)==false then self:CameraInput(button,"up",true) end
        end
    end
    local c=self.ownedCamera
    if not c then return end
    if c.stopping then
        if GetTime()-(c.lastStop or 0)>=.25 then self:StopOwnedCamera("Kamera-Stopp wiederholen") end
        return
    end
    if not self:PrimaryEnabled() or (GetMouseFocus and GetMouseFocus() and not self:IsWorldFocus()) then
        self:StopOwnedCamera("Kamera-Kontext beendet")
    elseif self:PhysicalMouseState(c.button)==false then
        self:CameraInput(c.button,"up",true)
    elseif self:PhysicalMouseState(c.button)==nil and GetTime()-c.time>=8 then
        self:StopOwnedCamera("Sicherheitsstopp nach 8 s ohne Mausstatus-API")
    end
end
function E:PrimaryEnabled()
    return self.db and self.db.enabled and self.db.world.enabled and not self:BypassRequested() and not self.worldBlocked and
        not self.traceRunning and not self.traceCastingPaused and not self.previewKind and
        not self.keyCaptureActive and not self.miniTest and not self.mouseTest and not self.bindingTest and not self.runTest and
        not (self.clickTestWindow and self.clickTestWindow:IsShown()) and not self.directClickTest and not self:TextInputFocused() and
        not (SpellIsTargeting and SpellIsTargeting())
end
function E:PrimaryTarget(button,cache,prefix)
    local unit,mode,reason,kind=self:ResolveWorldTarget(button,cache,prefix)
    if unit then return unit,mode,reason,kind end
    return nil,mode,reason,kind
end
function E:AddPrimaryBindings(desired)
    if not self:PrimaryEnabled() or not self:IsWorldFocus() then return end
    -- Do not capture a press that already belongs to a native camera binding.
    if (IsMouselooking and IsMouselooking()) then return end
    if (self.cameraHeld.LeftButton or self.cameraHeld.RightButton) and not next(self.primaryPresses) then return end
    local i=0
    for _,button in ipairs({"LeftButton","RightButton"}) do
        for _,prefix in ipairs(self.modifiers) do
            local unit,mode,reason,kind=self:PrimaryTarget(button,true,prefix)
            i=i+1
            local key=prefix..button; local actual=self:WorldActionKey(key,button)
            local value=kind and self.db.bindings[kind][key]
            local held=self.worldHeld[button] or self:PhysicalMouseDown(button)
            if unit and value and self:Resolve(value) and (mode~="direct-hostile" or self:IdentityUnit(self:HoverIdentity(unit))) and (not held or self.primaryPresses[button]) then
                desired[actual]={index=216+i,action="EASYCASTPRIMARY"..i,key=key,button=button,
                    unit=unit,context="world",kind=kind,primary=true}
            end
        end
    end
end
function E:PrimaryCameraCall(name)
    -- Only the camera pair already observed working in this client. Never
    -- dispatch Blizzard-only left selection/camera actions through this helper.
    if name~="MouselookStart" and name~="MouselookStop" then
        self:TestLog("KAMERA", "Nicht unterstützter Kameraaufruf verworfen: "..tostring(name)); return false
    end
    local fn=getglobal(name)
    if type(fn)~="function" then self:TestLog("KAMERA",name.." fehlt"); return false end
    self.cameraCalls=(self.cameraCalls or 0)+1
    if self.db.diagnosticTest then self.db.diagnosticTest.cameraCalls=(self.db.diagnosticTest.cameraCalls or 0)+1 end
    self:APIStart(name,"Kamerageste; kein Zauber")
    local ok,err=pcall(fn); self:APIEnd()
    self:TestLog("KAMERA",name.." · Lua="..tostring(ok).." · IsMouselooking="..tostring(IsMouselooking and IsMouselooking())..(not ok and " · "..tostring(err) or "").." (Rückkehr allein beweist keine Kamerabewegung)")
    return ok
end
function E:StopPrimaryCamera(p)
    if p and self.ownedCamera and self.ownedCamera.press==p then self:StopOwnedCamera("Kamerageste beendet") end
    if p then p.cameraStop=nil end
end
function E:AbortPrimaryPress(button,reason)
    local p=self.primaryPresses[button]
    if not p then return end
    p.cancelled=reason or "Abgebrochen"
    self:StopPrimaryCamera(p)
    if p.entry then p.entry.pressed=nil end
    self.primaryPresses[button]=nil
    self.worldCounts.cancelled=self.worldCounts.cancelled+1
    self:RecordWorldInput(button,"cancel","EasyCast",p.cancelled,nil,p.mode,p)
end
function E:CancelPrimaryPresses(reason)
    self:StopOwnedCamera(reason)
    for button in pairs(self.primaryPresses) do self:AbortPrimaryPress(button,reason) end
end
function E:CheckPrimaryPress(p,button,canStartCamera)
    if p.cameraStop then return end
    local x,y=GetCursorPosition()
    local moved=(x-p.x)^2+(y-p.y)^2>(self.db.world.dragPixels or 6)^2
    if not self:PrimaryEnabled() then p.cancelled="Weltzaubern pausiert"; return end
    if not self:IsWorldFocus() then p.cancelled="Maus über UI"; return end
    if p.targetGeneration~=self.targetGeneration then p.cancelled="Auswahl geändert" end
    if self:Key(button)~=p.key then p.cancelled="Zusatztaste geändert" end
    if moved then
        p.cancelled="Maus gezogen; kein Zauber"
        if canStartCamera and not p.cameraTried and not self.cameraChord then
            p.cameraTried=true
            local other=button=="LeftButton" and "RightButton" or "LeftButton"
            if self.primaryPresses[other] or self.worldHeld[other] or self:PhysicalMouseDown(other) then
                p.cancelled="Beide Maustasten: kein Zauber"; return
            end
            if type(MouselookStart)=="function" and type(MouselookStop)=="function" then
                self:StartOwnedCamera(p,button)
            else
                p.cancelled="Maus gezogen; Mouselook im Client nicht verfügbar"
                self:TestLog("KAMERA","MouselookStart / MouselookStop fehlt")
            end
            self:RecordWorldInput(button,"drag","Native Bindung",p.cancelled,nil,p.mode,p)
        end
    elseif GetTime()-p.time>=(self.db.world.maxHold or .15) then p.tooLong=true end
end
function E:UpdatePrimaryPresses()
    self:WatchOwnedCamera()
    self:UpdateNativeRun()
    for button,p in pairs(self.primaryPresses) do
        local abort
        local released=self:PhysicalMouseState(button)==false
        if released and not p.releaseObservedAt then
            p.releaseObservedAt=GetTime()
            self:TestLog("UP BEOBACHTET",button.." · Mausstatus=oben; Geste bleibt bis zur nativen UP-Bindung erhalten")
        end
        if not self:PrimaryEnabled() then abort="Weltzaubern pausiert"
        elseif GetTime()-p.time>60 then abort="Geste nach 60 Sekunden beendet"
        elseif p.releaseObservedAt and GetTime()-p.releaseObservedAt>.5 then abort="Kein natives UP innerhalb 500 ms nach beobachtetem Loslassen"
        elseif p.entry and GetBindingAction(self:WorldActionKey(p.key,button))~=p.entry.action then abort="Bindung von außen geändert" end
        if abort then self:AbortPrimaryPress(button,abort)
        else
            -- Polling may precede the native key-up callback. Never delete the
            -- press or cast here. Camera release remains immediate and separate.
            self:CheckPrimaryPress(p,button,not released and not p.releaseObservedAt)
        end
    end
end
function EasyCast_PrimaryBinding(index,state)
    E:CameraInput(index<=8 and "LeftButton" or "RightButton",state)
    if E.nativeRun and E.nativeRun.started then return end
    local e=E.contextIndex[216+index]
    if not e or not e.primary then
        E:RecordWorldInput(index<=8 and "LeftButton" or "RightButton",state,"Native Bindung","Eingabe ohne aktive EasyCast-Bindung",nil)
        return
    end
    local button=e.button
    if state~="down" and state~="up" then E:TestLog("NATIVE EINGABE","Ungültige Phase "..tostring(state)); return end
    E:ObserveInput(button,state,"Native Bindung")
    E:TestLog("NATIVE EINGABE",button.." / "..state)
    if state=="down" then
        -- A fresh native mouse DOWN starts a fresh gesture. A missed UP must
        -- never leave e.pressed blocking subsequent clicks for up to 60 seconds.
        if E.primaryPresses[button] then E:AbortPrimaryPress(button,"Neues natives DOWN; vorheriges UP fehlt") end
        e.pressed=nil
        if not E:PrimaryEnabled() or not E:IsWorldFocus() then
            E:RecordWorldInput(button,state,"Native Bindung",not E:PrimaryEnabled() and "Weltzaubern pausiert" or E:FocusDetails().reason,nil); return
        end
        if E:Key(button)~=e.key then E:RecordWorldInput(button,state,"Native Bindung","Zusatztaste passt nicht zur Bindung",nil); return end
        E:ArmNativeRun(button)
        local unit,mode,reason,kind=E:PrimaryTarget(button,true)
        local selectOnly=false
        -- Cover a pointer change between the last binding update and DOWN.
        if not unit and E.db.world.enemyMode~="direct" and button=="LeftButton" and E:Kind("mouseover")=="hostile" and not UnitIsUnit("mouseover","target") then
            unit="mouseover"; mode="selection-only"; kind="hostile"; selectOnly=true
        end
        if not unit then E:RecordWorldInput(button,state,"Native Bindung",reason or "Kein Ziel",nil); return end
        local value=E.db.bindings[kind][e.key]
        if not selectOnly and (not value or not E:Resolve(value)) then E:RecordWorldInput(button,state,"Native Bindung","Keine gültige Belegung",unit); return end
        local identity=E:HoverIdentity(unit)
        if not E:IdentityUnit(identity) then E:RecordWorldInput(button,state,"Native Bindung","Ziel nicht eindeutig erreichbar",unit); return end
        local x,y=GetCursorPosition()
        local p={entry=e,identity=identity,kind=kind,mode=mode,spell=value,key=e.key,selectOnly=selectOnly,
            time=GetTime(),x=x,y=y,source="Native Bindung",targetGeneration=E.targetGeneration}
        e.pressed=true; e.time=p.time; E.primaryPresses[button]=p
        if E.cameraChord then p.cancelled="Beide Maustasten"; p.cameraTried=true end
        for other,press in pairs(E.primaryPresses) do if other~=button then press.cancelled="Beide Maustasten"; p.cancelled="Beide Maustasten" end end
        E.worldCounts.down=E.worldCounts.down+1
        E:RecordWorldInput(button,state,"Native Bindung",selectOnly and "Anderer Gegner: nur auswählen" or "Ziel gespeichert; wartet auf Loslassen",unit,mode,p)
        return
    end
    local p=E.primaryPresses[button]
    e.observedDown=nil; e.observedUp=nil
    E.primaryPresses[button]=nil; e.pressed=nil
    if not p then E:RecordWorldInput(button,state,"Native Bindung","Natives UP ohne gespeichertes DOWN (siehe vorherigen Abbruch)",nil); return end
    if p.entry then p.entry.pressed=nil end
    if p.entry~=e then p.cancelled="Loslassen über andere Zusatztasten-Bindung" end
    E.worldCounts.up=E.worldCounts.up+1
    E:CheckPrimaryPress(p,button,false)
    local camera=p.cameraRequested
    E:StopPrimaryCamera(p)
    local reason=p.cancelled
    if camera then reason="Mouselook beendet; kein Zauber" end
    if p.tooLong or GetTime()-p.time>=(E.db.world.maxHold or .15) then reason=reason or "Zu lange gehalten" end
    local unit=not reason and E:IdentityUnit(p.identity)
    if not reason and (not unit or E:Kind(unit)~=p.kind or (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))) then reason="Gespeichertes Ziel nicht mehr gültig" end
    if reason then
        E.worldCounts.cancelled=E.worldCounts.cancelled+1
        E:RecordWorldInput(button,state,"Native Bindung",reason,nil,p.mode,p); return
    end
    if p.selectOnly then
        E:APIStart("TargetUnit",unit); TargetUnit(unit); E:APIEnd()
        E:RecordWorldInput(button,state,"Native Bindung","Anderen Gegner ausgewählt; kein Zauber",unit,p.mode,p); return
    end
    if E.db.bindings[p.kind][p.key]~=p.spell then
        E:RecordWorldInput(button,state,"Native Bindung","Belegung während des Klicks geändert",nil,p.mode,p); return
    end
    E:RecordWorldInput(button,state,"Native Bindung","Zauberaufruf: "..E:BindingLabel(p.spell),unit,p.mode,p)
    E.castOrigin="Welt"; E.castSource="Native Bindung"
    if E:CastWorldAction(unit,p.spell,p.kind) then E.worldCounts.casts=E.worldCounts.casts+1
    else E:RecordWorldInput(button,state,"Native Bindung","Zauberaufruf abgelehnt; siehe API-/Clientmeldung",unit,p.mode,p) end
    E.castOrigin=nil; E.castSource=nil
end
