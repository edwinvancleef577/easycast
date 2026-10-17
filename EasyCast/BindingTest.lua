-- Compare genuine engine binding callbacks, never replay a WorldFrame event.
local E=EasyCast
local action="EASYCASTBINDTEST"
local names={BUTTON1="Links",BUTTON2="Rechts",BUTTON3="Mitte"}
function E:BindingTestStatus(text)
    if self.bindingTestWindow then self.bindingTestWindow.status:SetText(text) end
    self:TestLog("BINDTEST",text)
end
function E:RestoreTestBinding()
    local p=self.bindingTest; if not p or not p.original then return true end
    if GetBindingAction(p.key)==action then
        self:APIStart("SetBinding",p.key.." wiederherstellen")
        local ok,result=pcall(SetBinding,p.key,p.original~="" and p.original or nil)
        self:APIEnd()
        local actual=GetBindingAction(p.key) or ""
        self:TestLog("BINDTEST RESTORE",p.key.." · Lua="..tostring(ok).." · Rückgabe="..tostring(result).." · jetzt="..actual)
        if actual~=p.original then
            self:Print("Testbelegung nicht wiederhergestellt. /reload ausführen; Bericht behalten.")
            return false
        end
    end -- Respect an intervening external change.
    self.db.bindingRecovery[p.key]=nil; p.original=nil
    return true
end
function E:FinishBindingTest(text)
    local p=self.bindingTest; if not p then return end
    if p.inFlight then self:APIEnd(); self:EndCastDiagnosis(p.inFlight.attempt,false); p.inFlight=nil end
    p.mode="idle"; p.press=nil; p.deadline=nil
    local restored=self:RestoreTestBinding()
    if not restored then self:BindingTestStatus("Wiederherstellung fehlgeschlagen. Bitte /reload ausführen; Bericht behalten.")
    elseif text then self:BindingTestStatus(text) end
end
function E:StopBindingTest()
    if self.bindingTest then
        self:FinishBindingTest("Test beendet; ursprüngliche Belegung wiederhergestellt, sofern noch im Besitz von EasyCast.")
        self.bindingTest=nil
        self:CancelWorldClicks("Bindungstest beendet"); self.worldPending={}; self.worldHeld={}; self.worldHeldAt={}
        self:RefreshWorldBindings(); self:RefreshWorldHooks(); self:RefreshTips()
    end
    if self.bindingTestWindow and self.bindingTestWindow:IsShown() then self.bindingTestWindow:Hide() end
end
function E:BindingTestWorldInput(phase,button,source)
    local p=self.bindingTest; if not p then return end
    p.held[button]=phase=="down" and true or nil
    self:TestLog("BINDTEST BEOBACHTUNG",tostring(source).." · "..tostring(button).." / "..tostring(phase).." · löst keinen Zauber aus")
end
function E:ArmBindingTest(key)
    self:FinishBindingTest()
    local p=self.bindingTest; if not p or not names[key] then return end
    if p.original then self:BindingTestStatus("Alte Bindung konnte nicht freigegeben werden. Bitte /reload."); return end
    if not SetBinding or not GetBindingAction then self:BindingTestStatus("Client bietet SetBinding / GetBindingAction nicht an."); return end
    local spell=self.spells["blessing of might"] or self.spells["segen der macht"]
    if not spell then self:BindingTestStatus("Blessing of Might / Segen der Macht nicht gelernt."); return end
    p.key=key; p.spell=spell; p.mode="countdown"; p.readyAt=GetTime()+3; p.deadline=GetTime()+15; p.count=nil
    p.downs=0; p.ups=0
    self:BindingTestStatus("In 3 Sekunden: "..names[key].." wird vorübergehend umbelegt.\nMaus auf freien Boden bewegen. Erst bei BEREIT kurz klicken.")
