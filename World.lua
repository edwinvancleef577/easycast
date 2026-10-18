local E=EasyCast
local allowed={LeftButton=true,RightButton=true,MiddleButton=true,Button4=true,Button5=true}
E.worldExpired={}; E.worldHeldAt={}; E.worldHeld={}; E.worldPending={}; E.worldLastUp={}
E.worldCounts={down=0,up=0,casts=0,cancelled=0}
function E:UnitGUIDValue(unit)
    if UnitGUID then
        local ok,guid=pcall(UnitGUID,unit)
        if ok and type(guid)=="string" and guid~="" then return guid end
    end
    local exists,guid=UnitExists(unit)
    if exists and type(guid)=="string" and guid~="" then return guid end
end
function E:WorldConflict(key,button)
    local actual=self:WorldActionKey(key,button)
    local entry=self.contextBindings and self.contextBindings[actual]
    local action=entry and entry.original or (GetBindingAction and GetBindingAction(actual) or "")
    if action=="CAMERAORSELECTORMOVE" or action=="TURNORACTION" then return nil end
    if action and action~="" and action~=self.worldActions[button] then return action end
end
function E:WorldHint() return self:ResolveWorldTarget() end
function E:CancelWorldClicks(reason)
    self.worldHover=nil
    if self.CancelPrimaryPresses then self:CancelPrimaryPresses(reason) end
    for _,p in pairs(self.worldPending) do p.cancelled=reason or "Abgebrochen" end
end
function E:WorldTargetChanged()
    self.targetGeneration=self.targetGeneration+1; self.worldHover=nil
    for button,p in pairs(self.worldPending) do
        local id=p.identity; local token=id.token or id.guid
        -- Native left selection may happen before GLOBAL_MOUSE_UP. A friendly
        -- unit selected by that same click is expected, not a redirect.
        if button=="LeftButton" and p.kind=="friendly" and token and UnitIsUnit("target",token) and
            (not id.guid or self:UnitGUIDValue(token)==id.guid) then
            p.targetGeneration=self.targetGeneration; id.targetGeneration=self.targetGeneration
        else p.cancelled="Auswahl gewechselt" end
    end
end
function E:WorldMouseoverChanged()
    if UnitExists("mouseover") then self:CaptureWorldHover() end
    self:UpdateContextBindings()
end
function E:CheckWorldPress(p,button)
    if p.cancelled then return end
    local x,y=GetCursorPosition()
    local cameraButton=button=="LeftButton" or button=="RightButton"
    if not self.db.enabled or not self.db.world.enabled or self.worldBlocked then p.cancelled="Weltklicks aus / Client-Sperre"
    elseif self:BypassRequested() then p.cancelled="EasyCast-Aussetztaste gehalten"
    elseif self.previewKind then p.cancelled="Positionsvorschau aktiv"
    elseif self.keyCaptureActive then p.cancelled="Tastenerfassung aktiv"
    elseif not self.worldKeyNames[button] and self:TextInputFocused() then p.cancelled="Tastatureingabe in Textfeld"
    elseif ChatFrameEditBox and ChatFrameEditBox:IsShown() then p.cancelled="Chat-Eingabe aktiv"
    elseif cameraButton and GetTime()-p.time>(self.db.world.maxHold or 0.15) then p.cancelled="Zeitlimit: kein Loslassen rechtzeitig erkannt"
    elseif cameraButton and (x-p.x)*(x-p.x)+(y-p.y)*(y-p.y)>(self.db.world.dragPixels or 6)^2 then p.cancelled="Maus gezogen"
    elseif self:Key(button)~=p.key or self.db.bindings[p.kind][p.key]~=p.spell then p.cancelled="Belegung / Zusatztaste geändert"
    elseif self.targetGeneration~=p.targetGeneration then p.cancelled="Auswahl gewechselt"
    elseif not self:IsWorldFocus() then p.cancelled="Maus über UI / Weltfokus verloren"
    else
        for _,other in ipairs({"LeftButton","RightButton"}) do
            if other~=button and (self.worldHeld[other] or self:PhysicalMouseDown(other)) then
                p.cancelled="Weitere Kamera-/Auswahltaste gedrückt"
            end
        end
    end
    -- IsMouselooking alone is NOT movement: even a short native click can hide
    -- the cursor. Actual movement events and maximum cursor excursion cancel.
