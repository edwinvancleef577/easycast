-- One-shot comparison using the ordinary WorldFrame/UI callbacks. No binding
-- replacement, camera calls, retries or casts from OnUpdate. The explicit
-- Blessing comparison invokes the same visible button through Button:Click.
local E=EasyCast
function E:ClickTestStatus(text)
    if self.clickTestWindow then self.clickTestWindow.status:SetText(text) end
    self:TestLog("DIREKTTEST",text)
end
function E:BlessingTestVisible()
    return self.clickTestWindow and self.clickTestWindow.selfTest and self.clickTestWindow:IsShown()
end
function E:ButtonTestMethod()
    return type(self.clickTestWindow.reference.Click)=="function" and "Button:Click" or "OnClick-Funktion"
end
function E:StopClickTest(reason)
    local p=self.directClickTest
    if p then self.directClickDrain={button=p.button,untilTime=GetTime()+.3} end
    self.directClickTest=nil
    if reason then self:ClickTestStatus(reason) end
end
function E:ClickTestTarget()
    if not self.db.enabled or not self.db.world.enabled then return nil,"EasyCast und Weltklicks einschalten." end
    if self.worldBlocked then return nil,"Client-Sperre gemeldet; Test abgebrochen." end
    if self:TestSuppressCast() then return nil,"Trockenlauf aktiv; zuerst beenden." end
    local selfCast=self.clickTestWindow and self.clickTestWindow.selfTest
    if not selfCast and not self:AliveEnemy("target") then return nil,"Zuerst einen lebenden Gegner auswählen." end
    if SpellIsTargeting and SpellIsTargeting() then return nil,"Aktive Zauberauswahl zuerst beenden." end
    local text=self.clickTestWindow and self.clickTestWindow.spell:GetText() or ""
    local spell=self.spells[string.lower(self:Trim(text))]
    if not spell then return nil,selfCast and "Blessing of Might / Segen der Macht wurde nicht im Zauberbuch gefunden." or "Gelernten Spruch eingeben, z. B. Crusader Strike." end
    if selfCast and (not UnitExists("player") or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))) then return nil,"Der eigene Charakter muss leben." end
    return {spell=spell,selfCast=selfCast,guid=self:UnitGUIDValue("target"),name=selfCast and UnitName("player") or UnitName("target"),generation=self.targetGeneration}
end
function E:ArmClickTest()
    local p,reason=self:ClickTestTarget()
    if not p then self:ClickTestStatus(reason); return end
    local f=self.clickTestWindow
    if p.selfCast then p.method=self:ButtonTestMethod() end
    p.button=f.testButton; p.phase=f.testPhase; p.expires=GetTime()+10
    if self.worldHeld[p.button] or self:PhysicalMouseDown(p.button) then self:ClickTestStatus("Maustaste zuerst loslassen."); return end
    self:CommitEdits(); f.spell:ClearFocus(); self:CloseDropdown()
    self:CancelWorldClicks("Direkttest"); self.worldPending[p.button]=nil
    self.directClickDrain=nil; self.directClickTest=p
    self.window:Hide(); self:RefreshWorldHooks()
    self:ClickTestStatus("BEREIT: außerhalb des Fensters einmal "..self:KeyLabel(p.button).." auf die Welt klicken.\n"..p.spell.cast.." auf "..p.name.." · "..(p.phase=="down" and "beim Drücken" or "beim Loslassen").." · 10 s Zeit."..(p.selfCast and "\nWeltklick → "..p.method.." → derselbe Button wie A." or ""))
end
function E:ClickTestOwns(button)
    local p=self.directClickTest
    if p and p.button==button then return true end
    local d=self.directClickDrain
    return d and d.button==button and GetTime()<d.untilTime
