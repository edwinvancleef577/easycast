local E=EasyCast
function E:RemoveWorldHooks()
    if not self.worldHooks then return end
    for _,h in pairs(self.worldHooks) do
        h.active=false
        if WorldFrame:GetScript(h.event)==h.wrapper then WorldFrame:SetScript(h.event,h.original) end
    end
    self.worldHooks=nil; self:CancelWorldClicks("Welt-Handler entfernt")
end
function E:RefreshWorldHooks()
    local active=self.nativeRun or self.runTest or self.bindingTest or self.mouseTest or (self.db and self.db.enabled and self.db.world.enabled and not self.worldBlocked and not self.traceRunning)
    if not active then self:RemoveWorldHooks(); return end
    if self.worldHooks or not WorldFrame then return end
    self.worldHooks={}
    for _,phase in ipairs({"down","up"}) do
        local h={event=phase=="down" and "OnMouseDown" or "OnMouseUp",active=true,phase=phase}
        h.original=WorldFrame:GetScript(h.event)
        h.wrapper=function(...)
            local a,b=arg[1],arg[2]
            local button=b or (type(a)=="string" and a) or arg1
            if h.active and E.runTest then E:RunTestInput(h.phase,button,"WorldFrame vor Original") end
            if h.active then E:CameraInput(button,h.phase) end
            local direct=h.active and E:ClickTestOwns(button)
            if h.active and h.phase=="down" and not direct then E:WorldInput("down",button,"WorldFrame") end
            if h.original then h.original(unpack(arg)) end
            if E.mouseTest then E:UpdateMouseTest() end
            if direct then
                local consumed,request=E:PrepareClickTest(h.phase,button)
                if request then
                    if request.route=="button" then E:RunButtonClickTest(request)
                    else
                        -- Deliberately direct, inside the native input callback:
                        -- no EasyCast Cast/WithUnit/pcall wrapper, target operation
                        -- or deferred execution. Native handler has already run.
                        CastSpellByName(request.spell.cast)
                        E:FinishDirectClickCall(request)
                    end
                end
            elseif h.active and h.phase=="up" then E:WorldInput("up",button,"WorldFrame") end
        end
        self.worldHooks[h.event]=h
        self:APIStart("WorldFrame.SetScript",h.event)
        local ok,err=pcall(WorldFrame.SetScript,WorldFrame,h.event,h.wrapper); self:APIEnd()
        if not ok then self:RemoveWorldHooks(); self:Print("Welt-Handler: "..tostring(err)); return end
    end
end