end
function E:WorldInput(phase,button,source)
    if self.runTest then self:RunTestInput(phase,button,source or "Welt"); return end
    self:CameraInput(button,phase)
    if self.nativeRun and self.nativeRun.started and (button=="LeftButton" or button=="RightButton") then
        self.worldHeld[button]=phase=="down" and true or nil
        self.worldHeldAt[button]=phase=="down" and GetTime() or nil
        self:ObserveInput(button,phase,source or "Welt")
        self:RecordWorldInput(button,phase,source or "Welt","Originale WoW-Laufbelegung; kein Zauber",nil)
        return
    end
    if self.bindingTest then self:BindingTestWorldInput(phase,button,source); return end
    if self.miniTest then self:MiniWorldInput(phase,button,source); return end
    if self.mouseTest then self:MouseTestInput(phase,button,source); return end
    if self:ClickTestOwns(button) then return end
    if self:BlessingTestVisible() then return end
    if self.traceRunning then self:TraceInput(phase,button,source or "Unbekannt"); return end
    if self.traceCastingPaused then return end
    if not self:IsInputButton(button) then return end
    source=source or "Unbekannt"; local now=GetTime()
    self.inputSources[source]=(self.inputSources[source] or 0)+1
    self:TestLog("EINGABE",phase.." · "..self:Key(button).." · "..source)
    self:ObserveInput(button,phase,source)
    -- A WorldFrame event is only a duplicate observer when a real binding
    -- owns this mouse button. It must not consume the binding's release.
    local owner=self:BindingOwnsMouse(button)
    if source~="Tastenbindung" and owner then
        self:TestLog("ROUTE",button.." / "..phase.." · "..source.." beobachtet; Tastenbindung führt aus")
        return
    end
    -- World/global observers must never arm or cast an auxiliary mouse gesture.
    -- Only its real native binding callback may do so, just like primary clicks.
    if allowed[button] and source~="Tastenbindung" then
        self.worldHeld[button]=phase=="down" and true or nil
        self.worldHeldAt[button]=phase=="down" and now or nil
        self:RecordWorldInput(button,phase,source,"Native WoW-Eingabe; keine aktive EasyCast-Bindung",nil)
        return
    end
    if phase=="up" then
        self.worldHeld[button]=nil; self.worldHeldAt[button]=nil; self.worldLastUp[button]=now
        local p=self.worldPending[button]; self.worldPending[button]=nil
        if not p then
            if self.worldExpired[button] then
                self:RecordWorldInput(button,phase,source,"Keine aktive Geste; vorheriger Druck bereits verworfen (Down vor "..string.format("%.3f",now-self.worldExpired[button]).." s)",nil)
                self.worldExpired[button]=nil
            end
            return
        end
        self.worldCounts.up=self.worldCounts.up+1
        self:CheckWorldPress(p,button)
        local unit=not p.cancelled and self:CachedHoverUnit(p.identity)
        if not p.cancelled and not unit then p.cancelled="Gespeicherte Einheit nicht mehr eindeutig erreichbar" end
        if unit and (self:Kind(unit)~=p.kind or (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))) then p.cancelled="Einheit nicht mehr gültig" end
        if p.cancelled then
            self.worldCounts.cancelled=self.worldCounts.cancelled+1
        self:RecordWorldInput(button,phase,source,p.cancelled,unit,p.mode,p); return
        end
        local conflict=self:WorldConflict(p.key,button)
        self:RecordWorldInput(button,phase,source,"Zauberaufruf: "..self:BindingLabel(p.spell)..(conflict and " · auch WoW: "..conflict or ""),unit,p.mode,p)
        local record=self.lastWorldInput
        self.castOrigin="Welt"; self.castSource=source
        local dry=self:TestSuppressCast()
        if self:CastWorldAction(unit,p.spell,p.kind) and not self.worldBlocked then self.worldCounts.casts=self.worldCounts.casts+1
        else record.reason=dry and "Trockenlauf: gültiger Mouse-up-Zauberklick" or self.worldBlocked and "Vom Client gesperrt: "..self.worldBlocked or "Zauberaufruf abgelehnt" end
        self.castOrigin=nil; self.castSource=nil
        return
    end
    if self.worldHeld[button] then return end
    if source~="Tastenbindung" and self.worldLastUp[button] and now-self.worldLastUp[button]<0.025 then return end
    self.worldExpired[button]=nil; self.worldHeld[button]=true; self.worldHeldAt[button]=now
    if button=="LeftButton" or button=="RightButton" then
        for other,p in pairs(self.worldPending) do
            if other~=button then p.cancelled="Weitere Kamera-/Auswahltaste gedrückt" end
        end
    end
    self.worldCounts.down=self.worldCounts.down+1
    local unit,mode,reason,kind=self:ResolveWorldTarget(button,true)
    if not unit then self:RecordWorldInput(button,phase,source,reason,nil,mode); return end
    local key=self:Key(button); local spell=self.db.bindings[kind][key]
    if not spell or not self:Resolve(spell) then
        self:RecordWorldInput(button,phase,source,"Kein gelernter Spruch für "..self:KeyLabel(key),unit,mode); return
    end
    local identity=self:HoverIdentity(unit)
    if not self:CachedHoverUnit(identity) then
        self:RecordWorldInput(button,phase,source,"Einheit ohne stabile ID; erst auswählen",unit,mode); return
    end
    local x,y=GetCursorPosition()
    local p={identity=identity,mode=mode,kind=kind,key=key,spell=spell,time=now,x=x,y=y,source=source,targetGeneration=self.targetGeneration}
    self.worldPending[button]=p; self:CheckWorldPress(p,button)
    self:DiagnosticSnapshot("MouseDown "..button,unit,self:Resolve(spell))
    self:RecordWorldInput(button,phase,source,p.cancelled or "Ziel gespeichert; wartet auf Loslassen",unit,mode,p)
