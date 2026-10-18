local E=EasyCast
function E:NativeTooltipUnit()
    local tip=GameTooltip
    if not tip or self.nativeTipNonUnit=="hard" then return end
    -- Spellbook/trainer tooltips must never inherit a previous unit tooltip,
    -- including unlearned spells rendered with SetText rather than SetSpell.
    local owner=self:FrameValue(tip,"GetOwner"); local depth=0
    while owner and depth<12 do
        local name=self:FrameValue(owner,"GetName")
        if name=="SpellBookFrame" or name=="ModernSpellBookFrame" or name=="ClassTrainerFrame" then return end
        owner=self:FrameValue(owner,"GetParent"); depth=depth+1
    end
    -- Portrait help such as "Player Options" contains no unit name. Its
    -- actual owner/focus still identifies the registered unit frame.
    local frameUnit=self:UnitFrameTooltipUnit(tip)
    if frameUnit then return frameUnit end
    if tip.GetUnit then
        local ok,name,unit=pcall(tip.GetUnit,tip)
        if ok and unit and UnitExists(unit) then return unit end
    end
    local tracked=self.nativeTipUnit
    local world=self:IsWorldFocus()
    local unit
    if world then unit=self:WorldHoverUnit()
    elseif self.hovered and self.hovered.frame:IsVisible() then unit=self.hovered.unit end
    -- Name text only confirms a real token in the current mouse context.
    local name=unit and UnitName(unit)
    if name then for i=1,3 do
        local line=getglobal("GameTooltipTextLeft"..i)
        local text=line and line:IsShown() and line:GetText()
        if text then
            text=string.gsub(string.gsub(string.gsub(text,"|c%x%x%x%x%x%x%x%x",""),"|r",""),"|T.-|t","")
            if self:Trim(text)==name then return unit end
        end
    end end
    if tracked and UnitExists(tracked) and (not self.nativeTipGUID or self:UnitGUIDValue(tracked)==self.nativeTipGUID) and
        (not world or not UnitExists("mouseover") or UnitIsUnit(tracked,"mouseover")) then return tracked end

end
function E:NativeTooltipScope(tip)
    if self:UnitFrameUnderMouse() then return "frames" end
    if self:IsWorldFocus() then return "world" end
    local owner=self:FrameValue(tip,"GetOwner"); local depth=0
    while owner and depth<12 do
        if self.frames[owner] then return "frames" end
        if owner==WorldFrame then return "world" end
        owner=self:FrameValue(owner,"GetParent"); depth=depth+1
    end
end
function E:ShouldHideNativeTooltip(tip)
    if self.miniTest or self.bindingTest or self:BypassRequested() then return false end
    if not self.db or not self.db.enabled or tip~=GameTooltip then return false end
    local kind=self:Kind(self:NativeTooltipUnit())
    local scope=self:NativeTooltipScope(tip)
    return kind and scope and self:HideDefaultTip(kind,scope=="world")
end
function E:UpdateNativeTooltip()
    if self:ShouldHideNativeTooltip(GameTooltip) then
        self:ClearCastFooter(); GameTooltip:Hide()
    else self:ApplyCastFooter() end
end
function E:InitNativeTooltip()
    local tip=GameTooltip; if not tip or self.nativeTipHooked==tip then return end
    self.nativeTipHooked=tip
    local original=tip.SetUnit
    if original then tip.SetUnit=function(frame,unit,...)
        E:ClearCastFooter(); E.nativeTipNonUnit=nil; E.nativeTipUnit=nil; E.nativeTipGUID=nil
        local a,b,c=original(frame,unit,unpack(arg))
        E.nativeTipNonUnit=nil; E.nativeTipUnit=unit; E.nativeTipGUID=unit and E:UnitGUIDValue(unit)
        if E:ShouldHideNativeTooltip(frame) then frame:Hide() end
        return a,b,c
    end end
    for _,method in ipairs({"ClearLines","SetText","SetBagItem","SetInventoryItem","SetHyperlink","SetSpell","SetAction","SetTalent","SetCraftSpell","SetAuctionItem","SetLootItem","SetMerchantItem","SetQuestItem","SetQuestLogItem","SetTradeSkillItem","SetCraftItem","SetTradePlayerItem","SetTradeTargetItem","SetLootRollItem","SetInboxItem","SetSendMailItem","SetAuctionSellItem","SetPlayerBuff","SetUnitBuff","SetUnitDebuff","SetUnitAura"}) do
        local fn=tip[method]; local hard=method~="SetText" and method~="ClearLines"
        if fn then tip[method]=function(frame,...)
            E:ClearCastFooter(); E.nativeTipUnit=nil; E.nativeTipGUID=nil; E.nativeTipNonUnit=hard and "hard" or nil
            return fn(frame,unpack(arg))
        end end
    end
    for _,method in ipairs({"AddLine","AddDoubleLine"}) do
        local fn=tip[method]
        if fn then tip[method]=function(frame,...)
            E:ClearCastFooter(); return fn(frame,unpack(arg))
        end end
    end
    local show=tip.Show
    tip.Show=function(frame,...)
        E:ClearCastFooter()
        if E:ShouldHideNativeTooltip(frame) then frame:Hide(); return end
        return show(frame,unpack(arg))
    end
    local hide=tip:GetScript("OnHide")
    tip:SetScript("OnHide",function(...)
        E:ClearCastFooter(); E.nativeTipUnit=nil; E.nativeTipGUID=nil; E.nativeTipNonUnit=nil
        if hide then return hide(unpack(arg)) end
    end)
end
