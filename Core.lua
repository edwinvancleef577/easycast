-- Independent implementation; no Puppeteer source or artwork is included.
EasyCast = {version="0.7.40-alpha", frames={}, spells={}, spellList={}, buttons={
    {"LeftButton","Links"}, {"RightButton","Rechts"}, {"MiddleButton","Mitte"},
    {"Button4","Maus 4"}, {"Button5","Maus 5"}, {"MOUSEWHEELUP","Rad hoch"}, {"MOUSEWHEELDOWN","Rad runter"}},
    modifiers={"", "SHIFT-", "CTRL-", "ALT-", "CTRL-SHIFT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-"}}
local E = EasyCast
E.tipContexts={"friendly","hostile","friendlyWorld","hostileWorld"}
E.defaults = {
    enabled=true, helpTooltips=true, language="auto", spellAliases={}, bindings={friendly={},hostile={}}, minimapAngle=220,
    tips={friendly={enabled=true,hideFrames=false,hideWorld=false,columns=1,rows=1,style="separate",size=16,width=84,opacity=85,labelMode="icon",mode="cursor",x=24,y=-22},
          hostile={enabled=true,hideFrames=false,hideWorld=false,columns=1,rows=1,style="separate",size=16,width=84,opacity=85,labelMode="icon",mode="cursor",x=24,y=-110}},
    tipAppearance={style="separate",layout="vertical",size=16,width=84,opacity=85,labelMode="icon",columns=1,perRow=5,gap=4,iconGap=4},
    world={enabled=false,maxHold=0.15,dragPixels=6,leftDragMode="mouselook",selfModifier="none",bypassModifier="none",enemyMode="select",gestureVersion=2}, keys={}, profiles={}, profile="Standard", diagnostics=false,
    window={x=0,y=0}, version=1
}
function E:Copy(value)
    if type(value)~="table" then return value end
    local out={}; for k,v in pairs(value) do out[k]=self:Copy(v) end
    return out
end
E.defaults.tips.friendlyWorld=E:Copy(E.defaults.tips.friendly)
E.defaults.tips.hostileWorld=E:Copy(E.defaults.tips.hostile)
function E:TipFaction(context)
    return (context=="friendly" or context=="friendlyWorld") and "friendly" or "hostile"
end
function E:TipContext(kind,world)
    if kind=="friendlyWorld" or kind=="hostileWorld" then return kind end
    return world and kind.."World" or kind
end
function E:Merge(target,defaults)
    for k,v in pairs(defaults) do
        if type(target[k])~=type(v) then target[k]=self:Copy(v)
        elseif type(v)=="table" then self:Merge(target[k],v) end
    end
end
function E:MigrateWorldGestures(world)
    if type(world)~="table" then return end
    if not world.gestureVersion then
        world.maxHold=.15; world.dragPixels=6; world.gestureVersion=1
    end
    if world.gestureVersion<2 then
        world.previousLeftDragMode=world.leftDragMode
        world.leftDragMode="mouselook"; world.gestureVersion=2
    end
end
-- Appearance is profile-wide; visibility/position remain per context.
function E:MigrateTipAppearance(db)
    if type(db.tipAppearance)~="table" then
        local source=db.tips and (db.tips.friendlyWorld or db.tips.friendly) or {}
        db.tipAppearance=self:Copy(self.defaults.tipAppearance)
        db.legacyTipAppearance=self:Copy(db.tips) -- keep old individual choices for recovery
        for _,key in ipairs({"style","size","width","opacity","labelMode","columns"}) do
            if source[key]~=nil then db.tipAppearance[key]=source[key] end
        end
        db.tipAppearance.layout=source.style=="integrated" and "horizontal" or "vertical"
    end
    self:Merge(db.tipAppearance,self.defaults.tipAppearance)
    local t=db.tipAppearance
    if t.style~="integrated" then t.style="separate" end
    if t.layout~="horizontal" then t.layout="vertical" end
    if t.labelMode~="off" and t.labelMode~="text" then t.labelMode="icon" end
    for key,limits in pairs({size={8,48},width={36,500},opacity={5,100},gap={0,16},iconGap={0,32},perRow={1,27},columns={1,3}}) do
        t[key]=math.max(limits[1],math.min(limits[2],math.floor(tonumber(t[key]) or self.defaults.tipAppearance[key])))
    end
    if t.style=="integrated" then t.columns=math.max(2,t.columns) end
end
function E:TipSettings(context)
    local t=self:Copy(self.db.tips[context])
    for k,v in pairs(self.db.tipAppearance) do t[k]=v end
    return t