end
function E:UpdateBindingTest()
    local p=self.bindingTest; if not p then return end
    local now=GetTime()
    if p.inFlight then self:FinishBindingTest("Lua-Fehler beim Zauberaufruf; keine Wiederholung. Bericht prüfen.") end
    if p.deadline and now>=p.deadline then
        self:FinishBindingTest("Zeit abgelaufen. Native Bindung: DOWN="..p.downs.." / UP="..p.ups..".\nBericht enthält Bindungsprüfung und Eingaben.")
    end
    if p.mode=="countdown" then
        local left=math.max(0,math.ceil(p.readyAt-now))
        if left~=p.count then
            p.count=left
            self:BindingTestStatus(left>0 and (names[p.key]..": noch "..left.." s. Maus auf freien Boden bewegen, Tasten loslassen.") or "Warte auf freie Welt und losgelassene Maustasten.")
        end
        if now>=p.readyAt and not next(p.held) and self:IsWorldFocus() and not self:TextInputFocused() and
            not self:PhysicalMouseDown("LeftButton") and not self:PhysicalMouseDown("RightButton") and
            not self:PhysicalMouseDown("MiddleButton") and not (IsMouselooking and IsMouselooking()) then
            p.original=GetBindingAction(p.key) or ""
            self.db.bindingRecovery=self.db.bindingRecovery or {}
            self.db.bindingRecovery[p.key]={action=action,original=p.original}
            self:APIStart("SetBinding",p.key.." = "..action)
            local ok,result=pcall(SetBinding,p.key,action)
            self:APIEnd()
            local actual=GetBindingAction(p.key)
            self:TestLog("BINDTEST SET",p.key.." · vorher="..p.original.." · Lua="..tostring(ok).." · Rückgabe="..tostring(result).." · gelesen="..tostring(actual))
            if not ok or actual~=action then self:FinishBindingTest("Client hat die Testbindung nicht übernommen. Bericht öffnen.")
            else
                p.mode="ready"; p.deadline=now+10
                self:BindingTestStatus("BEREIT: einmal kurz "..names[p.key].." auf freien Boden klicken.\nBeim Loslassen: Blessing of Might auf dich. Kein Gegner nötig.")
            end
        end
    elseif p.mode=="ready" then
        if GetBindingAction(p.key)~=action then self:FinishBindingTest("Bindung wurde von außen geändert. Test beendet.")
        elseif not self.db.enabled or self.worldBlocked then self:FinishBindingTest("EasyCast aus / Client-Sperre: Test beendet.")
        elseif p.press then
            local x,y=GetCursorPosition()
            if (x-p.press.x)^2+(y-p.press.y)^2>64 then p.press.cancelled="Maus gezogen" end
            if now-p.press.time>.5 then p.press.cancelled="Länger als 0,5 Sekunden gehalten" end
        end
    end
    local f=self.bindingTestWindow
    local focus=GetMouseFocus and GetMouseFocus()
    f.live:SetText("Aktuell: "..self:DiagnosticUnit("mouseover").."\nFokus: "..tostring(focus and self:FrameValue(focus,"GetName") or "<kein Name>"))
    f.edges:SetText("Native Tastenbindung: DOWN "..p.downs.." / UP "..p.ups..
        (p.mode=="ready" and (" · noch "..math.max(0,math.ceil(p.deadline-now)).." s") or ""))
end
function EasyCast_BindingTestInput(state)
    local p=E.bindingTest; if not p or p.mode~="ready" then return end
    if GetTime()>=p.deadline or GetBindingAction(p.key)~=action then E:FinishBindingTest("Test abgelaufen / Bindung geändert."); return end
    E:TestLog("BINDTEST NATIV",p.key.." · keystate="..tostring(state).." · "..E:DiagnosticUnit("mouseover"))
    -- A missing phase is evidence, not permission to synthesize a release.
    if state~="down" and state~="up" then E:FinishBindingTest("Native Bindung erreicht, aber DOWN/UP fehlt. Bericht öffnen."); return end
    if state=="down" then
        p.downs=p.downs+1
        if p.press then return end
        if not E:IsWorldFocus() or E:TextInputFocused() then return end
        local x,y=GetCursorPosition(); p.press={time=GetTime(),x=x,y=y}
        E:BindingTestStatus("ECHTES DOWN aus der Tastenbindung. Jetzt loslassen.")
        return
    end
    p.ups=p.ups+1
    local press=p.press; p.press=nil
    if not press then E:FinishBindingTest("UP ohne passendes DOWN. Kein Zauber."); return end
    local x,y=GetCursorPosition()
    local reason=press.cancelled
    if GetTime()-press.time>.5 then reason="Länger als 0,5 Sekunden gehalten" end
    if (x-press.x)^2+(y-press.y)^2>64 then reason="Maus gezogen" end
    if not E:IsWorldFocus() or E:TextInputFocused() then reason="Maus über UI / Texteingabe" end
    if not E.db.enabled or E.worldBlocked or not UnitExists("player") or
        (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) or (SpellIsTargeting and SpellIsTargeting()) then reason="Zauber momentan nicht zulässig" end
    if reason then E:FinishBindingTest("Kein Zauber: "..reason.."."); return end
    p.mode="casting" -- consume before invoking the client; no retry
    E.castOrigin="Bindungstest"; E.castSource="Native Tastenbindung "..p.key
    local attempt=E:BeginCastDiagnosis("player",p.spell); E.castOrigin=nil; E.castSource=nil
    p.inFlight={attempt=attempt}
    E:APIStart("CastSpellByName",p.spell.cast.." · onSelf=1 · native Bindung "..p.key)
    CastSpellByName(p.spell.cast,1)
    E:APIEnd(); E:EndCastDiagnosis(attempt,true); p.inFlight=nil
    E:FinishBindingTest("DOWN und UP über native Bindung erreicht; Selbstzauber aufgerufen.\nBitte Buff prüfen. API-Rückkehr allein bestätigt keinen Erfolg.")
