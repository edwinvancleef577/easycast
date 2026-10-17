local E=EasyCast
local function clean(value)
    local text=tostring(value)
    text=string.gsub(string.gsub(text,"[\r\n]"," "),"|c%x%x%x%x%x%x%x%x","")
    return string.sub(string.gsub(text,"|r",""),1,240)
end
function E:CastDiagnosisActive()
    local t=self.db and self.db.diagnosticTest
    return t and t.active and not t.worldTrace
end
function E:CastObservationActive()
    return self:CastDiagnosisActive() or (self.probe and self.probe:IsShown() and not self.traceRunning)
end
function E:DiagnosticUnit(unit)
    if not unit or not UnitExists(unit) then return tostring(unit or "nil").."=<keine>" end
    return tostring(unit).."="..clean(UnitName(unit)).." ["..tostring(self:UnitGUIDValue(unit) or "GUID fehlt").."]"
end
-- Shared read-only index for tooltip ranges and optional diagnosis.
-- This private tooltip never touches GameTooltip or modifies an action slot.
function E:SpellbookOrCursorBusy()
    for _,name in ipairs({"SpellBookFrame","ModernSpellBookFrame"}) do
        local frame=getglobal(name)
        if frame and frame.IsVisible and frame:IsVisible() then return true end
    end
    return (CursorHasSpell and CursorHasSpell()) or (CursorHasItem and CursorHasItem()) or (CursorHasMacro and CursorHasMacro())
end
function E:RequestDiagnosticActionScan()
    if not self:RangeIndexNeeded() then return end
    self.diagnosticActions=nil -- Old slots must not colour icons during rebuild.
    self.diagnosticScanDue=GetTime()+.25
end
function E:ScanDiagnosticActions()
    if self.scanningDiagnosticActions then return end
    if self:SpellbookOrCursorBusy() then
        self.diagnosticActionScan="wartet: Zauberbuch / Cursor aktiv"; self:RequestDiagnosticActionScan(); return
    end
    self.diagnosticActions={}; self.diagnosticActionScan="API fehlt"
    if not self:RangeIndexNeeded() or not GetActionTexture or not IsActionInRange then return end
    self.diagnosticScanDue=nil; self.scanningDiagnosticActions=true
    local ok,err=pcall(function()
        local tip=self.rangeScanTip
        if not tip then tip=CreateFrame("GameTooltip","EasyCastRangeScan",UIParent,"GameTooltipTemplate"); self.rangeScanTip=tip end
        if not tip.SetAction or not tip.SetOwner or not tip.ClearLines then return end
        tip:SetOwner(UIParent,"ANCHOR_NONE")
        for slot=1,120 do
            local texture=GetActionTexture(slot)
            local macro=GetActionText and GetActionText(slot)
            if texture and (not macro or macro=="") then
                tip:ClearLines(); tip:SetAction(slot)
                local left=getglobal("EasyCastRangeScanTextLeft1"); local right=getglobal("EasyCastRangeScanTextRight1")
                local name=left and left:GetText(); local rank=right and right:GetText()
                if name and name~="" then
                    table.insert(E.diagnosticActions,{slot=slot,name=clean(name),rank=rank and clean(rank) or "",icon=texture})
                end
            end
        end
        tip:Hide(); self.diagnosticActionScan="bereit"
    end)
    if self.rangeScanTip then self.rangeScanTip:Hide() end
    self.scanningDiagnosticActions=nil
    if not ok then self.diagnosticActionScan="nicht verfügbar: "..clean(err) end
    self:TestLog("REICHWEITEN-INDEX",self.diagnosticActionScan.." · Plätze="..table.getn(self.diagnosticActions))
