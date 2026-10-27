# iOS: förutsättningar och mätrisker

Ursprunglig utredning 2026-10-22. Implementation har därefter påbörjats;
[aktuell status och nästa steg](STATUS.md) beskriver vad som
nu har ändrats och verifierats. Fynden nedan beskriver utgångsläget.
Detaljerade uppdrag finns i [genomförandeplanen](IMPLEMENTATION_PLAN.md).

**Bedömning:** Större delen av Flutter-koden bör kunna återanvändas. Ett äldre
iOS-projekt och iOS-grenar för GPS, sensorer och enhetsinfo finns redan.
Störst arbete gäller byggmiljö, knappstyrning och verifiering på riktig iPhone.

## Dator och bygge

| Kontrollerat lokalt | Vad som behövs |
| --- | --- |
| Apple Silicon, macOS 26.5.1, Flutter 3.47.1 / Dart 3.13.1 | Behåll initialt SDK och `pubspec.lock`. |
| Command Line Tools är valt; ingen fullständig Xcode hittades i standardmapparna | Installera Xcode, välj verktygen och slutför första start/licenser. Låsta `device_info_plus` kräver Xcode ≥26.1.1. |
| `xcrun simctl` fungerar inte | Installera iOS-runtime via Xcode. Simulatorn följer med Xcode. |
| `pod` saknas på PATH och vanliga installationsplatser | Använd Swift Package Manager i första hand; CocoaPods vid konstaterat behov. |
| Telefon/signering har inte verifierats | Apple-konto, signering och Developer Mode behövs. Egen enhet kan testas med gratis Personal Team; TestFlight/App Store kräver medlemskap. |

