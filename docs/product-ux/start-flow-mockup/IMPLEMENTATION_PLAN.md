# Implementationsplan i två etapper

## Målbild

En ny användare ska kunna förstå SkidParks faktiska nytta utan att först skapa
egen mätdata och sedan skapa ett eget test med rätt skidor utan att administrera
skidparken i ett separat flöde.

Den färdiga resan är:

> Första start → öppna riktigt exempeltest → granska åk och kurvor → skapa eget
> test → lägg till egna skidor → registrera första åket.

Arbetet genomförs i två sammanhållna etapper:

1. **Appskal och allt före testarbetsytan:** navigation, intro, tema, testlista,
   skidpark och grundkomponenter.
2. **Testflödet:** exempeldata, GPS-livscykel, nytt test, skidurval och nytt åk.

Mockupen visar målbilden efter båda etapperna. Etapp 1 får därför inte lägga in
en låtsasversion av funktioner som blir riktiga först i etapp 2.

## Gemensam avgränsning

Det här är ett selektivt designomtag, inte ett totalt designsystemsprojekt.

Vi behåller:

- nuvarande analys- och inspelningsarkitektur där den inte orsakar GPS-problemet;
- den stora grafen och kopplingen mellan vald åkrad och markerad kurva;
- den dedikerade sidomenyn för filter och expertval;
- befintlig mörk färgriktning och lila primärfärg;
- användaren som slutlig uttolkare av resultatet.

Vi gör inte i någon av etapperna:

- en omdesign av analysgraf, sidomeny eller släppunktsanalys;
- en automatisk vinnare eller rekommendation av ”bästa skida”;
- en skidhistoriksida;
- disciplinetiketter som `stak`, `klassiskt` eller `skate`;
- statusarna förberett/aktivt/avslutat eller en obligatorisk avslutaknapp;
- en varning för lång tid mellan åk;
- ändringar av filter, Kalmanmodell, linjering eller annan mätberäkning.

---

## Etapp 1 – appskal och ytor före testet

**Status:** Implementerad och verifierad 2026-09-08.

### Syfte

SkidPark ska få den nya professionella designriktningen och en tydlig ingång
till kärnaktiviteten utan att vi samtidigt ändrar testets datamodell,
GPS-livscykel eller inspelningsflöde.

Etappen ska kunna granskas och mergas för sig. Det befintliga testformuläret och
den befintliga testarbetsytan fortsätter fungera tills etapp 2 ersätter deras
berörda delar.

### Arbetslista

- [x] Flytta `Tester` till första fliken.
- [x] Ersätt `GlidLabbet` som områdesnamn med `SkidPark` och `Tester`.
- [x] Inför den nya visuella grunden i `ThemeData`.
- [x] Bygg testlistans första-start-, tom-, laddnings- och fylltillstånd.
- [x] Inför produktlöftet och tydliga CTA-varianter för ny respektive van
      användare.
- [x] Bygg om testkorten med konkreta fakta i stället för livscykelstatus.
- [x] Bygg om skidparken från kortgrid till kompakt sökbar lista.
- [x] Anpassa lägg till/redigera skida till den nya formulärdesignen.
- [x] Kontrollera stora textstorlekar, långa skidnamn och små skärmar.
- [x] Kör widgettester, `flutter analyze` och visuell Android-verifiering.

### 1.1 Navigation och benämningar

Berör främst:

- `lib/common/navigation/bottom_navigation.dart`
- `lib/main.dart`
- `lib/features/glide_testing/explore/screen/glide_testing_home_screen.dart`

Arbete:

- Ordna flikarna `Tester`, `Skidor`, `Mer` och starta på `Tester`.
- Använd `SkidPark` som produktnamn i appfält och apptitel.
- Använd `Tester` som kort navigationsetikett. `GlidLabbet` tas bort som ett
  konkurrerande produktområde.
- Behåll flikarnas tillstånd med nuvarande `IndexedStack`.
- Ge vald flik både ikon-, text- och bakgrundssignal; färg ska inte vara enda
  markören.

Acceptanskriterier:

- Appen öppnas alltid på `Tester` efter en kall start.
- Flikordningen är `Tester`, `Skidor`, `Mer`.
- Ingen synlig text använder `GlidLabbet`.
- Flikbyte tappar inte lokal scroll eller pågående skärmtillstånd i onödan.

