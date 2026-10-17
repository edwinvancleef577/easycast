local E=EasyCast
function E:TestLog(event,detail)
    local t=self.db and self.db.diagnosticTest
    if not t or not t.active then return end
    table.insert(t.entries,string.format("%.3f",GetTime()-t.started).." ["..t.phase.."] "..event.." "..tostring(detail or ""))
    local limit=t.worldTrace and 1200 or 600
    if table.getn(t.entries)>limit then table.remove(t.entries,1); t.dropped=(t.dropped or 0)+1 end
end
function E:APIStart(name,detail)
    self.apiStack=self.apiStack or {}; table.insert(self.apiStack,name)
    self.activeAPI=name; self.lastAPI=name
    if name~="SetBinding" then self:TestLog("API >",name.." · "..tostring(detail or "")) end
end
function E:APIEnd()
    if self.activeAPI~="SetBinding" then self:TestLog("API <",self.activeAPI or "?") end
    if self.apiStack then table.remove(self.apiStack); self.activeAPI=self.apiStack[table.getn(self.apiStack)] else self.activeAPI=nil end
end
function E:TestSuppressCast()
    if self.runTest then return true end
    if self.miniTest or self.bindingTest then return true end
    if self.mouseTest then return true end
    if self.traceCastingPaused then return true end
    local t=self.db and self.db.diagnosticTest
    if not t or not t.active then return false end
    if t.phase=="live" then return false end
    if t.phase=="passiv" then return true end
    if t.phase=="frame" then return self.castOrigin~="Unitframe" end
    if t.phase=="world" then return self.castOrigin~="Welt" end
    return true
end
function E:TestPhase(phase)
    self:StopMiniTest()
    self.traceCastingPaused=nil
    if self.traceRunning then self:StopWorldTrace("Wechsel zum Zauber-Diagnosetest") end
    if phase=="start" then
        self.db.diagnosticTest={active=true,phase="passiv",started=GetTime(),entries={},version=self.version}
        self:TestLog("UMGEBUNG",(GetBuildInfo and GetBuildInfo() or "Build unbekannt")..
            " · Mausstatus="..tostring(type(IsMouseButtonDown)).." · CastAtUnit="..tostring(C_Spell and type(C_Spell.CastAtUnit)))
        self:TestLog("EINSTELLUNG","Addon="..tostring(self.db.enabled).." · Welt="..tostring(self.db.world.enabled))
        for kind,bindings in pairs(self.db.bindings) do
            for key,spell in pairs(bindings) do self:TestLog("SPRÜCHE",kind.." · "..key.."="..self:BindingLabel(spell).." · gelernt="..tostring(self:Resolve(spell)~=nil)) end
        end
        for _,b in ipairs(self.buttons) do self:TestLog("BINDUNG",b[2].."="..tostring(GetBindingAction and GetBindingAction(self.worldKeyNames[b[1]]))) end
    else
        local t=self.db.diagnosticTest
        if not t or not t.active then self:Print("Zuerst /ec test starten."); return end
        if phase=="stop" then self:TestLog("ENDE","Test beendet"); t.active=false; self:Print("Test gespeichert. /ec report öffnet den Bericht."); return end
        self:CancelWorldClicks("Testphase gewechselt"); t.phase=phase
    end
    local help={passiv="Nur beobachten, keine EasyCast-Zauber. Gegner wählen, kurz klicken, dann ziehen. Weiter: /ec test frame",
        frame="Gleicher Spruch auf Zielrahmen. Danach: /ec test world",
        world="Gleicher Spruch in der Welt: anderer Gegner auswählen, kurz klicken, ziehen, halten. Danach: /ec test stop"}
    if phase=="start" then self:LogCastDiagnosticSetup() end
    self:TestLog("PHASE",phase)
    self:Print(help[self.db.diagnosticTest.phase] or "Testphase geändert")
end
function E:BlockedAction(addon,fn)
    if addon~="EasyCast" then self:TestLog("ANDERES ADDON GESPERRT",tostring(addon).." · "..tostring(fn)); return end
    self.worldBlocked=tostring(fn or self.activeAPI or "unbekannte Funktion")
    self.lastBlock={name=self.worldBlocked,api=self.activeAPI or "kein aktiver instrumentierter Aufruf",
        lastAPI=self.lastAPI or "keiner",origin=self.castOrigin or "Eingabe / Konfiguration"}
    self:TestLog("CLIENT-SPERRE",self.lastBlock.name.." · aktiv="..self.lastBlock.api.." · Weg="..self.lastBlock.origin)
    if debugstack then
        local ok,stack=pcall(debugstack,2,8,0)
        if ok then self:TestLog("STACK",stack) end
    end
    self:CancelWorldClicks("Client-Sperre: "..self.worldBlocked)
    self:Print("Client blockiert "..self.worldBlocked..". Weltzauber pausiert; /ec report zeigt den Bericht.")
