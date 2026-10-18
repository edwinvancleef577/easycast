-- A real, small UI button under the pointer. The client performs hit-testing.
-- OnUpdate observes/positions only. No Click(), camera calls or replayed input.
local E=EasyCast
local function mouseButton(a,b)
    return b or (type(a)=="string" and a) or arg1
end
local function short(text)
    text=string.gsub(tostring(text or ""),"[\r\n]"," ")
    return string.len(text)>150 and string.sub(text,1,147).."..." or text
end
function E:MiniTestStatus(text)
    if self.miniTestWindow then self.miniTestWindow.status:SetText(text) end
    self:TestLog("MINI-STATUS",text)
end
function E:HideMiniArea(reason)
    local p=self.miniTest
    if p then p.mode="idle"; p.placeAt=nil; p.press=nil; p.deadline=nil end
    if self.miniCastButton then self.miniCastButton:EnableMouse(false); self.miniCastButton:Hide() end
    if reason then self:MiniTestStatus(reason) end
end
function E:StopMiniTest()
    self:StopBindingTest()
    if self.miniTest then
        if self.miniTest.inFlight then
            self:APIEnd(); self:EndCastDiagnosis(self.miniTest.inFlight.attempt,false); self.miniTest.inFlight=nil
        end
        self:TestLog("MINI-ENDE","Test geschlossen; Klickfläche entfernt")
        self:HideMiniArea(); self.miniTest=nil
        self:CancelWorldClicks("Mini-Test beendet"); self.worldPending={}; self.worldHeld={}; self.worldHeldAt={}
        self:RefreshWorldBindings(); self:RefreshTips()
    end
    if self.miniTestWindow and self.miniTestWindow:IsShown() then self.miniTestWindow:Hide() end
end
function E:MiniWorldInput(phase,button,source)
    local p=self.miniTest
    if not p or (button~="LeftButton" and button~="RightButton") then return end
    if phase=="down" then p.worldHeld[button]=true
    elseif phase=="up" then p.worldHeld[button]=nil end
    self:TestLog("MINI-WELTEINGABE",tostring(source).." · "..tostring(button).." / "..tostring(phase).." (kein Zauber)")
end
function E:ArmMiniArea(clickable)
    if not self.miniTest then return end
    self:HideMiniArea()
    local p=self.miniTest; p.mode="countdown"; p.clickable=clickable
    p.placeAt=GetTime()+3; p.deadline=GetTime()+23; p.lastCountdown=nil
    p.saved="Wird vor Aktivierung erfasst"; p.lastSample=nil; p.lastEdge="Noch kein Klick auf die Fläche"
    self:MiniTestStatus("In 3 Sekunden: Maus auf freien Boden oder einen Gegner bewegen.\n"..(clickable and "GRÜN: echte Klickfläche, Linksklick zaubert auf dich selbst." or "GRAU: durchlässiger Vergleich, keine Zauber durch die Fläche."))
end
function E:MiniAreaPosition()
    local x,y=GetCursorPosition(); local f=self.miniCastButton
    local scale=UIParent:GetEffectiveScale()
    f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
end
function E:MiniWorldSurface()
    -- In this explicitly armed test, an absent focus may be empty world.
    -- Named/known UI still wins hit-testing above the background-layer button.
    local focus=GetMouseFocus and GetMouseFocus()
    return not focus or focus==self.miniCastButton or self:IsWorldFocus()
