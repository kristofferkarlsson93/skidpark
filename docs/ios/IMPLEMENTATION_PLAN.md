# Plan för iOS-stöd

Status 2026-10-22: **signerad release installerad och startad på iPhone 17**;
exempelanalys och första inomhusinspelning/export är verifierade på iOS 26.7.1.
Se [aktuell verifiering och nästa steg på fysisk telefon](STATUS.md).
Bakgrund och källor: [iOS-utredningen](README.md).

## Gemensamt uppdragskontrakt

Varje IOS-uppdrag nedan kan ges till en egen Codex-kodagent. Ge agenten detta
dokument, utredningen och uppdragets ID. Agenten ska läsa `AGENTS.md`, aktuell
kod och vid UX-/flödesarbete `docs/product-ux/PRODUCT_DECISIONS.md`.
Vid arbete med mätkedjan ska även lokala
`docs/glide-data-analysis/README.md`, `VALIDATION_PLAN.md` och
`aa-2026-10-20/REPORT.md` läsas om de finns. De är Git-ignorerade; saknas de
ska agenten ange det och inte uppfinna slutsatser om mätkvalitet.

Varje uppdrag ska leverera en fokuserad diff, utförda kontroller, kvarstående
osäkerheter och eventuella avvikelser från planen. Huvudagenten granskar scope,
diff och verifiering före integration. Inga produktionsdata får raderas.

- Behåll Android fungerande, rådatans betydelse, stabila åknummer och komplett
  testbundet skidurval. Äldre exporter och exempeldata ska fortsätta fungera.
- GPS får bara starta efter `Nytt åk`; inspelningsrutten äger och stänger
  resurserna på samtliga utvägar. Att öppna analys ska vara behörighetsfritt.
- Ingen ny distansmodell, filtertrimning, orienteringsfusion, automatisk
  vinnare eller obligatorisk telefonmontering ingår.
- Använd befintliga paket först. Motivera nödvändiga uppdateringar och håll
  dem minimala; ingen generell dependency-uppgradering eller pluginfork.
- Kör `flutter analyze` för Dart-ändringar och relevanta befintliga tester.
  Efter dependencyändring eller färsk checkout: `dart run build_runner build`.
  Nya tester ska verifiera beteende och verkliga felrisker.
- Etapperna är scopegränser. Ett senare uppdrag får inte dras in i ett tidigare.
  Punkterna nedan är uppdragsbeskrivningar; faktisk genomförandestatus finns
  i statusdokumentet och får inte härledas från att en punkt finns i planen.

## Etapper och beroenden

| Etapp | Uppdrag | Klart när |
| --- | --- | --- |
| A: utvecklingsmiljö och startbar app | IOS-00, IOS-01 | Simulatorbygge och osignerat enhetsbygge fungerar med dokumenterad miljö. |
| B: användbar och robust inspelning | IOS-02–IOS-07 | Behörigheter, styrning, avbrott, databetydelse och filflöden är hanterade. |
| C: verifiering på simulator och enhet | IOS-08, IOS-09 | Kritiska flöden och verkliga sensorer har verifierats; begränsningar är redovisade. |
| D: valfri distribution | IOS-10 | Granskbar release är förberedd för vald kanal. Ingen publicering ingår. |

Genomförandet använder skärmstyrning med volymstub på iOS, iOS 15 och behållet
iPhone/iPad-stöd. Avbrottspolicyn i IOS-04 återstår att besluta och verifiera;
rekommendationerna där är fortfarande förslag.

IOS-00 → IOS-01 → IOS-02 → IOS-04 → IOS-05 → IOS-06 är huvudkedjan för
inspelningskoden. IOS-03 kan köras parallellt med IOS-02 efter att styrningen
godkänts. IOS-07 kan börja efter IOS-01 och integreras efter IOS-05.
IOS-08 följer efter etapp B, IOS-09 efter IOS-08 och IOS-10 efter IOS-09.
IOS-02/04/05 delar `data_recorder.dart` och ska inte redigeras parallellt.
IOS-03/06 delar inspelnings-VM/UI och integreras i turordning.

## IOS-00 — Förbered Mac, simulator och testtelefon

