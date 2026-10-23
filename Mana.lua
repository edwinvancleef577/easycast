-- Read-only affordability checks for the exact learned rank. Never allocate an
-- action slot, change targets or cast a spell to find its cost.
-- Nampower's IsSpellUsable returns its mana flag separately from usability:
-- https://github.com/Emyrk/nampower/blob/main/SCRIPTS.md
local E=EasyCast
E.spellManaCosts={}
local function flag(value)
    if value==true or value==1 then return true end
    if value==false or value==0 then return false end
end
function E:ReadManaCost(text)
    if type(text)~="string" or type(MANA_COST)~="string" then return end
    -- Use the client's localized cost header, not translated prose or a base
    -- database cost that would ignore talents and temporary cost reductions.
    local format,count=string.gsub(MANA_COST,"%%1%$d","ECMANAAMOUNT")
    local n; format,n=string.gsub(format,"%%d","ECMANAAMOUNT"); count=count+n
    if count~=1 then return end
    local pattern=string.gsub(format,"([%(%)%.%%%+%-%*%?%[%]%^%$])","%%%1")
    pattern=string.gsub(pattern,"ECMANAAMOUNT","(%%d+)")
    local _,_,amount=string.find(text,"^"..pattern.."$")
    return tonumber(amount)
end
function E:InvalidateManaCosts()
    self.spellManaCosts={}
end
function E:BindingLacksMana(value,info)
    if type(value)=="table" and value.type~="spell" then return end
    if not info or not info.slot then return end
    -- UnitMana reports rage/energy in forms too. A droplet must not claim
    -- insufficient mana for a different resource.
    if type(UnitPowerType)~="function" or UnitPowerType("player")~=0 then return end
    local spell=info.spellID or info.cast or info.name
    local native={IsSpellUsable,IsUsableSpell,C_Spell and C_Spell.IsSpellUsable}
    -- Explicit indices: optional API holes must not stop ipairs traversal.
    for i=1,3 do
        local fn=native[i]
        if type(fn)=="function" then
            local identifier=i==2 and (info.cast or info.name) or spell
            local ok,usable,lacking=pcall(fn,identifier)
            if ok and flag(lacking)~=nil then return flag(lacking) end
        end
    end
    local key=info.cast or info.name
    local cost=self.spellManaCosts[key]
    if cost==nil then self.spellStatusQueue[key]=info; return end
    if type(cost)~="number" or type(UnitMana)~="function" then return end
    local mana=UnitMana("player")
    if type(mana)=="number" and mana>=0 then return mana<cost end
end
function E:CreateManaBadge(parent)
    -- Native UI rectangles form a filled droplet, readable even at eight pixels.
    -- No font glyph or external texture dependency; all clients get the same mark.
    local badge=CreateFrame("Frame",nil,parent); badge:EnableMouse(false)
    badge:SetPoint("TOPRIGHT",parent,"TOPRIGHT",2,2); badge.rows={}
    for i,width in ipairs({1,3,3,5,7,7,5,3}) do
        local row=badge:CreateTexture(nil,"OVERLAY"); row:SetTexture(1,.48,.48,1)
        badge.rows[i]={texture=row,width=width}
    end
    return badge
end
function E:SizeManaBadge(badge,size)
    badge:SetWidth(size); badge:SetHeight(size)
    local pixel=size/8
    for i,row in ipairs(badge.rows) do
        row.texture:ClearAllPoints(); row.texture:SetPoint("TOP",badge,"TOP",0,-(i-1)*pixel)
        row.texture:SetWidth(row.width*pixel); row.texture:SetHeight(pixel)
    end
end
