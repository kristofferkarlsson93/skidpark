# Mockup: testvy med flikar och guide

Öppna [index.html](index.html) direkt i webbläsaren, eller använd den
[privata webbversionen](https://skidpark-analysis-ux-oct27.openalder9.chatgpt.site).
Lokala versionen behöver ingen server, installation eller internetanslutning.
Sites-projekt: `appgprj_6ae07965988081919cbde6b38601a9d0`.

Detta är den aktuella mockupen för testarbetsytan. Den ersätter de tre
alternativen A/B/C efter att användaren valt fliknavigation. Det är ett
granskningsunderlag för layout och ordalydelse; Flutter-appen ändras inte.
Beslutad riktning finns i [produktbesluten](../PRODUCT_DECISIONS.md).

## Navigation och tillstånd

- **Utan åk:** bara guiden, med synligt `Nytt åk`. Ingen tom graf, sidopanel
  eller ensam flikrad. Allt guideinnehåll går att rulla som en sammanhängande sida.
- **Med åk:** öppnar på Översikt. Flikarna är `Översikt`, `Släppunkt`, `Guide`.
  Tryck och tangentbordspilar byter vy. Ingen svepnavigering finns.
- **Guide med åk:** samma instruktioner och hjälptexter. Flikarna ligger kvar
  på samma höjd som i analysvyerna. Instruktioner ovanför och utfällbar hjälp
  nedanför flikarna kan rullas var för sig om innehållet inte ryms.
- **Alla åk dolda:** återställningshjälp för urvalet. Det är fortfarande ett
  test med åk och flikarna ligger kvar.
- **Sidopanelen:** åkurval, medel per skida och GPS + sensorer. Valen följer
  med mellan vyer. Länken till hjälp öppnar Guide-fliken, inte en extra hjälpvy.

Analysvyerna behåller grafens placering och höjd: 60 procent graf och 40 procent
nederdel, med appfältet som overlay. Grafavläsning och släppunktsreglaget har
egna gester.

## Textförslagen

Tre synliga steg beskriver samma backe/startplats, inspelning utan stakning
och upprepade åk med varje skidpar, oavsett antal skidpar. Därefter två utfällbara avsnitt:

- **Jämför åken:** Översikt, åkurval, simulerad släppunkt, variation och
  datakvalitet. Släppunkt beskrivs som en beräknad jämförelse, enligt den lokala
  dataanalysens förtydligande om den befintliga modellen.
- **Volymknappar på Android:** långtryck ner i testet; kort upp/ner samt
  långtryck ner i skidvalet; kort ner under inspelning. iPhone hänvisas till
  skärmknappar, enligt aktuell plattformsgren i `lib/main.dart`.

Guiden använder sakliga instruktioner och samma text med och utan åk.
Utvikta avsnitt behålls vid vybyte. Exakt ordalydelse är fortfarande ett förslag.

## Prova

1. Börja med **Utan åk**. Läs stegen och öppna båda hjälpavsnitten.
2. Välj **Med 4 åk**. Byt mellan samtliga flikar och kontrollera samma guide.
3. Dölj ett åk via reglageknappen. Byt vy och kontrollera att urvalet följer med.
4. Markera en åkrad och dra i grafen. Flytta reglaget i Släppunkt.
5. Dölj alla åk och återställ urvalet.

Direktlänkar: `#empty`, `#runs/overview`, `#runs/release`, `#runs/guide`.
Äldre länkar som `#a/runs` leder till den valda riktningen.
**Återställ** återgår till startvyn och stänger hjälpens utvikta avsnitt.

## Avgränsning och verifiering

Kurvor och analysvärden är fiktiva. Medelvisning illustrerar gruppering;
beräkningsvalet ändrar etiketten men gör ingen omräkning. Nytt åk visar en
förenklad skärmsekvens och återgår till fyra exempelåk efter demosparning.
Ingen GPS, sensordata, datalagring eller faktisk analys ingår. Export,
redigering och radering omdesignas inte. Helskärm illustreras inom telefonramen.

Verifierat i Chrome med klick, tangentbord, emulerade pekgester och granskade
skärmbilder. Kontrollerna omfattade guide med/utan åk, textutfällning och
rullning, flikordning, bevarad grafyta, urval över vybyten, tomt urval,
grafavläsning, reglage, återgång från Nytt åk och bredderna 375 och 390 px.
Inga JavaScript-undantag uppstod. Fysisk telefon och Safari återstår.
