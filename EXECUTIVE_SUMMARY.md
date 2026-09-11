# Executive Summary: Die Revolution der As-Built-Dokumentation im deutschen Glasfaserausbau

## 1. Der fundamentale Schmerz des Marktes (Der "Pain Point")

Der Breitbandausbau (FTTH) in Deutschland scheitert nicht an der Technologie der Glasfaser, sondern an der Bürokratie und der As-Built-Dokumentation im Tiefbau.

Generalunternehmer und Subunternehmer verlieren monatlich Millionen Euro an Liquidität, weil Rechnungen von Netzbetreibern (wie der Deutschen Telekom) oder Behörden erst bezahlt werden, wenn eine fehlerfreie, GIS-konforme und normierte Dokumentation (inkl. DIN 18220) vorliegt.

**Das Kernproblem auf der Baustelle:**
Tiefbauer und Monteure sind keine Büroangestellten. Ihre Aufgabe ist es, Gräben auszuheben und Kabel zu verlegen – nicht, komplexe Geodaten-Formulare auf Tablets auszufüllen. Planabweichungen (z.B. wegen Baumwurzeln oder Fremdleitungen) werden im Feld oft nur auf schmutzigem Papier skizziert oder gar nicht dokumentiert. Das führt zum "Stille-Post-Effekt": Wenn die Daten Wochen später im Büro des Projektmanagers ankommen, sind sie fehlerhaft, unvollständig und werden vom Auftraggeber abgelehnt.

## 2. Warum gibt es dafür noch keine Lösung? (Das Entwickler-Paradoxon)

Obwohl das Problem branchenweit bekannt ist und Milliarden auf dem Spiel stehen, gibt es keine dominante Softwarelösung. Die Gründe dafür liegen in einer massiven Diskrepanz zwischen der IT-Welt und der Realität auf der Baustelle:

- **Das Entwickler-Paradoxon:** Die meisten Softwareentwickler sitzen in modernen Büros in Berlin oder München und bauen "Cloud-First"-SaaS-Produkte für andere Büroangestellte. Sie haben keine Vorstellung davon, was es bedeutet, bei 2 Grad Celsius im Regen mit schmutzigen Handschuhen und ohne 4G-Internetempfang in einer Baugrube in ländlichen Gebieten zu arbeiten.
- **Der "Top-Down"-Ansatz der Giganten:** Große Netzbetreiber diktieren die Nutzung von hochkomplexen, veralteten GIS-Systemen (z.B. Esri, Smallworld). Diese Systeme verlangen vom Nutzer das Denken eines Ingenieurs. Softwarefirmen versuchen oft, diese komplexen Desktop-Systeme auf mobile Endgeräte zu zwängen, was an der Usability im Feld kläglich scheitert.
- **Sprachbarrieren ignoriert:** Der deutsche Tiefbau wird maßgeblich von internationalen Fachkräften (aus Osteuropa etc.) getragen. Deutsche Startups bauen oft Apps nur auf Deutsch oder Englisch und ignorieren, dass der Endnutzer am Graben die App in seiner Muttersprache bedienen muss, um Fehler zu vermeiden.

## 3. Warum UNSERE Software die endgültige Lösung ist

Unsere Software bricht mit dem gescheiterten "Top-Down"-Ansatz und löst das Problem "Bottom-Up". Wir passen nicht den Bauarbeiter an die Software an, sondern die Software an den Bauarbeiter – unterstützt durch modernste Künstliche Intelligenz (KI).

**Wichtig: Domänenspezifische KI statt generischer LLMs**
Unsere KI ist kein externes, generisches Sprachmodell (wie z.B. ChatGPT). Stattdessen nutzen wir spezialisierte, vortrainierte Computer-Vision- und Machine-Learning-Modelle, die wir exakt auf die hochspezifischen Anforderungen des Glasfaserausbaus nachtrainieren (Fine-Tuning). Diese Modelle sind maßgeschneidert, um genau dieses eine Problem – die präzise Erkennung von Gräben, Kabeltypen und Bauabweichungen – sicher, effizient und ohne Datenschutzrisiken zu lösen.

**Das intelligente Bindeglied (Die Schnittstelle):** Wir stellen die fehlende Schnittstelle zwischen den Bauarbeitern im Feld und den starren Datenformaten der Großkonzerne dar. Die Software erkennt automatisch kritische Punkte im Bauprozess (wie z. B. unvorhergesehene Hindernisse im Tiefbau oder notwendige Planabweichungen) und übersetzt die einfachen, unstrukturierten Eingaben der Monteure selbstständig in die hochkomplexen, standardisierten Formate, die von den großen Netzbetreibern gefordert werden.

