local E=EasyCast
function E:RangeIndexNeeded()
    if self:CastDiagnosisActive() then return true end
    if not self.db or not self.db.enabled then return false end
    for _,t in pairs(self.db.tips) do if t.enabled then return true end end
    return false
end
local function normalized(value)
    if value==1 or value==true then return 1 end
    if value==0 or value==false then return 0 end
end
function E:RangeCapabilities()
    return "IsSpellInRange="..type(IsSpellInRange).." · C_Spell="..type(C_Spell and C_Spell.IsSpellInRange).." · Rang-ID="..type(GetSpellIdForName)
end
-- Prefer exact spell/rank + explicit unit, independent of visible action bars.
function E:BindingRange(value,info,unit)
    if not unit or not UnitExists(unit) then return nil end
    if type(value)=="table" and value.type~="spell" then return nil end
    if not info or not info.name then return nil end
    local spell=info.cast or info.name
    local id
    if type(GetSpellIdForName)=="function" then
        local ok,v=pcall(GetSpellIdForName,spell)
        if ok and type(v)=="number" and v>0 then id=v end
    end
    if type(IsSpellInRange)=="function" then
        local ok,v
        if GetNampowerVersion or GetSpellIdForName then
            ok,v=pcall(IsSpellInRange,id or spell,unit)
        else
            -- Book form preserves rank on clients with the Blizzard signature.
            ok,v=pcall(IsSpellInRange,info.slot,BOOKTYPE_SPELL or "spell",unit)
            if not ok or normalized(v)==nil then ok,v=pcall(IsSpellInRange,spell,unit) end
        end
        if ok and normalized(v)~=nil then return normalized(v),"IsSpellInRange" end
    end
    if C_Spell and type(C_Spell.IsSpellInRange)=="function" then
        local ok,v=pcall(C_Spell.IsSpellInRange,id or spell,unit)
        if ok and normalized(v)~=nil then return normalized(v),"C_Spell.IsSpellInRange" end
    end
    -- Stock fallback refers only to the selected target. Never borrow its
    -- answer for a different mouse target and never modify the action bars.
    if not UnitIsUnit("target",unit) or type(IsActionInRange)~="function" then return nil,"keine passende Reichweiten-API" end
    local result
    for _,entry in ipairs(self.diagnosticActions or {}) do
        -- Exact spell and rank only. A shared texture or unconfirmed rank is
        -- insufficient, especially for healing spells with different ranges.
        if entry.name==info.name and entry.icon==info.icon and entry.rank==(info.rank or "") then
            local hasRange=true
            if ActionHasRange then local ok,v=pcall(ActionHasRange,entry.slot); hasRange=ok and v and true or false end
            if hasRange then
                local ok,v=pcall(IsActionInRange,entry.slot)
                if ok and (v==0 or v==1) then
                    if result~=nil and result~=v then return nil end
                    result=v
                end
            end
        end
    end
    return result,result~=nil and "Aktionsleiste" or "Reichweite unbekannt"
end
function E:PaintBindingRange(cell,value)
    cell.rangeState=value
    if cell.rangeMark then cell.rangeMark:Hide() end
    cell.icon:SetVertexColor(1,1,1)
    if cell.key then cell.key:SetTextColor(.93,.90,.80) end
end
function E:RangeReport()
    local lines={"EasyCast "..self.version.." · Reichweite ohne sichtbare Leisten",self:RangeCapabilities(),
        "1=in Reichweite; 0=außerhalb; nil=unbekannt. Keine Zielwechsel / keine Leistenänderungen.",
        "Mouseover: "..self:DiagnosticUnit("mouseover"),"Auswahl: "..self:DiagnosticUnit("target")}
    local focus=self:FocusDetails(); local hover,origin=self:WorldHoverUnit(focus)
    table.insert(lines,"Erkannt: "..self:UnitDescription(hover).." · "..origin.." · Fokus="..focus.reason)
    local target,mode,why=self:ResolveWorldTarget()
    table.insert(lines,"Zauberziel: "..self:UnitDescription(target).." · "..tostring(mode or why))
    local seen={}
    for _,kind in ipairs({"friendly","hostile"}) do for _,value in pairs(self.db.bindings[kind]) do
        local info=self:BindingInfo(value); local label=info and (info.cast or info.name)
        if label and not seen[label] then
            seen[label]=true
            for _,unit in ipairs({"player","target","mouseover"}) do
                local range,source=self:BindingRange(value,info,unit)
                table.insert(lines,label.." → "..unit..": "..tostring(range).." · "..tostring(source or "unbekannt"))
            end
        end
    end end
    table.insert(lines,"Ohne direkte Zauber-Reichweiten-API bleibt Vanilla auf vorhandene Aktionsplätze beschränkt. Sichtbare Buttons sind dafür nicht nötig, belegte Slots aber schon.")
    table.insert(lines,"Ein negatives Ergebnis unterscheidet allein nicht zwischen Mindest- und Maximalreichweite. Doppelpfeil = Richtung unbekannt.")
    return table.concat(lines,"\n")
end
