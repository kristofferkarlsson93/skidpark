# Klickbar mockup: startflöde och skidpark

Öppna [index.html](index.html) direkt i en webbläsare. Prototypen är fristående
och använder inga externa resurser.

Det här är ett konkret förslag, inte en samling alternativa frames. Telefonen
visar en skärm i taget. Panelen bredvid telefonen låter dig växla mellan två
datatillstånd: **Första start** och **Med egen data**.

## Flöden att prova

### Första start

1. Öppna **Exempeltest: fyra glidåk** och markera olika åk.
2. Gå tillbaka och välj **Skapa mitt första test**.
3. Lägg till två skidor direkt i testet. Skidorna sparas och väljs automatiskt.
4. Skapa testet och se den tomma testarbetsytan.
5. Öppna **Skidor** i bottennavigeringen och kontrollera att exempelskidorna
   inte ligger i den egna skidparken.

### Återkommande användare

1. Välj **Med egen data** i panelen.
2. Skapa ett nytt test. Alla sex egna skidor är valda från start.
3. Prova **Ingen**, **Alla**, **Senaste testet**, sökning och manuellt urval.
4. Öppna **Skidor** och jämför den kompakta listan med dagens stora
   tvåkolumnskort.

## Designriktning

- **Tester** är första fliken. `SkidPark` är produktnamnet; `GlidLabbet` tas bort
  som konkurrerande områdesnamn.
- Första starten förklarar nyttan med löftet **Bättre underlag för dagens
  skidval** och låter användaren öppna ett riktigt exempeltest direkt.
- Exempeltestet och dess två exempelskidor är riktiga databasposter med riktig
  rådata, men markeras som exempel. De ska inte visas i den egna skidparken
  eller i urvalet för nya test.
- Ett nytt test skapas i en helskärm. Namnet är förifyllt och redigerbart. Alla
  egna skidor är valda från början; undantagen klickas ur.
- Snabbvalen är **Alla**, **Ingen** och **Senaste testet**. Disciplinfilter
  avvaktas eftersom dagens skidmodell saknar strukturerad disciplin och sex par
  normalt är hanterbart.
- En ny skida kan skapas direkt i testflödet. Endast eget namn krävs. Formuläret
  stannar öppet så att flera skidpar kan läggas till efter varandra.
- Skidparken använder en enkolumnslista. Eget namn är primärt, märke/modell är
  sekundärt och teknisk data ligger på detaljsidan. Det ger ungefär dubbelt så
  hög informationsdensitet som dagens kortgalleri.
- Tappbara objekt får kort med tunn ram, 16 px radie och utan tung skugga.
  Primärknappar är fyllda, sekundärknappar har kontur och textlänkar används
  bara för lågprioriterade val. Minsta tryckyta är 44 px, normalt 50 px.
- Test har inga faser som `Förberett`, `Aktivt` eller `Avslutat`. Kort visar
  konkreta fakta: datum, antal skidor och antal åk.

## Medveten avgränsning

Analysvyn är inte omdesignad här. Mockupen visar endast gränsytan där
startflödet landar. Kraven på en stor graf, kopplingen mellan åkrad och kurva
samt den dedikerade sidomenyn finns bevarade i den kanoniska
[produktbeslutsfilen](../PRODUCT_DECISIONS.md). Den äldre analysmockupen har
tagits bort eftersom dess layout inte var godkänd.

Skidhistorik, disciplinetiketter, testarkivering, tidsvarningar mellan åk och
förändringar av mätmodellen är också avgränsade. Den konkreta ordningen för
implementation finns i [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

Implementation är indelad i två etapper. **Etapp 1** inför appskal, tema,
testlista och skidpark. **Etapp 2** kopplar på riktigt exempeltest,
GPS-livscykel, helskärmen för nytt test och testets skidurval. Prototypen visar
det samlade sluttillståndet efter båda etapperna.
