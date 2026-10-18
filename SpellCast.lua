local E=EasyCast
function E:CastSpellOnUnit(unit,spell)
    local backend=(C_Spell and type(C_Spell.CastAtUnit)=="function") and "CastAtUnit" or
        ((tonumber(SUPERWOW_VERSION) or 0)>0 and "SuperWoW" or "Vanilla")
    local hadTarget=UnitExists("target")
    local originallySelected=self:SameUnit("target",unit)
    local switched=false
    local previousAuto,restoreAuto
    local attempt=self:BeginCastDiagnosis(unit,spell)
    self:TestLog("ZAUBERZIEL",backend.." · explizit="..self:UnitDescription(unit))
    local ok,result=pcall(function()
        -- A friendly cast must never silently fall back to the player. Keep the
        -- user's CVar unchanged outside this synchronous input callback.
        if not E:SameUnit(unit,"player") and type(GetCVar)=="function" and type(SetCVar)=="function" then
            previousAuto=GetCVar("autoSelfCast")
            if previousAuto~=nil and tostring(previousAuto)~="0" then
                restoreAuto=true; SetCVar("autoSelfCast","0")
            end
        end
        if backend=="CastAtUnit" then
            E:APIStart("C_Spell.CastAtUnit",spell.cast.." · "..unit)
            local value=C_Spell.CastAtUnit(spell.cast,unit); E:APIEnd(); return value
        elseif backend=="SuperWoW" then
            -- Only SuperWoW's documented extension accepts a unit here. A
            -- string on stock Vanilla would be interpreted as self-cast=true.
            E:APIStart("CastSpellByName",spell.cast.." · unit="..unit)
            local value=CastSpellByName(spell.cast,unit); E:APIEnd()
            return value
        end
        if not originallySelected then
            E:APIStart("TargetUnit",unit); TargetUnit(unit); E:APIEnd()
            switched=true
            if not E:SameUnit("target",unit) then return false end
        end
        E:APIStart("CastSpellByName",spell.cast.." · Ziel="..unit.." · AutoSelfCast aus")
        -- Explicit false prevents an accidental truthy unit argument on Vanilla.
        local value=CastSpellByName(spell.cast,E:SameUnit(unit,"player") and true or false)
        E:APIEnd()
        if SpellIsTargeting and SpellIsTargeting() then
            -- A client may process the target switch after the first cast call.
            -- Complete the same cast on its intended target; never retry it.
            if not E:SameUnit("target",unit) or not SpellTargetUnit then return false end
            E:APIStart("SpellTargetUnit",unit); SpellTargetUnit(unit); E:APIEnd()
        end
        return value
    end)
    self:APIEnd()
    -- Cleanup also runs when a client API or an addon hook throws an error.
    if SpellIsTargeting and SpellIsTargeting() and SpellStopTargeting then pcall(SpellStopTargeting) end
    if restoreAuto then
        local restored,err=pcall(SetCVar,"autoSelfCast",previousAuto)
        if not restored then self:TestLog("WIEDERHERSTELLUNG","autoSelfCast: "..tostring(err)) end
    end
    -- Some SuperWoW attacks can select their explicit unit. Friendly casts must
    -- still restore the prior selection; direct-hostile selection happens earlier.
    if switched or (not originallySelected and self:SameUnit("target",unit)) then
        if hadTarget then pcall(TargetLastTarget) else pcall(ClearTarget) end
    end
    self:EndCastDiagnosis(attempt,ok,ok and result)
    if not ok then self:Print(self:L("Zauberaufruf fehlgeschlagen: ")..tostring(result)) end
    return ok and result~=false
end
