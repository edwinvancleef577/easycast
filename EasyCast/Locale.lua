-- UI text only. Never translate spell, item, macro, profile names or input IDs.
local E=EasyCast
E.localeTexts={enUS={
    ["Kopieren von"]="Copy from",
    ["Ersetzt die gesamte Belegung: %s · %s. Auch leere Einträge werden übernommen."]="Replaces the entire binding set: %s · %s. Empty entries are copied too.",
    ["Quelle und Ziel sind gleich; nichts geändert."]="Source and destination are identical; nothing changed.",
    ["Belegung kopiert: %s → %s (%s)."]="Bindings copied: %s → %s (%s).",
    ["Kopiert alle Maus-, Mausrad- und Tastaturbelegungen der Quelle in die oben gewählte Zusatztaste. Ersetzt auch leere Einträge. Freundlich und Feindlich bleiben getrennt."]="Copies all mouse, wheel and keyboard bindings from the source to the modifier selected above. Empty entries replace existing bindings too. Friendly and Hostile remain separate.",
    ["Quell-Zusatztaste wählen. Kopiert wird erst mit Kopieren von. Auch gespeicherte Belegungen reservierter Tasten sind als Quelle verfügbar."]="Choose the source modifier. Copying starts only when you click Copy from. Saved bindings of reserved modifiers can also be used as a source.",
    ["  ·  /ec  ·  Enter oder Feld verlassen speichert"]="  ·  /ec  ·  Enter or leaving a field saves",
    [" (Aussetztaste)|r"]=" (bypass key)|r",
    [" (Selbstzaubertaste)|r"]=" (self-cast key)|r",
    [" (bereits reserviert)|r"]=" (already reserved)|r",
    [" Einträge pro Zeile"]=" entries per row",
    [" erkannt · Taste loslassen zum Übernehmen."]=" detected · release the key to accept.",
    [" hinzugefügt"]=" added",
    [" in Originalgröße"]=" at original size",
    [" ist bereits vorhanden"]=" already exists",
    [" verkleinert"]=" scaled down",
    [" · Belegung erlaubt"]=" · assignment allowed",
    [" · jetzt die gewünschte Belegung eintragen."]=" · now enter the desired binding.",
    ["%d Spalte"]="%d column",
    ["%d Spalten"]="%d columns",
    ["1 · Grau: nur Gegner erkennen"]="1 · Gray: only detect enemies",
    ["2 · Grün: Selbstzauber testen"]="2 · Green: test self-cast",
    ["AN"]="ON",
    ["AUS"]="OFF",
    ["Abbrechen"]="Cancel",
    ["Abstand"]="Spacing",
    ["Abstand zum Icon"]="Gap to spell icon",
    ["Abstand zwischen Eingabesymbol oder Tastentext und Zaubericon. Bei Text darüber gilt der Abstand nach unten. Bei ausgeschalteter Beschriftung wird diese Einstellung ausgeblendet."]="Gap between the input symbol or key label and the spell icon. For text above, this is the vertical gap. Hidden when labels are off.",
    ["Abstand zwischen den Einträgen beziehungsweise Zeilen und Spalten der Belegungshilfe."]="Spacing between hint entries, rows and columns.",
    ["Aktion"]="Action",
    ["Aktionsplatz "]="Action slot ",
    ["Aktionsplatz 1 bis 120 eingeben · bisherige Belegung bleibt"]="Enter action slot 1–120 · previous binding kept",
    ["Aktiviert deine Belegungen direkt in der Spielwelt. Bei Links/Rechts trennen die Klickgrenzen Zaubern von Kameraziehen. Mitte, Maus 4/5 und Tastatur zaubern beim Loslassen ohne Zeit-/Bewegungsfilter."]="Enables bindings in the game world. For Left/Right, click limits distinguish casting from camera dragging. Middle, Mouse 4/5 and keyboard cast on release without duration or movement filters.",
    ["Anhalten"]="Pause",
    ["Anwenden / Reload"]="Apply / Reload",
    ["Auch WoW: "]="Also WoW: ",
    ["Aufnahme läuft auch bei geschlossenem Fenster weiter.\nOben am Bildschirm kannst du sie jederzeit stoppen."]="Recording continues when this window is closed.\nStop it at any time using the button at the top of the screen.",
    ["Aufnahme · Stop"]="Recording · Stop",
    ["Aufruf fehlgeschlagen: "]="Call failed: ",
    ["Aus: nur Zaubericons. Text: Eingabe linksbündig darüber. Eingabesymbol: Maussymbol links, bei Tastaturbelegungen nur der Tastenname. Gemeinsame Zusatztasten erscheinen einmal zentriert als Tastenkappen unter der Liste."]="Off: spell icons only. Text: input label left-aligned above. Input symbol: mouse symbol on the left, or just the key name for keyboard bindings. Shared modifiers appear once, centered as keycaps below the list.",
    ["Bedienhilfen (500 ms)"]="Control help (500 ms)",
    ["Beginnt diesen Diagnosetest neu und setzt seine bisherigen Messwerte zurück."]="Restarts this diagnostic test and resets its previous measurements.",
    ["Begleitdiagnose"]="Live recording",
    ["Beispiel-Einheit"]="Example unit",
    ["Belegt diese Maustaste vorübergehend für den Selbstzauber-Test um. Warte auf BEREIT, klicke auf freien Boden und lasse los. Die ursprüngliche Bindung wird anschließend wiederhergestellt."]="Temporarily assigns this mouse button to the self-cast test. Wait for BEREIT (READY), click on free ground and release. The original binding is then restored.",
    ["Belegte linke/rechte Maustaste: kurz klicken = zaubern; ziehen = Kamera und Charakter drehen.\nOhne passende Belegung bleibt die normale WoW-Steuerung erhalten.\nFür normales Linksklicken die Belegung ohne Zusatztaste leer lassen."]="Assigned left/right button: short click = cast; drag = turn camera and character.\nWithout an applicable binding, normal WoW controls remain available.\nFor normal left-clicking, leave the binding without a modifier empty.",
    ["Belegung ablegen"]="Drop a binding",
    ["Belegungshilfe"]="Binding hints",
    ["Bereich ausgeblendet · "]="Context hidden · ",
    ["Bereitet den angezeigten Weltklick-Vergleich vor. Warte auf BEREIT und klicke dann einmal außerhalb des Fensters."]="Prepares the displayed world-click comparison. Wait for BEREIT (READY), then click once outside the window.",
    ["Bericht"]="Report",
    ["Bericht öffnen"]="Open report",
    ["Beschriftung: Aus"]="Labels: Off",
    ["Beschriftung: Eingabesymbol links"]="Labels: Input symbol on left",
    ["Beschriftung: Text darüber"]="Labels: Text above",
    ["Bewegungsschwelle für Kameraziehen nur bei Links/Rechts. Andere Tasten werden nicht wegen Mausbewegung verworfen."]="Movement threshold for camera dragging with Left/Right only. Other keys are not rejected due to mouse movement.",
    ["Bitte die Sprache außerhalb des Kampfes anwenden."]="Please apply the language outside combat.",
    ["Bitte einen Profilnamen eingeben (max. 48 Zeichen)."]="Enter a profile name (up to 48 characters).",
    ["Bitte zuerst die aktive Zauberauswahl beenden."]="Finish the active spell targeting first.",
    ["Blessing: A / B"]="Blessing: A / B",
    ["Bricht den aktuellen Erfassungs- oder Diagnoseschritt ab und gibt temporäre Testbindungen frei."]="Cancels the current capture or diagnostic step and releases temporary test bindings.",
    ["Client bietet keinen Makro-Aufruf"]="Client does not provide a macro API",
    ["Deckkraft %"]="Opacity %",
    ["Deckkraft der eigenen Belegungshilfe beziehungsweise des EasyCast-Inhalts im WoW-Tooltip. Andere WoW-Inhalte und EasyThreat bleiben unverändert."]="Opacity of the separate hints or EasyCast content inside the WoW tooltip. Other WoW content and EasyThreat are unaffected.",
    ["Diagnose"]="Diagnostics",
    ["Diagnose …"]="Diagnostics …",
    ["Die Diagnose zeichnet auf. Klick beendet die Aufnahme und bewahrt den Bericht auf."]="Diagnostics are recording. Click to stop recording and keep the report.",
    ["Diese Auswahl ist reserviert und kann hier nicht gewählt werden."]="This choice is reserved and cannot be selected here.",
    ["Diese Taste wird nicht unterstützt.\nAndere Taste drücken oder Esc zum Abbrechen."]="This key is not supported.\nPress another key or Esc to cancel.",
    ["Diese Taste zuerst halten, dann klicken: EasyCast gibt die WoW-Belegungen frei, lässt originale Unitframe-Klicks durch und blendet seine Belegungshilfe aus. Gilt auch mit weiteren Zusatztasten. Laufende EasyCast-Gesten werden abgebrochen. Keine: kein vorübergehendes Aussetzen."]="Hold this key first, then click: EasyCast restores WoW bindings, passes unit-frame clicks to the original handler and hides its binding hints. Also works with additional modifiers. Active EasyCast gestures are canceled. None: no temporary bypass.",
    ["Diese Zusatztaste ist in der Welt für Selbstzauber reserviert. Die Belegungen dafür stellst du unter Freundlich ein. Vorhandene feindliche Belegungen bleiben gespeichert."]="This modifier is reserved for world self-casts. Configure its spells under Friendly. Existing hostile bindings are kept.",
    ["Direkt auswählen und zaubern"]="Select and cast directly",
    ["Direkt: Gegner unter der Maus hat Vorrang; sonst gilt der ausgewählte Gegner.\nErst auswählen: Linksklick auf einen anderen Gegner wählt ihn zunächst nur aus."]="Direct: the hovered enemy takes priority; otherwise use the selected enemy.\nSelect first: left-clicking a different enemy only selects it initially.",
    ["Drücke und löse eine Taste, etwa F6, um sie zur Liste hinzuzufügen. Escape bricht ab. Zusatztasten werden oben separat gewählt."]="Press and release a key, such as F6, to add it to the list. Escape cancels. Choose modifiers separately above.",
    ["EasyCast vorübergehend aussetzen"]="Temporarily bypass EasyCast",
    ["EasyCast-Kamerageste beendet."]="EasyCast camera gesture stopped.",
    ["Eigenes Tooltip"]="Separate tooltip",
    ["Entfernt die Belegung dieser Zeile für die oben ausgewählte Fraktion und Zusatztaste."]="Removes this row's binding for the faction and modifier selected above.",
    ["Entfernt die experimentelle Klickfläche aus der Welt. Die Live-Anzeige bleibt offen."]="Removes the experimental click surface from the world. The live monitor remains open.",
    ["Erst auswählen, dann zaubern"]="Select first, then cast",
    ["Erst auswählen: Linksklick auf einen anderen Weltgegner wählt ihn nur aus; danach zaubert die Belegung. Direkt: ein gültiger Klick wählt den Gegner unter der Maus aus und zaubert sofort. Ohne Gegner unter der Maus gilt das ausgewählte Ziel. Freundliche Mausziele und Selbstzauber haben Vorrang. Unitframes bleiben unverändert."]="Select first: left-clicking a different world enemy only selects it; subsequent clicks cast. Direct: a valid click selects the hovered enemy and casts immediately. Without a hovered enemy, use the selected target. Friendly mouse targets and self-casts take priority. Unit frames are unaffected.",
    ["Feindlich"]="Hostile",
    ["Feindlich · Einheitenrahmen"]="Hostile · Unit frames",
    ["Feindlich · Welt"]="Hostile · World",
    ["Fläche entfernen"]="Remove surface",
    ["Folgen"]="Follow",
    ["Freundlich"]="Friendly",
    ["Freundlich · Einheitenrahmen"]="Friendly · Unit frames",
    ["Freundlich · Welt"]="Friendly · World",
    ["Friert die Mausanzeige zum Lesen ein. Die Spielsteuerung und Begleitdiagnose laufen weiter."]="Freezes the mouse monitor for reading. Game controls and diagnostic recording continue.",
    ["Fügt die eingetragene Taste zur Belegungsliste hinzu und springt zu ihrer Zeile. Anschließend den Spruch oder die Aktion zuweisen."]="Adds the entered key to the binding list and scrolls to its row. Then assign a spell or action.",
    ["Führt den angezeigten Schritt aus: "]="Performs the displayed step: ",
    ["Für die Vorschau EasyCast und die Belegungshilfe dieser Gruppe einschalten."]="Enable EasyCast and binding hints for this context to show the preview.",
    ["Gegenstand nicht in Taschen oder Ausrüstung: "]="Item not found in bags or equipment: ",
    ["Gemeinsame Darstellung aller vier Bereiche. Im WoW-Tooltip wird die Belegungshilfe unter vorhandenen Aggrobalken ergänzt. Eigene Position und Mindestbreite gelten auch, wenn das WoW-Tooltip für den Bereich ausgeblendet ist und die Belegungshilfe separat erscheint. Beim Halten der Selbstzaubertaste in der Welt erscheint die eigene Belegungshilfe auch ohne WoW-Tooltip."]="Shared appearance for all four contexts. Inside WoW tooltips, hints appear below existing threat bars. Separate position and minimum width also apply when the WoW tooltip is hidden for a context. Holding the world self-cast modifier shows separate hints even without a WoW tooltip.",
    ["Gespeichert"]="Saved",
    ["Gilt für alle Bereiche. Horizontal liest sich von links nach rechts, vertikal von oben nach unten je Spalte. Alle Einträge sind linksbündig."]="Applies to all contexts. Horizontal reads left to right; vertical reads top to bottom in each column. All entries are left-aligned.",
    ["Grau + Symbol: nicht passend. Kopf = nur selbst; Pfeil hoch = zu weit.\nVorschau: Reichweite und Cooldown sind simuliert."]="Gray + symbol: unavailable. Head = self only; up arrow = out of range.\nPreview: range and cooldown are simulated.",
    ["Horizontal · links nach rechts"]="Horizontal · left to right",
    ["Horizontal: Zeile bis zur gewählten Anzahl füllen, dann umbrechen. Ein längerer Einheitenname verändert diese Grenze nicht. Vertikal: Spalten von oben nach unten füllen; im WoW-Tooltip mindestens zwei."]="Horizontal: fill a row to the chosen entry count, then wrap. A longer unit name does not change this limit. Vertical: fill columns from top to bottom; at least two inside the WoW tooltip.",
    ["Im WoW-Tooltip"]="Inside WoW tooltip",
    ["In der Welt erzwingt genau diese Zusatztaste dich selbst als Ziel. Verwendet wird die freundliche Belegung dieser Taste, auch bei angewähltem Gegner. Feindliche Belegungen werden dabei übergangen. Keine: kein erzwungenes Selbstziel; eigene Zielauswahl bleibt möglich."]="In the world, this exact modifier combination forces yourself as the target. It uses the friendly bindings for that modifier, even with an enemy selected. Hostile bindings are skipped. None: no forced self-target; selecting yourself still works.",
    ["Kein unterstütztes Icon · Namen direkt eingeben"]="Unsupported icon · enter the name directly",
    ["Keine"]="None",
    ["Klick kürzer als (ms)"]="Click shorter than (ms)",
    ["Klick öffnet oder schließt die Einstellungen. Ziehen verschiebt das Symbol an der Minimap."]="Click to open or close settings. Drag to move the icon around the minimap.",
    ["Language: English"]="Language: English",
    ["Leiste"]="Bar slot",
    ["Links"]="Left",
    ["Links/Rechts: Kurzer Klick zaubert; Ziehen steuert die Kamera."]="Left/Right: a short click casts; dragging controls the camera.",
    ["Live prüfen"]="Check live",
    ["Lädt ein gespeichertes Profil. Die bisherigen Änderungen werden zuvor im aktiven Profil gespeichert."]="Loads a saved profile. Changes to the previous profile are saved first.",
    ["Makro"]="Macro",
    ["Makroname nicht gefunden · bisherige Belegung bleibt"]="Macro name not found · previous binding kept",
    ["Maus 4"]="Mouse 4",
    ["Maus 5"]="Mouse 5",
    ["Mausanzeige"]="Mouse monitor",
    ["Max. "]="Max. ",
    ["Maximal 20 zusätzliche Tasten pro Profil."]="Up to 20 additional keys per profile.",
    ["Maximale Dauer eines Weltklicks nur für Links/Rechts. Für Mitte, Maus 4/5 und Tastatur gilt diese Grenze nicht."]="Maximum world-click duration for Left/Right only. This limit does not apply to Middle, Mouse 4/5 or keyboard keys.",
    ["Min. Breite"]="Min. width",
    ["Mindestbreite des eigenen Tooltips. Bei mehr Inhalt wächst es. Der Umbruch richtet sich nach Einträgen pro Zeile beziehungsweise Spalten."]="Minimum width of the separate tooltip. It grows to fit content. Wrapping follows entries per row or number of columns.",
    ["Mini-Klickfläche"]="Small click surface",
    ["Mit dieser Taste pausiert EasyCast in der Welt und auf Unitframes. Bestehende Belegungen bleiben gespeichert."]="Holding this key pauses EasyCast in the world and on unit frames. Existing bindings are kept.",
    ["Mitte"]="Middle",
    ["Mitte, Maus 4/5 und Tastatur: Zauber beim Loslassen, ohne diese Grenzen."]="Middle, Mouse 4/5 and keyboard: cast on release, without these limits.",
    ["Nach oben"]="Scroll up",
    ["Nach unten"]="Scroll down",
    ["Name eingeben oder Icon aus Zauberbuch, Makrofenster oder Tasche ablegen."]="Enter a name or drop an icon from your spellbook, macros or bags.",
    ["Name eingeben oder Icon hier ablegen"]="Enter a name or drop an icon here",
    ["Neu beginnen"]="Start again",
    ["Neue Belegung wählen oder Namen eingeben"]="Choose a new binding or enter a name",
    ["Ohne Zusatztaste"]="No modifier",
    ["Optionen"]="Options",
    ["Platziert eine durchlässige Testfläche. Der Client kann das Weltziel dahinter erkennen; die Fläche empfängt keine Klicks."]="Places a click-through test surface. The client can detect the world target behind it; the surface receives no clicks.",
    ["Platziert eine klickbare Testfläche. Ein echter Klick kann zaubern; die Fläche kann dabei die Welterkennung dahinter verdecken."]="Places a clickable test surface. A real click can cast; the surface may block world detection behind it.",
    ["Position zeigen / ziehen"]="Show / drag position",
    ["Position zurücksetzen"]="Reset position",
    ["Position: an der Maus"]="Position: at cursor",
    ["Position: fest am Bildschirm"]="Position: fixed on screen",
    ["Profil „"]="Profile “",
    ["Profile"]="Profiles",
    ["Protokolliert Eingaben, Entscheidungen und Clientmeldungen während des Spielens. Einschalten beginnt einen neuen Bericht; Ausschalten bewahrt ihn auf."]="Records input, decisions and client messages while playing. Enabling starts a new report; disabling keeps it.",
    ["Rad hoch"]="Wheel up",
    ["Rad runter"]="Wheel down",
    ["Rechts"]="Right",
    ["Schaltet EasyCast insgesamt ein oder aus. Die gespeicherten Belegungen bleiben erhalten."]="Enables or disables EasyCast. Saved bindings are kept.",
    ["Schließen"]="Close",
    ["Schließt die Einstellungen und speichert das aktive Profil."]="Closes settings and saves the active profile.",
    ["Schließt dieses Fenster. Ein dazugehöriger Eingabetest wird beendet."]="Closes this window and stops any input test belonging to it.",
    ["Scrollt die Liste beziehungsweise den Bericht nach oben."]="Scrolls the list or report up.",
    ["Scrollt die Liste beziehungsweise den Bericht nach unten."]="Scrolls the list or report down.",
    ["Selbstzauber"]="Self-cast",
    ["Selbstzauber und Aussetzen benötigen verschiedene Zusatztasten."]="Self-casting and bypassing need different modifier keys.",
    ["Selbstzauber: freundliche Belegung auf dich.\nAussetzen: Taste halten, dann normal in WoW klicken (auch auf Unitframes)."]="Self-cast: friendly bindings on yourself.\nBypass: hold the key, then use normal WoW clicks (including unit frames).",
    ["Setzt X und Y für den gewählten Tooltip und Positionsmodus auf die Ausgangswerte zurück."]="Resets X and Y for the selected tooltip and positioning mode to their defaults.",
    ["Setzt die Aktualisierung der Mausanzeige fort."]="Resumes updates of the mouse monitor.",
    ["Setzt nur die Position der Belegungshilfe im ausgewählten Bereich und Positionsmodus zurück."]="Resets only the binding hint position for the selected context and positioning mode.",
    ["Speichern"]="Save",
    ["Speichert die Einstellungen und lädt die Oberfläche neu, um die Sprache anzuwenden. Außerhalb des Kampfes verwenden."]="Saves settings and reloads the interface to apply the language. Use outside combat.",
    ["Speichert die aktuellen Belegungen und Optionen unter dem eingetragenen Profilnamen. Ein gleichnamiges Profil wird aktualisiert."]="Saves current bindings and options under the entered profile name. An existing profile with that name is updated.",
    ["Sprache"]="Language",
    ["Sprache gespeichert. Mit /reload anwenden."]="Language saved. Use /reload to apply.",
    ["Sprache: Automatisch"]="Language: Automatic",
    ["Sprache: Deutsch"]="Sprache: Deutsch",
    ["Spruch nicht gelernt oder unbekannt: "]="Spell not learned or unknown: ",
    ["Spruch nicht gelernt · bisherige Belegung bleibt"]="Spell not learned · previous binding kept",
    ["Startet eine neue Begleitdiagnose und öffnet die laufende Mausanzeige. Normales Zaubern bleibt aktiv."]="Starts a new live recording and opens the mouse monitor. Normal casting stays active.",
    ["Strg"]="Ctrl",
    ["Strg+"]="Ctrl+",
    ["TEST STARTEN"]="START TEST",
    ["Taste drücken und loslassen, z. B. F6 oder F.\nZusatztasten gelten wie oben gewählt. Esc bricht ab."]="Press and release a key, such as F6 or F.\nModifiers follow the selection above. Esc cancels.",
    ["Taste eintippen oder erfassen.\nZusatztasten oben auswählen."]="Type or capture a key.\nChoose modifiers above.",
    ["Taste erfassen"]="Capture key",
    ["Taste hinzufügen"]="Add key",
    ["Tastenbindung testen"]="Test key bindings",
    ["Tooltip-Aktualisierung fehlgeschlagen: "]="Tooltip update failed: ",
    ["Ungültige Taste. Beispiel: F6, F oder NUMPAD1."]="Invalid key. Examples: F6, F or NUMPAD1.",
    ["Unterstützen"]="Assist",
    ["Vergleich: Zauber mit diesem UI-Knopf auslösen"]="Compare: cast with this UI button",
    ["Vergleicht Blessing of Might über einen echten UI-Knopf mit dem Weltklick-Test. Du musst den Spruch gelernt haben."]="Compares Blessing of Might from a real UI button with the world-click test. You must have learned the spell.",
    ["Vergleicht echte Links-, Rechts- und Mittelklick-Bindungen anhand eines Selbstzaubers. Folge den Schritten im Testfenster."]="Compares real left, right and middle mouse bindings using a self-cast. Follow the test window instructions.",
    ["Vertikal · oben nach unten"]="Vertical · top to bottom",
    ["Vorschau"]="Preview",
    ["Vorschau "]="Preview ",
    ["Vorschau / Position verschieben"]="Preview / move position",
    ["Vorschau: "]="Preview: ",
    ["Vorschau: ohne Zusatztaste"]="Preview: no modifier",
    ["Wechselt zwischen allgemeinen Optionen, Zauberbelegungen und Tooltip-Einstellungen."]="Switches between general options, casting bindings and tooltip settings.",
    ["Weiter"]="Resume",
    ["Welt · Selbstzauber"]="World · Self-cast",
    ["Welt: Gegner direkt auswählen und zaubern"]="World: select enemy and cast directly",
    ["Welt: anderer Gegner = auswählen · danach zaubern"]="World: different enemy = select · then cast",
    ["Welt: kurz = Zauber · ziehen = Kamera"]="World: short = cast · drag = camera",
    ["Weltklicks"]="World clicks",
    ["Wert eingeben und mit Enter oder durch Verlassen des Feldes übernehmen."]="Enter a value, then press Enter or leave the field to apply it.",
    ["Wirkt den im Test gewählten Zauber direkt durch diesen echten UI-Klick. Damit vergleichst du ihn mit dem Weltklick-Weg."]="Casts the selected test spell through this real UI click, for comparison with the world-click route.",
    ["WoW-Einheitentooltip"]="WoW unit tooltip",
    ["Wählt die Art dieser Belegung: gelernter Zauber, vorhandenes Makro, Item, Zielaktion oder Aktionsleistenplatz (1 bis 120). Danach den passenden Namen beziehungsweise die Platznummer eingeben."]="Choose a learned spell, existing macro, item, target action or action bar slot (1–120). Then enter its name or slot number.",
    ["Wählt die Belegungsliste für freundliche oder feindliche Ziele. Änderungen gelten nur für diese Liste."]="Selects bindings for friendly or hostile targets. Changes apply only to that list.",
    ["Wählt die Sprache der EasyCast-Oberfläche. Automatisch folgt dem Client in einer der acht unterstützten Sprachen, sonst Englisch. Zauber- und Makronamen bleiben in der Sprache deines Clients. Anwenden lädt die Oberfläche neu; Diagnoseberichte bleiben vorerst Deutsch."]="Chooses the EasyCast interface language. Automatic follows any of the eight supported client languages, otherwise English. Spell and macro names stay in your client language. Apply reloads the interface; detailed diagnostic reports remain in German for now.",
    ["Wählt die Zusatztasten zur Belegung, etwa Shift oder Strg. Jede Kombination hat ihre eigene Liste. Die rot markierte Selbstzaubertaste ist bei Feindlich gesperrt; ihre Selbstzauber werden unter Freundlich belegt."]="Selects modifiers such as Shift or Ctrl. Each combination has its own bindings. The self-cast modifier is marked red and unavailable under Hostile; configure it under Friendly. Bypass combinations are unavailable for both.",
    ["Wählt diese Einstellung: "]="Selects this setting: ",
    ["Wählt eine Zielaktion: auswählen, das Ziel unterstützen, ihm folgen oder die aktuelle Auswahl aufheben."]="Choose a target action: select, assist, follow or clear your current target.",
    ["Wählt einen der vier unabhängigen Tooltip-Bereiche: freundlich oder feindlich, über Einheitenrahmen oder in der Welt."]="Selects one of four independent tooltip contexts: friendly or hostile, on unit frames or in the world.",
    ["Zauber"]="Spell",
    ["Zauberaufruf fehlgeschlagen: "]="Spell call failed: ",
    ["Zaubern"]="Casting",
    ["Zeigt Erklärungen nach einer halben Sekunde über EasyCast-Bedienelementen. Ausschalten blendet diese Bedienhilfen aus; die Zauber-Belegungshilfe bleibt unverändert."]="Shows explanations after hovering over EasyCast controls for half a second. Disabling this hides control help; spell binding hints are unaffected.",
    ["Zeigt die Belegungshilfe außerhalb des Menüs an ihrer eingestellten Position. Bei fester Position kannst du sie ziehen. Erneut klicken beendet die Anzeige."]="Shows binding hints outside the menu at their configured position. Fixed hints can be dragged. Click again to hide the preview.",
    ["Zeigt die gewählte Belegungshilfe als Vorschau. Bei fester Bildschirmposition kannst du sie ziehen. Erneutes Klicken beendet die Vorschau."]="Shows the selected binding hints as a preview. With fixed screen positioning, you can drag it. Click again to end the preview.",
    ["Zeigt im Beispiel die Belegungen dieser Zusatztaste. Das ändert deine echten Belegungen und die aktuell gedrückten Tasten nicht."]="Previews bindings for this modifier. Does not change your actual bindings or currently held keys.",
    ["Zeigt oder verbirgt EasyCasts Belegungen für den ausgewählten Bereich. Die gemeinsame Darstellung bleibt erhalten."]="Shows or hides EasyCast bindings for the selected context. Shared appearance settings are kept.",
    ["Zeigt oder verbirgt das normale Einheiten-Tooltip im gewählten Bereich. Item- und Zaubertooltips bleiben erhalten. Bei ausgeschaltetem WoW-Tooltip erscheint eine aktivierte Belegungshilfe separat, auch im integrierten Modus."]="Shows or hides the normal unit tooltip for the selected context. Item and spell tooltips are unaffected. When the WoW tooltip is off, enabled binding hints appear separately, even in integrated mode.",
    ["Zeigt oder verbirgt die Zauber-Belegungshilfe ausschließlich im oben gewählten Bereich."]="Shows or hides spell binding hints only in the context selected above.",
    ["Ziehe einen Zauber, ein Item oder ein Makro aus seinem Fenster hierher. Alternativ den Namen rechts eingeben."]="Drag a spell, item or macro here from its window. Alternatively, enter its name on the right.",
    ["Ziehen ab Weg (px)"]="Drag threshold (px)",
    ["Ziel abwählen"]="Clear target",
    ["Ziel wählen"]="Select target",
    ["Zurücksetzen"]="Reset",
    ["geladen. Einstellungen: /ec oder Minimap-Symbol."]="loaded. Settings: /ec or the minimap icon.",
    ["Änderungen bleiben beim Wechsel und bei /reload erhalten."]="Changes are kept when switching profiles and after /reload.",
    ["Öffnet den Bericht zum aktuellen Test zum Lesen und Kopieren."]="Opens the current test report for reading and copying.",
    ["Öffnet den Diagnosebericht zum Lesen und Kopieren."]="Opens the diagnostic report for reading and copying.",
    ["Öffnet den Vergleich zwischen einer durchlässigen Erkennungsfläche und einer klickbaren Zauberfläche."]="Opens the comparison of a click-through detection surface and a clickable casting surface.",
    ["Öffnet die Auswahl. Verfügbar: "]="Opens the selection. Available: ",
    ["Öffnet die optionalen Diagnosewerkzeuge: Aufnahme, Bericht, Mausbeobachtung und Eingabetests."]="Opens optional diagnostics: recording, reports, mouse monitoring and input tests.",
    ["Öffnet oder schließt die Live-Anzeige von Mausziel, Eingabe, Druckdauer und EasyCasts Entscheidung."]="Opens or closes the live display of mouse target, input, press duration and EasyCast's decision.",
    ["“ gespeichert."]="” saved.",
    ["Tooltips"]="Tooltips",
    ["Item"]="Item",
    ["Icon"]="Icon",
}}
E.localeTexts.deDE={} -- German source keys are the German dictionary.
E.languageOptions={{"auto","Sprache: Automatisch"},{"enUS","English"},{"deDE","Deutsch"},
    {"frFR","Français"},{"esES","Español"},{"ptBR","Português"},
    {"ruRU","Russian / Русский"},{"koKR","Korean / 한국어"},{"zhCN","Chinese / 简体中文"}}