### Fachliche Schichten und rollenbasierte Architektur
Wir bieten eine nahtlose, mehrschichtige Architektur, die aus klar getrennten fachlichen Schichten mit unterschiedlichen Rollen besteht (Domain-Driven Design). Jeder Akteur interagiert nur mit der Ebene, die exakt auf seine Bedürfnisse zugeschnitten ist:

**A. Die Feld-Ebene (Für den Bauarbeiter/Monteur - Obrero)**
Die App ist radikal simpel, zu 100% Offline-fähig und agiert als unsichtbarer Assistent:
- *KI-Sprachsteuerung & Auto-Übersetzung:* Der Monteur tippt nicht. Er drückt einen Knopf und sagt in seiner Muttersprache (z.B. Rumänisch oder Polnisch): "Haben das Rohr um 2 Meter nach links verlegt wegen einer Gasleitung". Die lokale KI auf dem Gerät transkribiert, übersetzt ins technische Deutsch und trägt die Abweichung automatisch in den digitalen Bauplan ein.
- *Automatisierte Foto-Geolokalisierung & KI-Vision:* Fotos der offenen Gräben werden automatisch mit GPS-Koordinaten, Zeitstempeln und Netzabschnitten verknüpft und durch Computer Vision direkt analysiert (Zutiefenerkennung, Kabeltypen).

**B. Die Bauleiter-Ebene (Qualitätssicherung im Feld - Bauleiter)**
Der Bauleiter nutzt ein Tablet-Dashboard vor Ort. Er muss keine Daten mehr abtippen, sondern nur noch die von der KI vorverarbeiteten Abweichungen und Fotobeweise der Monteure mit einem Klick freigeben (Approve/Reject).

**C. Die Projektmanager- & Büro-Ebene (Die "Heavy-Lifting" KI - Projektleiter)**
Hier entfaltet unsere Lösung ihren größten kommerziellen Wert. Anstatt dass Ingenieure wochenlang Daten konvertieren, übernimmt unsere KI-Engine für schwere Geodaten-Berechnungen die Arbeit:
- Die KI berechnet automatisch Biegeradien, Mikrorohr-Zuweisungen und Tiefen nach der neuen DIN 18220.
- Die Software generiert auf Knopfdruck die exakten Export-Formate (Shapefiles, GML, GIS-Nebenbestimmungen), die von der Deutschen Telekom, Förderstellen (z.B. atene KOM) oder Kommunen zwingend gefordert werden.

## 4. Beschleunigte Dokumentation, Prädiktion und Leistungsmessung mit minimalem Aufwand

Um potenziellen Marktproblemen wie strengeren Regulierungen und anhaltendem Fachkräftemangel proaktiv zu begegnen, optimiert unsere Plattform den gesamten Baulebenszyklus:

- **Agile und fehlerfreie Dokumentation:** Durch die direkte KI-Erfassung am Grabenrand (mittels Kamera und Sprache) wird die as-built Dokumentationszeit von Wochen auf Millisekunden reduziert. Die KI validiert die Daten in Echtzeit und verhindert so teure Nacharbeiten.
- **Ergebnisprädiktion und Risikomanagement:** Das System lernt aus historischen Baudaten und erkennt Muster. Es kann vorhersagen, wo (z.B. bei bestimmten Bodenbeschaffenheiten oder Wetterbedingungen) Verzögerungen auftreten werden, sodass Projektmanager proaktiv umplanen können, bevor Kosten entstehen.
- **Automatisierte KPI-Messung:** Die Messung des Baufortschritts (verlegte Meter, Materialverbrauch, Effizienz der Bautrupps) geschieht als unsichtbares Nebenprodukt der Feld-App. Dashboards aktualisieren sich in Echtzeit, ohne dass Manager oder Arbeiter zusätzliche Berichte ausfüllen müssen. Dies garantiert 100%ige Transparenz mit absolut minimalem administrativen Aufwand.

## 5. Geschäftsmodell, Skalierbarkeit & Marktpotenzial (Für Investoren)

Um zu verstehen, warum Horizon Link nicht nur ein nützliches Tool, sondern ein hochskalierbares, renditestarkes Geschäftsmodell ist, betrachten wir vier zentrale Faktoren:

