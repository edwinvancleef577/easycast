-- Search the cached learned spellbook; typing never calls a native spell scan.
local E=EasyCast
function E:SpellSuggestions(text)
    local query=string.lower(self:Trim(text)); local result,seen={},{}
    if query=="" or self.spellBookReady==false then return result end
    local ranks=string.find(query,"(",1,true)
    for _,entry in ipairs(self.spellList or {}) do
        local label=ranks and entry.cast or entry.name
        local lower=string.lower(label)
        local pos=string.find(lower,query,1,true)
        if pos and not seen[lower] then
            seen[lower]=true
            local info=ranks and entry or self.spells[lower]
            table.insert(result,{label=label,icon=info.icon,prefix=pos==1})
        end
    end
    table.sort(result,function(a,b)
        if a.prefix~=b.prefix then return a.prefix end
        return a.label<b.label
    end)
    while table.getn(result)>6 do table.remove(result) end
    return result
end
function E:HideSpellSuggestions()
    if self.spellSuggestions then self.spellSuggestions:Hide(); self.spellSuggestions.row=nil end
end
function E:AcceptSpellSuggestion(button)
    local popup=self.spellSuggestions
    local row=popup and popup.row
    if not row or not button.choice then return end
    local focused=self.focusedEdit==row.edit
    row.edit:SetText(button.choice.label)
    row.edit:ClearFocus()
    -- A button can receive mouse-down just after the edit box lost focus.
    if not focused then self:SaveRow(row) end
    self:HideSpellSuggestions()
end
function E:ShowSpellSuggestions(row)
    if self.refreshingBindings or row.actionType~="spell" or self.focusedEdit~=row.edit then return self:HideSpellSuggestions() end
    local choices=self:SpellSuggestions(row.edit:GetText())
    if table.getn(choices)==0 then return self:HideSpellSuggestions() end
    local popup=self.spellSuggestions
    if not popup then
        popup=self:Box(self.window,288,30); self.spellSuggestions=popup; popup.buttons={}
        popup:SetFrameStrata("DIALOG"); popup:SetFrameLevel(self.window:GetFrameLevel()+50)
        popup:SetClampedToScreen(true); popup:EnableMouse(true)
        popup:SetScript("OnUpdate",function()
            if not popup.row or E.focusedEdit~=popup.row.edit or not popup.row.edit:IsVisible() then E:HideSpellSuggestions() end
        end)
        for i=1,6 do
            local b=self:Button(popup,280,"",function() end)
            self:Place(b,popup,4,4+(i-1)*28)
            b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetWidth(20); b.icon:SetHeight(20); b.icon:SetPoint("LEFT",b,"LEFT",4,0)
            b.label:ClearAllPoints(); b.label:SetPoint("LEFT",b,"LEFT",30,0); b.label:SetWidth(244); b.label:SetJustifyH("LEFT")
            b:SetScript("OnMouseDown",function() E:AcceptSpellSuggestion(b) end)
            popup.buttons[i]=b
        end
    end
    popup.row=row; popup:ClearAllPoints(); popup:SetPoint("TOPLEFT",row.edit,"BOTTOMLEFT",0,-2)
    popup:SetHeight(table.getn(choices)*28+8)
    for i,b in ipairs(popup.buttons) do
        b.choice=choices[i]
        if b.choice then b.label:SetText(b.choice.label); b.icon:SetTexture(b.choice.icon); b:Show() else b:Hide() end
    end
    popup:Show()
end
function E:AttachSpellSuggestions(row)
    local focus=row.edit:GetScript("OnEditFocusGained")
    row.edit:SetScript("OnEditFocusGained",function() if focus then focus() end; E:ShowSpellSuggestions(row) end)
    row.edit:SetScript("OnTextChanged",function() E:ShowSpellSuggestions(row) end)
    row.edit:SetScript("OnTabPressed",function()
        local popup=E.spellSuggestions
        if popup and popup:IsShown() and popup.row==row then E:AcceptSpellSuggestion(popup.buttons[1]) end
    end)
    row.edit:SetScript("OnHide",function() if E.spellSuggestions and E.spellSuggestions.row==row then E:HideSpellSuggestions() end end)
end
