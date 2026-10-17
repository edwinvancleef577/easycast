local E=EasyCast
E.inputSources={}; E.inputHistory={}; E.rawInputs={}
local function short(text,n)
    text=tostring(text or "—"); text=string.gsub(text,"[\r\n]"," ")
    return string.len(text)>n and string.sub(text,1,n-3).."..." or text
end
function E:UnitDescription(unit)
    if not unit or not UnitExists(unit) then return "<keine>" end
    local kind=UnitIsUnit(unit,"player") and "eigener Spieler" or (self:Kind(unit) or "neutral")
    return tostring(UnitName(unit) or "?").." ["..kind.."]"
end
function E:ObserveInput(button,phase,source)
    local r=self.rawInputs[button] or {downCount=0,upCount=0}; self.rawInputs[button]=r
    if phase=="down" or phase=="up" then
        r[phase]={time=GetTime(),source=source}; r[phase.."Count"]=r[phase.."Count"]+1
    end
    self.lastObservedButton=button
end
function E:RecordWorldInput(button,phase,source,reason,unit,mode,gesture)
    local focus=self:FocusDetails(); local x,y=GetCursorPosition()
    local record={time=GetTime(),button=button,phase=phase,source=source,reason=reason,
        focus=focus.path~="" and focus.path or "<kein Frame>",
        mouse=self:UnitDescription("mouseover"),target=self:UnitDescription("target"),
        combat=self:InCombat(),cast=unit and self:UnitDescription(unit) or "<keines>",mode=mode}
    if gesture then
        record.saved=gesture.identity.name; record.guid=gesture.identity.guid
        record.duration=GetTime()-gesture.time; record.movement=math.sqrt((x-gesture.x)^2+(y-gesture.y)^2)
        record.spell=self:BindingLabel(gesture.spell); record.origin=gesture.source
    end
    self:TestLog("ERGEBNIS",button.." / "..phase.." · "..reason.." · Ziel="..record.cast.." · Zielwahl="..tostring(mode or "-")..(record.duration and " · "..math.floor(record.duration*1000).." ms / "..string.format("%.1f",record.movement).." px" or ""))
    self.lastWorldInput=record
    table.insert(self.inputHistory,record)
    if table.getn(self.inputHistory)>12 then table.remove(self.inputHistory,1) end
end
function E:InputRecordText(r)
    if not r then return "Noch kein Mausklick erkannt." end
    return self:KeyLabel(r.button).." / "..r.phase.." / "..r.source..": "..r.reason..(r.mode=="snapshot" and " [Mausaufnahme]" or "")
end
function E:CastFeedbackText()
    local a=self.lastCastAttempt
    if not a then return "Noch kein Zauberaufruf beobachtet.",.7,.7,.7 end
    if a.luaOK==false then return "Lua-Fehler beim Aufruf (siehe Bericht)",1,.42,.32 end
    if a.apiResult==false then return "Zauber-API hat den Aufruf abgelehnt (Rückgabe false)",1,.56,.3 end
    if a.feedback then
        return "Client zeitnah: "..a.feedback.source.." · "..short(a.feedback.text,90).." (Zuordnung offen)",.95,.76,.4
    end
    if GetTime()-a.time<1 then return "Lua-Aufruf erfolgt · warte auf Client-Rückmeldung",.95,.76,.4 end
    return "KEINE zeitnahe Client-Rückmeldung · Zaubererfolg unbestätigt",1,.56,.3
