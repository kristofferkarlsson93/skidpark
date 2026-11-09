# Bygga och köra på iOS

Projektet använder Swift Package Manager för native-pluginer och har iOS 15
som lägsta version. Använd `scripts/flutter_ios.sh` vid iOS-kommandon. Skriptet
sätter `BYPASS_PERMISSION_LOCATION_ALWAYS=1` när geolocators Swift-paket löses
och byggs. Appen använder platsåtkomst medan den är synlig; lägg inte till
bakgrundsplatsåtkomst som en rutinåtgärd.

## Lokal byggmiljö

Installera fullständiga Xcode, välj dess verktyg med `xcode-select` och slutför
första start/licenser. Installera en iOS-runtime om du vill köra simulatorn.
Flutter-/Dart-versioner och den lokala sensorpatchen beskrivs i
[projektets README](../../README.md).

Från projektroten, med Flutter på PATH:

```sh
./scripts/flutter_ios.sh pub get
dart run build_runner build
./scripts/flutter_ios.sh build ios --simulator --debug
./scripts/flutter_ios.sh build ios --release --no-codesign
flutter devices
./scripts/flutter_ios.sh run -d <simulator-eller-iphone-id>
```

Använd wrappern även för `run`. Bygget med `--no-codesign` verifierar
kompilering och paketering men kan inte installeras direkt på en telefon.

## Fysisk iPhone

1. Anslut telefonen, lås upp och välj **Lita på**. Aktivera **Utvecklarläge**
   under Inställningar → Integritet och säkerhet.
2. Lägg till ditt Apple-konto i Xcode → Settings → Accounts. Öppna
   `ios/Runner.xcworkspace`, välj Runner → Signing & Capabilities och ditt
   utvecklingsteam.
3. Kör `flutter devices` och därefter
   `./scripts/flutter_ios.sh run --release -d <iphone-id>` för mätning.
   Följ dialoger om certifikattillit och lokal signering. Förnya
   utvecklingsprofilen när det behövs.

Kontouppgifter, privata nycklar och lokal signeringskonfiguration ska inte
läggas i Git. Lokal installation innebär inte publicering i App Store.

## Styrning och verifiering

I ett eget test används skakning för **Nytt åk**. Vid skidval används en liten,
snabb vänster-/högertippning med återgång för att byta skida och skakning för
att bekräfta. Geststart låser skidvalet och räknar ned två sekunder; manuell
knappstart går direkt. Under inspelning används skärmknappen eller
autosparning för stopp. Tal, haptik och vakenhållning hör till det ordinarie
flödet.

Simulatorn kan verifiera UI, lagring och native-integration, men saknar
rörelsedata för verklig geststyrning och verifierar inte GPS-/sensorprecision.
Kvarvarande enhetskontroller och hantering av inspelningsavbrott finns i
[TODO.md](../../TODO.md). För mätvalidering används det lokala underlaget i
`docs/glide-data-analysis/` när det finns.
