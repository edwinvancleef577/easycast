-- A real second mouse DOWN executes Blizzard's MOVEFORWARD binding.
-- No movement API calls, RunBinding, synthetic clicks or delayed casts.
local E=EasyCast
local function other(button) return button=="LeftButton" and "RightButton" or "LeftButton" end
function E:NativeRunOwns(key)
    return self.nativeRun and self.nativeRun.saved[key]~=nil
end
function E:SetNativeRunButton(button)
    local p=self.nativeRun; if not p then return false end
    local previous=self.updatingWorldBindings; self.updatingWorldBindings=true
    local success=true
    for _,prefix in ipairs(self.modifiers) do
        local key=self:WorldActionKey(prefix..button,button)
        local actual=GetBindingAction(key) or ""
        local saved=p.saved[key]
        if saved then
            if actual~="MOVEFORWARD" then success=false end -- never overwrite another addon's change
        else
            local entry=self.contextBindings[key]
            local original=entry and actual==entry.action and entry.original or actual
            saved={original=original,button=button,action="MOVEFORWARD"}; p.saved[key]=saved
            self.db.bindingRecovery[key]={original=original,action="MOVEFORWARD"}
            -- Remove the contextual owner before changing the binding. Its
            -- ordinary cleanup must never remove the engine's pending UP.
            if entry then
                self.contextBindings[key]=nil; self.contextIndex[entry.index]=nil
            end
            local ok,result=pcall(self.AssignWorldKey,self,key,"MOVEFORWARD")
            if not ok or GetBindingAction(key)~="MOVEFORWARD" then
                success=false
                -- A rejected SetBinding may have left our previous contextual
                -- binding installed. Preserve recovery for that actual owner.
                if GetBindingAction(key)==actual then
                    saved.action=actual
                    self.db.bindingRecovery[key].action=actual
                end
                self:TestLog("LAUFEN FEHLER",key.." · "..tostring(result))
            end
        end
    end
    self.updatingWorldBindings=previous
    return success
end
function E:RestoreNativeRun()
    local p=self.nativeRun; if not p then return true end
    local previous=self.updatingWorldBindings; self.updatingWorldBindings=true
    local restored=true
    for key,saved in pairs(p.saved) do
        local ok=true
        if GetBindingAction(key)==saved.action then
            ok=pcall(self.AssignWorldKey,self,key,saved.original~="" and saved.original or nil)
            ok=ok and (GetBindingAction(key) or "")==saved.original
        end
        if ok then p.saved[key]=nil; self.db.bindingRecovery[key]=nil else restored=false end
    end
    self.updatingWorldBindings=previous
    if restored then
        self.nativeRun=nil
        self:TestLog("LAUFEN ENDE",p.started and "Beide Tasten oben; Originalbelegungen wiederhergestellt" or "Einzelklick; Laufbereitschaft beendet")
    end
    return restored
end
function E:CancelNativeRun(reason)
    local p=self.nativeRun; if not p then return end
    p.cancelled=reason or "Abgebrochen"
    -- Before the second DOWN only the unused button is replaced. Restoring
    -- that button cannot steal the first button's spell/camera UP.
    if not p.started and not p.held[p.second] then self:RestoreNativeRun() end
end
function E:ArmNativeRun(button)
    if self.nativeRun or not self:PrimaryEnabled() or not self:IsWorldFocus() or self.cameraHeld[other(button)] then return end
    self.nativeRun={first=button,second=other(button),saved={},held={[button]=true}}
    if self:SetNativeRunButton(other(button)) then
        self:TestLog("LAUFEN BEREIT",button.." gehalten; zweite Maustaste = originale MOVEFORWARD-Belegung")
    else self:CancelNativeRun("Laufbelegung fehlgeschlagen") end
end
function E:YieldToNativeMouse(button)
    if not self:PrimaryEnabled() or not self:IsWorldFocus() then return end
    local actual=self:WorldActionKey(self:Key(button),button)
    local own=self.contextBindings[actual]
    if own and GetBindingAction(actual)==own.action then return end
    -- First DOWN belongs to WoW. Remove the unused opposite overrides before
    -- its next physical DOWN, allowing the complete original two-button path.
    local previous=self.updatingWorldBindings; self.updatingWorldBindings=true
    for key,entry in pairs(self.contextBindings) do
        if entry.primary and entry.button==other(button) and not entry.pressed and not entry.observedDown then
            if GetBindingAction(key)==entry.action then self:AssignWorldKey(key,entry.original~="" and entry.original or nil) end
            self.contextBindings[key]=nil; self.contextIndex[entry.index]=nil; self.db.bindingRecovery[key]=nil
        end
    end
    self.updatingWorldBindings=previous
end
function E:NativeRunInput(button,phase,observedOnly)
    if observedOnly then return end -- Polling is not the engine's release callback.
    local p=self.nativeRun
    if not p then
        if phase=="down" and not self.cameraHeld[other(button)] then self:YieldToNativeMouse(button) end
        return
    end
    p.held[button]=phase=="down" and true or nil
    if phase=="down" then
        p.released=nil
        if button==p.second and not p.started then
            -- A global UI observation must not start a camera gesture.
            if p.cancelled or not self:IsWorldFocus() then
                p.cancelled=p.cancelled or "Maus über UI"; return
            end
            p.started=true
            self:CancelPrimaryPresses("Beide Maustasten: Laufen hat Vorrang")
            for _,pending in pairs(self.worldPending) do pending.cancelled="Laufgeste" end
            if not self:SetNativeRunButton(p.first) then p.cancelled="Laufbelegung unvollständig" end
            self:TestLog("LAUFEN NATIV","Beide Tasten = MOVEFORWARD; jedes echte UP stoppt; kein Zauber")
        end
        -- Also resume steering when one button is pressed again while the
        -- other stays held. Original single-button camera ownership is intact.
        if p.started and not p.cancelled and self:IsWorldFocus() and
            self.cameraHeld.LeftButton and self.cameraHeld.RightButton and
            not (IsMouselooking and IsMouselooking()) then
            self:StartOwnedCamera({time=GetTime()},button,true)
        end
    elseif phase=="up" then
        if not p.started and not p.held[p.second] then
            self:RestoreNativeRun() -- only the other, unused button was replaced
        elseif not next(p.held) then
            p.released=true -- restore in the NEXT update, after native UP executes
        end
    end
end
function E:UpdateNativeRun()
    local p=self.nativeRun; if not p then return end
    if not self:PrimaryEnabled() then self:CancelNativeRun("Weltzaubern pausiert") end
    p=self.nativeRun; if not p then return end
    if p.released and not next(p.held) then
        if self:RestoreNativeRun() then self:RefreshWorldHooks(); self:UpdateContextBindings() end
    end
end
