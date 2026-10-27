# Tre klickbara förslag: testarbetsytan

Öppna [index.html](index.html) direkt i webbläsaren. Alla resurser är lokala;
ingen installation, server eller anslutning behövs. En
[privat Sites-version](https://skidpark-analysis-ux-oct27.openalder9.chatgpt.site)
finns också för att kunna provas på telefon. Sites-projekt:
`appgprj_6ae07965988081919cbde6b38601a9d0`.

Detta är tre alternativ att jämföra, inte en beslutad ny design. Appens
Flutter-filer och tidigare produktbeslut ändras inte.

## Förslagen

| | Funktionell förändring | Tomt test | Främsta avvägning |
| --- | --- | --- | --- |
| A – Synliga flikar | Namngivna flikar under grafen ersätter högerkantens vyknappar. | Grafytan får en startpunkt, valda skidor och Nytt åk. Utfällbara tips under. | Direkt överblick; många flikar kräver horisontell rullning. |
| B – Svepsidor | Guide → Översikt → Släppunkt, med svep enbart i nederdelen och pilar som alternativ. | Öppnar på guiden. Med åk öppnas Översikt. | Mer utrymme; svepytan behöver upptäckas och fler sidor ger fler svep. |
| C – Samlad vyväljare | En kompakt vyknapp öppnar en meny med analysnamn och förklaringar. Urval har egen knapp under grafen. | Sammanfattar testet och erbjuder inspelning eller guide. | Skalar bäst till många vyer; vybyte kostar två tryck. |

Prova gärna A som referens för tydlighet och C för framtida utbyggnad. B testar
uttryckligen hypotesen att nederdelen är en tillräcklig och begriplig svepyta.
Inget alternativ inför obligatoriska testfaser eller en guide före varje analys.

## Gemensamt och avgränsat

- Analysgrafen ligger kvar överst och får 60 procent av arbetsytan, enligt
  befintlig `Expanded(flex: 3)` / `Expanded(flex: 2)`. Appfältet är en overlay.
  Inget nytt sidhuvud eller global bottennavigation läggs ovanför/under grafen.
- Den tomma grafen ersätts av relevant innehåll. På guidesidan används samma
  övre yta för instruktioner; analysvyerna behåller grafen.
- Tryck på en åkrad markerar kurvan. Dra i grafen för avläsning. SP2 är också
  streckad för att inte förlita skididentiteten enbart på färg.
- Sidopanelen har samma ansvar i alla alternativ: åkurval, medel per skida och
  GPS + sensorer. Val följer med vid vybyte och ändras direkt. Stängknappen
  bekräftar inte ett separat sparsteg.
- Urval, medelvisning och beräkningssätt syns när panelen stängs. Ett tomt urval
  får en egen återställning: åken är dolda, inte borta.
- Datakvalitet visas vid respektive åk. Varningar hålls synliga även i
  släppunktsresultat. Ingen vinnare utses.
- Guiden är alltid åtkomlig. Volyminstruktionerna gäller Android, enligt
  aktuell plattformsgren i `lib/main.dart`; iPhone hänvisas till skärmknappar.
- `Nytt åk` visar endast en förenklad helskärmssekvens. Ingen GPS, inspelning,
  behörighetsbegäran eller datalagring sker. Återgång efter demosparning visar
  samma fyra exempelåk, inte en ny faktisk post.
- Alla kurvor och värden är fiktiva. Medelvisning illustrerar gruppering,
  reglaget flyttar en linje och beräkningsvalet ändrar etiketten. Inga filter,
  mätmodeller eller släppunktsberäkningar implementeras eller valideras.
- Helskärmsknappen illustrerar en större graf inom telefonramen. Den verkliga
  appens landskapsläge, OS-gester och hårdvaruknappar ingår inte.
- Testlista och testinformation är navigationsankare. Redigering, export och
  radering omdesignas inte.

## Prova

Välj **Utan åk** / **Med 4 åk** utanför telefonen. Byt mellan A, B och C.
Återställ återgår till alternativets startvy och standardval.

1. Öppna tipsen i ett tomt test. Går det att förstå hur man kommer igång?
2. Visa fyra åk, markera en åkrad och dra över grafen.
3. Dölj ett åk i sidopanelen. Byt analysvy och kontrollera att urvalet följer med.
4. Prova medel per skida och GPS-valet. Syns de aktiva valen utanför panelen?
5. Dölj alla åk och hitta tillbaka till kurvorna.
6. I B: svep i åklistan, dra i grafen och dra i släppunktsreglaget. Bara första
   gesten ska byta sida. Lodrät listskroll ska fortsätta fungera.
7. I C: öppna vyväljaren och jämför om namnen och förklaringarna hjälper.

Direktlänkar fungerar med `#a/empty`, `#b/empty`, `#c/empty` och motsvarande
`/runs`. Valen är tillfälliga och återställs vid omladdning.

## Underlag och verifiering

Granskade aktuell jämförelseskärm, översikts- och släppunktsvyer, graf,
sidopanel, inspelningsnavigation, plattformsstöd för volymknappar och
`PRODUCT_DECISIONS.md`. Granskade också den lokala skärmbilden
`/private/tmp/skidpark-contrast-current.png` från 26 oktober. Ingen ny visuell
genomgång av en körande Flutter-app gjordes.

Inspiration: [Stravas aktivitetsanalys](https://support.strava.com/en-us/articles/15401943/viewing-activities)
för vägen från överblick till mer analys och
[Garmins aktivitetsytor](https://support.garmin.com/en-IE/?faq=Kc8agkXjSE7khwFFdZQuV6)
för åtskillnad mellan datasidor och interaktionsytor. Detta är designinspiration,
inte användarvalidering för SkidPark.

Prototyperna kontrollerades i Chrome med riktiga klick, drag, emulerade
pekgester och skärmbilder. Kontrollerna omfattade vybyte, grafavläsning, markering, gemensamt
urval, tomt urval, medelvisning, synliga beräkningsval, släppunktsreglage,
guide, helskärm, återgång och mobilbredderna 375 och 390 px. Inga
JavaScript-undantag uppstod. Privat publicering bekräftades av Sites.
Fysisk telefon, Safari och
fältanvändning behöver fortfarande provas innan någon lösning implementeras.