### 1.2 Tema och komponentregler

Berör främst:

- `lib/theme/app_theme.dart`
- befintliga delade widgets i `lib/common/shared_widgets/`

Arbete:

- Behåll mörk bakgrund och lila primärfärg men justera ytor, ramar och
  textkontrast efter mockupen.
- Kort: 16 px radie, 1 px ram och ingen elevation. Kort används för tappbara
  objekt och tydligt grupperade block, inte som generell dekoration.
- Fylld primärknapp: minst 50 px hög och 14 px radie. Konturknapp används för
  alternativa vägar. Ikonknappar har minst 44 × 44 px tryckyta.
- Formulärfält: minst 48 px höga med synlig fokusring. Hjälptext visas endast
  när den tillför information.
- Använd avståndsskalan 4, 8, 12, 16 och 24 px.
- Lägg standarderna i `ThemeData` först. Skapa en delad widget bara när minst
  två verkliga skärmar delar beteende, inte enbart utseende.
- Gå igenom befintliga skärmar så att globala temaändringar inte försämrar
  grafens overlays eller stora inspelningsknappar.

Acceptanskriterier:

- Testkort, skidrad och formulär känns som samma produkt utan att tvingas in i
  samma komponent.
- Ingen viktig kontroll har mindre än 44 px tryckyta.
- Brödtext, metadata och inaktiva kontroller är läsbara mot sina bakgrunder.
- Färg är aldrig enda signalen för val eller tillstånd.

### 1.3 Testlistan och första-start-information

Berör främst:

- `lib/features/glide_testing/explore/screen/glide_testing_home_screen.dart`
- `lib/features/glide_testing/explore/widgets/glide_testing_intro_card.dart`
- `lib/features/glide_testing/explore/widgets/glide_test_list_card.dart`
- `lib/features/glide_testing/explore/widgets/my_glide_tests_list.dart`

Arbete:

- Visa produktlöftet **Bättre underlag för dagens skidval** när användaren ännu
  saknar egna test.
- Använd den förklarande texten: **Jämför dina skidor med upprepade glidåk.
  Granska kurvor och datakvalitet – du gör själv bedömningen.**
- Visa en stor primärknapp `Skapa mitt första test` i första-start-tillståndet.
- För återkommande användare visas en kompakt `Nytt test`-handling i appfältet
  i stället för det stora introduktionsblocket.
- Testkort visar namn, datum/senaste aktivitet, antal skidor och antal åk.
- Hela kortet är tappbart. Ingen status som `Förberett`, `Aktivt` eller
  `Avslutat` införs.
- Lägg uttryckliga laddnings-, fel- och tomtillstånd så att tom lista inte ser ut
  som borttappat innehåll.
- Förbered visuell komponent för exempelkortet, men visa den inte i den riktiga
  appen förrän exempeldata och GPS-gränsen är klara i etapp 2.

Teknisk anmärkning:

- Antal åk kan räknas från befintliga relationer.
- Antal skidor i gamla test kan tills vidare räknas som unika skidor med åk.
  Tomma test får inte låtsas ha ett känt kandidatantal före etapp 2.

Acceptanskriterier:

- En ny användare förstår vad produkten gör och ser en tydlig nästa handling.
- En van användare når sitt senaste test utan att passera en permanent introvy.
- Kort visar bara fakta som går att härleda från nuvarande data.
- Etapp 1 innehåller ingen mockad eller hårdkodad exempelanalys.

### 1.4 Skidparken

Berör främst:

- `lib/features/ski_management/exlore/screen/ski_management_screen.dart`
- `lib/features/ski_management/exlore/widgets/my_skis_component.dart`
- `lib/features/ski_management/exlore/widgets/ski_card.dart`
- `lib/features/ski_management/create/add_ski_form.dart`
- `lib/features/ski_management/details/screen/ski_details_screen.dart`

Arbete:

- Ersätt tvåkolumnsgridden med en enkolumnslista.
- Visa eget namn som primär text och märke/modell som sekundär. Teknisk data
  visas inte i listan och skapar aldrig en stor tom yta.
- Lägg sökning över en fylld lista och en kompakt `Lägg till`-handling i
  appfältet.
- Tomtillståndet förklarar att användaren bör välja de namn hen själv känner
  igen i spåret och visar en enda primär CTA.
