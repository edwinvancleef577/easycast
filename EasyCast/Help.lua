local E=EasyCast
local explanations={
    ["EasyCast"]="Schaltet EasyCast insgesamt ein oder aus. Die gespeicherten Belegungen bleiben erhalten.",
    ["Bedienhilfen (500 ms)"]="Zeigt Erklärungen nach einer halben Sekunde über EasyCast-Bedienelementen. Ausschalten blendet diese Bedienhilfen aus; die Zauber-Belegungshilfe bleibt unverändert.",
    ["Weltklicks"]="Aktiviert deine Belegungen direkt in der Spielwelt. Bei Links/Rechts trennen die Klickgrenzen Zaubern von Kameraziehen. Mitte, Maus 4/5 und Tastatur zaubern beim Loslassen ohne Zeit-/Bewegungsfilter.",
    ["Begleitdiagnose"]="Protokolliert Eingaben, Entscheidungen und Clientmeldungen während des Spielens. Einschalten beginnt einen neuen Bericht; Ausschalten bewahrt ihn auf.",
    ["Speichern"]="Speichert die aktuellen Belegungen und Optionen unter dem eingetragenen Profilnamen. Ein gleichnamiges Profil wird aktualisiert.",
    ["Diagnose …"]="Öffnet die optionalen Diagnosewerkzeuge: Aufnahme, Bericht, Mausbeobachtung und Eingabetests.",
    ["Position zeigen / ziehen"]="Zeigt die Belegungshilfe außerhalb des Menüs an ihrer eingestellten Position. Bei fester Position kannst du sie ziehen. Erneut klicken beendet die Anzeige.",
    ["Zurücksetzen"]="Setzt nur die Position der Belegungshilfe im ausgewählten Bereich und Positionsmodus zurück.",
    ["Belegungshilfe"]="Zeigt oder verbirgt EasyCasts Belegungen für den ausgewählten Bereich. Die gemeinsame Darstellung bleibt erhalten.",
    ["Bericht öffnen"]="Öffnet den Diagnosebericht zum Lesen und Kopieren.",
    ["Bericht"]="Öffnet den Bericht zum aktuellen Test zum Lesen und Kopieren.",
    ["Mausanzeige"]="Öffnet oder schließt die Live-Anzeige von Mausziel, Eingabe, Druckdauer und EasyCasts Entscheidung.",
    ["Live prüfen"]="Startet eine neue Begleitdiagnose und öffnet die laufende Mausanzeige. Normales Zaubern bleibt aktiv.",
    ["Tastenbindung testen"]="Vergleicht echte Links-, Rechts- und Mittelklick-Bindungen anhand eines Selbstzaubers. Folge den Schritten im Testfenster.",
    ["Blessing: A / B"]="Vergleicht Blessing of Might über einen echten UI-Knopf mit dem Weltklick-Test. Du musst den Spruch gelernt haben.",
    ["Mini-Klickfläche"]="Öffnet den Vergleich zwischen einer durchlässigen Erkennungsfläche und einer klickbaren Zauberfläche.",
    ["×"]="Entfernt die Belegung dieser Zeile für die oben ausgewählte Fraktion und Zusatztaste.",
    ["Taste hinzufügen"]="Fügt die eingetragene Taste zur Belegungsliste hinzu und springt zu ihrer Zeile. Anschließend den Spruch oder die Aktion zuweisen.",
    ["Taste erfassen"]="Drücke und löse eine Taste, etwa F6, um sie zur Liste hinzuzufügen. Escape bricht ab. Zusatztasten werden oben separat gewählt.",
    ["Abbrechen"]="Bricht den aktuellen Erfassungs- oder Diagnoseschritt ab und gibt temporäre Testbindungen frei.",
    ["Vorschau / Position verschieben"]="Zeigt die gewählte Belegungshilfe als Vorschau. Bei fester Bildschirmposition kannst du sie ziehen. Erneutes Klicken beendet die Vorschau.",
    ["Position zurücksetzen"]="Setzt X und Y für den gewählten Tooltip und Positionsmodus auf die Ausgangswerte zurück.",
    ["Schließen"]="Schließt dieses Fenster. Ein dazugehöriger Eingabetest wird beendet.",
    ["Anhalten"]="Friert die Mausanzeige zum Lesen ein. Die Spielsteuerung und Begleitdiagnose laufen weiter.",
    ["Weiter"]="Setzt die Aktualisierung der Mausanzeige fort.",
    ["Neu beginnen"]="Beginnt diesen Diagnosetest neu und setzt seine bisherigen Messwerte zurück.",
    ["Fläche entfernen"]="Entfernt die experimentelle Klickfläche aus der Welt. Die Live-Anzeige bleibt offen.",
    ["1 · Grau: nur Gegner erkennen"]="Platziert eine durchlässige Testfläche. Der Client kann das Weltziel dahinter erkennen; die Fläche empfängt keine Klicks.",
    ["2 · Grün: Selbstzauber testen"]="Platziert eine klickbare Testfläche. Ein echter Klick kann zaubern; die Fläche kann dabei die Welterkennung dahinter verdecken.",
    ["TEST STARTEN"]="Bereitet den angezeigten Weltklick-Vergleich vor. Warte auf BEREIT und klicke dann einmal außerhalb des Fensters.",
    ["Vergleich: Zauber mit diesem UI-Knopf auslösen"]="Wirkt den im Test gewählten Zauber direkt durch diesen echten UI-Klick. Damit vergleichst du ihn mit dem Weltklick-Weg."
}
function E:RegisterHelp(widget,title,text)
    if not widget then return end
    widget.easyCastHelp=true; widget.helpTitle=title; widget.helpText=text