**Typ/beroende:** miljöuppdrag, först. Vissa steg kräver att användaren loggar
in i Apple-konto, accepterar licenser eller ändrar telefoninställningar.
**Ingår inte:** ändringar i appen eller köpt medlemskap.

1. Installera en fullständig Xcode som passar macOS och paketkraven
   (minst 26.1.1 enligt låsta `device_info_plus`). Välj dess developer directory,
   slutför first launch och låt användaren läsa/acceptera licenserna.
2. Installera iOS-plattform och simulatorruntime; skapa en arm64 iPhone-simulator.
   Kontrollera ledigt diskutrymme före nedladdningen.
3. Kör `flutter doctor -v`, `xcodebuild -version`, `xcrun simctl list devices`
   och `flutter devices`. Dokumentera exakta versioner och relevanta fel.
4. Inventera SwiftPM-stöd hos samtliga låsta native paket. Installera CocoaPods
   endast om den valda integrationsvägen behöver det; ändra inte globala
   Flutter-inställningar som rutin.
5. Förbered en riktig iPhone: anslutning, Trust, Developer Mode, Apple-konto
   och utvecklingssignering. Anteckna modell/iOS; publicera inga kontohemligheter.

**Acceptans:** simulatorn identifieras av Flutter och inga relevanta
iOS-verktygsfel återstår. Enhet/signeringens status är uttryckligen redovisad.
Om telefon saknas är miljöuppdraget bara delvis verifierat; sensorvalidering
får inte rapporteras klar.

## IOS-01 — Modernisera och bygg iOS-värdprojektet

**Beroende:** IOS-00, bekräftat minimistöd. **Äger:** `ios/`, nödvändiga
projektinställningar i `pubspec.yaml`, motiverade lockfilsändringar.
**Ingår inte:** behörighets-UX, knappstyrning eller mätalgoritmer.

1. Migrera det befintliga projektet med installerad stabil Flutter som referens
   (nu 3.47.7; malljämförelsen började med 3.47.1).
   Använd en tillfällig separat Flutter-app för malljämförelse vid behov;
   skriv inte över hela projektet med `flutter create .`.
2. Anpassa deployment targets till iOS 15 och kontrollera Debug/Profile/Release,
   testtarget och `AppFrameworkInfo.plist` enligt aktuell Flutter-migrering.
3. Migrera AppDelegate/pluginregistrering och Info.plist till UIScene.
   Kontrollera automatmigreringens diff och bevara appnamn, ikoner och splash.
4. Integrera native plugins med SwiftPM i första hand, inklusive projektberoende
   och prepare-preaction. Använd CocoaPods-fallback endast för konstaterat behov.
   Dokumentera hur låsning och ren checkout fungerar. `sqlite3` 3 använder
   code assets; lägg inte till ett äldre SQLite-bibliotek av gammal vana.
5. Inventera varje låst native plugins iOS-minimum och Swift/Xcode-krav.
   Behåll bundle-ID; hantera lokalt signeringsteam utan att checka in hemligheter.
6. Bygg simulatorapp och kör exempeltestet. Kör också
   `flutter build ios --release --no-codesign` för enhetsarkitektur.

**Acceptans:** båda byggena lyckas; appen startar, pluginregistrering och
SQLite fungerar och exempelanalysen öppnas utan platsdialog. Ange verkliga
byggresultat, inte bara statiskt granskad konfiguration. Inget köp eller
uppladdning krävs för dessa byggkontroller.

## IOS-02 — Plats-/rörelsebehörigheter och iOS-GPS-konfiguration

**Beroende:** IOS-01, godkänd omfattning för förgrundsinspelning.
**Äger:** behörighetsdelarna i `data_recorder.dart`, iOS-behörighetskonfiguration.
Samordna eventuella UI-anrop med IOS-03. **Ingår inte:** bakgrundsinspelning.

1. Ersätt engelska plats- och rörelsebeskrivningar med konkreta svenska texter.
   Behåll begäran först efter `Nytt åk`. Analys och exempel ska fungera utan
   plats- eller rörelseåtkomst.
2. Hantera första begäran, Tillåt en gång, nekat/permanent nekat, avstängda
   platstjänster och återkomst från appinställningarna. Kontrollera vilka
   inställningslänkar faktiskt fungerar på iOS.