- Gör `Lägg till skida` och `Redigera skida` till vanliga helskärmar. Visa namn
  och modell först; teknisk data och anteckningar ligger under
  `Fler uppgifter`.
- Behåll skiddetaljen enkel. Skidhistorik läggs inte till.

Acceptanskriterier:

- Sex skidpar går att överblicka utan att scrolla genom stora tomma kortytor.
- Långa namn trunkeras kontrollerat, men hela raden är tappbar.
- Sökning matchar både eget namn och märke/modell.
- Endast namn krävs för att spara en skida.

### Etapp 1 – verifiering och leveransgräns

Automatiskt:

```text
flutter analyze
flutter test <widgettester för navigation, testlista och skidpark>
```

Manuellt på Android-emulator eller telefon:

1. kall start och flikordning;
2. testlista utan test, med ett test och med flera test;
3. skidpark utan skidor och med minst sex skidpar;
4. sökning, lägg till, redigera och back-navigation;
5. stora systemtypsnitt och en smal mobilskärm;
6. öppna ett befintligt test och starta ett åk för att upptäcka regressioner
   från temaändringen.

Etappen är klar när alla ytor fram till testarbetsytan följer målbilden och det
gamla test-/inspelningsflödet fortfarande fungerar. Det kompletta
första-värde-flödet är däremot inte klart förrän etapp 2 är levererad.

Verifierat 2026-09-09 med åtta passerande Flutter-tester, byggd och installerad
debug-APK samt manuell Android-genomgång av navigation, testlista, skidpark,
skidformulär, skiddetalj och befintlig test-/inspelningsyta. `flutter analyze`
rapporterar 33 sedan tidigare befintliga varningar/info, men inga i
Etapp 1-filerna.

---

## Etapp 2 – testflöde, GPS och skidurval

### Syfte

Koppla ihop den visuella grunden med riktig exempeldata, ett testbundet
skidurval och en GPS-livscykel som bara aktiveras när användaren faktiskt ska
registrera ett åk.

### Arbetslista

- [ ] Lägg till test–skida-relation, exempelmarkering och `AppSetting` i Drift.
- [ ] Migrera befintliga test till ett bevarat skidurval.
- [ ] Flytta platsbehörighet och GPS-start från testöppning till `Nytt åk`.
- [ ] Extrahera importlogiken och paketera ett verkligt exempeltest som asset.
- [ ] Installera exempeldata exakt en gång och stöd uttrycklig återställning.
- [ ] Visa det riktiga exempelkortet på första-start-skärmen.
- [ ] Ersätt bottom sheet med helskärmen `Nytt glidtest`.
- [ ] Implementera massval, sökning och snabbskapande av flera skidor.
- [ ] Låt inspelningsflödet använda testets skidurval.
- [ ] Stöd en medveten avvikelse till en annan skida.
- [ ] Lägg databas-, widget- och integrationstester för hela resan.
- [ ] Kör analys och manuell provning av GPS- och inspelningsflödet.

### 2.1 Datamodell för testets skidor och exempeldata

Berör främst:

- `lib/common/database/database.dart`
- nya tabeller under `lib/common/database/models/`
- `lib/common/database/repository/glide_test_repository.dart`
- `lib/common/database/repository/ski_repository.dart`
- `lib/features/glide_testing/models/glide_test_candidate.dart`

Datamodell:

- Lägg till `GlideTestSki` med `glideTestId`, `skiId` och `sortOrder`.
- Använd sammansatt primärnyckel för test och skida.
- Lägg `isExample` med standardvärdet `false` på test och skida.
- Lägg till nyckel/värde-tabellen `AppSetting`. Nyckeln
  `example_data_v1_installed` gör exempelinstallationen beständig utan ett nytt
  externt beroende.
- Öka Drift-schemaversionen och skriv en explicit migration.
- Vid migration: koppla varje befintligt test till alla aktiva skidor som var
  valbara före migrationen. Det bevarar det gamla inspelningsbeteendet även för
  test som ännu saknar åk.
- Utöka testutkastet med en icke-tom lista `skiIds`.
- Spara test och relationer atomiskt i en databastransaktion.

Repository-API:

