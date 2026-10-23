local E=EasyCast
local question="Interface\\Icons\\INV_Misc_QuestionMark"
E.actionChoices={{"target","Ziel wählen"},{"assist","Unterstützen"},{"follow","Folgen"},{"clear","Ziel abwählen"}}
function E:BindingLabel(value)
    local text=type(value)=="table" and value.value or value
    if type(value)~="table" or value.type=="spell" then
        local info=self:Resolve(value)
        if info then
            local alias=self.db.spellAliases[string.lower(self:Trim(text))]
            local highest=type(value)=="table" and value.spellID and value.highest
            if type(value)~="table" or not value.spellID then highest=(alias and alias.highest) or string.lower(self:Trim(text))==string.lower(info.name) end
            return highest and info.name or info.cast
        end
    end
    return tostring(text or "")
end
function E:MacroIndex(name)
    if not GetMacroInfo then return end
    for i=1,138 do local n=GetMacroInfo(i); if n==name then return i end end
end
function E:FindItem(name)
    local wanted=string.lower(tostring(name))
    local function match(link)
        if not link then return false end
        local _,_,id=string.find(link,"item:(%d+)")
        local _,_,label=string.find(link,"%[(.-)%]")
        return wanted==id or (label and string.lower(label)==wanted)
    end
    if GetContainerNumSlots and GetContainerItemLink then
        for bag=0,4 do for slot=1,GetContainerNumSlots(bag) do
            if match(GetContainerItemLink(bag,slot)) then
                local icon=GetContainerItemInfo(bag,slot)
                return {bag=bag,slot=slot,icon=icon}
            end
        end end
    end
    if GetInventoryItemLink then for slot=1,19 do
        if match(GetInventoryItemLink("player",slot)) then
            return {inventory=slot,icon=GetInventoryItemTexture("player",slot)}
        end
    end end
end
function E:BindingInfo(value)
    if type(value)~="table" then return self:Resolve(value) end
    local kind,name=value.type,value.value
    if kind=="spell" then return self:ResolveSpellIdentity(value) end
    if kind=="macro" then
        local i=self:MacroIndex(name)
        if i then local n,icon=GetMacroInfo(i); return {name=n,icon=icon,index=i} end
    elseif kind=="item" and name and name~="" then
        local item=self:FindItem(name) or {missing=true,icon=value.icon or question}; item.name=name; return item
    elseif kind=="slot" then
        local slot=tonumber(name)
        if slot and slot>=1 and slot<=120 and slot==math.floor(slot) then return {name=E:L("Aktionsplatz ")..slot,slot=slot,icon=GetActionTexture and GetActionTexture(slot) or question} end
    elseif kind=="action" then
        for _,a in ipairs(self.actionChoices) do if a[1]==name then return {name=self:L(a[2]),icon="Interface\\Icons\\Ability_Hunter_SniperShot"} end end
    end
end
function E:SetAction(kind,key,action)
    if action and (not action.value or self:Trim(action.value)=="") then action=nil end
    if action and not self:BindingInfo(action) then return false end
    self.db.bindings[kind][key]=action and self:SpellAction(action) or nil
    self:CancelWorldClicks("Belegung geändert")
    if self.initialized then self:RefreshWorldBindings() end
    return true
end
function E:WithUnit(unit,callback)
    if not unit or not UnitExists(unit) then return false end
    local had=UnitExists("target"); local changed=not UnitIsUnit("target",unit)
    if changed then self:APIStart("TargetUnit",unit); TargetUnit(unit); self:APIEnd() end
    if not UnitIsUnit("target",unit) then
        if changed then if had then TargetLastTarget() else ClearTarget() end end
        return false
    end
    local ok,err=pcall(callback)
    -- A macro may intentionally change targets; preserve that explicit choice.
    if changed and UnitIsUnit("target",unit) then
        if had then TargetLastTarget() else ClearTarget() end
    end
    if not ok then self:Print(E:L("Aufruf fehlgeschlagen: ")..tostring(err)) end
    return ok