3. Läs `getLocationAccuracy()` efter erhållen behörighet. Vid reducerad
   precision: visa begränsningen och en väg till exakt plats. Om tillfällig
   full precision används, lägg till motsvarande purpose key i Info.plist.
   Nekande får inte skapa en dialogloop eller blockera befintlig analys.
4. Ange explicita AppleSettings för vald policy: ingen automatisk paus under
   aktiv inspelning och ingen bakgrundslokalisering i förgrundsomfattningen.
   Granska `automotiveNavigation` mot `fitness`/`otherNavigation`; dokumentera
   vald aktivitetsklass utan att lova bättre precision eller frekvens.
5. Kontrollera geolocators Always-bypass för **låsta** `geolocator_apple`.
   Kopiera inte det nyare miljövariabelexemplet till ett manifest som ignorerar
   det. Om en minimal uppdatering behövs för fungerande SwiftPM-konfiguration,
   redovisa native diff, versionsändring och Android-påverkan.
6. Verifiera att nekad barometer/rörelseåtkomst kan redovisas som saknad data
   utan att stänga appen eller kasta bort redan inspelad GPS.

**Acceptans:** matrisen ovan provas på simulator och relevanta behörighetsfall
på enhet. Ingen Always-/kamera-/mikrofon-/fotobehörighet begärs av kärnflödet.
Efter nekande går appen att använda och ett nytt inspelningsförsök kan göras.

## IOS-03 — Plattformskapacitet för volyminmatning och ärliga instruktioner

**Beroende:** IOS-01 och godkänt beslut om skärmstyrning på iOS.
**Äger:** `volume_control.dart`, `volume_press_handler.dart`, `main.dart`,
berörda instruktioner i overview/skidval/inspelning och deras tester.
**Ingår inte:** privata API:er, kamera för knappfångst, ljudvolymstrick,
extern fjärrkontroll eller nytt större navigationsflöde.

1. Återanvänd `VolumeButtonInput`; exponera kapacitet och välj implementation
   genom composition. Android behåller kort-/långtryck; iOS anger saknat stöd
   och har strömmar som inte producerar knapphändelser.
2. Säkerställ att alla kärnhandlingar fungerar med befintliga skärmknappar:
   nytt åk, välj skida, starta, stoppa/spara, avbryt och tillbaka.
3. Dölj eller anpassa volymtips där kapaciteten saknas. Inventera särskilt
   `overview_container.dart`, `start_test_run.dart`, `record_test_run.dart`.
   Förändra inte Androids instruktioner eller normalflöde oavsiktligt.
4. Kontrollera korrekt avregistrering av MethodChannel och timers vid dispose.
   Begränsa refaktorn till vad plattformsvalet kräver.
5. Prova iPhones volymknappar fysiskt: normal systemvolym ska fungera och inte
   starta/stoppa inspelning. Android: verifiera kort/långt tryck i översikt,
   skidval och inspelning, inklusive pausen under snabbskapa-skida-formuläret.

**Acceptans:** ingen falsk knappinstruktion på iOS; full skärmstyrning finns.
Androids befintliga knappflöden är verifierade. Om volymnavigation fortfarande
är ett absolut krav ska detta beslut återföras till användaren, inte ersättas
med en experimentell implementation inom uppdraget.

## IOS-04 — Skärmlås och avbrott utan tyst fortsatt mätning

**Beroende:** IOS-02 och godkänd avbrottspolicy.
**Äger:** `run_recording_screen.dart`, inspelnings-VM och `data_recorder.dart`.
**Ingår inte:** inspelning i bakgrunden eller generell återställning efter
processdöd. Sådan dataräddning är en separat utökning om den behövs.

1. Implementera den beslutade hanteringen av att lämna aktiv förgrund.
   Rekommenderat: avsluta mätningen, behåll insamlad delmätning för medvetet
   spara/avbryt och visa att åket avbröts. Återstarta aldrig ett åk tyst.
2. Skilj verklig bakgrund/låsning från tillfälligt `inactive`, exempelvis en
   systemdialog. Behörighetsdialoger eller nekande får inte radera ett åk.
3. Om skärmen ska hållas vaken under åk: aktivera det endast i beslutad del
   av inspelningsrutten och återställ vid samtliga utvägar. Redovisa nytt
   paket eller native kod om det behövs; påverka inte analysvyns vilobeteende.
