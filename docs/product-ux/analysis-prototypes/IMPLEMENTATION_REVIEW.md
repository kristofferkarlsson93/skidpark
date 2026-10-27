# Implementation och UX-granskning, 2026-10-27

Implementationen följer den godkända mockupens navigation och guide. Texten
är korrigerad till **Gör flera åk med varje skidpar**. Ett test kan innehålla
valfritt antal skidpar.

## Verifierat

- 47 Flutter-tester passerar, inklusive guide på 360×740, bevarad
  expansion/rullning, åkurval över flikbyten och exempeltestets restriktioner.
- `flutter analyze`: samma 23 befintliga informationsanmärkningar som före
  ändringen; inga nya fel eller varningar. `git diff --check` passerar.
- Isolerad Android-installation `com.krikar.skidpark.skidpark.e2e`, Android 17,
  emulator-5554: livscykel, inspelning/spara, alla tre flikar, tomt urval,
  avbryt/back, annan skida och snabbskapande av skida passerar Maestro.
- Verkliga Android-volymhändelser i emulatorn: långtryck från tom guide och
  Guide med åk; kort upp/ner i skidval; långtryck startar; kort ner sparar;
  återöppning och tillbaka återställer rätt flik.
- Widgettester blockerar volymstart bakom sidopanel, meny, dialog och annan
  route. Manuellt långtryck med öppen sidopanel lämnade panelen öppen.
- Manuell genomgång med UI-hierarki, tryck, grafgest och granskade skärmbilder:
  tom guide, utfälld analysguide, sidopanel, släppunkt utan hastighetsdata och
  appens exempeltest med fyra kurvor inklusive faktiskt släppunktsresultat.
  Ett nytt tomt test med tre valda skidpar granskades också.

## Korrigeringar och avgränsning

Granskningen hittade en befintlig krasch i släppunktens val av startpunkt när
ett sparat åk saknar hastighetspunkter. Detta hanteras nu utan krasch;
analysreglaget/knappen är avstängda med en förklaring. Ett regressionstest
täcker fallet. Beräkningar för åk med användbara punkter ändras inte.

Sidopanelens åkurvalsrubrik fick flexibel bredd. Helskärmsknappen flyttades upp
när högerkantens vyknappar togs bort. Informationsdialogen om släppunkt
beskriver samma beräknade jämförelse som guiden.

Appens befintliga tema, mätvärdeskort och resultatpresentation återanvänds;
mockupens fiktiva datakvalitetsvarningar implementeras inte. Grafens position
och 60/40-fördelning bevaras. Befintlig överlappning mellan grafens sista
X-axeletiketter vid vissa distanser observerades, men grafens axellayout
omdesignas inte i denna leverans.

Kontrollen gäller gränssnitt och navigering. Fysisk telefon, iOS-visuell
genomgång, handskar/kyla och mätprecision har inte verifierats här.

## Efterföljande justering av nederdelen

Flikar och urvalsrad skrollar nu med nederdelens innehåll, medan grafen ligger
kvar på 60 procent. Varje vy bevarar sin skrollposition. Guidelänken i
sidopanelen och beräkningsetiketten i urvalsraden är borttagna enligt användarens
återkoppling; inställningarna i sidopanelen finns kvar. Detta ersätter
mockupens tidigare fasta flikrad och hjälplänk.

Åtta riktade widgettester passerar efter justeringen, inklusive återgång till
flikarna efter skrollning, guide-expansion/skrollposition och volymhantering.
Flutter-analysen har samma 23 befintliga informationsanmärkningar.
