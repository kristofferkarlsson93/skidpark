# Aktuella produkt- och UX-beslut

Det här är den kanoniska sammanfattningen av SkidParks nuvarande
produktinriktning. Använd den för att slippa återöppna redan fattade beslut i
nya diskussioner. Uppdatera den när ett beslut faktiskt ändras, inte för varje
ny skiss eller tillfällig implementation.

Statusmarkeringar:

- **Beslutat:** bekräftad riktning för kommande implementation.
- **Arbetsantagande:** rimlig utgångspunkt som ännu inte är validerad.
- **Pausat:** medvetet utanför nuvarande fokus.

## Produktens kärna

- **Beslutat:** Glidtestet är huvudaktiviteten. Skidan är det beständiga objektet
  som test och framtida lärande kan knytas till. Skidparken stödjer testningen
  men ska inte dominera produkten.
- **Beslutat:** Produktlöftet är **Bättre underlag för dagens skidval**. Appen
  ska inte påstå att den automatiskt väljer rätt eller bästa skida.
- **Beslutat:** Resultatet ska vara granskningsbart. Användaren tolkar kurvor,
  mätvärden och datakvalitet och gör själv den slutliga bedömningen.
- **Arbetsantagande:** `SkidPark` fungerar som paraplynamn med beskrivningen
  `Glidtester för längdskidåkare`. Namnet är inte domän- eller
  varumärkesvaliderat.

## Informationsarkitektur

- **Beslutat:** Huvudnavigationen är `Tester`, `Skidor`, `Mer`, i den ordningen.
  Appen öppnas på `Tester`.
- **Beslutat:** `GlidLabbet` används inte som konkurrerande produktområde.
- **Beslutat:** Samma test- och analysarbetsyta används hemma, under träning och
  inför tävling. Produkten inför inte separata hemma-/spårlägen.
- **Beslutat:** Ett test har inga obligatoriska faser som förberett, aktivt eller
  avslutat. Användaren kan återvända, lägga till åk och analysera när hen vill.
- **Pausat:** En historiksida för varje skida.

## Verkliga användningssituationer

- **Beslutat:** Test kan förberedas hemma eller i bilen och användas flexibelt i
  spåret.
- **Beslutat:** Appen får inte styra användaren till ett visst växlingsmönster
  mellan åkning och analys. Snabb kontroll och djupanalys ska kunna göras efter
  vilket åk som helst.
- **Arbetsantagande:** En typisk skidpark innehåller omkring sex par och två till
  fyra kandidater väljs ofta inför ett test. Detta bygger på produktägarens egen
  erfarenhet och är inte validerad användarresearch.
- **Arbetsantagande:** Kyla, handskar, rörelse och enhandsanvändning motiverar
  stora tryckytor, tydlig nästa handling och helskärmar för kritiska moment.

## Skidor och preparering

- **Beslutat:** Användarens eget namn, exempelvis `SP1` eller `Atomic Röd`, är
  skidans primära identitet. Märke och modell är sekundärt.
- **Beslutat:** Endast namn krävs när en skida skapas. Övriga uppgifter kan
  läggas till senare.
- **Beslutat:** Valla hör inte hemma som löpande dokumentation på skidans
  detaljvy i det nuvarande flödet. Struktur kan ändras men så sällan att den inte
  prioriteras som historik nu.
- **Pausat:** Strukturerade disciplinetiketter och snabbval som alla stak-,
  klassiska eller skate-skidor.

## Första värde och exempeldata

- **Beslutat:** En ny användare ska kunna utforska ett riktigt exempeltest med
  två exempelskidor och riktiga exempelåk.
- **Beslutat:** Exemplet ska använda samma databasposter, rådata, beräkningar och
  analysskärmar som egna test. Ingen parallell mockprodukt byggs.
- **Beslutat:** Exempelskidor märks tydligt och visas inte i användarens egen
  skidpark eller i urvalet för nya egna test.
- **Arbetsantagande:** Exempeltestet skyddas från nya åk och redigering men låter
  analyskontrollerna vara interaktiva. Detta är en reversibel
  implementationsdetalj, inte ett validerat användarbehov.

## Skapa test

- **Beslutat:** `Nytt glidtest` är en helskärm, inte en bottom sheet eller drawer.
- **Beslutat:** Testnamnet är förifyllt och redigerbart.
- **Beslutat:** Anteckningar finns inte i skapandet. De kan läggas till i
  testinformationen direkt efteråt eller senare, utan ett obligatoriskt steg.
- **Beslutat:** Användaren väljer testets skidor vid skapandet. Alla egna skidor
  är valda från början och undantagen klickas ur.
- **Beslutat:** Snabbvalen är `Alla`, `Ingen` och `Senaste testet`.
- **Beslutat:** Nya skidor kan skapas direkt i testflödet, sparas i den riktiga
  skidparken och väljs automatiskt. Flera kan skapas efter varandra.
- **Beslutat:** När testet har skapats öppnas testarbetsytan utan att inspelning
  startar automatiskt.
- **Beslutat:** Vid `Nytt åk` visas testets valda skidor först, men användaren kan
  medvetet avvika och välja en annan egen skida.
- **Beslutat:** En saknad skida kan snabbskapas från skidvalet för `Nytt åk`.
  Endast namn krävs; skidan sparas i skidparken, läggs till i testets urval och
  väljs utan att åket startas automatiskt. Formuläret expanderas inline under
  skidlistan. Handlingen ingår inte i volymknappsnavigeringen, som pausas medan
  formuläret är öppet.