end
function E:Cast(unit,value)
    if type(value)~="table" then return self:CastSpell(unit,value) end
    if value.type=="spell" then return self:CastSpell(unit,value) end
    if self:TestSuppressCast() then self:TestLog("TROCKENTEST",self:BindingLabel(value)); return false end
    if self.worldBlocked or not unit or not UnitExists(unit) then return false end
    local info=self:BindingInfo(value); if not info then return false end
    if value.type=="action" then
        local fn=({target=TargetUnit,assist=AssistUnit,follow=FollowUnit,clear=ClearTarget})[value.value]
        if not fn then return false end
        self:APIStart(value.value,unit); local ok,err=pcall(fn,unit); self:APIEnd()
        if not ok then self:Print(tostring(err)) end
        return ok
    end
    if SpellIsTargeting and SpellIsTargeting() then return false end
    return self:WithUnit(unit,function()
        if value.type=="slot" then
            E:APIStart("UseAction",value.value); UseAction(info.slot); E:APIEnd()
            if SpellIsTargeting and SpellIsTargeting() then SpellTargetUnit(unit) end
        elseif value.type=="item" then
            if info.missing then error(E:L("Gegenstand nicht in Taschen oder Ausrüstung: ")..value.value) end
            E:APIStart("UseItem",value.value)
            if info.inventory then UseInventoryItem(info.inventory) else UseContainerItem(info.bag,info.slot) end
            E:APIEnd()
            if SpellIsTargeting and SpellIsTargeting() then SpellTargetUnit(unit) end
        elseif value.type=="macro" then
            local old=EasyCastUnit; EasyCastUnit=unit
            E:APIStart("Macro",value.value)
            local ok,err=pcall(function()
                if RunMacro then RunMacro(info.index); return end
                local _,_,body=GetMacroInfo(info.index)
                if not ChatFrameEditBox or not ChatEdit_SendText then error(E:L("Client bietet keinen Makro-Aufruf")) end
                local edit=ChatFrameEditBox; local previous=edit:GetText()
                local worked,reason=pcall(function()
                    for line in string.gfind(body or "","[^\r\n]+") do
                        if string.sub(line,1,1)~="#" then edit:SetText(line); ChatEdit_SendText(edit,0) end
                    end
                end)
                edit:SetText(previous or "")
                if not worked then error(reason) end
            end)
            EasyCastUnit=old; E:APIEnd(); if not ok then error(err) end
        end
    end)
end
function E:InputButtons()
    local out=self:Copy(self.buttons)
    for _,key in ipairs(self.db.keys) do table.insert(out,{key,key}) end
    return out
end
function E:IsInputButton(button)
    for _,v in ipairs(self:InputButtons()) do if v[1]==button then return true end end
    return false
end
function E:NormalizeKey(key)
    key=string.upper(self:Trim(key))
    if not string.find(key,"^[A-Z0-9]+$") or string.len(key)>16 then return nil end
    if string.find(key,"BUTTON") or string.find(key,"MOUSE") or ({ESCAPE=true,ENTER=true,UNKNOWN=true,LSHIFT=true,RSHIFT=true,LCTRL=true,RCTRL=true,LALT=true,RALT=true})[key] then return false end
    local _,_,fkey=string.find(key,"^F(%d+)$")
    local named={SPACE=true,TAB=true,BACKSPACE=true,INSERT=true,DELETE=true,HOME=true,END=true,PAGEUP=true,PAGEDOWN=true,UP=true,DOWN=true,LEFT=true,RIGHT=true,NUMPAD0=true,NUMPAD1=true,NUMPAD2=true,NUMPAD3=true,NUMPAD4=true,NUMPAD5=true,NUMPAD6=true,NUMPAD7=true,NUMPAD8=true,NUMPAD9=true,NUMPADPLUS=true,NUMPADMINUS=true,NUMPADMULTIPLY=true,NUMPADDIVIDE=true,NUMPADDECIMAL=true}
    if string.len(key)~=1 and not named[key] and not (fkey and tonumber(fkey)>=1 and tonumber(fkey)<=24) then return false end
    return key
end
function E:AddKey(key)
    key=self:NormalizeKey(key)
    if not key then return false,E:L("Ungültige Taste. Beispiel: F6, F oder NUMPAD1.") end
    if self:IsInputButton(key) then return false,"existing",key end
    if table.getn(self.db.keys)>=20 then return false,E:L("Maximal 20 zusätzliche Tasten pro Profil.") end
    table.insert(self.db.keys,key); return true
end
function E:ProfileSnapshot()
    return self:Copy({bindings=self.db.bindings,tips=self.db.tips,tipAppearance=self.db.tipAppearance,legacyTipAppearance=self.db.legacyTipAppearance,world=self.db.world,keys=self.db.keys})
end
function E:SaveProfile(name)
    name=self:Trim(name); if name=="" or string.len(name)>48 then return false end
    if self.CommitEdits then self:CommitEdits() end
    self.db.profiles[name]=self:ProfileSnapshot(); self.db.profile=name; return true