4. Säkerställ stopp av GPS och samtliga sensorströmmar vid spara, avbryt,
   tillbaka, fel och disposal. Hantera GPS-fel synligt; grön status får inte
   hänga kvar och autospara får inte fortsätta utifrån gamla stoppunkter.
5. Verifiera sparfel/återförsök, navigeringsgest på iOS och upprepade nya åk.

**Acceptans:** fysiskt verifierade hemknapp/hemgest, lås/lås upp,
systemavbrott, framåt/bakåt/avbryt/start/stopp/spara. Ingen dold inspelning
eller tyst hopfogning över luckor. Rapportera tydligt att ännu osparad data
fortfarande kan förloras om processen dödas.

## IOS-05 — Sensorsemantik, tidsbaser och inspelningsursprung

**Beroende:** IOS-04. **Äger:** sensorsource, rådatamodeller,
`sensor_recording_metadata.dart`, enhetsinfo och metadataflödet genom
inspelning, repository, import/export. **Ingår inte:** ny filtermodell.

1. Gör ett kort enhetsprov: stilla, translation längs varje telefonaxel,
   känd rotation åt båda håll och nytt åk efter stopp. Kör acceleration,
   gyro, orientering och barometer samtidigt, inte bara var för sig.
2. Verifiera m/s², rad/s, hPa, quaternionordning och vilken riktning quaternionen
   transformerar. Kontrollera sensorernas inbördes tecken; dubblera inte
   pluginets iOS-konverteringar. `accuracyRadians = -1` betyder okänd.
3. Mät faktisk frekvens, jitter och bortfall från sensortidsstämplarna.
   Registrera begärda intervall separat; barometerintervallet på iOS är inte
   styrbart genom nuvarande plugin.
4. Kartlägg GPS-mättid, GPS-mottagningstid, sensors_plus-tid, orienteringens
   boot-tid i ns och inspelningsklockans µs. Verifiera att analyserna använder
   jämförbara tidsbaser. Bevara befintliga tidsfält och gamla exporters betydelse.
   Följ upp barometerns observerade tidsdiskrepans på cirka 1,15 s i första
   iPhone-exporten; se lokal analys länkad från statusdokumentet. Orsaken är
   inte fastställd och råtiderna får inte korrigeras på antagande.
5. Utred giltighetsförlusten i native → Position: negativ fart/fartnoggrannhet
   blir utelämnad och därefter `0/0`. Bevara giltighet när källan faktiskt
   tillhandahåller den; representera annars osäkerhet uttryckligt. Härled inte
   en säker giltighetsflagga från att värdet råkar vara noll. Om lösningen
   kräver pluginfork/nytt native kontrakt: lämna ett konkret separat förslag
   innan en sådan arkitekturändring görs.
6. Lägg bakåtkompatibel inspelningskontext per åk i befintlig metadata:
   plattform, konkret modell (`utsname.machine` på iOS), OS/appversion och
   relevanta sensor-/GPS-inställningar. Blanda inte in personligt enhetsnamn
   eller nya identifieringsbehörigheter. Behåll exportörens enhetsinfo separat.
7. Bevara kontexten genom import/export. Äldre åks inspelningsursprung ska
   anges som okänt när det saknas, aldrig fyllas med exporttelefonens identitet.
   Föredra befintlig metadata-JSON framför ny databasstruktur.

**Acceptans:** en iPhone-export kan läsas med alla enheter och tidsbaser
förklarade; saknade sensorer/okänd noggrannhet är synliga i metadata.
Fokuserade kompatibilitetstester visar att Android-exempel, äldre exporter,
nya åk och återexport behåller rådata, ursprung, åknummer och skidurval.
Återstående giltighetsambiguitet måste vara löst eller tydligt avgränsad
innan automatisk stoppdetektion godkänns i IOS-06.

## IOS-06 — Frekvensoberoende stoppregler och säkra kvalitetsvärden

**Beroende:** IOS-03, IOS-05. **Äger:** autosparande i
`run_recorder_view_model.dart`, noggrannhetsbedömning och fokuserade tester.
**Ingår inte:** ändrad trimning, distansintegration, Kalmanmodell eller filter-alpha.

