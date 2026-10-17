local E=EasyCast
-- Cells never repeat the common modifier. All input labels/icons are left aligned.
function E:BindingCellMetrics(entry,size,mode,iconGap)
    iconGap=iconGap or 4
    local label=entry.label or self:KeyLabel(entry.button) or ""
    if mode=="off" then return size,size end
    if mode=="text" then return math.max(size,self:LabelWidth(label,9)),size+12+iconGap end
    return size+(self.worldKeyNames[entry.button] and size+iconGap or self:LabelWidth(label,9)+iconGap),math.max(size,12)
end
function E:LayoutBindingCell(cell,entry,size,width,mode,iconGap)
    iconGap=iconGap or 4
    cell.glyph=cell.glyph or cell:CreateTexture(nil,"ARTWORK")
    cell.icon:ClearAllPoints(); cell.key:ClearAllPoints(); cell.glyph:ClearAllPoints()
    cell.key:Hide(); cell.glyph:Hide()
    cell.icon:SetWidth(size); cell.icon:SetHeight(size); cell.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); cell.icon:Show()
    local label=entry.label or self:KeyLabel(entry.button) or ""
    if mode=="text" then
        cell.key:SetText(label); cell.key:SetJustifyH("LEFT"); cell.key:SetWidth(width); cell.key:SetHeight(12)
        cell.key:SetPoint("TOPLEFT",cell,"TOPLEFT",0,0); cell.key:Show()
        cell.icon:SetPoint("TOPLEFT",cell,"TOPLEFT",0,-12-iconGap)
    elseif mode=="icon" then
        local x=0
        if self.worldKeyNames[entry.button] then
            cell.glyph:SetTexture(self:InputGlyph(entry.button)); cell.glyph:SetWidth(size); cell.glyph:SetHeight(size)
            cell.glyph:SetPoint("LEFT",cell,"LEFT",0,0); cell.glyph:Show(); x=size+iconGap
        else
            local w=self:LabelWidth(label,9)
            cell.key:SetText(label); cell.key:SetWidth(w); cell.key:SetHeight(math.max(size,12)); cell.key:SetJustifyH("LEFT")
            cell.key:SetPoint("LEFT",cell,"LEFT",0,0); cell.key:Show(); x=w+iconGap
        end
        cell.icon:SetPoint("LEFT",cell,"LEFT",x,0)
    else cell.icon:SetPoint("LEFT",cell,"LEFT",0,0) end
    self:PaintBindingRange(cell,entry.range)
    self:PaintBindingStatus(cell,entry.status)
end
function E:ModifierFooter(frame,prefix,width,top,inset)
    frame.modifierCaps=frame.modifierCaps or {}
    local labels={}
    for _,v in ipairs({{"ALT-","Alt"},{"CTRL-",E:L("Strg")},{"SHIFT-","Shift"}}) do
        if string.find(prefix or "",v[1],1,true) then table.insert(labels,v[2]) end
    end
    local total=0
    for _,label in ipairs(labels) do total=total+self:LabelWidth(label,9)+10+4 end
    total=math.max(0,total-4)
    local x=0
    for i,label in ipairs(labels) do
        local cap=frame.modifierCaps[i]
        if not cap then
            cap=self:Box(frame,30,16); cap:EnableMouse(false); cap.label=self:Text(cap,9)
            cap.label:SetPoint("CENTER",cap,"CENTER",0,0); frame.modifierCaps[i]=cap
        end
        cap:SetFrameStrata(frame:GetFrameStrata()); cap:SetFrameLevel(frame:GetFrameLevel()+1)
        local w=self:LabelWidth(label,9)+10
        cap:SetWidth(w); cap:SetHeight(16); cap.label:SetText(label)
        cap:SetBackdropColor(.12,.13,.12,.9); cap:SetBackdropBorderColor(.44,.45,.42,.9)
        cap:ClearAllPoints(); cap:SetPoint("TOP",frame,"TOP",x-total/2+w/2,-top); cap:Show(); x=x+w+4
    end
    for i=table.getn(labels)+1,table.getn(frame.modifierCaps) do frame.modifierCaps[i]:Hide() end
    return math.max(0,x-4),table.getn(labels)>0 and 20 or 0
end
-- Shared live/preview/native layout. A wider unit name never changes wrapping.
function E:LayoutBindings(frame,entries,t,maxWidth,top,inset,prefix)
    frame.cells=frame.cells or {}; local cells=frame.cells
    local count=table.getn(entries); local size=t.size or 16; local gap=t.gap or 4
    local mode=t.labelMode or "icon"; local cw,ch=size,size
    for _,entry in ipairs(entries) do
        local w,h=self:BindingCellMetrics(entry,size,mode,t.iconGap); cw=math.max(cw,w); ch=math.max(ch,h)
    end
    local columns,rows
    if t.layout=="horizontal" then
        columns=math.max(1,math.min(count,t.perRow or 5)); rows=math.ceil(count/columns)
    else
        columns=math.max(t.style=="integrated" and 2 or 1,t.columns or 1)
        rows=math.ceil(count/columns)
    end
    -- Screen boundary is the only emergency wrap, independent of native text width.
    columns=math.max(1,math.min(columns,math.floor((maxWidth+gap)/(cw+gap))))
    rows=math.ceil(count/columns)
    for i,entry in ipairs(entries) do
        local cell=cells[i]
        if not cell then
            cell=CreateFrame("Frame",nil,frame); cell:EnableMouse(false)
            cell.icon=cell:CreateTexture(nil,"ARTWORK"); cell.key=self:Text(cell,10); cells[i]=cell
        end
        local col,row
        if t.layout=="horizontal" then col=math.mod(i-1,columns); row=math.floor((i-1)/columns)
        else col=math.floor((i-1)/math.max(1,rows)); row=math.mod(i-1,math.max(1,rows)) end
        cell:SetFrameStrata(frame:GetFrameStrata()); cell:SetFrameLevel(frame:GetFrameLevel()+1)
        cell:ClearAllPoints(); cell:SetPoint("TOPLEFT",frame,"TOPLEFT",inset+col*(cw+gap),-top-row*(ch+gap))
        cell:SetWidth(cw); cell:SetHeight(ch); cell.button=entry.button
        self:LayoutBindingCell(cell,entry,size,cw,mode,t.iconGap); cell:Show()
    end
    for i=count+1,table.getn(cells) do cells[i]:Hide() end
    local width=columns*cw+(columns-1)*gap
    local height=rows>0 and rows*ch+math.max(0,rows-1)*gap or 0
    local fw,fh=self:ModifierFooter(frame,prefix,width,top+height+5,inset)
    return math.max(width,fw),height+(fh>0 and 5+fh or 0)
end
