-- Read-only tooltip status. Never change targets or enter spell targeting to
-- probe validity. Unknown restrictions remain unknown (not a valid-target claim).
local E=EasyCast
E.spellRestrictions={}; E.spellStatusQueue={}; E.spellRangeLimits={}
local function plain(text)
    return E:Trim(string.gsub(string.gsub(text or "","|c%x%x%x%x%x%x%x%x",""),"|r",""))
end
function E:SelfOnlySpell(info)
    if not info or not info.slot then return end
    local key=info.cast or info.name
    local known=self.spellRestrictions[key]
    if known~=nil then return known=="self" end
    -- Exact, conservative fallback for the reported spell. No inference from
    -- zero range, icon alone, or incidental words in the spell description.
    if (info.name=="Lightning Shield" or info.name=="Blitzschlagschild") and
        string.lower(info.icon or "")=="interface\\icons\\spell_nature_lightningshield" then return true end
    self.spellStatusQueue[key]=info
end
function E:UpdateSpellMetadata()
    if self.nextSpellStatusScan and GetTime()<self.nextSpellStatusScan then return end
    if self:SpellbookOrCursorBusy() then return end
    local key,info=next(self.spellStatusQueue)
    if not key then return end
    self.nextSpellStatusScan=GetTime()+.15; self.spellStatusQueue[key]=nil
    self.spellRestrictions[key]="unknown"
    self.spellManaCosts[key]=false
    local ok,err=pcall(function()
        if not E.spellStatusTip then E.spellStatusTip=CreateFrame("GameTooltip","EasyCastSpellStatusScan",UIParent,"GameTooltipTemplate") end
        local tip=E.spellStatusTip
        tip:SetOwner(UIParent,"ANCHOR_NONE"); tip:ClearLines(); tip:SetSpell(info.slot,BOOKTYPE_SPELL or "spell")
        -- A standalone range field among the header lines is evidence. Do not
        -- search descriptive prose for 'self' or infer from missing range.
        for i=2,4 do for _,side in ipairs({"Left","Right"}) do
            local line=getglobal("EasyCastSpellStatusScanText"..side..i)
            local value=line and line:IsShown() and plain(line:GetText())
            if value then
                local mana=E:ReadManaCost(value)
                if mana then E.spellManaCosts[key]=mana end
                local _,_,low,high=string.find(value,"^(%d+)%s*%-%s*(%d+)%s+yd range$")
                if not low then _,_,low,high=string.find(value,"^(%d+)%s*%-%s*(%d+)%s+m Reichweite$") end
                if high then E.spellRangeLimits[key]={min=tonumber(low),max=tonumber(high)}
                else
                    local _,_,maximum=string.find(value,"^(%d+)%s+yd range$")
                    if not maximum then _,_,maximum=string.find(value,"^(%d+)%s+m Reichweite$") end
                    if maximum then E.spellRangeLimits[key]={min=0,max=tonumber(maximum)} end
                end
            end
            if value and value~="" and (value=="Self" or value=="Selbst" or
                (SPELL_RANGE_SELF and value==SPELL_RANGE_SELF)) then E.spellRestrictions[key]="self" end
        end end
    end)
    if self.spellStatusTip then self.spellStatusTip:Hide() end
    if not ok then self:TestLog("ZAUBERSTATUS",tostring(err)) end
end
function E:BindingCooldown(value,info)
    if not info then return end
    local kind=type(value)=="table" and value.type or "spell"
    local fn,a,b
    if kind=="spell" then fn,a,b=GetSpellCooldown,info.slot,BOOKTYPE_SPELL or "spell"
    elseif kind=="slot" then fn,a=GetActionCooldown,info.slot
    elseif kind=="item" and not info.missing then
        if info.inventory then fn,a,b=GetInventoryItemCooldown,"player",info.inventory
        else fn,a,b=GetContainerItemCooldown,info.bag,info.slot end
    end
    -- Macro execution may choose a different spell/target: no guessed timer.
    if type(fn)~="function" or a==nil then return end
    local ok,start,duration,enabled=pcall(fn,a,b)
    if not ok or type(start)~="number" or type(duration)~="number" or enabled==0 then return end
    local remaining=start+duration-GetTime()
    if duration>0 and remaining>0 then return {start=start,duration=duration,remaining=remaining} end
