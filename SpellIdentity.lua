-- Persist real spell IDs, never spellbook positions or guessed icon matches.
-- Names remain accepted for editing; IDs resolve them in the current client language.
local E=EasyCast
function E:ReadSpellID(id,full,slot)
    if type(id)=="number" and id>0 and id==math.floor(id) then return id end
    if type(GetSpellIdForName)=="function" then
        local ok,value=pcall(GetSpellIdForName,full)
        if ok and type(value)=="number" and value>0 and value==math.floor(value) then return value end
    end
    -- Some clients expose IDs only in spell hyperlinks. Never use the slot
    -- itself as an ID: spellbook positions change with language and training.
    if slot and type(GetSpellLink)=="function" then
        local ok,link=pcall(GetSpellLink,slot,BOOKTYPE_SPELL or "spell")
        if ok and type(link)=="string" then
            local _,_,value=string.find(link,"spell:(%d+)")
            value=tonumber(value)
            if value and value>0 then return value end
        end
    end
end
function E:RememberSpellIdentities()
    if not self.db then return end
    self.db.spellAliases=self.db.spellAliases or {}
    local aliases=self.db.spellAliases
    local anchors={}
    for _,entry in ipairs(self.spellList) do
        if entry.spellID and not anchors[entry.name] then anchors[entry.name]=entry.spellID end
    end
    for key,entry in pairs(self.spells) do
        if entry.spellID then
            -- Retain old-language names across sessions, profiles and rank upgrades.
            -- A collision must not silently redirect an old binding to another spell.
            local old=aliases[key]
            if not old then
                local highest=key==string.lower(entry.name)
                aliases[key]={id=highest and anchors[entry.name] or entry.spellID,highest=highest}
            end
        end
    end
end
function E:SpellAction(value)
    if type(value)=="table" and value.type~="spell" then return self:Copy(value) end
    local action=type(value)=="table" and self:Copy(value) or {type="spell",value=value}
    local entry=self:ResolveSpellIdentity(value)
    if entry and entry.spellID and not action.spellID then
        local key=string.lower(self:Trim(action.value))
        local alias=self.db.spellAliases[key]
        action.spellID=entry.spellID
        action.highest=(alias and alias.highest) or key==string.lower(entry.name) or false
    end
    return action
end
function E:MigrateSpellBindings()
    local function migrate(bindings)
        for _,group in pairs(bindings or {}) do
            for key,value in pairs(group) do
                if type(value)=="string" or (type(value)=="table" and value.type=="spell") then
                    local action=E:SpellAction(value)
                    if action.spellID then group[key]=action end
                end
            end
        end
    end
    migrate(self.db.bindings)
    for _,profile in pairs(self.db.profiles or {}) do migrate(profile.bindings) end
end
function E:ResolveSpellIdentity(text)
    if self.spellBookReady==false then return end
    if type(text)=="table" then
        if text.spellID then
            local entry=self.spellsByID and self.spellsByID[text.spellID]
            if entry then return text.highest and self.spells[string.lower(entry.name)] or entry end
            -- An available ID index is authoritative; an unlearned spell must
            -- not silently turn into a different spell with the same name.
            if self.spellsByID and next(self.spellsByID) then return end
        end
        text=text.value
    end
    if type(text)~="string" then return end
    local key=string.lower(self:Trim(text))
    local alias=self.db and self.db.spellAliases and self.db.spellAliases[key]
    if alias and self.spellsByID and next(self.spellsByID) then
        local entry=self.spellsByID[alias.id]
        if not entry then return end -- Never substitute another rank for an unlearned explicit ID.
        return alias.highest and self.spells[string.lower(entry.name)] or entry
    end
    -- Stock clients still work by current-language names; no mandatory extension.
    return self.spells[key]
end
