-- Isolated experiment: genuine hardware input executes Blizzard's MOVEFORWARD.
-- Never call movement functions, RunBinding or synthetic button clicks here.
local E=EasyCast
local rightAction="EASYCASTRUNTEST"
function E:RunTestStatus(text)
    if self.runTestWindow then self.runTestWindow.status:SetText(text) end
    self:TestLog("LAUFTEST",text)
end
function E:SetRunTestKey(key,action)
    local p=self.runTest; if not p then return false end
    local old=GetBindingAction(key) or ""
    if not p.saved[key] then p.saved[key]={original=old} end
    local entry=p.saved[key]
    if entry.action and old~=entry.action then
        self:RunTestStatus("Belegung von außen geändert: "..key..". Test abbrechen."); return false
    end
    -- Record recovery before mutation; UPDATE_BINDINGS can fire synchronously.
    entry.action=action
    self.db.bindingRecovery[key]={original=entry.original,action=action}
    self:APIStart("SetBinding",key.." = "..action.." / Lauftest")
    local ok,result=pcall(SetBinding,key,action); self:APIEnd()
    local actual=GetBindingAction(key) or ""
    self:TestLog("LAUFTEST BINDUNG",key.." · vorher="..old.." · jetzt="..actual.." · Lua="..tostring(ok).." · Rückgabe="..tostring(result))
    return ok and actual==action
end
function E:RestoreRunTest()
    local p=self.runTest; if not p then return true end
    local restored=true
    for key,entry in pairs(p.saved) do
        if GetBindingAction(key)==entry.action then
            self:APIStart("SetBinding",key.." / Lauftest wiederherstellen")
            local ok=pcall(SetBinding,key,entry.original~="" and entry.original or nil); self:APIEnd()
            if not ok or (GetBindingAction(key) or "")~=entry.original then restored=false end
        end
        if restored or GetBindingAction(key)~=entry.action then self.db.bindingRecovery[key]=nil end
    end
    if restored then p.saved={} end
    return restored
end
function E:FinishRunTest(text,close)
    local p=self.runTest; if not p then return end
    p.cancel=true; p.close=close or p.close
    p.finishText=text or "Test beendet."
    self:RunTestStatus("Beide Maustasten loslassen. Belegungen bleiben bis zum Loslassen erhalten.\nFalls du weiterläufst: normale Vorwärts-Taste kurz drücken und loslassen.")
end
function E:RunTestInput(phase,button,source)
    local p=self.runTest
    if not p or (button~="LeftButton" and button~="RightButton") then return end
    local was=p.held[button]
    p.held[button]=phase=="down" and true or nil
    if (phase=="down" and not was) or (phase=="up" and was) then
        self:TestLog("LAUFTEST EINGABE",source.." · "..button.." / "..phase.." · L="..tostring(GetBindingAction("BUTTON1")).." · R="..tostring(GetBindingAction("BUTTON2")))
    end
    if p.cancel or (p.mode~="ready" and p.mode~="active") then return end
    if phase=="down" and button=="LeftButton" and p.leftArmed and not p.started then
        if not self:IsWorldFocus() or self:Key("")~="" then self:FinishRunTest("UI / Zusatztaste: Test abgebrochen."); return end
        p.started=true; p.mode="active"
        if p.variant~="single" then
            -- This is the actual experiment: does the engine use this new
            -- binding for RIGHT UP, or its original DOWN binding?
            if not self:SetRunTestKey("BUTTON2","MOVEFORWARD") then self:FinishRunTest("Rechte Testbelegung fehlgeschlagen."); return end
        end
        self:RunTestStatus(p.variant=="single" and "LINKS gedrückt. Läufst du? Jetzt Links loslassen: stoppt es?" or
            (p.variant=="leftup" and "Beide gedrückt. Jetzt NUR LINKS loslassen, rechts weiter halten.\nStoppt der Charakter? Danach auch rechts loslassen." or
            "Beide gedrückt. Jetzt NUR RECHTS loslassen, links weiter halten.\nStoppt der Charakter? Danach auch links loslassen."))
    elseif phase=="up" and p.started then
        if not p.firstUp then
            p.firstUp=button
            self:TestLog("LAUFTEST ERSTES LOSLASSEN",button.." · Bewegung bitte selbst prüfen; keine Erfolgserkennung")
        end
        if not next(p.held) then p.finished=true; p.releasedAt=p.releasedAt or GetTime() end
    end