end
function E:PrepareClickTest(phase,button)
    if not self:ClickTestOwns(button) then return false end
    self:ObserveInput(button,phase,"WorldFrame-Direkttest")
    self:TestLog("DIREKT-EINGABE",button.." / "..phase)
    local p=self.directClickTest
    if not p then return true end
    if GetTime()>p.expires or not self.db.enabled or not self.db.world.enabled or self.worldBlocked or self:TestSuppressCast() then
        self:StopClickTest("Test abgebrochen / Zeit abgelaufen."); return true
    end
    if not self:IsWorldFocus() or self:TextInputFocused() or (ChatFrameEditBox and ChatFrameEditBox:IsShown()) then
        self:StopClickTest("Test abgebrochen: Maus über UI oder Texteingabe."); return true
    end
    if (not p.selfCast and ((not p.guid and self.targetGeneration~=p.generation) or not self:AliveEnemy("target") or
        (p.guid and self:UnitGUIDValue("target")~=p.guid) or UnitName("target")~=p.name)) or
        (p.selfCast and UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) or (SpellIsTargeting and SpellIsTargeting()) then
        self:StopClickTest("Test abgebrochen: Ziel oder Zauberauswahl geändert."); return true
    end
    if phase=="down" then
        p.seenDown=true
        if p.selfCast and p.phase=="up" then self:ClickTestStatus("B: "..self:KeyLabel(button).." DOWN erkannt.\nWarte auf UP; dann wird Button A per "..p.method.." ausgelöst.") end
    end
    if phase=="up" and not p.seenDown then return true end
    local request
    if phase==p.phase and not p.fired then
        p.fired=true
        local source="WorldFrame OnMouse"..(phase=="down" and "Down" or "Up")
        if p.selfCast then request={route="button",spell=p.spell,source=source,button=button,method=p.method}
        else request=self:BeginDirectClickCall(p.spell,source) end
    end
    if phase=="up" then self.directClickTest=nil; self.directClickDrain={button=button,untilTime=GetTime()+.3} end
    return true,request
end
function E:BeginDirectClickCall(spell,source,unit)
    self.castOrigin="Direkttest"; self.castSource=source
    local attempt=self:BeginCastDiagnosis(unit or "target",spell)
    self.castOrigin=nil; self.castSource=nil
    local request={spell=spell,attempt=attempt,selfCast=unit=="player"}
    self.directCallInFlight=request
    self:APIStart("CastSpellByName",spell.cast..(unit=="player" and " · onSelf=1" or "").." · direkt / "..source)
    return request
end
function E:FinishDirectClickCall(request)
    self.directCallInFlight=nil; self:APIEnd(); self:EndCastDiagnosis(request.attempt,true)
    self:ClickTestStatus((request.selfCast and (self.buttonClickRequest and "B: Weltklick → "..self.buttonClickRequest.method.." → OnClick erreicht." or "A: Echter UI-Button → OnClick erreicht.").."\nBlessing of Might: Selbstzauber aufgerufen.\n" or "Direkter API-Aufruf zurückgekehrt.\n").."Bitte Buff prüfen; API-Rückkehr allein bestätigt keinen Zauber.")
end
function E:RunButtonClickTest(request)
    local button=self.clickTestWindow.reference
    if request.method=="Button:Click" and type(button.Click)~="function" then self:StopClickTest("Button:Click inzwischen nicht verfügbar; Test abgebrochen."); return end
    self.buttonClickRequest=request; self.buttonClickInFlight=true
    self:TestLog("BUTTONTEST","B: "..request.source.." → "..request.method)
    self:APIStart(request.method,"Blessing-Vergleich, Weg B")
    if request.method=="Button:Click" then button:Click("LeftButton")
    else button:GetScript("OnClick")() end
    self:APIEnd(); self.buttonClickInFlight=nil; self.buttonClickRequest=nil
    if not request.reached then self:ClickTestStatus("B: "..request.method.." aufgerufen, aber OnClick NICHT erreicht.\nKein Zauberaufruf durch den Testhandler.") end