end
function E:TestReport()
    local t=self.db.diagnosticTest
    local lines={"EasyCast "..self.version.." · Diagnosetest",
        "Kamera-Aufrufe in dieser Aufnahme: "..tostring(t and t.cameraCalls or 0).." · RunBinding-Aufrufe: keine",
        "Client-Sperre: "..(self.worldBlocked or "in dieser Sitzung nicht gemeldet"),
        "Hinweis: API-Rückkehr beweist keinen erfolgreichen Zauber.",
        "Ein nicht gemeldetes Sperrereignis beweist nicht, dass keine Sperre aufgetreten ist.",
        "Ein vorhandener Bericht bleibt über /reload erhalten; /ec record on startet neu.",
        "Reichweiten-Leistenabfrage: 1=in Reichweite laut Client; 0=außerhalb; nil=keine Aussage. Kein Entfernungsmesswert.",
        "CLIENT-Zeilen stammen vom Client/UI. Letzter EC-Versuch bezeichnet nur zeitliche Nähe, keine bewiesene Zuordnung.",
        "SetBinding-Einzelaufrufe ausgeblendet; Sperrereignisse behalten die aktive API."}
    if self.inputHistory and table.getn(self.inputHistory)>0 then
        table.insert(lines,"LETZTE EINGABEN (auch ohne Aufnahme; Alter relativ zum Bericht):")
        for _,r in ipairs(self.inputHistory) do
            table.insert(lines,"vor "..string.format("%.2f",GetTime()-r.time).." s · "..self:InputRecordText(r)..
                (r.duration and " · "..math.floor(r.duration*1000).." ms / "..string.format("%.1f",r.movement).." px" or ""))
        end
    end
    if self.lastBlock then table.insert(lines,"Aktiv bei Sperre: "..self.lastBlock.api.." · "..self.lastBlock.origin) end
    if t and t.worldTrace then
        table.insert(lines,"WorldFrame-Test: EasyCast selbst zaubert nicht; vorhandene Handler werden direkt aufgerufen.")
        table.insert(lines,"Kein Overlay. Beobachtetes Nichtauftreten ist kein Beweis für fehlende Unterstützung.")
        table.insert(lines,"Verworfene Zeilen: "..tostring(t.dropped or 0))
        if t.finished then table.insert(lines,"Dauer: "..string.format("%.2f",t.finished).." s") end
        local down,up=0,0
        for k,v in pairs(t.counts or {}) do
            if string.find(k,"WorldFrame/OnMouseDown/",1,true) then down=down+v end
            if string.find(k,"WorldFrame/OnMouseUp/",1,true) then up=up+v end
        end
        table.insert(lines,"WorldFrame Down/Up: "..down.."/"..up)
        local keys={}; for k in pairs(t.counts or {}) do table.insert(keys,k) end; table.sort(keys)
        for _,k in ipairs(keys) do table.insert(lines,"ZÄHLER "..k.." = "..t.counts[k]) end
    end
    if t then
        table.insert(lines,"Verworfene alte Protokollzeilen: "..tostring(t.dropped or 0))
        table.insert(lines,"Testversion: "..tostring(t.version).." · Phase: "..tostring(t.phase))
        for _,line in ipairs(t.entries) do table.insert(lines,line) end
    else table.insert(lines,"Noch kein Test. Mit /ec test beginnen.") end
    return table.concat(lines,"\n")
end
function E:ShowTestReport(customReport)
    if not self.reportWindow then
        local f=self:Box(UIParent,800,530,"EasyCastTestReport")
        f:SetPoint("CENTER",UIParent,"CENTER",0,0); self:RaiseDiagnostics(f,false); f:EnableMouse(true)
        local title=self:Text(f,13,"EasyCast · Testbericht · Strg+A, Strg+C zum Kopieren")
        title:SetPoint("TOPLEFT",f,"TOPLEFT",16,-14)
        local scroll=CreateFrame("ScrollFrame","EasyCastTestReportScroll",f,"UIPanelScrollFrameTemplate")
        self:RegisterScrollHelp("EasyCastTestReportScroll")
        scroll:SetPoint("TOPLEFT",f,"TOPLEFT",16,-42); scroll:SetWidth(742); scroll:SetHeight(424)
        local edit=self:Edit(scroll,730,424); edit:SetMultiLine(true); edit:SetMaxLetters(0)
        edit:SetScript("OnEscapePressed",function() edit:ClearFocus(); f:Hide() end)
        scroll:SetScrollChild(edit); f.edit=edit
        local close=self:Button(f,100,"Schließen",function() f:Hide() end); close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-16,16)
        table.insert(UISpecialFrames,"EasyCastTestReport"); self.reportWindow=f
    end
    local f=self.reportWindow; local report=customReport or self:TestReport()
    local _,lines=string.gsub(report,"\n","\n")
    f.edit:SetText(report); f.edit:SetHeight(math.max(424,lines*28+180))
    self:RaiseDiagnostics(f,false); f:Show(); f.edit:SetFocus(); f.edit:HighlightText()
end
