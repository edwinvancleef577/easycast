local E=EasyCast
E.targetGeneration=0
function E:FrameValue(frame,method,param)
    if not frame or type(frame[method])~="function" then return nil end
    local ok,value
    if param~=nil then ok,value=pcall(frame[method],frame,param)
    else ok,value=pcall(frame[method],frame) end
    if ok then return value end
end
function E:SameUnit(a,b)
    if UnitIsUnit(a,b) then return true end
    local ga=self:UnitGUIDValue(a); local gb=self:UnitGUIDValue(b)
    return ga and gb and string.lower(ga)==string.lower(gb) or false
end
function E:WorldHoverUnit(focus)
    -- Normalize a real mouseover identity to the stable player token. Some
    -- extended clients expose equal GUIDs while UnitIsUnit returns nil.
    if UnitExists("mouseover") then
        if self:SameUnit("mouseover","player") then return "player","mouseover / eigene GUID" end
        return "mouseover","mouseover"
    end
    focus=focus or self:FocusDetails()
    local own=self:UnitGUIDValue("player")
    if focus.accepted and focus.guid and own and string.lower(focus.guid)==string.lower(own) then
        return "player","Weltframe / eigene GUID"
    end
    return nil,"Client meldet kein Welt-Mausziel"
end
function E:FocusDetails()
    local f=GetMouseFocus and GetMouseFocus()
    local chain={}; local node=f; local world=false; local depth=0
    local mouseGuid=self:UnitGUIDValue("mouseover")
    while node and depth<6 do
        local name=self:FrameValue(node,"GetName")
        local kind=self:FrameValue(node,"GetObjectType") or "?"
        table.insert(chain,(name or "<unbenannt>").." ["..kind.."]")
        if node==WorldFrame or name=="WorldFrame" then world=true end
        depth=depth+1
        local parent=self:FrameValue(node,"GetParent")
        if parent==node then break end
        node=parent
    end
    local direct=f and (f==WorldFrame or self:FrameValue(f,"GetName")=="WorldFrame")
    local guid=self:FrameValue(f,"GetName",1)
    -- GetName(1) is only evidence when it matches the current unit's real GUID.
    -- Ordinary unnamed/UI frames are never accepted merely because they lack a name.
    local ownGuid=self:UnitGUIDValue("player")
    local ownPlate=world and type(guid)=="string" and ownGuid and string.lower(guid)==string.lower(ownGuid)
    local plate=f and ((mouseGuid and guid==mouseGuid) or ownPlate)
    local knownUI=f and self.frames[f]
    local unit=f and self:FrameValue(f,"GetAttribute","unit")
    local nameplateToken=type(unit)=="string" and string.find(unit,"^nameplate%d+$")
    local tokenPlate=world and nameplateToken and UnitIsUnit(unit,"mouseover")
    local accepted=not knownUI and (direct or plate or tokenPlate)
    local reason
    if accepted then reason=direct and "WorldFrame" or "zugeordnete Namensplakette"
    elseif not f then reason="Client liefert keinen Mausframe"
    elseif knownUI then reason="Einheitenrahmen (UI)"
    else reason="UI oder noch nicht zugeordneter Frame" end
    return {frame=f,path=table.concat(chain," > "),accepted=accepted and true or false,
        reason=reason,guid=plate and guid or nil}
end
function E:IsWorldFocus()
    return self:FocusDetails().accepted
end
function E:InCombat()
    return UnitAffectingCombat and UnitAffectingCombat("player") and true or false
end
function E:AliveEnemy(unit)
    return self:Kind(unit)=="hostile" and (not UnitIsDeadOrGhost or not UnitIsDeadOrGhost(unit))
end
-- Keep unit identity, never just a name (two NPCs may have the same name).
function E:HoverIdentity(unit)
    unit=unit or "mouseover"
    local guid=self:UnitGUIDValue(unit)
    local token
    for _,u in ipairs({"player","pet","target","party1","party2","party3","party4",
        "partypet1","partypet2","partypet3","partypet4"}) do
        if self:SameUnit(u,unit) then token=u; break end
    end
    if not token then
        for i=1,40 do
            if UnitIsUnit("raid"..i,unit) then token="raid"..i; break end
        end
    end
    return {guid=guid,token=token,name=UnitName(unit),kind=self:Kind(unit),
        own=self:SameUnit(unit,"player") and true or false,
        selected=UnitIsUnit(unit,"target") and true or false,
        targetGeneration=self.targetGeneration}
end
function E:CaptureWorldHover()
    if not self.db or not self.db.enabled or not self.db.world.enabled or self.previewKind then
        self.worldHover=nil; return
    end
    if not self:IsWorldFocus() then self.worldHover=nil; return end
    if IsMouselooking and IsMouselooking() then return end
    local unit=self:WorldHoverUnit()
    if self:Kind(unit) then
        local h=self:HoverIdentity(unit)
        h.time=GetTime(); h.x,h.y=GetCursorPosition()
        self.worldHover=h
    else
        -- An empty world observed on a regular update invalidates the cache.
        -- Only the short gap between that update and the input callback is bridged.
        self.worldHover=nil
    end
