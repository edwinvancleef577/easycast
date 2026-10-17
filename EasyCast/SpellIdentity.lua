-- Persist real spell IDs, never spellbook positions or guessed icon matches.
-- Names remain accepted for editing; IDs resolve them in the current client language.
local E=EasyCast
function E:ReadSpellID(id,full)
    if type(id)=="number" and id>0 and id==math.floor(id) then return id end
    if type(GetSpellIdForName)=="function" then
        local ok,value=pcall(GetSpellIdForName,full)
        if ok and type(value)=="number" and value>0 and value==math.floor(value) then return value end
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
function E:ResolveSpellIdentity(text)
    if self.spellBookReady==false or type(text)~="string" then return end
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
