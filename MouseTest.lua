-- Target-independent input observation. Never casts or synthesizes input.
local E=EasyCast
local buttons={"LeftButton","RightButton"}
local names={LeftButton="LINKS",RightButton="RECHTS"}
local function milliseconds(seconds) return math.floor(seconds*1000+.5).." ms" end
local function sample()
    local focus=GetMouseFocus and GetMouseFocus()
    local frame=focus and (E:FrameValue(focus,"GetName") or E:FrameValue(focus,"GetObjectType")) or "kein Frame"
    return {frame=frame,mouseover=UnitExists("mouseover") and (UnitName("mouseover") or "Einheit") or "keine Einheit",
        looking=type(IsMouselooking)=="function" and (IsMouselooking() and "ja" or "nein") or "unbekannt"}
end
local function stateText(s)
    return "Fokus="..s.frame.." · Mouseover="..s.mouseover.." · Kameramodus="..s.looking
end
function E:MouseTestLog(text)
    local t=self.mouseTest; if not t then return end
    local line=string.format("%.3f",GetTime()-t.started).."  "..text
    table.insert(t.entries,line)
    if table.getn(t.entries)>200 then table.remove(t.entries,1); t.dropped=t.dropped+1 end
end
function E:MouseTestInput(phase,button,source)
    local t=self.mouseTest
    -- WorldFrame is the measured surface. Global events can also originate
    -- on UI controls; do not mix them in or count duplicate deliveries.
    if not t or source~="WorldFrame" or not names[button] or (phase~="down" and phase~="up") then return end
    local r=t.buttons[button]; local now=GetTime()
    local s=sample()
    if phase=="down" then
        if r.held then return end
        r.held=true; r.started=now; r.downCount=r.downCount+1
        r.lastDown=now-t.started; r.before=s; r.result="KLICK-DOWN erkannt"
        self:MouseTestLog(names[button].." DOWN → KLICK-DOWN · WorldFrame.OnMouseDown · "..stateText(s))
    else
        if not r.held then
            self:MouseTestLog(names[button].." UP ohne erfasstes DOWN · keine Druckdauer ableitbar")
            r.result="UP ohne DOWN"; return
        end
        r.held=false; r.duration=now-r.started; r.upCount=r.upCount+1
        r.lastUp=now-t.started; r.result="KLICK-UP erkannt"
        self:MouseTestLog(names[button].." UP → KLICK-UP · "..milliseconds(r.duration).." · WorldFrame.OnMouseUp · "..stateText(s))
    end
    self:UpdateMouseTest()
end
function E:MouseTestReport()
    local t=self.mouseTest or self.db.mouseInputTest
    if not t then return "Noch kein Eingabetest. /ec mousetest öffnet ihn." end
    local lines={"EasyCast "..t.version.." · Maus DOWN / UP", "Kein Gegner nötig. Keine EasyCast-Zauber in diesem Test.",
        "DOWN/UP werden aus WorldFrame-Ereignissen abgeleitet. Fokus/Mouseover/Kameramodus werden getrennt beobachtet.",
        "Mouseover-Verlust ist kein Nachweis eines unsichtbaren Mauszeigers. Sichtbarkeit wird nicht direkt gemessen.",
        "Verworfene alte Zeilen: "..t.dropped}
    for _,b in ipairs(buttons) do
        local r=t.buttons[b]
        table.insert(lines,names[b]..": DOWN="..r.downCount.." · UP="..r.upCount..(r.duration and " · zuletzt "..milliseconds(r.duration) or ""))
    end
    for _,line in ipairs(t.entries) do table.insert(lines,line) end
    return table.concat(lines,"\n")
end
function E:UpdateMouseTest()
    local t,f=self.mouseTest,self.mouseTestWindow
    if not t or not f or not f:IsShown() then return end
    local s=sample(); local stamp=stateText(s)
    if stamp~=t.lastState then self:MouseTestLog("BEOBACHTUNG · "..stamp); t.lastState=stamp end
    f.observation:SetText("Mausfokus: "..s.frame.."\nEinheit unter Maus: "..s.mouseover.." · Kameramodus: "..s.looking)
    for _,button in ipairs(buttons) do
        local r,c=t.buttons[button],f.cards[button]
        c.state:SetText(r.held and "GEDRÜCKT / HALTEN" or r.upCount>0 and "LOSGELASSEN" or "BEREIT")
        c.state:SetTextColor(r.held and 1 or .56,r.held and .77 or .88,r.held and .35 or .63)
        c.duration:SetText("Druckdauer: "..(r.held and milliseconds(GetTime()-r.started) or r.duration and milliseconds(r.duration) or "—"))
        c.count:SetText("DOWN "..r.downCount.."    UP "..r.upCount)
        c.down:SetText("Letztes DOWN: "..(r.lastDown and string.format("%.3f s",r.lastDown) or "—"))
        c.up:SetText("Letztes UP: "..(r.lastUp and string.format("%.3f s",r.lastUp) or "—"))
        c.result:SetText(r.result or "Warte auf Maustaste")
    end
    -- Keep interpreted edges visible even if down and up arrive between UI
    -- refreshes. Observation lines cannot push these out of the short list.
    local edges={}
    for i=table.getn(t.entries),1,-1 do
        if string.find(t.entries[i],"→",1,true) and
            (string.find(t.entries[i],"^%d+%.%d+  LINKS ") or string.find(t.entries[i],"^%d+%.%d+  RECHTS ")) then
            table.insert(edges,1,t.entries[i]); if table.getn(edges)==4 then break end
        end
    end
    for i=1,4 do
        local line=edges[i] or ""
        -- Compact live history; the report retains every sampled detail.
        local cut=string.find(line," · WorldFrame",1,true)
        if cut then line=string.sub(line,1,cut-1) end
        f.history[i]:SetText(line)
    end
