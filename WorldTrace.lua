-- Observational test only. No spells, camera calls, or input replay.
local E=EasyCast
local scripts={"OnMouseDown","OnMouseUp"}
local function clean(v)
    return string.sub(string.gsub(tostring(v or "<nil>"),"[\r\n]"," / "),1,180)
end
local function read(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,unpack(arg))
    if ok then return value end
    return "<Lesefehler>"
end
function E:TraceUnit(unit)
    if not UnitExists(unit) then return "<keines>" end
    return clean(UnitName(unit)).." ["..tostring(self:Kind(unit) or "neutral")..
        "; id="..tostring(self:UnitGUIDValue(unit) or "nicht verfügbar")..
        "; target="..tostring(UnitIsUnit(unit,"target") and true or false)..
        "; player="..tostring(UnitIsUnit(unit,"player") and true or false).."]"
end
function E:TraceSnapshot()
    local focus=self:FocusDetails()
    local tip=GameTooltip
    local shown=self:FrameValue(tip,"IsShown")
    local visible=self:FrameValue(tip,"IsVisible")
    local owner=self:FrameValue(tip,"GetOwner")
    local tipUnit="API fehlt"
    if tip and type(tip.GetUnit)=="function" then
        local ok,name,unit=pcall(tip.GetUnit,tip)
        tipUnit=ok and (clean(name).." / "..clean(unit)) or "Lesefehler"
    end
    local lines={}
    for i=1,3 do
        local fs=getglobal("GameTooltipTextLeft"..i)
        table.insert(lines,clean(self:FrameValue(fs,"GetText")))
    end
    local mouse=self:TraceUnit("mouseover")
    local target=self:TraceUnit("target")
    local looking=read(IsMouselooking)
    local held={}
    if IsMouseButtonDown then
        for _,b in ipairs(self.buttons) do
            if read(IsMouseButtonDown,b[1]) then table.insert(held,b[1]) end
        end
    else table.insert(held,"API fehlt") end
    local x,y=GetCursorPosition()
    local detail="mouse="..mouse.." · target="..target.." · Fokus="..clean(focus.path)..
        " · Kamera="..tostring(looking).." · Tasten="..table.concat(held,",").." · Mod="..self:Key("")..
        " · Tooltip shown/visible="..tostring(shown).."/"..tostring(visible)..
        " · Besitzer="..clean(self:FrameValue(owner,"GetName")).." · TooltipUnit="..tipUnit..
        " · Text="..table.concat(lines," | ")
    local compact="Maus: "..mouse.."\nZiel: "..target.."\nFokus: "..clean(focus.path)..
        "\nKamera: "..tostring(looking).." · Tooltip sichtbar: "..tostring(visible).."\nTooltip: "..lines[1]
    return detail,string.format(" · XY=%.1f,%.1f",x or 0,y or 0),compact
end
function E:TraceCapture(label,force)
    if not self.traceRunning then return end
    local detail,xy,compact=self:TraceSnapshot()
    self.traceCompact=compact
    if force or detail~=self.traceLastState then
        self.traceLastState=detail
        self:TestLog(label,detail..xy)
    end
end
function E:TraceSafeCapture(label,force)
    local ok,err=pcall(self.TraceCapture,self,label,force)
    if not ok then self:TestLog("DIAGNOSE-LESEFEHLER",clean(err)) end
end
function E:TraceInput(phase,button,source)
    if not self.traceRunning then return end
    local t=self.db.diagnosticTest
    local key=source.."/"..phase.."/"..tostring(button)
    t.counts[key]=(t.counts[key] or 0)+1
    self.traceLastInput=source.." "..phase.." "..tostring(button)
    self:TraceSafeCapture("EINGABE "..self.traceLastInput,true)