end
function E:UpdateClickTest()
    -- Cleanup only, including a Lua error from an unwrapped native call.
    if self.directCallInFlight then
        local r=self.directCallInFlight; self.directCallInFlight=nil
        self:APIEnd(); self:EndCastDiagnosis(r.attempt,false); self:StopClickTest("Direkter Aufruf nicht normal zurückgekehrt; Lua-Fehler prüfen.")
    end
    if self.buttonClickInFlight then
        self:APIEnd(); self.buttonClickInFlight=nil; self.buttonClickRequest=nil
        self:StopClickTest("B: Buttonaufruf nicht normal zurückgekehrt. Lua-Fehler prüfen; keine Wiederholung.")
    end
    if self.directClickTest and GetTime()>self.directClickTest.expires then self:StopClickTest("Test beendet: 10 Sekunden abgelaufen.") end
    if self.directClickDrain and GetTime()>=self.directClickDrain.untilTime then self.directClickDrain=nil end
end
function E:ShowClickTest(mode)
    if self.runTest then self:FinishRunTest("Bitte Lauftest zuerst schließen.",true); return end
    self:StopMiniTest()
    self:StopMouseTest()
    self:StopClickTest(); self:StopKeyCapture(); self:CloseDropdown()
    self.window:Hide()
    if self.probe then self.probe:Hide() end
    if self.reportWindow then self.reportWindow:Hide() end
    if not self.clickTestWindow then
        local f=self:Box(UIParent,540,380,"EasyCastClickTest"); self.clickTestWindow=f
        f:SetScale(self.window:GetEffectiveScale()/UIParent:GetEffectiveScale()); f:SetPoint("CENTER",UIParent,"CENTER",0,-180); f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true)
        f.testButton="LeftButton"; f.testPhase="down"
        local handle=CreateFrame("Frame",nil,f); handle:SetWidth(540); handle:SetHeight(32); handle:SetPoint("TOP",f,"TOP",0,0); handle:EnableMouse(true); handle:RegisterForDrag("LeftButton")
        handle:SetScript("OnDragStart",function() f:StartMoving() end); handle:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
        f.title=self:Heading(f,"EasyCast · Weltklick-Test",16,10)
        f.close=CreateFrame("Button",nil,handle,"UIPanelCloseButton")
        self:RegisterHelp(f.close,"Schließen","Schließt dieses Testfenster und beendet seinen Test."); f.close:SetWidth(32); f.close:SetHeight(32); f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2)
        f.close:SetFrameLevel(handle:GetFrameLevel()+2)
        f.close:SetScript("OnClick",function() f:Hide() end)
        local note=self:Text(f,11); f.note=note
        note:SetWidth(508); note:SetPoint("TOPLEFT",f,"TOPLEFT",16,-42)
        f.spell=self:Place(self:Edit(f,508),f,16,78)
        f.spell:SetScript("OnEnterPressed",function() f.spell:ClearFocus() end)
        f.buttonChoice=self:Place(self:Dropdown(f,246,{{"LeftButton","Linksklick"},{"RightButton","Rechtsklick"}},function() return f.testButton end,function(v) E:StopClickTest(); f.testButton=v end),f,16,116)
        f.phaseChoice=self:Place(self:Dropdown(f,246,{{"down","Beim Drücken (DOWN)"},{"up","Beim Loslassen (UP)"}},function() return f.testPhase end,function(v) E:StopClickTest(); f.testPhase=v end),f,278,116)
        f.arm=self:Place(self:Button(f,508,"TEST STARTEN",function() E:ArmClickTest() end),f,16,154)
        f.arm:SetHeight(30); f.arm.selected=true; f.arm.Paint()
        f.reference=self:Place(self:Button(f,508,"Vergleich: Zauber mit diesem UI-Knopf auslösen",function()
            local via=E.buttonClickRequest
            if via and via.reached then return end
            if not via then E:StopClickTest() end
            f.spell:ClearFocus()
            local p,reason=E:ClickTestTarget(); if not p then E:ClickTestStatus(reason); return end
            if via then via.reached=true; E:TestLog("BUTTONTEST","B: gemeinsamer OnClick-Handler erreicht")
            elseif p.selfCast then E:TestLog("BUTTONTEST","A: gemeinsamer OnClick-Handler durch echten UI-Klick erreicht") end
            local request=E:BeginDirectClickCall(via and via.spell or p.spell,via and via.source.." → "..via.method.." → UI OnClick" or "UI OnClick",p.selfCast and "player" or "target")
            if p.selfCast then CastSpellByName(request.spell.cast,1) else CastSpellByName(request.spell.cast) end
            E:FinishDirectClickCall(request)
        end),f,16,192)
        f.status=self:Text(f,11,""); f.status:SetWidth(508); f.status:SetHeight(96); f.status:SetPoint("TOPLEFT",f,"TOPLEFT",16,-226)
        self:Place(self:Button(f,160,"Abbrechen",function() E:StopClickTest("Test abgebrochen.") end),f,16,340)
        self:Place(self:Button(f,160,"Bericht",function() E:ShowTestReport() end),f,190,340)
        self:Place(self:Button(f,160,"Schließen",function() f:Hide() end),f,364,340)
        f:SetScript("OnHide",function() f.spell:ClearFocus(); E:StopClickTest() end)
        table.insert(UISpecialFrames,"EasyCastClickTest")
    end
    local f=self.clickTestWindow
    self:StopClickTest(); self:RaiseDiagnostics(f,true)
    local previousSelf=f.selfTest; f.selfTest=mode=="might"
    f.title:SetText(f.selfTest and "EasyCast · Blessing of Might · A / B" or "EasyCast · Weltklick-Test")
    f.note:SetText(f.selfTest and "A: Button unten anklicken. B: Weltklick aktivieren, dann draußen klicken.\nBeide Wege verwenden denselben Button und zaubern auf dich selbst." or "1. Gegner auswählen.  2. TEST STARTEN drücken.\n3. Einmal außerhalb dieses Fensters in die Spielwelt klicken.")
    f.arm.label:SetText(f.selfTest and "B · Nächsten Weltklick verwenden" or "TEST STARTEN")
    f.reference.label:SetText(f.selfTest and "A · Blessing of Might auf mich" or "Vergleich: Zauber mit diesem UI-Knopf auslösen")
    f.arm:ClearAllPoints(); self:Place(f.arm,f,16,f.selfTest and 192 or 154)
    f.reference:ClearAllPoints(); self:Place(f.reference,f,16,f.selfTest and 154 or 192)
    f.reference:SetHeight(30); f.status:SetJustifyV("TOP")
    f.spell:EnableMouse(not f.selfTest)
    if f.selfTest then
        f.spell:SetText(self.spells["blessing of might"] and "Blessing of Might" or self.spells["segen der macht"] and "Segen der Macht" or "Blessing of Might")
        f.testButton="LeftButton"; f.testPhase="up"
    elseif f.spell:GetText()=="" or previousSelf then
        local value=self.db.bindings.hostile.LeftButton
        if type(value)~="table" or value.type=="spell" then f.spell:SetText(self:BindingLabel(value)) end
    end
    f.buttonChoice:Refresh(); f.phaseChoice:Refresh()
    self:SetDiagnostics(true); f:Show(); f.spell:ClearFocus(); self:ReleaseWorldBindings()
    self:ClickTestStatus(f.selfTest and "A: Blessing of Might per Button auslösen und Buff prüfen.\nDann Buff per Rechtsklick entfernen und globale Abklingzeit abwarten.\nB aktivieren, bei BEREIT einmal außerhalb des Fensters klicken.\nWeg B: "..self:ButtonTestMethod()..(self:ButtonTestMethod()=="OnClick-Funktion" and " (Button:Click im Client nicht vorhanden)." or ".") or "Noch nicht gestartet. Gegner wählen und TEST STARTEN drücken.\nSobald BEREIT erscheint: einmal in die Spielwelt klicken.")
end