- `watchSkisForTest(testId)` i sparad ordning;
- `getLatestRealTestSkiIds()` för `Senaste testet`;
- `createTestWithSkis(draft)` för atomisk skapning;
- `replaceSkisForTest(testId, skiIds)` för redigering och medvetna avvikelser;
- streams för testkortens antal skidor och åk utan N+1-frågor;
- aktiva skidstreams som kan exkludera exempelposter.

Acceptanskriterier:

- Skidordning och urval finns kvar efter omstart.
- Ett misslyckat relationsinsert lämnar inte ett halvt skapat test.
- Befintliga användares gamla test går fortfarande att spela in åk i.
- Exempelposter kan läsas av sitt eget test men kommer inte in i användarens
  vanliga urval.

### 2.2 GPS och platsbehörighet

Berör främst:

- `lib/features/glide_testing/explore/widgets/my_glide_tests_list.dart`
- `lib/features/glide_testing/compare/screens/glide_test_compare_screen.dart`
- `lib/features/glide_testing/test_runs/screen/run_recording_screen.dart`
- `lib/features/glide_testing/test_runs/data_recorder.dart`

Nuvarande problem:

- `MyGlideTestsList` kräver platsbehörighet innan ett test kan öppnas.
- `GlideTestCompareScreen.initState()` skapar `DataRecorder` och startar en
  passiv GPS-prenumeration även när användaren bara vill analysera hemma.

Arbete:

- Öppna alla tidigare test och exempeltest utan platsbehörighetskontroll.
- Skapa inte en aktiv `DataRecorder` när analysvyn öppnas.
- När användaren trycker `Nytt åk`: begär platsbehörighet, skapa/starta
  `DataRecorder` och öppna helskärmen för skidval.
- Låt GPS värmas upp medan användaren väljer skida; starta inte rådatainspelning
  förrän användaren uttryckligen startar åket.
- Avsluta GPS-prenumerationen när inspelningsflödet lämnas, även vid avbrutet åk
  eller nekad behörighet.
- Visa tydligt fel och väg framåt om behörigheten nekas eller GPS saknas.

Acceptanskriterier:

- Att öppna och analysera ett test aktiverar inte platsikonen i operativsystemet.
- En användare kan utforska exempeltestet helt utan platsbehörighet.
- GPS startar först efter `Nytt åk` och stängs när inspelningsflödet lämnas.
- Ett avbrutet eller nekat flöde lämnar ingen prenumeration eller recorder aktiv.
- Befintlig rådatainsamling och autosparlogik ändrar inte betydelse.

### 2.3 Riktigt exempeltest

Berör främst:

- ny `assets/example_data/example_glide_test.json`
- ny tjänst, exempelvis
  `lib/features/glide_testing/example_data/example_data_installer.dart`
- `lib/features/glide_testing/explore/widgets/dev_import_dialog.dart`
- `lib/features/glide_testing/explore/screen/glide_testing_home_screen.dart`
- `lib/features/more_page/screens/more_page.dart`
- `pubspec.yaml`

Arbete:

- Exportera ett verkligt, granskat test med två anonymt namngivna skidor och
  fyra representativa åk. Behåll GPS- och accelerometerrådata.
- Extrahera JSON-tolkning och import från `DevImportDialog` till en
  återanvändbar tjänst. Dialogen väljer bara fil; tjänsten gör arbetet.
- Kör `ExampleDataInstaller.ensureInstalled()` när testlistan laddas första
  gången.
- Skriv `example_data_v1_installed=true` i `AppSetting` i samma
  databastransaktion som exempelposterna. Borttaget exempel återkommer därför
  inte automatiskt vid nästa start.
- Lägg `Återställ exempeltest` under `Mer`.
- Använd samma repositories, beräkningar, graf och filterkontroller som för egna
  test. Ingen separat demoanalys skapas.
- Märk exemplet tydligt. Dölj nya åk och redigering för exempeltestet, men låt
  analyskontrollerna vara interaktiva.
- Filtrera bort exempelskidor från skidparken och alla egna testurval.

Acceptanskriterier:

- Första starten visar ett kort märkt `Exempel` med två skidor och fyra åk.
- Kurvorna räknas från samma rådata och kodväg som egna test.
- Exempelskidor syns aldrig i `Skidor` eller när ett eget test skapas.
- Exempeltestet kan tas bort och återställas uttryckligen.
- Ingen parallell mockad produkt eller duplicerad analysskärm finns.

### 2.4 Helskärmen Nytt glidtest