end
function E:StopMouseTest()
    if self.mouseTest then
        self:MouseTestLog("ENDE · Anzeige geschlossen; offene Drücke werden beendet, kein UP erfunden")
        self.mouseTest=nil
        self:CancelWorldClicks("Eingabetest beendet"); self.worldPending={}; self.worldHeld={}; self.worldHeldAt={}
        self:RefreshWorldHooks(); self:RefreshWorldBindings()
    end
    if self.mouseTestWindow and self.mouseTestWindow:IsShown() then self.mouseTestWindow:Hide() end
end
function E:ShowMouseTest()
    if self.runTest then self:FinishRunTest("Bitte Lauftest zuerst schließen.",true); return end
    self:StopMiniTest()
    self:StopMouseTest(); self:StopClickTest(); self.directClickDrain=nil
    self:StopWorldTrace("Wechsel zum Eingabetest"); self:StopKeyCapture(); self:CloseDropdown(); self:CommitEdits()
    for _,f in ipairs({self.window,self.clickTestWindow or self.window,self.probe or self.window,self.reportWindow or self.window}) do f:Hide() end
    local t={started=GetTime(),version=self.version,entries={},dropped=0,buttons={}}
    for _,b in ipairs(buttons) do t.buttons[b]={downCount=0,upCount=0} end
    self.mouseTest=t; self.db.mouseInputTest=t
    self:CancelWorldClicks("Eingabetest"); self.worldPending={}; self.worldHeld={}; self.worldHeldAt={}
    self:ReleaseWorldBindings(); self:RefreshWorldHooks()
    if not self.mouseTestWindow then
        local f=self:Box(UIParent,600,476,"EasyCastMouseTest"); self.mouseTestWindow=f
        f:SetScale(self.window:GetEffectiveScale()/UIParent:GetEffectiveScale())
        f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-80); f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true)
        local handle=CreateFrame("Frame",nil,f); handle:SetWidth(600); handle:SetHeight(32); self:Place(handle,f,0,0)
        handle:EnableMouse(true); handle:RegisterForDrag("LeftButton")
        handle:SetScript("OnDragStart",function() f:StartMoving() end)
        handle:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
        self:Heading(f,"EasyCast · Maus DOWN / UP",16,10)
        f.close=CreateFrame("Button",nil,handle,"UIPanelCloseButton"); self:RegisterHelp(f.close,"Schließen","Schließt dieses Testfenster und beendet seinen Test."); f.close:SetWidth(32); f.close:SetHeight(32)
        f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2); f.close:SetScript("OnClick",function() E:StopMouseTest() end)
        local note=self:Text(f,12,"TEST LÄUFT · Kein Gegner nötig.\nAußerhalb dieses Fensters links/rechts drücken, halten und loslassen.")
        note:SetWidth(568); self:Place(note,f,16,42)
        f.cards={}
        for i,b in ipairs(buttons) do
            local c=self:Box(f,278,172); c:EnableMouse(false); self:Place(c,f,16+(i-1)*290,90); f.cards[b]=c
            self:Heading(c,names[b],12,10)
            local function label(size,y) local l=E:Text(c,size); l:SetWidth(254); E:Place(l,c,12,y); return l end
            c.state=label(16,35); c.duration=label(13,60); c.count=label(12,83)
            c.down=label(11,106); c.up=label(11,125); c.result=label(12,147)
        end
        f.observation=self:Text(f,11); f.observation:SetWidth(568); f.observation:SetHeight(36); self:Place(f.observation,f,16,274)
        local hint=self:Text(f,10,"Fokus/Mouseover-Verlust wird separat angezeigt. Cursor-Sichtbarkeit: nicht direkt messbar.")
        hint:SetWidth(568); self:Place(hint,f,16,312)
        f.history={}
        for i=1,4 do
            local line=self:Text(f,11); line:SetWidth(568); line:SetHeight(18); self:Place(line,f,16,338+(i-1)*20); f.history[i]=line
        end
        f.reset=self:Place(self:Button(f,178,"Neu beginnen",function() E:ShowMouseTest() end),f,16,430)
        f.report=self:Place(self:Button(f,178,"Bericht",function() E:ShowTestReport(E:MouseTestReport()) end),f,210,430)
        self:Place(self:Button(f,178,"Schließen",function() E:StopMouseTest() end),f,404,430)
        f:SetScript("OnHide",function() E:StopMouseTest() end)
        table.insert(UISpecialFrames,"EasyCastMouseTest")
    end
    self:RaiseDiagnostics(self.mouseTestWindow,true); self.mouseTestWindow:Show()
    self:MouseTestLog("START · WorldFrame-Ereignis → KLICK-DOWN / KLICK-UP; EasyCast-Zaubern pausiert")
    self:UpdateMouseTest()
end
