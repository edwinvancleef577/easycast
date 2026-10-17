local E=EasyCast
function E:RegisterUnitFrame(frame,unit)
    if type(frame)=="string" then frame=getglobal(frame) end
    if not frame or not frame.GetScript or not frame.RegisterForClicks then return false end
    if self.frames[frame] then self.frames[frame].unit=unit; return true end
    local record={frame=frame,unit=unit,original={}}
    self.frames[frame]=record
    record.original.click=frame:GetScript("OnClick")
    record.original.enter=frame:GetScript("OnEnter")
    record.original.leave=frame:GetScript("OnLeave")
    record.original.hide=frame:GetScript("OnHide")
    frame:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp","Button4Up","Button5Up")
    record.click=function(a,b)
        local button=b or (type(a)=="string" and a) or arg1 or "LeftButton"
        if not E:Dispatch(record.unit,button) and record.original.click then record.original.click(a,b) end
    end
    record.enter=function(a,b)
        if record.original.enter then record.original.enter(a,b) end
        E.hovered=record; E:RefreshTips()
    end
    record.leave=function(a,b)
        if E.hovered==record then E.hovered=nil end
        E:RefreshTips()
        if record.original.leave then record.original.leave(a,b) end
    end
    record.hide=function(a,b)
        if E.hovered==record then E.hovered=nil end
        E:RefreshTips()
        if record.original.hide then record.original.hide(a,b) end
    end
    frame:SetScript("OnClick",record.click); frame:SetScript("OnEnter",record.enter)
    frame:SetScript("OnLeave",record.leave); frame:SetScript("OnHide",record.hide)
    return true
end
function E:ScanFrames()
    self:RegisterUnitFrame("PlayerFrame","player")
    self:RegisterUnitFrame("PetFrame","pet")
    self:RegisterUnitFrame("TargetFrame","target")
    for i=1,4 do
        self:RegisterUnitFrame("PartyMemberFrame"..i,"party"..i)
        self:RegisterUnitFrame("PartyMemberFrame"..i.."PetFrame","partypet"..i)
    end
end
function E:Diagnostics()
    local count,overwritten=0,0
    for f,r in pairs(self.frames) do
        count=count+1
        if f:GetScript("OnClick")~=r.click then overwritten=overwritten+1 end
    end
    self:Print(self.version.." · "..count.." angebundene Frames · "..overwritten.." nachträglich geänderte Klickhandler")
    self:Print(C_Spell and type(C_Spell.CastAtUnit)=="function" and "Zauberweg: ClassicAPI, direkt auf Einheit." or "Zauberweg: Vanilla, Ziel kurz wechseln und wiederherstellen.")
    self:Print("Weltklicks: "..(self.db.world.enabled and "AN" or "AUS").." · Globale Mausereignisse: "..tostring(self.worldMouseEvents or 0))
    local c=self.worldCounts
    if c then self:Print("Mausdruck: "..c.down.." · Loslassen: "..c.up.." · Zauberaufrufe: "..c.casts.." · Abgebrochen: "..c.cancelled) end
    self:Print("Welt: Zauber beim Loslassen; Links auf anderen Gegner wählt nur aus. * = WoW-Doppelbelegung.")
    if self.lastWorldInput then
        local r=self.lastWorldInput
        self:Print("Letzte tatsächliche Zaubertasten-Eingabe: "..self:InputRecordText(r))
        self:Print("Frame beim Klick: "..r.focus)
        self:Print("Maus beim Klick: "..r.mouse.." · Auswahl: "..r.target.." · Kampf: "..(r.combat and "JA" or "NEIN"))
        self:Print("Zauberziel beim Klick: "..r.cast)
    else
        self:Print("Noch kein Mausklick erfasst. /ec probe zeigt den Mausfokus live.")
    end
end
-- Optional integration for UI replacements, without scanning unknown frames.
function EasyCast_RegisterUnitFrame(frame,unit)
    return E:RegisterUnitFrame(frame,unit)
end

-- Resolve the frame actually under the pointer, including portrait children.
-- A cached OnEnter alone must not keep a unit-frame hint alive over the world.
function E:UnitFrameUnderMouse()
    local focus=GetMouseFocus and GetMouseFocus(); local node=focus; local depth=0
    while node and depth<12 do
        local record=self.frames[node]
        if record and node:IsVisible() then return record.unit,record end
        node=self:FrameValue(node,"GetParent"); depth=depth+1
    end
end
function E:UnitFrameTooltipUnit(tip)
    local unit,record=self:UnitFrameUnderMouse(); if not unit then return end
    local owner=self:FrameValue(tip,"GetOwner")
    if not owner or owner==UIParent or owner==WorldFrame then return unit end
    local node=owner; local depth=0
    while node and depth<12 do
        if node==record.frame then return unit end
        node=self:FrameValue(node,"GetParent"); depth=depth+1
    end
end
