# iOS: bygg- och teststatus

Uppdaterat 2026-10-22. **Signerad release är installerad och startad på fysisk
iPhone 17.** Användaren bekräftar exempelgraf och inspelning/sparning inomhus.
Telefonen och den delade exporten anger iOS **26.7.1** (23H30); användaren
förbereder uppdatering till iOS 27. Utomhus- och glidvalidering återstår.
Arbetet finns i arbetsytan utan commit.

## Miljö

| Del | Verifierat |
| --- | --- |
| Mac | Apple Silicon, macOS 27.0.1 (26A434). |
| Xcode | 27.1 (27A9275); first launch klart och `xcode-select` pekar på `/Applications/Xcode.app/Contents/Developer`. |
| Flutter / Dart | Stabil Flutter **3.47.7**, Dart **3.13.5**; uppgraderat från 3.47.1 med ren SDK-arbetsyta. |
| Simulator | iOS 27.0 (24A434), separat iPhone 17: **SkidPark iOS Smoke**. iOS 27.1-runtime finns också installerad. |
| Native paket | Alla tio iOS-pluginer byggs med Swift Package Manager; CocoaPods behövdes inte. |
| Telefon / signering | Fysisk iPhone 17, USB/Trust, Utvecklarläge och DDI fungerar. Personal Team, Apple Development-certifikat och telefonmatchande provisioning-profil har skapats. Användaren godkände utvecklarprofilen; appen startar. Profilen gäller till **2026-10-29**. |