end
function E:SampleMiniTest()
    local p,f=self.miniTest,self.miniTestWindow; if not p then return end
    local focus=GetMouseFocus and GetMouseFocus()
    local focusName=focus and (self:FrameValue(focus,"GetName") or self:FrameValue(focus,"GetObjectType")) or "<kein Frame>"
    local live=self:DiagnosticUnit("mouseover") -- deliberately no target/cache fallback
    local visible=GameTooltip and GameTooltip:IsShown()
    local line=getglobal("GameTooltipTextLeft1")
    local tip=visible and ("sichtbar: "..short(line and line:GetText() or "<kein Text>")) or "nicht sichtbar"
    local state=p.mode.." / "..(p.clickable and "klickbar" or "durchlässig").." / Fläche="..(self.miniCastButton:IsShown() and "sichtbar" or "ausgeblendet")
    local stamp=state.." / "..live.." / Fokus="..focusName.." / Tooltip="..tip
    if stamp~=p.lastSample then self:TestLog("MINI-MESSUNG",stamp); p.lastSample=stamp end
    f.live:SetText("AKTUELL vom Client: "..live)
    f.saved:SetText("VOR AKTIVIERUNG gespeichert: "..(p.saved or "noch keine Aufnahme"))
    f.focus:SetText("MAUSFOKUS: "..focusName)
    f.tooltip:SetText("WoW-TOOLTIP: "..tip)
    f.edge:SetText(p.lastEdge or "Noch kein Klick auf die Fläche")
    -- The displayed observation never fabricates an underlying unit or a tooltip.
    f.detail:SetText(p.press and ("Druckdauer: "..math.floor((GetTime()-p.press.time)*1000).." ms · Fläche steht still") or
        p.mode=="active" and ("Fläche folgt der Maus · noch "..math.max(0,math.ceil(p.deadline-GetTime())).." s") or "Fläche: "..(p.mode=="idle" and "inaktiv" or "wartet auf Platzierung"))
end
function E:UpdateMiniTest()
    local p=self.miniTest; if not p then return end
    if p.inFlight then
        local attempt=p.inFlight.attempt; p.inFlight=nil; self:APIEnd(); self:EndCastDiagnosis(attempt,false)
        self:HideMiniArea("Zauberaufruf nicht normal zurückgekehrt; Lua-Fehler prüfen. Keine Wiederholung.")
    end
    local now=GetTime(); local button=self.miniCastButton
    if p.deadline and now>=p.deadline then self:HideMiniArea("Durchlauf beendet. Für einen weiteren Vergleich neu platzieren.") end
    if p.mode=="countdown" then
        local remaining=math.max(0,math.ceil(p.placeAt-now))
        if remaining~=p.lastCountdown then
            p.lastCountdown=remaining
            self:MiniTestStatus(remaining>0 and ("PLATZIERUNG IN "..remaining.." s · Maus jetzt in die Spielwelt bewegen.") or "Warte auf Maus über der Welt. Nicht klicken, bis der Rahmen erscheint.")
        end
        if now>=p.placeAt and not next(p.worldHeld) and self:MiniWorldSurface() and not self:TextInputFocused() and
            not self:PhysicalMouseDown("LeftButton") and not self:PhysicalMouseDown("RightButton") and
            not (IsMouselooking and IsMouselooking()) then
            p.saved=self:DiagnosticUnit("mouseover")
            self:TestLog("MINI-AUFNAHME",p.saved)
            self:MiniAreaPosition(); p.mode="active"
            button:SetBackdropBorderColor(p.clickable and .35 or .65,p.clickable and .95 or .65,p.clickable and .45 or .65,1)
            button:EnableMouse(p.clickable); button:Show()
            self:MiniTestStatus(p.clickable and "GRÜN: Fläche ist klickbar. Über Gegner bewegen und Live-Zeile prüfen.\nKurzer Linksklick: Blessing of Might auf dich. Rechtsklick bricht ab." or
                "GRAU: Fläche ist durchlässig. Über verschiedene Gegner bewegen.\nMouseover und Tooltip kommen unverändert vom Client / deinen anderen Addons.")
        end
    elseif p.mode=="active" then
        local focus=GetMouseFocus and GetMouseFocus()
        if p.press then
            local x,y=GetCursorPosition(); local press=p.press
            if (x-press.x)^2+(y-press.y)^2>64 then press.cancelled="Maus gezogen" end
            if now-press.time>.5 then press.cancelled="Zu lange gehalten" end
            if now-press.time>2 then self:HideMiniArea("Kein vollständiger kurzer Klick; Fläche freigegeben.") end
        elseif self:MiniWorldSurface() then
            self:MiniAreaPosition(); button:Show()
        else button:Hide() end -- UI remains above the low-layer test area
    end
    self:SampleMiniTest()