end
function E:ControlHelpTitle(widget)
    return widget.helpTitle or (widget.label and widget.label:GetText()) or "EasyCast"
end
function E:ControlHelpText(widget)
    if widget.helpText then return self:L(type(widget.helpText)=="function" and widget.helpText() or widget.helpText) end
    local title=self:SourceText(self:ControlHelpTitle(widget))
    if explanations[title] then return self:L(explanations[title]) end
    local plain=string.gsub(title,"%s+·%s+[A-Z]+$","")
    plain=self:SourceText(plain); title=plain
    if explanations[plain] then return self:L(explanations[plain]) end
    if widget.options then
        local choices=type(widget.options)=="function" and widget.options() or widget.options
        local labels={}; for _,v in ipairs(choices or {}) do table.insert(labels,widget.rawLabels and v[2] or self:L(v[2])) end
        return self:L("Öffnet die Auswahl. Verfügbar: ")..table.concat(labels,"; ").."."
    end
    if string.find(title,"^Belegungshilfe:") then return self:L("Zeigt oder verbirgt die Zauber-Belegungshilfe ausschließlich im oben gewählten Bereich.") end
    if (string.find(title,"^WoW%-Tooltip") or string.find(title,"^WoW%-Einheitentooltip")) then return self:L("Zeigt oder verbirgt das normale Einheiten-Tooltip im gewählten Bereich. Item- und Zaubertooltips bleiben erhalten. Bei ausgeschaltetem WoW-Tooltip erscheint eine aktivierte Belegungshilfe separat, auch im integrierten Modus.") end
    if string.find(title," testen$") then return self:L("Belegt diese Maustaste vorübergehend für den Selbstzauber-Test um. Warte auf BEREIT, klicke auf freien Boden und lasse los. Die ursprüngliche Bindung wird anschließend wiederhergestellt.") end
    if string.find(title,"^A:") or string.find(title,"^A ·") then return self:L(explanations["Vergleich: Zauber mit diesem UI-Knopf auslösen"]) end
    if string.find(title,"^B:") or string.find(title,"^B ·") then return self:L(explanations["TEST STARTEN"]) end
    return self:L("Führt den angezeigten Schritt aus: ")..self:L(title).."."
end
function E:ResetControlHelp()
    self.helpOwner=nil; self.helpSince=nil; self.helpSignature=nil
    if self.controlTooltip then self.controlTooltip:Hide() end
end
function E:UpdateControlHelp()
    if not self.db or not self.db.helpTooltips or not GetMouseFocus then self:ResetControlHelp(); return end
    local widget=GetMouseFocus(); local count=0
    while widget and not widget.easyCastHelp and count<20 do
        widget=widget.GetParent and widget:GetParent(); count=count+1
    end
    if not widget or not widget.easyCastHelp or not widget:IsVisible() or widget.pressed or widget.helpDragging then self:ResetControlHelp(); return end
    local title=self:SourceText(self:ControlHelpTitle(widget)); local text=self:ControlHelpText(widget); local signature=title.."\n"..text
    if self.helpOwner~=widget or self.helpSignature~=signature then
        self:ResetControlHelp(); self.helpOwner=widget; self.helpSignature=signature; self.helpSince=GetTime(); return
    end
    if GetTime()-(self.helpSince or GetTime())<.5 then return end
    local tip=self.controlTooltip
    if not tip then
        tip=CreateFrame("GameTooltip","EasyCastControlTooltip",UIParent,"GameTooltipTemplate")
        tip:EnableMouse(false); if tip.SetClampedToScreen then tip:SetClampedToScreen(true) end
        self.controlTooltip=tip; tip:Hide()
    end
    if tip:IsShown() then return end
    tip:SetFrameStrata("TOOLTIP"); tip:SetFrameLevel(math.max(1000,widget:GetFrameLevel()+10))
    tip:SetOwner(widget,"ANCHOR_RIGHT"); tip:ClearLines(); tip:SetText(self:L(title),.9,.76,.43)
    tip:AddLine(text,.92,.92,.88,true); tip:Show()