Berör främst:

- `lib/features/glide_testing/create/glide_test_form.dart`
- en fokuserad view-model i samma feature
- `lib/features/ski_management/create/add_ski_form.dart`

Arbete:

- Ersätt `showModalBottomSheet` med en vanlig helskärmsroute.
- Fyll testnamnet med `Glidtest d MMM HH:mm`, men låt det skrivas över.
- Läs alla aktiva icke-exempel-skidor och markera dem från start.
- Visa vald mängd och stöd `Alla`, `Ingen`, `Senaste testet` samt sökning.
- Visa sökning när listan har fler än fyra skidor. Bevara val för filtrerade
  rader.
- Lägg `Lägg till ny skida` i samma skärm. Kräv endast namn, spara i den riktiga
  skidparken, välj skidan automatiskt och gör formuläret redo för nästa skida.
- Lägg anteckningar bakom en hopfälld valfri sektion.
- Kräv minst en vald skida för att skapa testet.
- Efter skapande öppnas testarbetsytan med tom graf och `Nytt åk`.
  Inspelningen startas inte automatiskt.
- Hantera back-navigation och osparade ändringar utan en yta som kan stängas av
  tryck utanför.

Acceptanskriterier:

- Med sex egna skidor krävs en handling för att skapa ett test med alla sex.
- Två till fyra kandidater kan väljas med få tryck.
- Två nya skidor kan skapas efter varandra utan att lämna testformuläret.
- Testet kan inte skapas med noll skidor.
- Namn och urval finns kvar vid sökning och andra lokala omrenderingar.

### 2.5 Testets skidurval vid Nytt åk

Berör främst:

- `lib/features/glide_testing/test_runs/viewModel/run_recorder_view_model.dart`
- `lib/features/glide_testing/test_runs/widgets/start_test_run.dart`

Arbete:

- Byt `watchActiveSkis()` mot `watchSkisForTest(glideTestId)` som primär lista.
- Behåll möjligheten att avvika genom den lågprioriterade handlingen
  `Välj annan skida`.
- Visa övriga aktiva skidor i avvikelseflödet och lägg vald skida till testets
  urval så att valet är begripligt även vid nästa åk.
- Behåll fullskärm, volymknappsnavigering och stora kontroller för kall miljö.

Acceptanskriterier:

- Skidvalet visar normalt bara skidorna som valdes när testet skapades.
- En annan skida kan väljas utan att testet behöver återskapas.
- Exempelskidor kan aldrig väljas i egna åk.
- Volymknappsnavigering fungerar med den filtrerade listan.

### Etapp 2 – verifiering och leveransgräns

Databas och generering:

```text
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test <databas-, widget- och integrationstester för etapp 2>
```

Manuellt på Android-emulator eller telefon:

1. uppgradera en databas från nuvarande schemaversion och öppna gamla test;
2. ren installation med exempeltest men tom egen skidpark;
3. öppna exempeltest utan GPS-behörighet eller aktiv platsikon;
4. skapa första testet och två skidor i samma flöde;
5. återkommande användare med sex skidor och `Senaste testet`;
6. välj en annan skida än kandidaterna när ett nytt åk startas;
7. starta, avbryt och spara åk samt kontrollera GPS-prenumerationens avslut;
8. back-navigation, tangentbord, lång lista och stora systemtypsnitt.

Etappen är klar när hela resan i målbilden fungerar med riktig lokal data och
inga läs-/analysflöden aktiverar GPS.

---

## Rekommenderad genomförandeordning

### Etapp 1

1. Tema och regressionskontroll av befintliga kritiska kontroller.
2. Navigation och benämningar.
3. Testlista, intro och testkort.
4. Skidpark, skiddetalj och skidformulär.
5. Widgettester, analys och manuell visuell granskning.

### Etapp 2

1. Drift-schema, migration och repository-API.
2. GPS-livscykel och platsbehörighet.
3. Importtjänst och riktigt exempeltest.
4. Helskärm för nytt test och snabbskapande av skidor.
5. Testbundet skidurval i inspelningsflödet.
6. Databas-/flödestester, analys och manuell provning.

GPS-gränsen genomförs före exempeltestet visas i produktionen. Då kan exemplet
leverera sitt avsedda värde — analys hemma utan platsbehörighet — från första
gången användaren ser det.