function E:ResolveLocale(preference)
    local language=preference
    if not language or language=="auto" then language=GetLocale and GetLocale() or "deDE" end
    if language=="enGB" then language="enUS" elseif language=="esMX" then language="esES" end
    return self.localeTexts[language] and language or "enUS"
end
function E:InitLocale()
    self.localePreference=self.db.language
    self.locale=self:ResolveLocale(self.db.language)
end
function E:L(key,...)
    if type(key)~="string" then return key end
    local dictionary=self.localeTexts[self.locale]
    local text=self.locale=="deDE" and key or (dictionary and dictionary[key]) or self.localeTexts.enUS[key] or key
    if arg and table.getn(arg)>0 then return string.format(text,unpack(arg)) end
    return text
end
-- Only for resolving control help from translated labels, never for game data.
function E:SourceText(text)
    local dictionary=self.localeTexts[self.locale]
    if dictionary then for source,value in pairs(dictionary) do if value==text then return source end end end
    return text
end
function E:ApplyLanguage()
    if self:InCombat() then self:Print(self:L("Bitte die Sprache außerhalb des Kampfes anwenden.")); return false end
    self:CommitEdits(); self:SaveProfile(self.db.profile)
    self:StopKeyCapture(); self:ReleaseWorldBindings()
    if ReloadUI then ReloadUI() else self:Print(self:L("Sprache gespeichert. Mit /reload anwenden.")) end
    return true