end
function E:AttachSettingsHelp()
    local descriptions={
        mainDropdown="Wechselt zwischen allgemeinen Optionen, Zauberbelegungen und Tooltip-Einstellungen.",
        kindDropdown="Wählt die Belegungsliste für freundliche oder feindliche Ziele. Änderungen gelten nur für diese Liste.",
        modDropdown="Wählt die Zusatztasten zur Belegung, etwa Shift oder Strg. Jede Kombination hat ihre eigene Liste. Die rot markierte Selbstzaubertaste ist bei Feindlich gesperrt; ihre Selbstzauber werden unter Freundlich belegt.",
        copyBindings="Kopiert alle Maus-, Mausrad- und Tastaturbelegungen der Quelle in die oben gewählte Zusatztaste. Ersetzt auch leere Einträge. Freundlich und Feindlich bleiben getrennt.",
        copySource="Quell-Zusatztaste wählen. Kopiert wird erst mit Kopieren von. Auch gespeicherte Belegungen reservierter Tasten sind als Quelle verfügbar.",
        clickMillis="Maximale Dauer eines Weltklicks nur für Links/Rechts. Für Mitte, Maus 4/5 und Tastatur gilt diese Grenze nicht.",
        dragPixels="Bewegungsschwelle für Kameraziehen nur bei Links/Rechts. Andere Tasten werden nicht wegen Mausbewegung verworfen.",
        tipContext="Wählt einen der vier unabhängigen Tooltip-Bereiche: freundlich oder feindlich, über Einheitenrahmen oder in der Welt.",
        profileDropdown="Lädt ein gespeichertes Profil. Die bisherigen Änderungen werden zuvor im aktiven Profil gespeichert.",

        enemyMode="Erst auswählen: Linksklick auf einen anderen Weltgegner wählt ihn nur aus; danach zaubert die Belegung. Direkt: ein gültiger Klick wählt den Gegner unter der Maus aus und zaubert sofort. Ohne Gegner unter der Maus gilt das ausgewählte Ziel. Freundliche Mausziele und Selbstzauber haben Vorrang. Unitframes bleiben unverändert.",
        bypassModifier="Diese Taste zuerst halten, dann klicken: EasyCast gibt die WoW-Belegungen frei, lässt originale Unitframe-Klicks durch und blendet seine Belegungshilfe aus. Gilt auch mit weiteren Zusatztasten. Laufende EasyCast-Gesten werden abgebrochen. Keine: kein vorübergehendes Aussetzen.",
        selfModifier="In der Welt erzwingt genau diese Zusatztaste dich selbst als Ziel. Verwendet wird die freundliche Belegung dieser Taste, auch bei angewähltem Gegner. Feindliche Belegungen werden dabei übergangen. Keine: kein erzwungenes Selbstziel; eigene Zielauswahl bleibt möglich.",
        tipLabels="Aus: nur Zaubericons. Text: Eingabe linksbündig darüber. Eingabesymbol: Maussymbol links, bei Tastaturbelegungen nur der Tastenname. Gemeinsame Zusatztasten erscheinen einmal zentriert als Tastenkappen unter der Liste.",
        tipColumns="Horizontal: Zeile bis zur gewählten Anzahl füllen, dann umbrechen. Ein längerer Einheitenname verändert diese Grenze nicht. Vertikal: Spalten von oben nach unten füllen; im WoW-Tooltip mindestens zwei.",
        tipStyle="Gemeinsame Darstellung aller vier Bereiche. Im WoW-Tooltip wird die Belegungshilfe unter vorhandenen Aggrobalken ergänzt. Eigene Position und Mindestbreite gelten auch, wenn das WoW-Tooltip für den Bereich ausgeblendet ist und die Belegungshilfe separat erscheint. Beim Halten der Selbstzaubertaste in der Welt erscheint die eigene Belegungshilfe auch ohne WoW-Tooltip.",
        tipLayout="Gilt für alle Bereiche. Horizontal liest sich von links nach rechts, vertikal von oben nach unten je Spalte. Alle Einträge sind linksbündig.",
        tipPreviewChoice="Zeigt im Beispiel die Belegungen dieser Zusatztaste. Das ändert deine echten Belegungen und die aktuell gedrückten Tasten nicht.",
        tipOpacity="Deckkraft der eigenen Belegungshilfe beziehungsweise des EasyCast-Inhalts im WoW-Tooltip. Andere WoW-Inhalte und EasyThreat bleiben unverändert.",
        tipGap="Abstand zwischen den Einträgen beziehungsweise Zeilen und Spalten der Belegungshilfe.",
        tipIconGap="Abstand zwischen Eingabesymbol oder Tastentext und Zaubericon. Bei Text darüber gilt der Abstand nach unten. Bei ausgeschalteter Beschriftung wird diese Einstellung ausgeblendet.",
        tipWidth="Mindestbreite des eigenen Tooltips. Bei mehr Inhalt wächst es. Der Umbruch richtet sich nach Einträgen pro Zeile beziehungsweise Spalten."
    }
    for key,text in pairs(descriptions) do if self[key] then self[key].helpText=text end end
end

function E:RegisterScrollHelp(name)
    self:RegisterHelp(getglobal(name.."ScrollBarScrollUpButton"),"Nach oben","Scrollt die Liste beziehungsweise den Bericht nach oben.")
    self:RegisterHelp(getglobal(name.."ScrollBarScrollDownButton"),"Nach unten","Scrollt die Liste beziehungsweise den Bericht nach unten.")
end