## Testarbetsytans interaktionskrav

- **Beslutat:** Åkrader och kurvor ska kunna ses i samma vy. Ett tryck på ett åk
  markerar dess kurva och tillhörande värden.
- **Beslutat:** Grafen är central och ska ges stor yta. Kontroller får ligga som
  overlays där de inte skymmer data.
- **Beslutat:** Datakvalitet hör till respektive åk och ska inte duplicera
  åklistan på en separat skärm.
- **Beslutat:** En dedikerad sidomeny är lämplig för flera filter och
  expertinställningar. Åkurval och medelvisning syns när menyn är stängd;
  beräkningssättets etikett visas inte i sammanfattningsraden. Sidomenyn
  innehåller ingen länk till guiden, som nås under `Testet`.
- **Beslutat:** Analysvyer byts med namngivna flikar under grafen, utan
  svepnavigering. Ordningen är `Översikt`, `Släppunkt`, `Testet`. Grafens stora
  yta och placering bevaras; sidomenyn behåller åkurval och beräkning.
- **Beslutat:** Flikrad och urvalssammanfattning skrollar tillsammans med
  nederdelens innehåll för att ge åklistan mer plats. Grafen behåller sina
  60 procent av arbetsytan. Skrolla tillbaka upp i nederdelen för att nå flikarna.
- **Beslutat:** `Testet` visar testnamn och allmänna anteckningar, som kan
  redigeras direkt med `Spara` och `Avbryt`. Guiden ligger under informationen
  och är inledningsvis hopfälld när åk finns. Anteckningar per åk är uppskjutna.
- **Beslutat:** Testinformationen samlar skidurval, anteckningar och guide. Skidurvalet
  visas före anteckningarna. Tomma anteckningar visas som `Lägg till anteckning`,
  utan stor tom textruta. Sparad text visas direkt, med högst tre rader och
  `Visa hela anteckningen`/`Visa mindre` när texten är längre. All text finns kvar
  vid redigering och sparning. Namn och anteckningar redigeras inline.
  Guiden ligger kvar under `Testet`; ingen fjärde flik eller flytt till ⋮ införs.
- **Beslutat:** Före anteckningarna visar `Skidor i testet` ett kompakt urval
  och knappen `Ändra skidor`. Den öppnar en separat vy för enbart skidurvalet,
  med `Alla`, `Ingen` och möjlighet att lägga till skidor som vid testskapande.
  Namn och anteckningar redigeras bara på `Testet`; `Redigera testinfo` tas bort
  ur menyn. Skidurvalet styr förslagen för nya åk. Att välja bort en skida
  raderar eller döljer inte dess tidigare åk, som även ska följa med vid export.
- **Beslutat:** Ett test utan åk visar testinformationen och den utfällda guiden,
  utan flikrad eller tom graf. `Nytt åk` är fortsatt synligt. När åk finns öppnas
  Översikt och `Testet` finns längst till höger.
- **Beslutat:** Guiden ska vara en saklig, kort bruksanvisning. Tre synliga
  steg beskriver samma backe/startplats, inspelning och upprepade åk. Fördjupning
  om analys och plattformens styrning kan fällas ut. Formuleringen är
  `Gör flera åk med varje skidpar`: guiden får inte antyda att ett test är
  begränsat till två skidpar.
- **Beslutat:** `Nytt åk`, skidval och inspelning använder helskärmar som inte kan
  stängas genom ett oavsiktligt tryck utanför.
- **Beslutat:** Att öppna eller analysera ett test ska inte begära
  platsbehörighet eller starta GPS. Det sker först efter `Nytt åk`.
- **Beslutat:** Åknummer är stabila inom testet och ändras inte när ett tidigare
  åk raderas. Numret lagras med åket i stället för att räknas från globala
  databas-id:n eller aktuell listposition.
- **Beslutat:** Testets sparade skidurval är beständigt och följer med vid export,
  även för valda skidor som ännu inte har något åk.
- **Pausat:** En ny visuell layout för själva analysgrafen. Kraven ovan ska
  bevaras när den frågan återupptas.

## Styrning och inspelningsstart

- **Beslutat:** iPhone använder skakning för `Nytt åk`, liten snabb
  vänster-/högertippning med återgång för skidval och skakning för att bekräfta
  och starta efter två sekunders nedräkning. Gestprovet har bedömts tillräckligt
  användbart av produktägaren för inkoppling i ordinarie flöde. Bekräftelsen
  låser skidvalet och gestlyssningen stoppas före nedräkningen. Start avbryts
  vid skärmlås, appbyte, täckande vy eller tillbaka.
  Under inspelningen är iPhone-gester avstängda; stopp sker via befintlig
  skärmknapp eller autosparning. En särskild stoppgest är fortsatt uppskjuten.
  Androids volymknappar använder samma handlingar med bibehållet knappbeteende.
  Manuell knappstart går direkt utan nedräkning. Geststartens nedräkning ska
  visa endast en stor siffra och vald skida på appens mörka bakgrund.
  iPhone-skärmen hålls vaken i synligt skidval och inspelning; normalt
  vilobeteende återställs när rutten lämnas eller appen blir inaktiv.
  Den separata provvyn under `Mer` är borttagen. Styrningen används direkt i
  test- och inspelningsflödet. Kvarvarande enhetskontroller finns i
  [TODO.md](../../TODO.md).