end

-- Use the client's own UI font, including its Cyrillic/CJK variants.
function E:FontPath()
    if GameFontNormal and type(GameFontNormal.GetFont)=="function" then
        local ok,path=pcall(GameFontNormal.GetFont,GameFontNormal)
        if ok and type(path)=="string" and path~="" then return path end
    end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end
function E:LabelWidth(text,size)
    text=tostring(text or ""); size=size or 9
    if not self.textMeasure then self.textMeasure=UIParent:CreateFontString(nil,"OVERLAY"); self.textMeasure:Hide() end
    local measure=self.textMeasure
    measure:SetFont(self:FontPath(),size); measure:SetText(text)
    if type(measure.GetStringWidth)=="function" then
        local width=measure:GetStringWidth()
        if type(width)=="number" and width>0 then return width end
    end
    -- Defensive estimate for clients without measurement: count characters,
    -- not UTF-8 bytes. Cyrillic/Latin are narrow; CJK characters use a full em.
    local width=0
    for i=1,string.len(text) do
        local byte=string.byte(text,i)
        if byte<128 or byte>=192 then width=width+(byte>=224 and size or size*5.5/9) end
    end
    return width
end
function E:FitButtonLabel(button)
    local available=math.max(12,button:GetWidth()-(button.arrow and 34 or 14))
    local width=self:LabelWidth(button.label:GetText(),11)
    local size=width>available and math.max(9,11*available/width) or 11
    button.label:SetFont(self:FontPath(),size)
    button.label:SetWidth(available)
    button.label:SetJustifyH((button.arrow or button.dropdownRow) and "LEFT" or "CENTER")
end