Källor: [Flutter: iOS-miljö](https://docs.flutter.dev/platform-integration/ios/setup),
[paketets Xcode-krav](https://pub.dev/packages/device_info_plus/versions/13.2.0),
[Apples kontotyper](https://developer.apple.com/help/account/basics/about-your-developer-account).

Projektet anger iOS 13; **Flutter 3.47 stöder lägst iOS 15**. Migrera även
AppDelegate/Info.plist till UIScene och aktuell pluginregistrering. Native
beroenden saknar färdig projektintegration. SwiftPM är numera standard, så
avsaknad av Podfile betyder inte automatiskt att den måste skapas.
[Plattformsstöd](https://docs.flutter.dev/reference/supported-platforms),
[UIScene-migrering](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate),
[SwiftPM](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).

## Beroenden och behörigheter

De låsta versionerna har granskats; ingen generell uppgradering är motiverad.

| Område | Befintligt stöd och återstående arbete |
| --- | --- |
| `geolocator` 14.0.3 / Apple 2.3.14 | Platsnyckeln finns, med engelsk standardtext. Behöver svensk beskrivning samt hantering av nekad, tillfällig och ungefärlig platsåtkomst. Granska Always-bypass för exakt pluginversion/byggväg; nyare SwiftPM-instruktioner kan inte kopieras direkt. |
| `sensors_plus` 7.1.0 | Rörelsenyckeln finns, på engelska. Verifiera nekad åtkomst, saknade sensorer och samtidiga strömmar. Behörigheten behövs särskilt för barometern. |
| `flutter_rotation_sensor` 0.4.0 | iOS-stöd finns. Verifiera koordinater, tecken och tidsbas. |
| Volymknappar | MethodChannel finns endast i Android. Se begränsningen nedan. |
| Drift/SQLite, filer, delning, länkar och grafik | iOS-stöd finns. Prova lagring, exempeldata, Filer/iCloud i befintlig debugimport, export och UI. Projektet deklarerar iPhone **och** iPad. |

Underlag: [Geolocator](https://pub.dev/packages/geolocator),
[Sensors Plus 7.1.0](https://pub.dev/packages/sensors_plus/versions/7.1.0),
[rotationspaketet](https://pub.dev/packages/flutter_rotation_sensor/versions/0.4.0),
samt lokal paketkällkod. Kärnflödet behöver ingen kamera-, mikrofon- eller
fotobehörighet. Bakgrundsplatsåtkomst är inte konfigurerad och bör inte läggas
till som rutin.

**Volymnavigation kan inte utlovas på iOS.** Apples `AVCaptureEventInteraction`
är begränsat till aktiv kameraanvändning. App Review 2.5.9 förbjuder ändrad
standardknappsfunktion. Observerad ljudvolym ger inte tillförlitliga nedtryck,
uppsläpp och långtryck. Rekommendationen är befintliga skärmknappar och
plattformskapacitet som döljer felaktiga volymtips. Det avsteget behöver
godkännas före implementation; ett privat experiment är separat.
[Apple: knapp-API](https://developer.apple.com/documentation/avkit/avcaptureeventinteraction),
[App Review 2.5.9](https://developer.apple.com/app-store/review/guidelines/#software-requirements).

## Vad kan ändra beteende eller tillförlitlighet?

1. **GPS-frekvens.** Android begär 5 Hz men tidigare exporter ligger omkring
   1 Hz. iOS-inställningen anger inget tidsintervall. Hög begärd noggrannhet
   garanterar ingen frekvens: om iPhone är snabbare/långsammare måste mätas,
   tillsammans med luckor, ålder och leveransfördröjning.
   [Core Location-konfiguration](https://developer.apple.com/documentation/corelocation/getting-the-current-location-of-a-device).
2. **Frekvensberoende regler.** Autosparandets gräns på 20 GPS-punkter blir
   ungefär 20 sekunder vid 1 Hz och fyra vid 5 Hz. Även trimningens tre extra
   punkter och lågpassfiltrets fasta `alpha = 0.1` påverkas av frekvens.
   Sparbeteende och kurva kan därför skilja trots samma rörelse.
3. **GPS-giltighet.** Låsta Apple-pluginet utelämnar ogiltig fart/fartnoggrannhet;
   Dart ersätter med `0`. Autosparande och trimning kan tolka bortfall som
   stopp, även om Kalmanfiltret har ett skydd för `0/0`. Negativ
   positionsnoggrannhet kan dessutom få bästa UI-betyget. Reducerad
   precisionsbehörighet begränsar mätningen oavsett önskad noggrannhet.
   [Fartnoggrannhet](https://developer.apple.com/documentation/corelocation/cllocation/speedaccuracy),
   [precisionsbehörighet](https://developer.apple.com/documentation/corelocation/cllocationmanager/accuracyauthorization).
4. **Sensorsemantik.** Begärda 50 Hz för rörelsesensorerna måste verifieras.
   iOS gravitationsborttagning kan ge annat brus/fördröjning. Pluginen
   konverterar redan till m/s² och hPa; dubbelkonvertera inte. iOS-barometerns
   frekvens är inte styrbar här och rotationsnoggrannheten är okänd (`-1`).
   Gyro/orientering påverkar ännu inte produktionskodens hastighetsfusion.
   [Apple: faktisk sensorfrekvens](https://developer.apple.com/documentation/coremotion/cmmotionmanager/devicemotionupdateinterval).
5. **Tid och ursprung.** GPS, sensors_plus och orientering har olika tidsbaser.
   Kontrollera omräkning och koordinater. Enhetsinfo hämtas vid **export**, så
   importerade Android-åk kan få iPhones exportörsinfo. Inspelningsplattform,
   konkret modell och inställningar bör lagras per åk och följa import/export.
6. **Skärmlås/avbrott.** Explicit livscykelhantering och vakenhållning saknas.
   Osparad data ligger i minnet. GPS och rörelsedata kan inte antas fortsätta
   tillsammans när iOS pausar appen; bakgrunds-GPS löser inte hela problemet.

**Verifiering på enhet krävs:** kort sensorprov och upprepade A–A-åk med normalt
handgrepp. Bedöm hela hastighetsförloppet och variationen; jämnare kurvor eller
rätt slutdistans bevisar inte bättre noggrannhet. Jämför initialt skidor med
samma telefon. Simulatorn verifierar bygge/UI, inte verklig mätprecision.

## Beslut före genomförande

- Skärmstyrning på iOS eller separat privat knappexperiment.
- Avbrottspolicy: rekommenderat synlig app, bevarad delmätning och tydlig
  avbrottsinformation. Inspelning under lås/bakgrund är en egen utökning.
- iOS 15, fortsatt iPad-stöd och lokal testning kontra senare distribution.

## Hur utredningen verifierades

Kodens inspelning, lagring, import/export, analys och knappkanal har granskats,
liksom låsta pakets native källkod och lokal mätanalys. Miljön kontrollerades
med verktygs-/versionskommandon och reglerna mot officiella källor ovan.
Inget iOS-bygge, enhetstest eller installation har körts.