end
function E:DiagnosticRange(unit,spell)
    if not spell or not spell.name then return "kein Spruch auflösbar" end
    if not UnitIsUnit("target",unit) then return "Leistenabfrage nicht auf Sollziel anwendbar (andere Zielauswahl)" end
    local lines={}
    for _,entry in ipairs(self.diagnosticActions or {}) do
        if entry.name==spell.name and entry.icon==spell.icon and (entry.rank=="" or entry.rank==spell.rank) then
            local ok,value=pcall(IsActionInRange,entry.slot)
            table.insert(lines,"Platz "..entry.slot.." / "..(entry.rank~="" and entry.rank or "Rang nicht bestätigt").."="..(ok and tostring(value) or "API-Fehler"))
        end
    end
    if table.getn(lines)==0 then return "kein passender Leistenplatz / "..tostring(self.diagnosticActionScan or "nicht gescannt") end
    return table.concat(lines,"; ")
end
function E:DiagnosticSnapshot(label,unit,spell)
    if not self:CastDiagnosisActive() then return end
    local targeting=SpellIsTargeting and SpellIsTargeting()
    self:TestLog("ZUSTAND "..label,self:DiagnosticUnit(unit).." · Auswahl: "..self:DiagnosticUnit("target")..
        " · Maus: "..self:DiagnosticUnit("mouseover").." · Kampf="..tostring(self:InCombat()).." · Zielcursor="..tostring(targeting).." · API="..tostring(self.activeAPI))
    self:TestLog("REICHWEITE "..label,self:DiagnosticRange(unit,spell))
    local cooldown=spell and self:BindingCooldown(spell.cast,spell)
    self:TestLog("ZEITPUNKT "..label,"letzter Frame="..math.floor((self.lastFrameDuration or 0)*1000).." ms · Rest-CD="..tostring(cooldown and cooldown.remaining or "kein aktiver / unbekannt"))
end
function E:BeginCastDiagnosis(unit,spell)
    if not self:CastObservationActive() then return end
    self.castAttemptNumber=(self.castAttemptNumber or 0)+1
    local a={id=self.castAttemptNumber,time=GetTime(),unit=unit,spell=spell,
        wanted=self:DiagnosticUnit(unit),guid=self:UnitGUIDValue(unit),origin=self.castOrigin or "?",source=self.castSource}
    self.lastCastAttempt=a
    self:TestLog("VERSUCH #"..a.id,a.origin.." / "..tostring(a.source or "?").." · "..spell.cast.." · Sollziel="..a.wanted)
    self:DiagnosticSnapshot("vor #"..a.id,unit,spell)
    return a
end
function E:EndCastDiagnosis(attempt,ok,result)
    if not attempt or not self:CastObservationActive() then return end
    attempt.luaOK=ok; attempt.apiResult=result
    self:TestLog("RÜCKKEHR #"..attempt.id,"Lua-Aufruf="..tostring(ok).." · API-Rückgabe="..tostring(result).." (kein Server-Erfolgsnachweis)")
    self:DiagnosticSnapshot("direkt nach #"..attempt.id,attempt.unit,attempt.spell)
    -- Observation only: never issue or repeat a cast from OnUpdate.
    self.castObservation=attempt
end
function E:UpdateCastDiagnosis()
    if self.diagnosticScanDue and GetTime()>=self.diagnosticScanDue then
        self.diagnosticScanDue=nil
        if self:RangeIndexNeeded() then self:ScanDiagnosticActions() end
    end
    local attempt=self.castObservation; self.castObservation=nil
    if not attempt or not self:CastObservationActive() then return end
    self:TestLog("NÄCHSTER FRAME #"..attempt.id,"Sollziel beim Aufruf="..attempt.wanted)
    self:DiagnosticSnapshot("Frame nach #"..attempt.id,attempt.unit,attempt.spell)
end
function E:DiagnosticFeedback(source,a,b,c,d,e)
    if not self:CastObservationActive() then return end
    local last=self.lastCastAttempt
    if source~="PLAYER_TARGET_CHANGED" then
        local feedback={time=GetTime(),source=source,text=clean(a)}
        self.lastClientFeedback=feedback
        if last and feedback.time-last.time<=1 then last.feedback=feedback end
    end
    local relation=last and " · letzter EC-Versuch #"..last.id.." vor "..string.format("%.3f",GetTime()-last.time).." s" or " · kein EC-Versuch seit Diagnosestart"
    self:TestLog("CLIENT "..source,clean(a).." | "..clean(b).." | "..clean(c).." | "..clean(d).." | "..clean(e)..relation)