end
function E:BindingStatus(value,info,unit,range)
    local kind=type(value)=="table" and value.type or "spell"
    local selfOnly=kind=="spell" and self:SelfOnlySpell(info) or nil
    local wrongSelf=selfOnly and unit and UnitExists(unit) and not self:SameUnit(unit,"player")
    local limits=info and self.spellRangeLimits[info.cast or info.name]
    local lacksMana=self:BindingLacksMana(value,info)
    local reason=wrongSelf and "Self" or (range==0 and (limits and limits.min==0 and "RangeUp" or "RangeBoth")) or (lacksMana and "Mana") or nil
    return {cooldown=self:BindingCooldown(value,info),selfOnly=selfOnly,lacksMana=lacksMana,reason=reason,invalid=reason~=nil}

end
function E:PaintBindingStatus(cell,status)
    if not cell.statusLayer then
        self.statusCellSerial=(self.statusCellSerial or 0)+1
        if type(CooldownFrame_SetTimer)=="function" then
            local ok,cd=pcall(CreateFrame,"Model","EasyCastCooldown"..self.statusCellSerial,cell,"CooldownFrameTemplate")
            if ok then cell.cooldown=cd; cd:EnableMouse(false); cd:Hide() end
        end
        local f=CreateFrame("Frame",nil,cell); f:EnableMouse(false); cell.statusLayer=f
        f.shade=f:CreateTexture(nil,"BACKGROUND"); f.shade:SetTexture(0,0,0,.35); f.shade:SetAllPoints(f)
        f.time=self:Text(f,10); f.time:SetPoint("CENTER",f,"CENTER",0,0); f.time:SetJustifyH("CENTER")
        f.badge=f:CreateTexture(nil,"OVERLAY"); f.badge:SetTexture("Interface\\AddOns\\EasyCast\\Media\\Self")
        f.badge:SetPoint("TOPRIGHT",f,"TOPRIGHT",2,2)
        f.manaBadge=self:CreateManaBadge(f); f.manaBadge:Hide()
    end
    local f=cell.statusLayer; local size=cell.icon:GetWidth()
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",cell.icon,"TOPLEFT",0,0); f:SetWidth(size); f:SetHeight(size)
    f:SetFrameStrata(cell:GetFrameStrata()); f:SetFrameLevel(cell:GetFrameLevel()+3)
    f.time:SetFont(E:FontPath(),math.max(8,math.min(12,size*.65)),"OUTLINE")
    f.time:SetWidth(size+4); f.time:SetHeight(size); f.badge:SetWidth(math.max(8,math.min(12,size*.6))); f.badge:SetHeight(math.max(8,math.min(12,size*.6)))
    status=status or {}; cell.spellStatus=status
    self:SizeManaBadge(f.manaBadge,math.max(8,math.min(12,size*.6)))
    f.manaBadge:SetFrameStrata(f:GetFrameStrata()); f.manaBadge:SetFrameLevel(f:GetFrameLevel()+1)
    if cell.icon.SetDesaturated then cell.icon:SetDesaturated(status.invalid and true or false) end
    cell.icon:SetVertexColor(1,1,1)
    cell.icon:SetAlpha(status.invalid and .3 or 1)
    if status.reason=="Mana" then f.badge:Hide(); f.manaBadge:Show()
    elseif status.reason then
        f.manaBadge:Hide()
        f.badge:SetTexture("Interface\\AddOns\\EasyCast\\Media\\"..status.reason)
        f.badge:SetVertexColor(1,.48,.48,1); f.badge:Show()
    else f.badge:Hide(); f.manaBadge:Hide() end
    local cd=status.cooldown
    if cd then
        f.shade:Show(); f.time:SetText(cd.remaining>=60 and math.ceil(cd.remaining/60).."m" or tostring(math.ceil(cd.remaining))); f.time:Show()
    else f.shade:Hide(); f.time:Hide() end
    if cell.cooldown then
        local c=cell.cooldown
        c:ClearAllPoints(); c:SetPoint("TOPLEFT",cell.icon,"TOPLEFT",0,0); c:SetWidth(size); c:SetHeight(size)
        c:SetFrameStrata(cell:GetFrameStrata()); c:SetFrameLevel(cell:GetFrameLevel()+1)
        if cd then
            if c.ecStart~=cd.start or c.ecDuration~=cd.duration then
                local ok=pcall(CooldownFrame_SetTimer,c,cd.start,cd.duration,1)
                if ok then c.ecStart=cd.start; c.ecDuration=cd.duration else c:Hide() end
            end
            if c.ecStart==cd.start then c:Show() end
        else c:Hide(); c.ecStart=nil; c.ecDuration=nil end
    end
    f:Show()
end