end
function EasyCast_RunTestInput(state)
    local p=E.runTest; if not p then return end
    E:RunTestInput(state,"RightButton","Native Testbindung")
    E:TestLog("LAUFTEST NATIV RECHTS",tostring(state).." · aktuell="..tostring(GetBindingAction("BUTTON2")))
    if state=="down" and p.mode=="ready" and not p.cancel and p.variant~="single" and not p.leftArmed then
        if not E:IsWorldFocus() or E:Key("")~="" then E:FinishRunTest("Bitte ohne Zusatztasten auf freien Boden klicken."); return end
        p.leftArmed=E:SetRunTestKey("BUTTON1","MOVEFORWARD")
        if p.leftArmed then E:RunTestStatus("RECHTS erkannt. Weiter halten und jetzt LINKS dazudrücken.")
        else E:FinishRunTest("Linke Testbelegung fehlgeschlagen.") end
    elseif state=="up" and not p.started and p.leftArmed then E:FinishRunTest("Rechts ohne Links losgelassen; kein Lauftest.") end
end
function E:ArmRunTest(variant)
    local p=self.runTest
    if not p or next(p.saved) then self:RunTestStatus("Erst beide Tasten loslassen und laufenden Test beenden."); return end
    p.variant=variant; p.mode="countdown"; p.readyAt=GetTime()+3; p.deadline=GetTime()+18
    p.cancel=nil; p.close=nil; p.started=nil; p.finished=nil; p.firstUp=nil; p.releasedAt=nil; p.leftArmed=nil; p.count=nil
    self:RunTestStatus("In 3 Sekunden bereit. Maus auf freien Boden bewegen.\nKeine Zusatztasten halten. Ein Gegner darf ausgewählt sein, ist aber nicht nötig.")
end
function E:UpdateRunTest()
    local p=self.runTest; if not p then return end
    local now=GetTime()
    for _,b in ipairs({"LeftButton","RightButton"}) do
        if p.held[b] and self:PhysicalMouseState(b)==false then self:RunTestInput("up",b,"Mausstatus") end
    end
    if p.mode=="countdown" and now>=p.readyAt and not next(p.held) and
        not self:PhysicalMouseDown("LeftButton") and not self:PhysicalMouseDown("RightButton") and
        self:IsWorldFocus() and self:Key("")=="" and not (IsMouselooking and IsMouselooking()) and not p.cancel then
        p.mode="ready"
        if p.variant=="single" then
            p.leftArmed=self:SetRunTestKey("BUTTON1","MOVEFORWARD")
            if not p.leftArmed then self:FinishRunTest("Linke Testbelegung fehlgeschlagen.")
            else self:RunTestStatus("BEREIT: Links auf freiem Boden drücken, kurz halten und loslassen.\nPrüfen: Läuft der Charakter und stoppt er beim Loslassen?") end
        elseif self:SetRunTestKey("BUTTON2",rightAction) then
            self:RunTestStatus("BEREIT: Rechts auf freiem Boden drücken und halten. Dann Links dazudrücken.\n"..(p.variant=="leftup" and "Anschließend LINKS zuerst loslassen." or "Anschließend RECHTS zuerst loslassen."))
        else self:FinishRunTest("Rechte Testbelegung fehlgeschlagen.") end
    end
    if p.deadline and now>=p.deadline and not p.cancel and not p.finished then self:FinishRunTest("Zeit abgelaufen.") end
    if self.worldBlocked and not p.cancel then self:FinishRunTest("Client-Sperre: Bericht öffnen.") end
    if p.cancel or p.finished then
        if not next(p.held) and not self:PhysicalMouseDown("LeftButton") and not self:PhysicalMouseDown("RightButton") then
            p.releasedAt=p.releasedAt or now
            -- Never restore from the UP observer itself: let native UP finish.
            if now-p.releasedAt>=.1 then
                if self:RestoreRunTest() then
                    p.mode="idle"; p.cancel=nil; p.finished=nil; p.deadline=nil; p.releasedAt=nil
                    self:RunTestStatus((p.finishText or "Beide Tasten losgelassen; Belegungen wiederhergestellt.").."\nBitte unten das beobachtete Ergebnis wählen.")
                    p.finishText=nil
                    if p.close then
                        self.runTest=nil; self:RefreshWorldBindings(); self:RefreshWorldHooks(); self:RefreshTips(); return
                    end
                else self:RunTestStatus("Belegung konnte nicht wiederhergestellt werden. Beide Tasten loslassen, dann /reload.") end
            end
        else p.releasedAt=nil end
    end
    if self.runTestWindow then
        self.runTestWindow.live:SetText("Links: "..(p.held.LeftButton and "UNTEN" or "oben").." | "..tostring(GetBindingAction("BUTTON1"))..
            "\nRechts: "..(p.held.RightButton and "UNTEN" or "oben").." | "..tostring(GetBindingAction("BUTTON2"))..
            "\nErstes Loslassen: "..tostring(p.firstUp or "—").." · Bewegungserfolg wird nicht automatisch erkannt.")
    end