end
function E:InitDB()
    if type(EasyCastDB)~="table" then EasyCastDB={} end
    self:MigrateWorldGestures(EasyCastDB.world)
    for _,profile in pairs(EasyCastDB.profiles or {}) do if type(profile)=="table" then self:MigrateWorldGestures(profile.world) end end
    self:MigrateTipSettings(EasyCastDB.tips)
    for _,profile in pairs(EasyCastDB.profiles or {}) do if type(profile)=="table" then self:MigrateTipSettings(profile.tips) end end
    self:MigrateTipAppearance(EasyCastDB)
    for _,profile in pairs(EasyCastDB.profiles or {}) do if type(profile)=="table" then self:MigrateTipAppearance(profile) end end
    self:Merge(EasyCastDB,self.defaults); self.db=EasyCastDB
    for _,kind in ipairs(self.tipContexts) do
        local t=self.db.tips[kind]
        if t.mode~="fixed" and t.mode~="cursor" then t.mode="cursor" end
        if type(t.positions)~="table" then
            t.positions={cursor={x=24,y=self:TipFaction(kind)=="friendly" and -22 or -110},
                fixed={x=self:TipFaction(kind)=="friendly" and -320 or 320,y=0}}
        end
        t.positions[t.mode]={x=t.x,y=t.y}
    end
    -- The active working settings are the newest persisted state, including
    -- upgrades from releases that did not checkpoint the active profile.
    self.db.profiles[self.db.profile]=self:ProfileSnapshot()
end
function E:MigrateTipSettings(tips)
    if type(tips)~="table" then return end
    -- Clone old shared settings once, including positions and visibility.
    -- Appearance is migrated separately to the profile-wide table.
    for _,kind in ipairs({"friendly","hostile"}) do
        if type(tips[kind])=="table" and type(tips[kind.."World"])~="table" then
            tips[kind.."World"]=self:Copy(tips[kind])
        end
    end
    for _,kind in ipairs(self.tipContexts) do
        local t=tips[kind]
        if type(t)=="table" then
            if type(t.hideWorld)~="boolean" then t.hideWorld=t.hideDefault==true end
            if type(t.hideFrames)~="boolean" then t.hideFrames=t.hideDefault==true end
            t.hideDefault=nil
            if t.labelMode~="off" and t.labelMode~="text" and t.labelMode~="icon" then
                t.labelMode=(t.labels or t.style=="integrated") and "text" or "icon"
            end
            t.labels=nil
            t.columns=math.max(1,math.min(3,math.floor(tonumber(t.columns) or 1)))
            t.rows=math.max(1,math.min(3,math.floor(tonumber(t.rows) or 1)))
            if t.mode~="fixed" and t.mode~="cursor" then t.mode="cursor" end
            if type(t.positions)~="table" then t.positions={} end
            local friendly=self:TipFaction(kind)=="friendly"
            if type(t.positions.cursor)~="table" then t.positions.cursor={x=24,y=friendly and -22 or -110} end
            if type(t.positions.fixed)~="table" then t.positions.fixed={x=friendly and -320 or 320,y=0} end
            t.x=tonumber(t.x) or t.positions[t.mode].x
            t.y=tonumber(t.y) or t.positions[t.mode].y
            t.positions[t.mode]={x=t.x,y=t.y}
        end
    end
end
function E:HideDefaultTip(kind,world)
    local context=self:TipContext(kind,world); local t=self.db.tips[context]
    if t.hideDefault~=nil then return t.hideDefault and true or false end
    if context=="friendlyWorld" or context=="hostileWorld" then return t.hideWorld end
    return t.hideFrames
end
function E:SetTipMode(kind,mode)
    local t=self.db.tips[kind]
    t.positions[t.mode]={x=t.x,y=t.y}
    t.mode=mode
    local pos=t.positions[mode]
    t.x=pos.x; t.y=pos.y
end
function E:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff8fe0a0EasyCast:|r "..message) end
end
function E:Trim(s)
    return (string.gsub(string.gsub(s or "","^%s+",""),"%s+$",""))
end
function E:Key(button)
    local s=""
    if IsAltKeyDown() then s=s.."ALT-" end
    if IsControlKeyDown() then s=s.."CTRL-" end
    if IsShiftKeyDown() then s=s.."SHIFT-" end
    return s..button
end
function E:KeyLabel(key)
    local text=key
    for _,b in ipairs(self.buttons) do text=string.gsub(text,b[1],self:L(b[2])) end
    text=string.gsub(text,"CTRL%-",E:L("Strg+"))
    text=string.gsub(text,"SHIFT%-","Shift+")
    return (string.gsub(text,"ALT%-","Alt+"))
end
function E:Kind(unit)
    if not unit or not UnitExists(unit) then return nil end
    if UnitCanAttack("player",unit) then return "hostile" end
    if self:SameUnit("player",unit) or UnitIsFriend("player",unit) then return "friendly" end
    return nil