- **Monetarisierung (B2B SaaS):** Unser Geschäftsmodell basiert auf wiederkehrenden Umsätzen (Recurring Revenue) durch ein hybrides Lizenzmodell. Wir berechnen eine nutzungsbasierte Gebühr pro Sitzplatz (Feldarbeiter/Büro) sowie eine Performance-Fee pro dokumentiertem Kilometer (Pay-per-Meter). Dies garantiert, dass unser Umsatz parallel zum Erfolg und Bauvolumen unserer Kunden wächst.
- **Der "Moat" (Daten-Netzwerkeffekt):** Jeder dokumentierte Graben, jedes Foto und jede Korrektur trainieren unsere domänenspezifische KI. Innerhalb kürzester Zeit bauen wir die europaweit größte proprietäre Datenbank für as-built Glasfaser-Infrastruktur auf. Dieser "Data Flywheel"-Effekt macht unsere KI kontinuierlich intelligenter und schafft eine unüberwindbare Markteintrittsbarriere (Moat) für neue Wettbewerber.
- **API-First & Enterprise-Integration:** Großkonzerne fürchten den Austausch ihrer Kernsysteme (wie SAP oder Esri Smallworld). Horizon Link zwingt sie nicht dazu. Unsere Architektur ist "API-First" konzipiert: Wir fungieren als intelligentes Plugin, das die chaotischen Felddaten sammelt, bereinigt und strukturiert direkt in die veralteten Legacy-Systeme der Kunden einspeist. Das senkt die Einstiegshürde (Time-to-Value) drastisch.
- **Total Addressable Market (TAM):** Allein in Deutschland und der DACH-Region werden durch Regierungsprogramme (Gigabit-Ausbau) dutzende Milliarden Euro in den FTTH-Markt gepumpt. Wenn bis zu 10% der Baukosten durch Bürokratie, Nacharbeiten und verzögerte Dokumentation verloren gehen, adressiert Horizon Link direkt einen Multi-Milliarden-Euro-Schmerz. Da Tiefbauprozesse weltweit standardisiert sind, ist die Software nahtlos auf das europäische und globale Ausland skalierbar.

## 6. Fazit: Ein unaufhaltsamer Wettbewerbsvorteil

Indem unsere Software die Komplexität vor dem Arbeiter im Graben versteckt, durch eine klare fachliche Rollentrennung glänzt und die schweren Rechenoperationen sowie die Bürokratiestandards durch KI automatisiert, schließen wir die teuerste Lücke im deutschen FTTH-Markt.

Wir transformieren einen wochenlangen, fehleranfälligen Büroprozess in einen automatisierten Datenfluss in Echtzeit. Für General- und Subunternehmer bedeutet dies nicht nur massive Einsparungen bei den Personalkosten, sondern vor allem eines: Rechnungen werden Monate früher bezahlt. In einem Markt, der von Liquidität getrieben wird, ist diese Lösung kein "Nice-to-have", sondern überlebenswichtig.

---

## 7. Quellen & Referenzen (Marktvalidierung)

Die in diesem Dokument beschriebenen Marktbedingungen und Potenziale werden durch aktuelle Branchendaten und staatliche Initiativen untermauert:

1. **Gigabitförderung des Bundes (Marktvolumen):** Der Bund investiert massiv in den Glasfaserausbau. Allein durch die "Gigabitförderung 2.0" wurden Anfang 2026 rund 1,8 Milliarden Euro bewilligt, gefolgt von einer weiteren Milliarde im April 2026. Insgesamt belaufen sich die Bundesinvestitionen auf ca. 21 Milliarden Euro. *Referenz: [Bundesministerium für Digitales und Verkehr (BMDV) / atene KOM](https://gigabitbuero.de/)*
2. **DIN 18220 (Standardisierung & Bürokratie):** Die seit Juli 2023 geltende DIN-Norm für "Trenching-, Fräs- und Pflugverfahren" erzwingt bundesweit einheitliche, aber komplexe Dokumentations- und Einmessungsstandards, die ohne digitale Helfer im Feld kaum rechtssicher und profitabel umzusetzen sind. *Referenz: [Deutsches Institut für Normung - DIN 18220](https://www.din.de/)*
3. **BREKO Marktanalyse (Kritische Marktlage):** Die aktuelle Marktanalyse des Bundesverbandes Breitbandkommunikation (BREKO) warnt vor explodierenden Baukosten und einem stagnierenden Investitionsklima. Um in diesem Umfeld profitabel zu bleiben, ist ein massiver Bürokratieabbau und die Digitalisierung der Bauprozesse zwingend erforderlich – exakt der Schmerzpunkt, den Horizon Link löst. *Referenz: [BREKO Marktanalyse Glasfaserausbau](https://www.brekoverband.de/)*