end
function E:TraceHook(script)
    local original=WorldFrame:GetScript(script)
    local entry={original=original,enabled=true}
    self.traceHooks[script]=entry
    entry.wrapper=function(...)
        -- WoW 1.12 uses the global this/arg1; newer environments can pass args.
        local button=(type(arg[1])=="string" and arg[1]) or arg[2] or arg1
        local active=E.traceRunning and entry.enabled
        if active then
            E.traceSequence=E.traceSequence+1
            E:TraceInput(script,button,"WorldFrame")
            E:TestLog("AUFRUF",tostring(E.traceSequence).." · "..script)
            E:TestLog("ORIGINAL >",script.." · vorhanden="..tostring(original~=nil))
            E.traceOriginal=script
        end
        -- Direct call, exactly once; original errors are not swallowed.
        if original then original(unpack(arg)) end
        if active then
            E.traceOriginal=nil
            E:TestLog("ORIGINAL <",script)
            E:TraceSafeCapture("NACH "..script,true)
            E.traceNextFrame=true
        end
    end
    self:TestLog("HOOK >",script.." · Original="..tostring(original))
    self.traceOperation="WorldFrame:SetScript("..script..")"
    local ok,err=pcall(WorldFrame.SetScript,WorldFrame,script,entry.wrapper)
    self.traceOperation=nil
    local installed=ok and WorldFrame:GetScript(script)==entry.wrapper
    self:TestLog("HOOK <",script.." · installiert="..tostring(installed)..(ok and "" or " · "..clean(err)))
    return installed
end
function E:TraceUnhook()
    for _,script in ipairs(scripts) do
        local entry=self.traceHooks and self.traceHooks[script]
        if entry then
            entry.enabled=false
            if WorldFrame:GetScript(script)==entry.wrapper then
                local ok,err=pcall(WorldFrame.SetScript,WorldFrame,script,entry.original)
                self:TestLog("HOOK ENTFERNT",script.." · ok="..tostring(ok)..(ok and "" or " · "..clean(err)))
            else
                self:TestLog("HOOK NICHT ÜBERSCHRIEBEN",script.." · inzwischen von anderem Code ersetzt; eigener Wrapper inaktiv")
            end
        end
    end
    self.traceHooks=nil
end
function E:TraceShowPanel()
    if not self.tracePanel then
        local f=self:Box(UIParent,650,200,"EasyCastTracePanel")
        f:SetPoint("TOP",UIParent,"TOP",0,-65)
        self:RaiseDiagnostics(f,true); f:EnableMouse(false)
        f.text=self:Text(f,11,"")
        f.text:SetPoint("TOPLEFT",f,"TOPLEFT",10,-10)
        f.text:SetWidth(630); f.text:SetHeight(180)
        if f.text.SetJustifyV then f.text:SetJustifyV("TOP") end
        self.tracePanel=f
    end
    self.tracePanel:Show()
end
function E:StartWorldTrace()
    if self.runTest then self:FinishRunTest("Bitte Lauftest zuerst schließen.",true); return end
    self:StopMiniTest()
    self:StopMouseTest()
    self:StopClickTest()
    if self.traceRunning then self:Print("Test läuft. /ec trace hook aktiviert die WorldFrame-Handler; /ec trace stop beendet ihn."); return end
    self:CancelWorldClicks("Diagnose gestartet"); self.worldPending={}; self.worldHeld={}
    self.db.diagnosticTest={active=true,phase="trace-passiv",started=GetTime(),entries={},version=self.version,
        worldTrace=true,counts={},dropped=0}
    self.traceRunning=true; self:RefreshWorldHooks(); self:ReleaseWorldBindings(); self.traceCastingPaused=true; self.traceSequence=0; self.traceLastState=nil; self.traceLastInput="noch keine"
    self.traceOriginal=nil; self.traceOperation=nil; self.traceNextFrame=nil; self.traceAbort=nil
    self.traceElapsed=0; self.traceAudit=0
    if self.window then self.window:Hide() end
    if self.reportWindow then self.reportWindow:Hide() end
    self:TestLog("START","Passiv: keine WorldFrame-Hooks; EasyCast-Zauber gesperrt. Originale WoW-/Fremdaddon-Aktionen bleiben möglich.")
    self:TestLog("UMGEBUNG",clean(GetBuildInfo and GetBuildInfo()).." · ClassicAPI="..tostring(CLASSIC_API_VERSION)..
        " · SuperWoW="..tostring(SUPERWOW_VERSION).." · Mausstatus="..type(IsMouseButtonDown)..
        " · Mausfokus="..type(GetMouseFocus).." · CastAtUnit="..type(C_Spell and C_Spell.CastAtUnit))
    self:TestLog("EINSTELLUNGEN","Addon="..tostring(self.db.enabled).." · Welt="..tostring(self.db.world.enabled)..
        " · Friendly-Standardtooltip-aus="..tostring(self:HideDefaultTip("friendly",true)))
    for _,b in ipairs(self.buttons) do self:TestLog("BINDUNG",b[1].."="..tostring(GetBindingAction(self.worldKeyNames[b[1]]))) end
    for _,s in ipairs(scripts) do self:TestLog("HANDLER",s.."="..tostring(WorldFrame:GetScript(s))) end
    for ev,ok in pairs(self.worldEventRegistration or {}) do self:TestLog("EVENT-REGISTRIERUNG",ev.."="..tostring(ok).." (keine Zustellgarantie)") end
    self:TraceSafeCapture("ANFANG",true); self:TraceShowPanel()
    self:Print("Diagnose PASSIV (max. 120 s): Gegner anklicken und Kamera ziehen. Danach /ec trace hook. Bericht: /ec report.")