end
-- Unknown/unavailable is distinct from a confirmed release. Numeric 0 is
-- truthy in Lua, but means UP in clients exposing numeric mouse states.
function E:PhysicalMouseState(button)
    if type(IsMouseButtonDown)~="function" then return nil end
    local ok,down=pcall(IsMouseButtonDown,button)
    if not ok then return nil end
    if down==true or down==1 then return true end
    if down==false or down==0 then return false end
    return nil
end
function E:PhysicalMouseDown(button) return self:PhysicalMouseState(button)==true end
function E:UpdateWorldPresses()
    -- Release overrides as soon as the modifier is observed, not just every 40 ms.
    if self:BypassRequested() and next(self.contextBindings) then self:ReleaseWorldBindings() end
    self:UpdatePrimaryPresses()
    for button,p in pairs(self.worldPending) do self:CheckWorldPress(p,button) end
    -- Polling observes only. OnUpdate must never consume a hardware release
    -- or execute a spell before the actual input callback arrives.
    if IsMouseButtonDown then
        self.polledButtons=self.polledButtons or {}
        for _,entry in ipairs(self.buttons) do
            local button=entry[1]; local down=self:PhysicalMouseDown(button)
            if down and not self.polledButtons[button] then self:ObserveInput(button,"down","Mausstatus (nur Beobachtung)")
            elseif not down and self.polledButtons[button] then self:ObserveInput(button,"up","Mausstatus (nur Beobachtung)") end
            self.polledButtons[button]=down
        end
    end
    for button,p in pairs(self.worldPending) do
        if GetTime()-p.time>60 then
            self:RecordWorldInput(button,"timeout","Beobachtung",p.cancelled or "Verwaiste Eingabe nach 60 Sekunden bereinigt",nil,p.mode)
            self.worldCounts.cancelled=self.worldCounts.cancelled+1
            self.worldExpired[button]=p.time
            self.worldPending[button]=nil; self.worldHeld[button]=nil
        end
    end
    for button,time in pairs(self.worldHeldAt) do
        if GetTime()-time>60 then self.worldHeld[button]=nil; self.worldHeldAt[button]=nil end
    end
    self:CaptureWorldHover()
end
function E:InitWorldClicks(events)
    self.worldEventRegistration={}
    for _,ev in ipairs({"GLOBAL_MOUSE_DOWN","GLOBAL_MOUSE_UP","UPDATE_MOUSEOVER_UNIT",
        "PLAYER_STARTED_LOOKING","PLAYER_STARTED_TURNING","PLAYER_TARGET_CHANGED","UPDATE_BINDINGS",
        "ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN","UI_ERROR_MESSAGE","PLAYER_LOGOUT"}) do
        self.worldEventRegistration[ev]=pcall(function() events:RegisterEvent(ev) end)
    end
    self:RefreshWorldBindings()
    self:RefreshWorldHooks()
    -- Original WorldFrame handlers remain direct; PrimaryWorld owns only its own camera requests.
end