end
function E:ShowBindingTest()
    if self.runTest then self:FinishRunTest("Bitte Lauftest zuerst schließen.",true); return end
    self:StopMiniTest(); self:StopMouseTest(); self:StopClickTest(); self.directClickDrain=nil
    self:StopWorldTrace("Wechsel zum Bindungstest"); self:StopKeyCapture(); self:CloseDropdown(); self:CommitEdits()
    for _,f in ipairs({self.window,self.clickTestWindow or self.window,self.probe or self.window,self.reportWindow or self.window}) do f:Hide() end
    self:SetDiagnostics(true)
    self.bindingTest={mode="idle",held={},downs=0,ups=0}
    self:ReleaseWorldBindings(); self:RefreshWorldHooks(); self:RefreshTips()
    if not self.bindingTestWindow then
        local f=self:Box(UIParent,600,350,"EasyCastBindingTest"); self.bindingTestWindow=f
        f:SetScale(self.window:GetEffectiveScale()/UIParent:GetEffectiveScale()); f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-70)
        f:EnableMouse(true); f:SetClampedToScreen(true)
        self:Heading(f,"EasyCast · Echte Tastenbindung",16,10)
        f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); self:RegisterHelp(f.close,"Schließen","Schließt dieses Testfenster und beendet seinen Test."); f.close:SetWidth(32); f.close:SetHeight(32)
        f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2); f.close:SetScript("OnClick",function() E:StopBindingTest() end)
        local hint=self:Text(f,11,"1. Blessing-Buff entfernen, globale Abklingzeit abwarten.\n2. Links testen wählen, Maus auf freien Boden bewegen.\n3. Bei BEREIT kurz links klicken und prüfen, ob der Buff erscheint.\nAuswahl/Kamera der Testtaste pausieren für höchstens 10 Sekunden.")
        hint:SetWidth(568); self:Place(hint,f,16,43)
        for i,key in ipairs({"BUTTON1","BUTTON2","BUTTON3"}) do
            local selected=key
            f[key]=self:Place(self:Button(f,180,names[key].." testen",function() E:ArmBindingTest(selected) end),f,16+(i-1)*194,118)
        end
        f.status=self:Text(f,12); f.status:SetWidth(568); f.status:SetHeight(54); f.status:SetJustifyV("TOP"); self:Place(f.status,f,16,158)
        f.live=self:Text(f,11); f.live:SetWidth(568); f.live:SetHeight(40); self:Place(f.live,f,16,219)
        f.edges=self:Text(f,11); f.edges:SetWidth(568); self:Place(f.edges,f,16,272)
        self:Place(self:Button(f,180,"Abbrechen",function() E:FinishBindingTest("Abgebrochen; Testbindung freigegeben.") end),f,16,310)
        self:Place(self:Button(f,180,"Bericht",function() E:FinishBindingTest(); E:ShowTestReport() end),f,210,310)
        self:Place(self:Button(f,180,"Schließen",function() E:StopBindingTest() end),f,404,310)
        f:SetScript("OnHide",function() E:StopBindingTest() end); table.insert(UISpecialFrames,"EasyCastBindingTest")
    end
    self:RaiseDiagnostics(self.bindingTestWindow,true); self.bindingTestWindow:Show()
    self:BindingTestStatus("Zuerst Links testen. Danach Mitte als Vergleich.\nKeine Klickfläche über der Welt; kein Gegner nötig.")
    self:UpdateBindingTest()
end