end
function E:EnableWorldTraceHooks()
    if not self.traceRunning then self:Print("Zuerst /ec trace starten."); return end
    if self.traceHooks then self:Print("WorldFrame-Hooks sind bereits aktiv."); return end
    self.db.diagnosticTest.phase="trace-hook"
    self.traceHooks={}
    self:TestLog("PHASE","WorldFrame-Hooks werden installiert; weiterhin keine EasyCast-Zauber.")
    for _,s in ipairs(scripts) do
        if not self:TraceHook(s) or self.traceAbort then self:StopWorldTrace("Hook-Installation abgebrochen"); return end
    end
    self:Print("Diagnose HOOK: dieselben Klicks und Kamerazüge wiederholen. /ec trace stop, dann /ec report.")
end
function E:StopWorldTrace(reason)
    if not self.traceRunning then return end
    self:TraceUnhook()
    self:TraceSafeCapture("ENDE-ZUSTAND",true)
    self:TestLog("ENDE",reason or "Manuell beendet")
    local t=self.db.diagnosticTest
    t.active=false; t.finished=GetTime()-t.started
    self.traceRunning=false; self.traceCastingPaused=nil; self.traceOriginal=nil; self.traceOperation=nil
    self:CancelWorldClicks("Diagnose beendet"); self.worldPending={}; self.worldHeld={}; self.polledButtons={}
    self:RefreshWorldHooks(); self:RefreshWorldBindings()
    if self.tracePanel then self.tracePanel:Hide() end
    self:Print("Trockenlauf beendet. Normale EasyCast-Einstellungen wieder aktiv. Bericht: /ec report. Eine gemeldete Client-Sperre bleibt bestehen.")
end
function E:TraceEvent(ev,a,b)
    if not self.traceRunning then return end
    if ev=="ADDON_ACTION_BLOCKED" or ev=="ADDON_ACTION_FORBIDDEN" then
        self:TestLog("SPERRE",ev.." · Addon="..clean(a).." · Funktion="..clean(b)..
            " · Operation="..tostring(self.traceOperation).." · Originalhandler="..tostring(self.traceOriginal))
        self.traceAbort="Client-Sperrereignis: "..tostring(a).." / "..tostring(b)
    end
    self:TraceSafeCapture("EVENT "..tostring(ev).." "..clean(a).." "..clean(b),true)
end
function E:UpdateWorldTrace(dt)
    if not self.traceRunning then return end
    local t=self.db.diagnosticTest
    if self.traceAbort or GetTime()-t.started>=120 or table.getn(t.entries)>=1100 then
        self:StopWorldTrace(self.traceAbort or "Zeit-/Protokolllimit erreicht"); return
    end
    if self.traceNextFrame then self.traceNextFrame=nil; self:TraceSafeCapture("NÄCHSTES UPDATE",true) end
    self.traceElapsed=self.traceElapsed+(dt or 0)
    if self.traceElapsed<0.05 then return end
    self.traceElapsed=0
    self:TraceSafeCapture("ZUSTAND",false)
    if self.traceHooks then
        for _,s in ipairs(scripts) do
            local h=self.traceHooks[s]
            if h and WorldFrame:GetScript(s)~=h.wrapper and not h.replaced then
                h.replaced=true; self:TestLog("HANDLER GEWECHSELT",s.." · fremder Handler; kein erneutes Überschreiben")
            end
        end
    end
    local remaining=math.max(0,120-math.floor(GetTime()-t.started))
    if self.tracePanel then self.tracePanel.text:SetText("EasyCast "..self.version.." · "..t.phase.." · "..remaining.." s\n"..
        "EasyCast-Zauber AUS · /ec trace hook · /ec trace mark TEXT · /ec trace stop\n"..
        "Letzte Eingabe: "..self.traceLastInput.."\n"..(self.traceCompact or "").."\n"..
        "Ereignisse: "..table.getn(t.entries).." · WorldFrame-Aufrufe: "..self.traceSequence) end
end