end
function E:IdentityUnit(h,ignoreGeneration)
    if not h or (not ignoreGeneration and h.targetGeneration~=self.targetGeneration) then return nil end
    if h.token and UnitExists(h.token) then
        if h.guid then
            if self:UnitGUIDValue(h.token)==h.guid then return h.token end
        elseif self:Kind(h.token)==h.kind and UnitName(h.token)==h.name then
            -- Stable player/party tokens; target swaps are guarded by the event.
            return h.token
        end
    end
    if h.guid and self:UnitGUIDValue("mouseover")==h.guid and UnitExists("mouseover") then return "mouseover" end
    -- Extended clients may accept a GUID as a unit token. Validate before use.
    if h.guid and UnitExists(h.guid) and self:UnitGUIDValue(h.guid)==h.guid then return h.guid end
end
function E:CachedHoverUnit(h) return self:IdentityUnit(h) end
-- Bypass wins over self-cast and includes combinations (Alt+Shift, for example).
function E:BypassRequested(prefix)
    local key=self.db and self.db.world and self.db.world.bypassModifier
    return key and key~="none" and string.find(prefix or self:Key(""),key,1,true)~=nil or false
end
function E:CastWorldAction(unit,value,kind)
    if self:BypassRequested() then return false end
    -- Called only from a real input callback after gesture/identity validation.
    -- A direct hostile cast keeps its enemy selected; friendly casts restore it.
    if kind=="hostile" and self.db.world.enemyMode=="direct" and not UnitIsUnit(unit,"target") and not self:TestSuppressCast() then
        local identity=self:HoverIdentity(unit)
        self:APIStart("TargetUnit",unit); TargetUnit(unit); self:APIEnd()
        if not UnitExists("target") or (identity.guid and self:UnitGUIDValue("target")~=identity.guid) or not UnitIsUnit(unit,"target") then return false end
        unit="target"
    end
    return self:Cast(unit,value)
end
function E:SelfCastRequested(prefix)
    local key=self.db.world.selfModifier
    return key and key~="none" and (prefix or self:Key(""))==key
end
function E:ResolveWorldTarget(button,allowCache,prefix)
    if self:BypassRequested() or self:BypassRequested(prefix) then return nil,nil,"EasyCast-Aussetztaste gehalten" end
    if self.worldBlocked then return nil,nil,"Client-Sperre: "..self.worldBlocked end
    if not self.db.enabled then return nil,nil,"EasyCast aus" end
    if not self.db.world.enabled then return nil,nil,"Weltklicks aus" end
    local focus=self:FocusDetails()
    if not focus.accepted then return nil,nil,focus.reason end
    if IsMouselooking and IsMouselooking() then return nil,nil,"Kamera aktiv" end
    if self.previewKind then return nil,nil,"Positionsvorschau aktiv" end
    if self:SelfCastRequested(prefix) then
        if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return nil,nil,"Eigener Spieler ist tot" end
        return "player","self-modifier",nil,"friendly"
    end
    local h,unit,mode
    local hover,origin=self:WorldHoverUnit(focus)
    if self:Kind(hover) then
        h=self:HoverIdentity(hover); unit=hover; mode=origin
    elseif allowCache and self.worldHover then
        local candidate=self.worldHover; local x,y=GetCursorPosition()
        if GetTime()-candidate.time<=0.15 and (x-candidate.x)^2+(y-candidate.y)^2<=(self.db.world.dragPixels or 6)^2 then
            h=candidate; unit=self:IdentityUnit(h); mode="snapshot"
            if not unit then return nil,nil,"Letzte Maus-Einheit nicht mehr eindeutig erreichbar" end
        end
    end
    -- An explicit self modifier separates the player's model from the enemy
    -- behind it during combat. Other friendly mouse targets still take priority.
    if h and h.own and self.db.world.selfModifier~="none" and self:InCombat() and self:AliveEnemy("target") then
        h=nil; unit=nil; mode="self-guard"
    end
    if h and h.kind=="friendly" then
        -- Resolve per input, including its exact modifier. A passing friend must
        -- not swallow a hostile-only binding on the currently selected enemy.
        local key=button and ((prefix or self:Key(""))..button)
        local friendly=key and self.db.bindings.friendly[key]
        if key and (not friendly or friendly=="") and self:AliveEnemy("target") then
            return "target","friendly-unbound-hostile-selection",nil,"hostile"
        end
        if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then return nil,nil,"Freund ist tot" end
        return unit,mode,nil,"friendly"
    end
    if h and h.kind=="hostile" and self.db.world.enemyMode=="direct" and self:AliveEnemy(unit) then
        return unit,"direct-hostile",nil,"hostile"
    end
    if h and h.kind=="hostile" and button=="LeftButton" and not h.selected then
        return nil,nil,"Anderer Gegner: nur Zielauswahl"
    end
    if UnitIsUnit("target","player") and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
        return "player","self-selection",nil,"friendly"
    end
    if self:AliveEnemy("target") then return "target",mode=="self-guard" and "Selbst erkannt; Gegner bis Selbstzauber-Taste" or "selection",nil,"hostile" end
    return nil,nil,"Kein freundliches Mausziel und kein Gegner ausgewählt"
end

function E:WorldTipUnit()
    local hover=self:WorldHoverUnit()
    local chosen=self:ResolveWorldTarget()
    if chosen and (self:SelfCastRequested() or (hover and self:SameUnit(hover,"player") and not self:SameUnit(chosen,hover))) then
        return chosen,true
    end
    return hover,false
end