1. Dokumentera dagens beteende: minst 20 punkter, två fartvärden ≤0,15 m/s,
   sedan tre sekunders nedräkning. Föreslå explicita tidsvillkor som bevarar
   avsikten över olika GPS-frekvenser. Stäm av valda tidsgränser före ändring.
2. Använd verkliga mättider och giltiga färska fartvärden för stoppvillkoret;
   en tät burst, dubbletter eller `0/0` utan känd giltighet ska inte räknas som
   säker stillastående mätning. Ingen ny GPS under nedräkningen ska hanteras
   enligt en uttrycklig regel, inte tas som bekräftat stopp.
3. Låt manuell stopp/spara fungera även vid korta åk eller dålig GPS.
   Visa okänd/dålig kvalitet för ogiltig positionsnoggrannhet. Tolka inte
   operativsystemets noggrannhetsuppskattning som garanti för rätt hastighetskurva.
4. Testa likvärdiga förlopp vid 1/5 Hz och ojämn leverans, GPS-lucka,
   ogiltig fart, riktig stillastående punkt, kort åk och återupptagen rörelse.
5. Lägg konstaterade problem med ±3-punkters trimning och fast filter-alpha i
   separata uppföljningar med visad påverkan; ändra dem inte i portningen.

**Acceptans:** sparbeslut styrs av tid och datakvalitet, inte mottaget antal
punkter. Både Android och iOS provas. Befintliga analyser ändras inte av detta
uppdrag; eventuella blockerande analysfel kräver ett separat avgränsat beslut.

## IOS-07 — Lagring, filöverföring och plattformens gränssnitt

**Beroende:** IOS-01; slutlig integration efter IOS-03/05.
**Äger:** exportservice och anropsställe, befintlig debugimport,
konstaterade iOS-layoutfel. **Ingår inte:** ny publik import eller redesign.

1. Verifiera skapa/redigera skida och test, installera exempel en gång,
   spara/radera åk, stäng/starta appen och läs tillbaka riktig SQLite-data.
2. Exportera till Filer och dela JSON på iPhone. Prova även iPad eftersom
   projektet deklarerar stöd. Ge delningsdialogen ett lämpligt ankare vid behov.
   `share_plus` 13.3.0 har redan fallback när `sharePositionOrigin` saknas;
   beskriv därför inte dagens kod som en bevisad iPad-krasch.
3. Prova lokal fil och iCloud-fil, avbryt och fel i befintlig debugimport.
   Kontrollera återexport efter överföring Android → iOS och iOS → Android.
   Använd version 3 och äldre fixtures utan att tappa åk eller ännu oåkta skidor.
4. Kontrollera safe areas, Dynamic Island/skärmutskärning, tangentbord,
   rimlig större text, analys i liggande och återgång till stående.
5. Kontrollera kontaktlänk och ikon/splash. Lägg bara till URL-scheman om ett
   faktiskt `canLaunchUrl`-/integrationsbehov finns. Undvik extra filbehörigheter.

**Acceptans:** spara/omstart/analys/export fungerar utan datatapp, och det
deklarerade enhetsstödet har provats. Eventuellt iPhone-only-stöd måste vara
ett beslutat scopebyte, inte en genväg runt iPad-fel.

## IOS-08 — Reproducerbart iOS-flödestest

**Beroende:** IOS-02–07. **Äger:** avgränsad iOS-testkörning, testdata och
relevanta befintliga Flutter-tester. **Ingår inte:** stort nytt testramverk.

1. Utgå från `e2e/maestro` och `scripts/run_android_e2e.sh`. Återanvänd relevanta
   användarresor och välj en liten iOS-runner med befintlig Maestro om möjligt.
   Ersätt Androidspecifika adb-/GPS-/installationssteg; anta inte att skriptet
   redan är plattformsoberoende. Föreslå alternativ innan ett nytt ramverk införs.
2. Använd separat bundle-ID och simulator för rensning/testdata. Radera eller
   ominstallera aldrig användarens vanliga SkidPark för att få ett grönt test.
3. Täck kallstart/exempel utan platsdialog, skapa test, nytt åk/behörighet,
   välj skida/starta/stoppa/spara, avbryt/tillbaka, öppna analys och omstart.
   Använd en deterministisk simulerad rutt med dokumenterade begränsningar.