end
function E:InitCastDiagnostics(events)
    self.castEventRegistration={}
    for _,name in ipairs({"SPELLCAST_START","SPELLCAST_STOP","SPELLCAST_FAILED","SPELLCAST_INTERRUPTED",
        "SPELLCAST_DELAYED","SPELLCAST_CHANNEL_START","SPELLCAST_CHANNEL_STOP","CHAT_MSG_SPELL_FAILED_LOCALPLAYER",
        "UI_INFO_MESSAGE","ACTIONBAR_SLOT_CHANGED","SPELL_QUEUE_EVENT","SPELL_CAST_EVENT","SPELL_FAILED_SELF"}) do
        self.castEventRegistration[name]=pcall(function() events:RegisterEvent(name) end)
    end
    local f=UIErrorsFrame
    if f and type(f.AddMessage)=="function" and not self.errorDisplayHook then
        local original=f.AddMessage
        f.AddMessage=function(frame,message,...)
            -- Forward every message unchanged, including all native arguments.
            E:DiagnosticFeedback("UIErrorsFrame",message)
            return original(frame,message,unpack(arg))
        end
        self.errorDisplayHook=true
    end
end
function E:LogCastDiagnosticSetup()
    self.lastCastAttempt=nil; self.castObservation=nil; self.castAttemptNumber=0
    self.lastClientFeedback=nil
    self:TestLog("UMGEBUNG",GetBuildInfo and clean(GetBuildInfo()) or "Build unbekannt")
    if GetAddOnMetadata then
        for _,name in ipairs({"ModernSpellBook","DragonForgeUI","DragonflightUI","ShaguTweaks","EasyThreat"}) do
            local ok,version=pcall(GetAddOnMetadata,name,"Version")
            if ok and version then self:TestLog("ADDON",name.." Version="..clean(version).." · geladen="..tostring(IsAddOnLoaded and IsAddOnLoaded(name))) end
        end
    end
    self:TestLog("CLIENT-APIS","CLASSIC_API_VERSION="..tostring(CLASSIC_API_VERSION).." · SUPERWOW_VERSION="..tostring(SUPERWOW_VERSION).." · IsMouseButtonDown="..type(IsMouseButtonDown).." · CastAtUnit="..type(C_Spell and C_Spell.CastAtUnit))
    if type(GetNampowerVersion)=="function" then
        local ok,a,b,c=pcall(GetNampowerVersion)
        self:TestLog("NAMPOWER",ok and tostring(a).."."..tostring(b).."."..tostring(c) or "Versionsabfrage fehlgeschlagen")
    end
    if GetCVar then
        for _,name in ipairs({"NP_QueueCastTimeSpells","NP_QueueInstantSpells","NP_SpellQueueWindowMs","NP_SpamProtectionEnabled"}) do
            local ok,value=pcall(GetCVar,name)
            if ok and value~=nil and value~="" then self:TestLog("CLIENT-EINSTELLUNG",name.."="..tostring(value)) end
        end
    end
    self:TestLog("KLICK-GRENZEN","Nur Links/Rechts: "..math.floor(self.db.world.maxHold*1000).." ms · "..self.db.world.dragPixels.." px")
    self:TestLog("REICHWEITEN-API",self:RangeCapabilities())
    self:TestLog("DIAGNOSE","UIErrorsFrame="..tostring(self.errorDisplayHook).." · IsActionInRange="..type(IsActionInRange))
    for name,registered in pairs(self.castEventRegistration or {}) do self:TestLog("EVENT",name.." registriert="..tostring(registered)) end
    self:ScanDiagnosticActions()
end