end
function E:UpdateProbe()
    if not self.probe or not self.probe:IsShown() or self.probePaused then return end
    local f=self:FocusDetails(); local unit,mode,reason=self:ResolveWorldTarget()
    local hover,hoverOrigin=self:WorldHoverUnit(f)
    local r=self.lastWorldInput; local button=self.lastObservedButton or (r and r.button)
    local press=button and self.primaryPresses[button]
    if press and r and r.button==button then
        local x,y=GetCursorPosition()
        r.duration=GetTime()-press.time; r.movement=math.sqrt((x-press.x)^2+(y-press.y)^2)
    end
    local raw=button and self.rawInputs[button]; local a=self.lastCastAttempt
    local function transition(phase)
        local t=raw and raw[phase]
        return t and t.source.." · vor "..string.format("%.2f",GetTime()-t.time).." s" or "noch nicht erfasst"
    end
    local function hook(phase)
        local h=self.worldHooks and self.worldHooks[phase]
        return not h and "aus" or WorldFrame:GetScript(phase)==h.wrapper and "aktiv" or "von anderem Addon ersetzt"
    end
    local routes={}
    for _,b in ipairs({"LeftButton","RightButton","MiddleButton","Button4","Button5"}) do
        table.insert(routes,self:KeyLabel(b).."="..(self:NativeRunOwns(self:WorldActionKey(self:Key(b),b)) and "WoW-Laufen" or self:BindingOwnsMouse(b) and "Bindung" or "WorldFrame"))
    end
    local feedback,red,green,blue=self:CastFeedbackText()
    local lines={
        "LIVE · EasyCast "..(self.db.enabled and "AN" or "AUS").." · Welt "..(self.db.world.enabled and "AN" or "AUS").." · "..(self.traceCastingPaused and "TEST: Zaubern pausiert" or "Zauberaufrufe freigegeben").." · Sperre: "..(self.worldBlocked or "nicht gemeldet"),
        "Mausframe: "..short(f.path~="" and f.path or "<kein Frame>",120),
        "Weltfläche: "..(f.accepted and "JA" or "NEIN").." · "..f.reason.." · "..tostring(hoverOrigin),
        "Unter Maus: "..self:DiagnosticUnit("mouseover").." · Erkannt: "..self:UnitDescription(hover),
        "Auswahl: "..self:DiagnosticUnit("target"),
        "Mögliches Ziel jetzt: "..(unit and self:UnitDescription(unit).." / "..tostring(mode) or reason),
        "Eingabewege: "..table.concat(routes," · "),
        "WorldFrame-Hooks: Down "..hook("OnMouseDown").." · Up "..hook("OnMouseUp"),
        "LETZTE EINGABE · "..(button and self:KeyLabel(button) or "keine").." · Down: "..transition("down"),
        "Loslassen (Up): "..transition("up"),
        "Entscheidung: "..short(self:InputRecordText(r),120),
        "Gespeichertes Ziel: "..(r and r.saved and r.saved.." ["..tostring(r.guid or "stabiler Token").."]" or "keine Geste gespeichert"),
        "Druckdauer / Weg: "..(r and r.duration and math.floor(r.duration*1000).." ms / "..string.format("%.1f",r.movement).." px" or "—")..((button=="LeftButton" or button=="RightButton") and (" · Grenzen: "..math.floor((self.db.world.maxHold or .15)*1000).." ms / "..tostring(self.db.world.dragPixels or 6).." px") or " · kein Klickzeit-/Bewegungsfilter"),
        "ZAUBERAUFRUF · "..(a and "#"..a.id.." "..a.spell.cast.." · "..a.origin.." / "..tostring(a.source or "?") or "noch keiner"),
        "Sollziel beim Aufruf: "..(a and a.wanted or "—"),
        feedback,
        "Letzte Clientmeldung: "..(self.lastClientFeedback and short(self.lastClientFeedback.source.." · "..self.lastClientFeedback.text,108) or "keine erfasst"),
        "EasyCast-Kamera: "..(self.ownedCamera and (self.ownedCamera.stopping and "STOPP ausstehend" or "AKTIV") or "aus").." · Not-Aus: Escape / /ec stop"
    }
    for i,text in ipairs(lines) do self.probe.lines[i]:SetText(text) end
    self.probe.lines[16]:SetTextColor(red,green,blue)
end
function E:ToggleProbe()
    if not self.probe then
        local f=self:Box(UIParent,780,464,"EasyCastMouseProbe"); self.probe=f
        local pos=self.db.probePosition or {x=24,y=-70}
        f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",pos.x,pos.y)
        self:RaiseDiagnostics(f,true); f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(false)
        local header=CreateFrame("Frame",nil,f); header:SetWidth(780); header:SetHeight(35); header:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); header:EnableMouse(true); header:RegisterForDrag("LeftButton")
        header:SetScript("OnDragStart",function() f:StartMoving() end)
        header:SetScript("OnDragStop",function()
            f:StopMovingOrSizing(); local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
            E.db.probePosition={x=f:GetLeft()*scale,y=f:GetTop()*scale-UIParent:GetHeight()}
        end)
        local title=self:Text(header,12,"EasyCast "..self.version.." · Mausdiagnose (hier ziehen)")
        title:SetPoint("TOPLEFT",header,"TOPLEFT",12,-10); title:SetTextColor(.56,.88,.63)
        f.pause=self:Place(self:Button(header,88,"Anhalten",function()
            E.probePaused=not E.probePaused; f.pause.label:SetText(E.probePaused and "Weiter" or "Anhalten"); f.pause.selected=E.probePaused; f.pause.Paint(); E:UpdateProbe()
        end),header,460,6)
        self:Place(self:Button(header,100,"Bericht",function() E:ShowTestReport() end),header,554,6)
        self:Place(self:Button(header,100,"Schließen",function() f:Hide() end),header,662,6)
        f.lines={}
        for i=1,18 do
            local text=self:Text(f,i==2 and 10 or 11); text:SetPoint("TOPLEFT",f,"TOPLEFT",12,-43-(i-1)*22)
            text:SetWidth(756); text:SetHeight(21); f.lines[i]=text
            if i==1 or i==9 or i==14 then text:SetTextColor(.56,.88,.63) end
        end
        local hint=self:Text(f,10,"Anzeige unten ist mausklickdurchlässig. Anhalten friert nur die Anzeige ein. /ec probe schließt.")
        hint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",12,10); hint:SetTextColor(.65,.70,.64)
        self:UpdateProbe(); return
    end
    if self.probe:IsShown() then self.probe:Hide()
    else self:RaiseDiagnostics(self.probe,true); self.probe:Show(); self:UpdateProbe() end
end
