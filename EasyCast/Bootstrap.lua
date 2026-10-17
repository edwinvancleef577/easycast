local E=EasyCast
local events=CreateFrame("Frame","EasyCastEvents")
local elapsed,scan=0,0
function E:Initialize()
    if self.initialized then return end
    self:InitDB(); self:InitLocale(); if self.db.diagnosticTest then self.db.diagnosticTest.active=false end; self:RefreshSpells()
    self.tips={}; for _,context in ipairs(self.tipContexts) do self.tips[context]=self:BuildTip(context) end
    self:InitNativeTooltip(); self:InitCursorCapture(); self:InitThreatBridge()
    self:InitSettings(); self:InitMinimap(); self:ScanFrames()
    self.initialized=true
    SLASH_EASYCAST1="/easycast"; SLASH_EASYCAST2="/ec"
    SlashCmdList.EASYCAST=function(msg)
        msg=E:Trim(msg or "")
        if string.lower(msg)=="range" then E:ShowTestReport(E:RangeReport())
        elseif string.lower(msg)=="stop" then E:FinishRunTest("/ec stop",true); E:StopOwnedCamera("/ec stop"); E:CancelWorldClicks("Not-Aus"); E:ReleaseWorldBindings(); E:Print(E:L("EasyCast-Kamerageste beendet."))
        elseif string.lower(msg)=="runtest" then E:ShowRunTest()
        elseif string.lower(msg)=="keys" then E:ShowFunctionKeyReport()
        elseif string.lower(msg)=="mousetest" then E:ShowMouseTest()
        elseif string.lower(msg)=="bindingtest" then E:ShowBindingTest()
        elseif string.lower(msg)=="minitest" then E:ShowMiniTest()
        elseif string.lower(msg)=="mighttest" then E:ShowClickTest("might")
        elseif string.lower(msg)=="mousereport" then E:ShowTestReport(E:MouseTestReport())
        elseif string.lower(msg)=="clicktest" then E:ShowClickTest()
        elseif msg=="record on" then E:SetDiagnostics(true); E:Print("Begleitdiagnose gestartet. /ec mark LEISTE, RAHMEN oder WELT setzt eine Vergleichsmarkierung.")
        elseif msg=="record off" then E:SetDiagnostics(false); E:Print("Bericht gespeichert: /ec report")
        elseif string.sub(msg,1,5)=="mark " then E:TestLog("MARKER",string.sub(msg,6)); E:Print("Vergleichsmarkierung gespeichert.")
        elseif msg=="trace" then E:StartWorldTrace()
        elseif msg=="trace hook" then E:EnableWorldTraceHooks()
        elseif msg=="trace stop" or (msg=="test stop" and E.traceRunning) then E:StopWorldTrace()
        elseif string.sub(msg,1,11)=="trace mark " then E:TestLog("MARKER",string.sub(msg,12)); E:Print("Markierung gespeichert.")
        elseif msg=="diagnose" or msg=="diag" then E:Diagnostics()
        elseif msg=="probe" then E:ToggleProbe()
        elseif msg=="test" then E:TestPhase("start")
        elseif msg=="test frame" then E:TestPhase("frame")
        elseif msg=="test world" then E:TestPhase("world")
        elseif msg=="test stop" then E:TestPhase("stop")
        elseif msg=="report" then E:ShowTestReport()
        else E:ToggleSettings() end
    end
    self:RecoverBindings(); self:ImportLegacyContextKeys(); self:InitWorldClicks(events); self:InitCastDiagnostics(events)
    if self.db.diagnostics then self:SetDiagnostics(true) end
    self:Print(E:L("geladen. Einstellungen: /ec oder Minimap-Symbol."))