end
function E:RunTestAnswer(answer)
    local p=self.runTest; if not p or p.mode~="idle" or not p.variant then return end
    self:TestLog("LAUFTEST NUTZER",p.variant.." · zuerst="..tostring(p.firstUp).." · "..answer)
    self:RunTestStatus("Gespeichert: "..answer.."\nNächsten Test wählen oder Bericht öffnen.")
end
function E:ShowRunTest()
    if self.runTest then self.runTest.close=nil; self.runTestWindow:Show(); return end
    self:StopBindingTest(); self:StopMiniTest(); self:StopMouseTest(); self:StopClickTest(); self:StopWorldTrace("Lauftest")
    self:StopKeyCapture(); self:CloseDropdown(); self:CommitEdits(); self.window:Hide()
    self:SetDiagnostics(true); self:ReleaseWorldBindings()
    self.runTest={mode="idle",saved={},held={}}; self:RefreshWorldHooks()
    if not self.runTestWindow then
        local f=self:Box(UIParent,660,430,"EasyCastRunTest"); self.runTestWindow=f
        f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-70); f:EnableMouse(true); f:SetClampedToScreen(true)
        self:Heading(f,"EasyCast · Laufen mit originaler WoW-Belegung",16,10)
        local hint=self:Text(f,11,"In einem freien, sicheren Bereich testen. EasyCast-Zauber sind während dieses Fensters pausiert.\n1 testen, danach 2 und 3. Auf die Welt klicken, nicht auf das Fenster.\nFalls du weiterläufst: beide Maustasten loslassen und deine Vorwärts-Taste kurz drücken/loslassen.")
        hint:SetWidth(628); self:Place(hint,f,16,45)
        for i,v in ipairs({{"single","1 · Links: Start/Stopp"},{"leftup","2 · Links zuerst loslassen"},{"rightup","3 · Rechts zuerst loslassen"}}) do
            local variant=v[1]; self:Place(self:Button(f,200,v[2],function() E:ArmRunTest(variant) end),f,16+(i-1)*212,112)
        end
        f.status=self:Text(f,12); f.status:SetWidth(628); f.status:SetHeight(86); self:Place(f.status,f,16,152)
        f.live=self:Text(f,11); f.live:SetWidth(628); f.live:SetHeight(66); self:Place(f.live,f,16,244)
        for i,label in ipairs({"Läuft und stoppt richtig","Läuft nach Loslassen weiter","Läuft gar nicht"}) do
            local answer=label; self:Place(self:Button(f,200,label,function() E:RunTestAnswer(answer) end),f,16+(i-1)*212,322)
        end
        self:Place(self:Button(f,200,"Abbrechen",function() E:FinishRunTest("Abgebrochen.") end),f,16,374)
        self:Place(self:Button(f,200,"Bericht",function() E:FinishRunTest("Bericht geöffnet."); E:ShowTestReport() end),f,228,374)
        self:Place(self:Button(f,200,"Schließen",function() f:Hide() end),f,440,374)
        local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetWidth(28); close:SetHeight(28); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2)
        close:SetScript("OnClick",function() f:Hide() end)
        f:SetScript("OnHide",function() E:FinishRunTest("Fenster geschlossen.",true) end)
        table.insert(UISpecialFrames,"EasyCastRunTest")
    end
    self:RaiseDiagnostics(self.runTestWindow,true); self.runTestWindow:Show()
    self:RunTestStatus("Bitte mit Test 1 beginnen. Noch keine Taste umbelegt.")
end
function E:IsRaidMarkerBinding(key)
    local entry=self.contextBindings[key]
    local actual=GetBindingAction(key) or ""
    local action=entry and actual==entry.action and entry.original or actual
    return string.find(action or "","^RAIDTARGET%d+$")~=nil or action=="RAIDTARGETNONE"
end
function E:ShowFunctionKeyReport()
    local lines={"EasyCast · F-Tasten / Zielmarkierungen","Normale RAIDTARGET-Belegungen haben Vorrang vor EasyCast.","Makro-/Addon-Belegungen werden hier zur Prüfung angezeigt; keine Tasten werden geändert."}
    for i=1,12 do
        local key="F"..i; local entry=self.contextBindings[key]
        table.insert(lines,key..": WoW="..tostring(GetBindingAction(key) or "")..(entry and " · vorher="..tostring(entry.original) or "")..
            " · freundlich="..self:BindingLabel(self.db.bindings.friendly[key]).." · feindlich="..self:BindingLabel(self.db.bindings.hostile[key]))
    end
    self:ShowTestReport(table.concat(lines,"\n"))
end