end
function E:MiniMouseDown(button)
    local p=self.miniTest; if not p or p.mode~="active" or not p.clickable then return end
    self:TestLog("MINI-EINGABE","DOWN "..tostring(button).." · echter Mini-Button-Handler")
    if button~="LeftButton" then self:HideMiniArea("Andere Maustaste: abgebrochen. Dieser Klick wird nicht nachträglich durchgereicht."); return end
    if p.press then return end
    local x,y=GetCursorPosition(); p.press={time=GetTime(),x=x,y=y}
    p.lastEdge="LINKS DOWN empfangen · warte auf UP / OnClick"
    self.miniCastButton:SetBackdropBorderColor(1,.8,.25,1); self:SampleMiniTest()
end
function E:MiniMouseUp(button)
    local p=self.miniTest; if not p or not p.press or button~="LeftButton" then return end
    p.press.released=true
    p.lastEdge="LINKS UP empfangen · "..math.floor((GetTime()-p.press.time)*1000).." ms"
    self:TestLog("MINI-EINGABE",p.lastEdge); self:SampleMiniTest()
end
function E:ShowMiniTest()
    if self.runTest then self:FinishRunTest("Bitte Lauftest zuerst schließen.",true); return end
    self:StopMiniTest(); self:StopMouseTest(); self:StopClickTest(); self.directClickDrain=nil
    self:StopWorldTrace("Wechsel zum Mini-Test"); self:StopKeyCapture(); self:CloseDropdown(); self:CommitEdits()
    for _,f in ipairs({self.window,self.clickTestWindow or self.window,self.probe or self.window,self.reportWindow or self.window}) do f:Hide() end
    self:SetDiagnostics(true)
    self.miniTest={mode="idle",saved="noch keine Aufnahme",worldHeld={}}
    self:CancelWorldClicks("Mini-Test"); self.worldPending={}; self.worldHeld={}; self.worldHeldAt={}
    self:ReleaseWorldBindings(); self:RefreshTips()
    if not self.miniTestWindow then
        local f=self:Box(UIParent,650,420,"EasyCastMiniTest"); self.miniTestWindow=f
        f:SetScale(self.window:GetEffectiveScale()/UIParent:GetEffectiveScale())
        f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-70); f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true)
        local handle=CreateFrame("Frame",nil,f); handle:SetWidth(650); handle:SetHeight(32); self:Place(handle,f,0,0)
        handle:EnableMouse(true); handle:RegisterForDrag("LeftButton")
        handle:SetScript("OnDragStart",function() f:StartMoving() end); handle:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
        self:Heading(f,"EasyCast · Mini-Klickfläche / Mouseover",16,10)
        f.close=CreateFrame("Button",nil,handle,"UIPanelCloseButton"); self:RegisterHelp(f.close,"Schließen","Schließt dieses Testfenster und beendet seinen Test."); f.close:SetWidth(32); f.close:SetHeight(32)
        f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2); f.close:SetScript("OnClick",function() E:StopMiniTest() end)
        local hint=self:Text(f,11,"Modus wählen, dann innerhalb von 3 Sekunden die Maus in die Welt bewegen.\n32 x 32 Pixel: grau = durchlässig · grün = klickbar · gelb = gedrückt.")
        hint:SetWidth(618); self:Place(hint,f,16,43)
        f.passive=self:Place(self:Button(f,302,"1 · Grau: nur Gegner erkennen",function() E:ArmMiniArea(false) end),f,16,84)
        f.active=self:Place(self:Button(f,302,"2 · Grün: Selbstzauber testen",function() E:ArmMiniArea(true) end),f,332,84)
        f.active.selected=true; f.active.Paint()
        f.status=self:Text(f,11); f.status:SetWidth(618); f.status:SetHeight(42); f.status:SetJustifyV("TOP"); self:Place(f.status,f,16,126)
        for i,name in ipairs({"live","saved","focus","tooltip","edge","detail"}) do
            local line=self:Text(f,i==1 and 12 or 11); line:SetWidth(618); line:SetHeight(25)
            self:Place(line,f,16,180+(i-1)*28); f[name]=line
            if i==1 then line:SetTextColor(.56,.88,.63) end
        end
        self:Place(self:Button(f,196,"Fläche entfernen",function() E:HideMiniArea("Fläche entfernt. Live-Anzeige läuft weiter.") end),f,16,378)
        self:Place(self:Button(f,196,"Bericht",function() E:HideMiniArea("Bericht geöffnet; Fläche entfernt."); E:ShowTestReport() end),f,226,378)
        self:Place(self:Button(f,196,"Schließen",function() E:StopMiniTest() end),f,438,378)
        f:SetScript("OnHide",function() E:StopMiniTest() end); table.insert(UISpecialFrames,"EasyCastMiniTest")
        local b=self:Box(UIParent,32,32,"EasyCastMiniCastButton","Button"); self.miniCastButton=b
        b:SetBackdropColor(.06,.12,.08,.12); b:SetFrameStrata("BACKGROUND")
        b:SetFrameLevel((WorldFrame and WorldFrame:GetFrameLevel() or 0)+5)
        b:EnableMouse(false); b:RegisterForClicks("LeftButtonUp"); b:Hide()
        b:SetScript("OnMouseDown",function(a,c) E:MiniMouseDown(mouseButton(a,c)) end)
        b:SetScript("OnMouseUp",function(a,c) E:MiniMouseUp(mouseButton(a,c)) end)
        b:SetScript("OnClick",function(a,c)
            local p=E.miniTest; local press=p and p.press
            if mouseButton(a,c)~="LeftButton" or not p or p.mode~="active" or not p.clickable or not press then return end
            E:UpdateMiniTest() -- refresh motion/hold checks, never casts
            if E.miniTest~=p or not p.press then return end
            p.press=nil -- one shot, even if client delivers a duplicate callback
            E:TestLog("MINI-EINGABE","OnClick auf echtem Mini-Button erreicht")
            if not press.released or press.cancelled then E:HideMiniArea("Kein Zauber: "..(press.cancelled or "UP fehlt").."."); return end
            if not E.db.enabled or E.worldBlocked or E:TextInputFocused() or
                not UnitExists("player") or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) or (SpellIsTargeting and SpellIsTargeting()) then
                E:HideMiniArea("Kein Zauber: EasyCast aus, Client-Sperre, Texteingabe oder ungültiger Spieler-/Zielcursorzustand."); return
            end
            local spell=E.spells["blessing of might"] or E.spells["segen der macht"]
            if not spell then E:HideMiniArea("Mouseover-Test möglich; Blessing of Might / Segen der Macht nicht gelernt."); return end
            p.lastEdge="OnClick erreicht · Blessing of Might auf mich aufgerufen"
            p.mode="casting" -- consumed; keep the real clicked button visible during the call
            E.castOrigin="Mini-Button"; E.castSource="Echter UI OnClick"
            local attempt=E:BeginCastDiagnosis("player",spell); E.castOrigin=nil; E.castSource=nil
            p.inFlight={attempt=attempt}
            E:APIStart("CastSpellByName",spell.cast.." · onSelf=1 · echter Mini-Button")
            CastSpellByName(spell.cast,1)
            E:APIEnd(); E:EndCastDiagnosis(attempt,true); p.inFlight=nil
            E:HideMiniArea()
            E:MiniTestStatus("Echter Mini-Button: Zauberaufruf zurückgekehrt.\nBitte Buff prüfen; die API-Rückkehr bestätigt keinen Erfolg.")
            E:SampleMiniTest()
        end)
    end
    self:RaiseDiagnostics(self.miniTestWindow,true); self.miniTestWindow:Show()
    self:MiniTestStatus("GRAU prüft nur die Gegnererkennung. GRÜN prüft einen echten Klick.\nDer Selbstzauber bei GRÜN beweist keine Gegnererkennung dahinter.")
    self:TestLog("MINI-START","Live-Mouseover ohne Cache-Ersatz; gespeicherte Einheit nur Anzeige. EasyCast-Tooltipänderungen pausiert. Andere Addons bleiben aktiv.")
    self:SampleMiniTest()
end