end
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PARTY_MEMBERS_CHANGED")
events:SetScript("OnEvent",function(a,b,c,d,e,f,g)
    local ev=b or event
    if ev=="PLAYER_LOGIN" or (ev=="PLAYER_ENTERING_WORLD" and not E.initialized) then E:Initialize() end
    if not E.initialized then return end
    E:TraceEvent(ev,c or arg1,d or arg2)
    if E.castEventRegistration and E.castEventRegistration[ev] and ev~="ACTIONBAR_SLOT_CHANGED" then E:DiagnosticFeedback(ev,c or arg1,d or arg2,e or arg3,f or arg4,g or arg5) end
    if ev=="PLAYER_TARGET_CHANGED" then E:DiagnosticFeedback(ev,E:DiagnosticUnit("target")) end
    if ev=="SPELLS_CHANGED" then
        E:TestLog("ZAUBERBUCH", "SPELLS_CHANGED; laufende Eingabe bleibt erhalten")
        E:RefreshSpells(); E:UpdateContextBindings(); E:RequestDiagnosticActionScan()
    elseif ev=="PARTY_MEMBERS_CHANGED" or ev=="PLAYER_ENTERING_WORLD" then
        if ev=="PLAYER_ENTERING_WORLD" then E:StopMiniTest() end
        E:ScanFrames(); E:CancelWorldClicks("Gruppen-/Weltwechsel")
        if ev=="PLAYER_ENTERING_WORLD" then E:RequestDiagnosticActionScan(); E.worldPending={}; E.worldHeld={}; E.worldHover=nil end
    elseif ev=="GLOBAL_MOUSE_DOWN" or ev=="GLOBAL_MOUSE_UP" then
        E.worldMouseEvents=(E.worldMouseEvents or 0)+1
        E:WorldInput(ev=="GLOBAL_MOUSE_DOWN" and "down" or "up",c or arg1,"Global")
    elseif ev=="UPDATE_MOUSEOVER_UNIT" then E:WorldMouseoverChanged()
    elseif ev=="PLAYER_TARGET_CHANGED" then
        E:WorldTargetChanged()
    elseif ev=="UPDATE_BINDINGS" then E:UpdateContextBindings()
    elseif ev=="PLAYER_LOGOUT" then E:RestoreNativeRun(); E:RestoreRunTest(); E:StopMiniTest(); E:SaveProfile(E.db.profile); E:StopWorldTrace("Logout / Reload"); E:RemoveWorldHooks(); E:ReleaseWorldBindings()
    elseif ev=="ACTIONBAR_SLOT_CHANGED" then E:RequestDiagnosticActionScan()
    elseif ev=="UI_ERROR_MESSAGE" then E:DiagnosticFeedback(ev,c or arg1,d or arg2,e or arg3,f or arg4,g or arg5)
    elseif ev=="ADDON_ACTION_BLOCKED" or ev=="ADDON_ACTION_FORBIDDEN" then
        local addon,fn=c or arg1,d or arg2
        E:BlockedAction(addon,fn)
    elseif ev=="PLAYER_STARTED_LOOKING" or ev=="PLAYER_STARTED_TURNING" then E:TestLog("BEWEGUNG",ev) end
end)
events:SetScript("OnUpdate",function(a,b)
    if not E.initialized then return end
    local dt=b or (type(a)=="number" and a) or arg1 or 0
    elapsed=elapsed+dt; scan=scan+dt
    E.lastFrameDuration=dt
    if dt>=.1 and E:CastDiagnosisActive() then E:TestLog("FRAME-PAUSE",math.floor(dt*1000).." ms; Klickgrenze="..math.floor((E.db.world.maxHold or .15)*1000).." ms") end
    if E.spellBookRetry and GetTime()>=E.spellBookRetry and (E.spellBookRetryCount or 0)<20 then
        if E:RefreshSpells() then E:UpdateContextBindings() end
    end
    E:UpdateControlHelp()
    E:UpdateClickTest()
    E:UpdateMiniTest()
    E:UpdateBindingTest()
    E:UpdateRunTest()
    E:UpdateCastDiagnosis()
    E:UpdateWorldTrace(dt)
    E:UpdateWorldPresses()
    if GameTooltip and GameTooltip:IsShown() then E:UpdateNativeTooltip() end
    if elapsed>=0.04 then elapsed=0; E:UpdateSpellMetadata(); E:UpdateContextBindings(); E:RefreshTips(); E:UpdateProbe(); E:UpdateMouseTest() end
    if scan>=2 then scan=0; E:ScanFrames(); E:InitThreatBridge() end
end)