end
function E:LoadProfile(name)
    if not self.db.profiles[name] then return false end
    -- Save before reading: selecting the current profile must not reload an
    -- older snapshot over its live settings.
    self:SaveProfile(self.db.profile)
    local profile=self:Copy(self.db.profiles[name])
    self:MigrateWorldGestures(profile.world)
    self:MigrateTipSettings(profile.tips)
    self:MigrateTipAppearance(profile)
    for _,key in ipairs({"bindings","tips","tipAppearance","legacyTipAppearance","world","keys"}) do self.db[key]=profile[key] end
    self:Merge(self.db,self.defaults); self:MigrateTipSettings(self.db.tips); self.db.profile=name
    self:RefreshWorldBindings(); self:RefreshWorldHooks(); self:RefreshSettings(); self:RefreshTips(); return true
end
function E:CursorBinding()
    if CursorHasSpell and CursorHasSpell() and self.cursorBinding then return self:Copy(self.cursorBinding) end
    if CursorHasItem and CursorHasItem() and self.cursorBinding then return self:Copy(self.cursorBinding) end
    if CursorHasMacro and CursorHasMacro() and self.cursorBinding then return self:Copy(self.cursorBinding) end
    if GetCursorInfo then
        local kind,a,b=GetCursorInfo()
        if not kind then return nil end
        if kind=="macro" then local n,icon=GetMacroInfo(a); return n and {type="macro",value=n,icon=icon} end
        if kind=="item" then return {type="item",value=tostring(a)} end
    end
    if ((not CursorHasSpell and not CursorHasItem) or (self.cursorBinding and self.cursorBinding.type=="macro" and not CursorHasMacro)) and self.cursorBinding and GetTime()-(self.cursorTime or 0)<30 then return self:Copy(self.cursorBinding) end
end
function E:InitCursorCapture()
    if self.cursorCapture then return end; self.cursorCapture=true
    local function hook(name,read)
        local original=getglobal(name); if not original then return end
        setglobal(name,function(...)
            -- Observe pickup metadata only while editing bindings; never let
            -- EasyCast's lookup prevent another addon's original pickup call.
            if E.window and E.window:IsShown() and E.page=="casts" then
                local ok,value=pcall(read,arg[1],arg[2],arg[3])
                E.cursorBinding=ok and value or nil; E.cursorTime=GetTime()
            else E.cursorBinding=nil end
            return original(unpack(arg))
        end)
    end
    hook("PickupSpell",function(i,book)
        if type(i)~="number" or i<1 or i~=math.floor(i) or i>2048 then return end
        book=book or BOOKTYPE_SPELL or "spell"
        if book~=(BOOKTYPE_SPELL or "spell") then return end
        -- Resolve from our known spellbook snapshot, not another native lookup
        -- against a potentially stale slot supplied by a replacement book.
        for _,entry in ipairs(E.spellList) do
            if entry.slot==i then return {type="spell",value=entry.cast} end
        end
    end)
    hook("PickupMacro",function(i) local name,icon=GetMacroInfo(i); return name and {type="macro",value=name,icon=icon} end)
    local function item(link,icon)
        local _,_,name=string.find(link or "","%[(.-)%]"); return name and {type="item",value=name,icon=icon}
    end
    hook("PickupContainerItem",function(b,s) return item(GetContainerItemLink(b,s),GetContainerItemInfo(b,s)) end)
    hook("PickupInventoryItem",function(s) return item(GetInventoryItemLink("player",s),GetInventoryItemTexture("player",s)) end)
    local clear=ClearCursor
    if clear then ClearCursor=function() E.cursorBinding=nil; return clear() end end
end
function E:SetDiagnostics(enabled)
    if self.traceRunning then self:StopWorldTrace("Diagnosemodus geändert") end
    self.traceCastingPaused=nil; self.db.diagnostics=enabled and true or false
    if enabled then
        self.db.diagnosticTest={active=true,phase="live",started=GetTime(),entries={},version=self.version}
        self:TestLog("START","Begleitdiagnose; Zaubern aktiv"); self:LogCastDiagnosticSetup()
    elseif self.db.diagnosticTest then self:TestLog("ENDE","Diagnose beendet"); self.db.diagnosticTest.active=false end
    self:RefreshWorldHooks()
    if self.RefreshDiagnosticIndicator then self:RefreshDiagnosticIndicator() end
end