4. Kontrollera att stoppade rutter inte längre skickar sensor-/GPS-händelser.
   Behåll fokuserade VM-/datatester där simulatorn inte kan ge trovärdig kontroll.
5. Dokumentera ett körkommando, verktygsversioner, vad automatiseringen faktiskt
   täcker och vilka fysiska knapp-/sensor-/avbrottskontroller som är manuella.

**Acceptans:** körningen kan upprepas från dokumenterat utgångsläge och relevanta
Flutter-tester/analyze passerar. Androids befintliga E2E-körning fungerar efter
gemensamma ändringar. Simulerad GPS redovisas inte som validerad mätprecision.

## IOS-09 — Verifiera verklig mätning på iPhone och jämför Android

**Beroende:** IOS-08, tillgång till riktiga telefoner.
**Typ:** agentförberedd mätning/analys med användarens fysiska insamling.
**Ingår inte:** ny produktionsalgoritm eller löfte om en viss meternoggrannhet.

1. Förbered kort protokoll och analys av exporternas intervall, tidsluckor,
   fördröjning, GPS-fart/fartnoggrannhet, position, sensorfrekvens och felstatus.
   Ange i förväg vad som räknas som saknad/ogiltig information.
2. Kör sensorprovet från IOS-05 på iPhone och Android. Prova även kallstart,
   nytt åk efter gammalt, nekad behörighet, skärmlås/avbrott och återgång.
3. Samla upprepade A–A-åk, riktmärke 8–10 per telefon i samma backe med samma
   skidor och normalt handgrepp. Anteckna vind, förhållanden och störningar.
   Kontrollera hela hastighetsförloppet med fusion av/på; behåll misslyckade åk
   med förklaring. Tillfällig montering kan användas för en specifik kontroll,
   men är inget krav för normal användning.
4. Jämför repeterbarhet inom varje telefon först. Med en iPhone och en Android
   kan resultatet inte isolera OS från hårdvara, firmware och åkarens variation.
   Utöka senare till fler modeller om fynden motiverar det.
5. Använd visuella observationer och kända passagetider/stoppmarkeringar när
   tillgängligt. En oberoende referens behövs för påståenden om absolut
   noggrannhet; en avancerad referensrigg krävs inte för första enhetsprovet.
6. Skriv kort resultat med rådatahänvisningar, fungerande beteende, avvikelser
   och rekommenderat nästa steg. Lägg persondata/exporter i avsedda ignorerade
   mappar, inte i Git. Håll publik slutsats fri från exakta privata GPS-spår.

**Acceptans:** det går att redovisa iPhones faktiskt observerade GPS-/sensorfrekvens,
avbrottsbeteende och A–A-variation utan att tillskriva dem alla iOS-enheter.
Ingen känd allvarlig datatapp-/falskstoppbugg kvarstår. Kvarstående
mätosäkerhet är uttrycklig; ändrad filtrering kräver ny separat plan.

## IOS-10 — Förbered vald distribution, om den efterfrågas

**Beroende:** IOS-09 och separat val av distribution.
**Ingår inte:** köpa medlemskap, uppladdning eller publicering.

1. För lokal användning: dokumentera signering, installation och Personal Teams
   begränsningar. Kräv inte App Store-arbete för ett personligt test.
2. För TestFlight/App Store: kontrollera aktuellt medlemskap, bundle-ID,
   provisioning, version/buildnummer och SDK-krav för vald kanal.
3. Granska releasearkivets samlade privacy manifests och använda required-reason
   APIs. Pluginernas manifest ersätter inte granskning av appens egna anrop.
   Använd inte en kopierad lista med osanna API-skäl eller nya identifieringsrättigheter.
4. Förbered integritetstext och App Privacy-svar utifrån faktiskt dataflöde:
   lokal lagring och användarstyrd export. Kontrollera releasebyggets riktiga
   beteende och att debugimport inte exponeras.
5. Förbered signerat arkiv, installations-/distributionsinstruktion och
   granskningsunderlag för behörigheter, styrning och mätbegränsningar.

**Acceptans:** konkret releaseunderlag och verifierat arkiv finns för granskning.
Ingen leverans får beskrivas som publicerad innan en separat auktoriserad
uppladdning/publicering faktiskt har skett.