end
function E:RefreshSpells()
    if not GetSpellName then return false end
    local spells,spellList,byID={},{},{}
    local iconsPending=false
    -- Vanilla's spellbook slots are contiguous. Later ranks overwrite bare names.
    for i=1,2048 do
        local name,rank,id=GetSpellName(i,BOOKTYPE_SPELL or "spell")
        if not name then break end
        if not IsPassiveSpell or not IsPassiveSpell(i,BOOKTYPE_SPELL or "spell") then
            rank=rank or ""
            local full=name..(rank~="" and "("..rank..")" or "")
            local entry={name=name,rank=rank,cast=full,slot=i,spellID=self:ReadSpellID(id,full,i),
                icon=GetSpellTexture and GetSpellTexture(i,BOOKTYPE_SPELL or "spell")}
            -- The basic melee action has a stable icon even when the client or
            -- a spellbook replacement supplies an empty/unusable texture.
            local lower=string.lower(name)
            if lower=="attack" or lower=="angriff" or (type(ATTACK)=="string" and lower==string.lower(ATTACK)) then
                entry.icon="Interface\\Icons\\INV_Sword_04"
            elseif type(entry.icon)~="string" or self:Trim(entry.icon)=="" then
                entry.icon="Interface\\Icons\\INV_Misc_QuestionMark"; iconsPending=true
            end
            spells[string.lower(name)]=entry
            spells[string.lower(full)]=entry
            if entry.spellID then byID[entry.spellID]=entry end
            table.insert(spellList,entry)
        end
    end
    if table.getn(spellList)==0 then
        self.spellBookReady=false
        self.spellBookRetry=GetTime()+.5
        self.spellBookRetryCount=(self.spellBookRetryCount or 0)+1
        return false
    end
    self.spells=spells; self.spellList=spellList; self.spellsByID=byID
    self.spellBookReady=true
    self.spellBookRetry=iconsPending and GetTime()+.5 or nil
    self.spellBookRetryCount=iconsPending and (self.spellBookRetryCount or 0)+1 or 0
    self.spellRestrictions={}; self.spellStatusQueue={}; self.spellRangeLimits={}
    self:InvalidateManaCosts()
    self:RememberSpellIdentities()
    self:MigrateSpellBindings()
    -- SPELLS_CHANGED can follow login/reload. Update question-mark icons without
    -- overwriting a name that the user is currently entering in the settings.
    for _,row in ipairs(self.bindingRows or {}) do
        local info=self:Resolve(self.db.bindings[row.kind][row.key])
        row.icon:SetTexture(info and info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    return true
end
function E:Resolve(text)
    if type(text)=="table" then return self:BindingInfo(text) end
    return self:ResolveSpellIdentity(text)
end
function E:SetBinding(kind,key,text)
    text=self:Trim(text)
    if text=="" then
        self.db.bindings[kind][key]=nil
        if self.initialized and self.RefreshWorldBindings then self:RefreshWorldBindings() end
        return true
    end
    if not self:Resolve(text) then return false end
    local action=self:SpellAction(text)
    self.db.bindings[kind][key]=action.spellID and action or text
    if self.initialized and self.RefreshWorldBindings then self:RefreshWorldBindings() end
    return true
end
function E:CastSpell(unit,text)
    if self.TestSuppressCast and self:TestSuppressCast() then
        self:TestLog("TROCKENTEST",tostring(self.castOrigin).." · "..tostring(text).." · "..self:UnitDescription(unit)); return false
    end
    local spell=self:Resolve(text)
    if not spell then self:Print(E:L("Spruch nicht gelernt oder unbekannt: ")..tostring(text)); return false end
    if not unit or not UnitExists(unit) then return false end
    if SpellIsTargeting and SpellIsTargeting() then
        self:Print(E:L("Bitte zuerst die aktive Zauberauswahl beenden.")); return false
    end
    return self:CastSpellOnUnit(unit,spell)
end
function E:Dispatch(unit,button)
    local running=self.nativeRun and self.nativeRun.started
    if self.CameraInput then self:CameraInput(button,"up") end
    if running then return true end -- A world run released over a unit frame is not a cast.
    if not self.db or not self.db.enabled or self:BypassRequested() then return false end
    local kind=self:Kind(unit)
    if not kind then return false end
    local key=self:Key(button)
    -- Unit frames use explicit bindings. World selection is handled separately.
    local text=self.db.bindings[kind][key]
    if not text or text=="" then return false end
    self.castOrigin="Unitframe"; self.castSource="OnClick"; self:Cast(unit,text); self.castOrigin=nil; self.castSource=nil
    return true -- A configured cast must never fall through into a unit menu.
end
function E:TooltipPoint(kind,cursorX,cursorY)
    local t=self.db.tips[kind]
    if t.mode=="fixed" then return "CENTER",t.x,t.y end
    return "BOTTOMLEFT",cursorX+t.x,cursorY+t.y
end