Patchuppgraderingen behåller Flutter 3.47-serien och innehåller rättningar för
uppstart med Xcode 27 och debugkrascher på fysisk iOS 27.
[Flutters ändringslogg](https://github.com/flutter/flutter/blob/master/CHANGELOG.md).
Gradle och Android-konfigurationen har inte ändrats.

`flutter doctor -v` hittar Xcode och simulatorn. Det visar fortfarande en
generell CocoaPods-varning trots att båda SwiftPM-byggena lyckas. Androids
befintliga avsaknad av cmdline-tools/licenskontroll är inte åtgärdad här.

## Kod som finns på plats

- iOS 15, UIScene/AppDelegate/SceneDelegate, pluginregistrering och SwiftPM
  enligt aktuell Flutter-mall. Bundle-ID, ikoner och iPhone/iPad-stöd är behållna.
- Svenska plats-/rörelsetexter och tillfällig exakt plats via `GlideRecording`.
  Reducerad precision ger varning och inställningslänk utan inspelningsförbud.
- Explicita GPS-inställningar för förgrundsinspelning på iOS: `fitness`,
  ingen automatisk paus och ingen bakgrundsplatsåtkomst. GPS-fel och ogiltig
  positionsnoggrannhet lämnar inte kvar ett grönt kvalitetsbetyg.
- Android behåller volymhanteringen. iOS använder en stub och befintliga
  skärmknappar; volymtips döljs där stödet saknas.
- Enda paketuppdateringen är `geolocator_apple` 2.3.14 → 2.4.2 för fungerande
  Always-bypass med SwiftPM. `scripts/flutter_ios.sh` sätter
  `BYPASS_PERMISSION_LOCATION_ALWAYS=1` och skickar argumenten vidare till Flutter.

En billigare kodagent (`gpt-6-luna`) har fått avgränsade uppdrag och gjort
bygg-/testverifieringen; huvudagenten har granskat ändringarna och kört
simulatorproven. Efter Xcode-installationen behövdes inga ytterligare
produktionskodändringar. Rådataformat, databasschema, filter, distansmodell
och autosparandets stoppregler är oförändrade.

## Verifiering med Flutter 3.47.7

| Kontroll | Resultat |
| --- | --- |
| `dart run build_runner build` | Godkänd; ignorerade Drift-filer regenererade. |
| `flutter test --no-pub --reporter expanded` | **40 tester passerade**, inklusive skärmstyrd inspelning med volymstub och iOS-behörighets-/GPS-statusfall. |
| `flutter analyze --no-pub` | 0 error, 0 warning, 25 befintliga infoanmärkningar; dessa ger exitkod 1. |
| `./scripts/flutter_ios.sh build ios --simulator --debug` | Godkänd direkt i arbetsytan. App i `build/ios/iphonesimulator/Runner.app`. |
| `./scripts/flutter_ios.sh build ios --release --no-codesign` | Godkänd direkt i arbetsytan, 26,3 MB. `build/ios/iphoneos/Runner.app` är osignerad och kan inte installeras som den är. |
| Signerad release | Godkänd med Xcode, automatisk provisioning och konkret iPhone-destination. `build/ios/Release-iphoneos/Runner.app` passerar `codesign --verify --deep --strict`; profilens team, bundle-ID och telefon matchar. Team-ID användes som kommandoradsinställning, utan projektändring. |
| Installation / start på fysisk iPhone | `devicectl` installerade och startade appen efter användarens profilgodkännande. Processen kvarstår. Användaren bekräftar startskärm och exempelgraf; SQLite-filen finns i appens lagring. |
| Fysiskt inomhusprov / JSON-export | Användaren bekräftar att ett eget åk kan sparas och öppnas. Delad exportformat 3 avkodad: GPS, accel, gyro, barometer och orientering har datapunkter, matchande metadataantal och inga loggade sensorfel. Riktig rörelse/glid är inte provat. |
| Native simulatorstart / SQLite | Godkänd. Exemplet öppnar graf med fyra åk utan platsdialog eller volymtips. Tillbaka, appstopp, omstart och ny öppning fungerar. Schema 7; exemplet har två skidor och fyra åk. |
| Native inspelningsflöde i simulator | Skida och test skapade via UI. Skidval, start, avbryt före start, kasta pågående åk och manuell sparning fungerar utan volymtips. Sparade åk 1 och 2 återlästa efter omstart. Automatstoppsprovet nedan passerar inte. |
| Diff, Bash-syntax, plist/projektformat och scheme-XML | Godkända. |

Första byggförsöken tömde den genererade SwiftPM-listan och gav
`Module 'device_info_plus' not found`. En separat kopia byggde med identiska
källor. Efter användarens `xcode-select`-byte och ny `pub get` byggde även
arbetsytan, och SwiftPM-metadata förblev `ios: true`. Ingen pluginfork eller
manuell ändring i genererade filer behövdes.

Simulatorprovet använder en tillfällig appkopia med separat bundle-ID
`com.krikar.skidpark.skidpark.e2e`; appens vanliga lagring har inte rensats.
Maestro 2.10.0 kör begränsade tillfälliga flödesfiler. Detta är inte en färdig
iOS-E2E-runner enligt IOS-08. `example.yaml` och `manual-save.yaml` passerade.
Inspelningsproven använder Maestros beviljade behörigheter och simulerad GPS;
de verifierar inte iPhones riktiga behörighetsdialoger. Lokala loggar och flöden:

- `/private/tmp/skidpark-ios-workspace-debug-20261022.log`
- `/private/tmp/skidpark-ios-workspace-release-20261022.log`
- `/private/tmp/skidpark-ios-signed-release-iphone-20261022.log`
- `/private/tmp/skidpark-ios-install-20261022.json`
- `/private/tmp/skidpark-ios-launch-20261022.json`
- `/private/tmp/skidpark-test-20261022.log`
- `/private/tmp/skidpark-analyze-20261022.log`
- `/private/tmp/skidpark-flutter-doctor-20261022.log`
- `/private/tmp/skidpark-ios-smoke-20261022/`

Tillfälliga filer kan försvinna vid omstart. Simulatorn verifierar appflöde
och lagring, inte verklig GPS- eller sensorprecision.

**Observerad begränsning:** Maestros simulerade rutt ändrade position men
levererade fart `0.0` i samtliga 40 råa GPS-punkter under ett sex sekunder
långt åk. Befintligt automatstopp sparade därför innan flödet hann trycka
`SPARA`. Åket finns kvar som nummer 1 i SQLite, med bevarad rådata. Det är
ett underkänt prov av hela den automatiserade rutten, inte verifierad
automatstoppfunktion. Simulatorns fartmodell motsvarar inte verklig rörelse;
fyndet visar varför IOS-05/06 och fysisk mätning återstår. Inga stoppregler
eller filter har ändrats för att få simulatorprovet att passera.

Det separata manuella sparprovet skapade ett avsiktligt mycket kort åk 2
utan GPS-punkter och läste tillbaka båda åken efter omstart. Det verifierar
sparning och stabila åknummer, inte att en användbar mätning samlats in.

**Första fysiska exporten:** GPS ligger omkring 1 Hz, rörelsesensorerna omkring
50 Hz och barometern omkring 1 Hz i inomhusprovet. Barometerns källtid och
mottagningstid har en lokal diskrepans på cirka 1,15 s som behöver följas upp.
Rotationens rapporterade noggrannhet är okänd (`-1`). Detaljer finns i den
[lokala, Git-ignorerade analysen](../glide-data-analysis/ios-2026-10-22/REPORT.md).
Inomhusprovet verifierar insamling och export; det ger inte ett mått på
glidprecision eller en generell iOS/Android-jämförelse.

## Kör igen

Från projektroten, med Flutter på PATH:

```sh
./scripts/flutter_ios.sh pub get
dart run build_runner build
./scripts/flutter_ios.sh build ios --simulator --debug
./scripts/flutter_ios.sh build ios --release --no-codesign
flutter devices
./scripts/flutter_ios.sh run -d <simulator-eller-iphone-id>
```

Använd wrappern även för `run` så geolocators Swift-manifest får rätt flagga.

## Installera på fysisk iPhone

1. Anslut med USB, lås upp och välj **Lita på**. Aktivera **Utvecklarläge**
   under Inställningar → Integritet och säkerhet; telefonen kan behöva startas om.
2. Lägg till ditt Apple-konto i Xcode → Settings → Accounts. Öppna
   `ios/Runner.xcworkspace`, välj Runner-target → Signing & Capabilities och
   ditt Personal Team. Gratis konto räcker för lokal testning.
3. Kör `flutter devices` och därefter
   `./scripts/flutter_ios.sh run -d <iphone-id>`. Följ eventuella dialoger för
   certifikattillit på telefonen och nyckelring på Macen.
4. Vid faktisk mätning, kör en signerad release via
   `./scripts/flutter_ios.sh run --release -d <iphone-id>` och behåll appen
   synlig med skärmen på tills avbrottshanteringen nedan är verifierad.

Den installerade utvecklingsprofilen löper ut **29 oktober 2026**. Förnya
utvecklingsinstallationen från Macen då. Signeringen och nycklarna är lokala;
team-ID har inte lagts till i projektfilen. Ingen App Store-uppladdning är gjord.

Kontouppgifter, privata nycklar och lokal signeringskonfiguration ska inte
läggas i Git. Ingen App Store-publicering eller köpt medlemskap krävs här.
[Flutter: fysisk iOS-enhet](https://docs.flutter.dev/platform-integration/ios/setup),
[Apple: kontotyper](https://developer.apple.com/help/account/basics/about-your-developer-account).

## Kvar före påståenden om tillförlitlig iOS-inspelning

- **IOS-00/01:** Grundbygge, signering, installation och uppstart är verifierade
  på iOS 26.7.1. Upprepa snabbprovet efter telefonens uppdatering till iOS 27.
- **IOS-02/03:** Första insamling/sparning är provad på telefon. Nekade och
  reducerade behörigheter, upprepade åk, avbryt/tillbaka samt normal systemvolym
  behöver provas fysiskt. Androids fysiska volymknappsregression återstår.
- **IOS-04:** Skärmlås, bakgrund och avbrott saknar färdig hantering.
  Osparad data ligger i minnet. Ingen bakgrundsinspelning har införts.
- **IOS-05/06:** Verifiera koordinater, tidsbaser och ursprung per åk.
  Pluginets `0/0` för ogiltig fart kan fortfarande påverka trimning/autosparande.
  Stoppreglerna är fortfarande beroende av antalet GPS-punkter.
- **IOS-07:** Delning till Filer/iCloud, debugimport, iPad och fler lagringsflöden.
- **IOS-08/09:** Reproducerbar iOS-E2E, verkliga sensorprov och upprepade A–A-åk.
- **IOS-10:** Distribution är inte påbörjad eller beställd.

Följ [genomförandeplanen](IMPLEMENTATION_PLAN.md). Rapportera iPhone-fynd
innan filter eller mätmodell ändras.
