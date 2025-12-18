# Projekt: SkidPark (Virtual Glide Tester)

**Version:** 1.1
**Datum:** 2024-12-18
**Fokus:** Android (Flutter)

## 1. Problemformulering & Bakgrund

### Den Gyllene Standarden (2 Personer)

Att testa glid på längdskidor görs optimalt av två personer.

1. Båda åkarna startar i bredd i en backe.
2. Man håller varandra i handen (eller en stav) för att utjämna hastigheten.
3. På en given signal släpper man taget.
4. Den skida som glider ifrån den andra har lägre friktion och vinner testet.
   Denna metod är överlägsen då den eliminerar yttre variabler i realtid.

### Problemet (Ensamtestaren)

Många vallare och åkare testar ensamma. Trots att man ofta drar ett streck i snön för att starta på samma ställe, uppstår utmaningar:

* **Mikro-variationer:** Även från samma startlinje kan små skillnader i utgångshastighet eller kroppsposition påverka slutresultatet.
* **Subjektivitet:** "Känslan" är svår att kvantifiera och minnas över tid.
* **Trubbig data:** Att bara mäta "hur långt man kom" är ibland missvisande. En skida kan kännas trög men glida långt, eller tvärtom.

## 2. Lösning: Den Virtuella Referensåkaren

Appen ska fungera som den andra personen. Den ska skapa en objektiv sanning ur subjektiva förutsättningar genom avancerad dataanalys.

### Kärnfunktionalitet

1. **Datainsamling:** Spela in GPS-position och Accelerometer-data (G-krafter) högfrekvent.
2. **Absolut Analys:** Visa traditionell statistik (Maxhastighet, Medelhastighet, Total distans).
3. **Relativ Analys (The "Killer Feature"):**
* Möjlighet att jämföra **flera** skidpar eller åk samtidigt.
* Genom att **normalisera** kurvorna simulerar appen ett lopp där alla skidor startar vid exakt samma punkt (t.ex. vid maxfart) med samma hastighet.
* Resultatet visar vilken skida som **bevarar hastigheten bäst** (minst inbromsning/retardation).



## 3. Teknisk Arkitektur & Design

### Tech Stack

* **Framework:** Flutter (Dart).
* **Database:** Drift (SQLite) för lokal lagring av tunga dataset.
* **State Management:** Provider / ChangeNotifier (MVVM).
* **Sensorer:** `geolocator` (GPS) & `sensors_plus` (Accelerometer).

### Designmönster & Principer

* **MVVM (Model-View-ViewModel):** Tydlig separation mellan UI och logik.
* **Clean Code:** Variabelnamn ska vara beskrivande (engelska). Undvik kryptiska matematiska förkortningar.
* **Graceful Degradation:** Appen ska fungera med enbart GPS, men ge bättre resultat med Sensor Fusion aktiverat.

### Algoritmer & Logik

#### A. Sensor Fusion (Kalman Filter)

För att motverka GPS:ens låga uppdateringsfrekvens (1Hz) och "hackighet" används ett 1-dimensionellt Kalmanfilter.

* **Input:** GPS-hastighet (Observation) + Accelerometer Y-axel (Prediktion).
* **Logik:** NyFart = GammalFart + (Acceleration \times Tid).
* **Gatekeeper:** Accelerometerdata ignoreras om GPS-farten är **< 0.8 m/s (ca 3 km/h)**. Detta filtrerar bort de kraftiga G-krafter som uppstår när användaren hanterar telefonen vid start och stopp.

#### B. Auto-Alignment (Synkronisering)

För att jämföra åk i en graf måste de synkroniseras i tid och rum.

* **Metod:** Hitta index för **Maxhastighet** i varje åk. Eller låt användaren välja vid vilken meter vi börjar.
* **Action:** Förskjut (Offset) åkens distans-axel så att alla "toppar" hamnar på Distans = 0.

## 4. Användarflöde (UX)

### Inspelning

1. Användaren startar inspelning.
2. Lägger telefonen på skidan/benet (Krav: Skärm uppåt, topp framåt).
3. Åker teststräckan.
4. Stoppar inspelning (eller Auto-stop).
5. Datan sparas rå (GPS + Accel Events) i databasen.

### Analysvy

1. Användaren väljer ett "Test" (gruppering av åk).
2. Väljer vilka åk som ska jämföras (1 till N stycken).
3. **Sensor Fusion Toggle:** Användaren kan slå av/på fusionsfiltret för att se skillnad på rådata och processad data. Inställningen sparas per testtillfälle.
4. Grafen ritar upp kurvor där man tydligt ser skillnader i glid/retardation.

## 5. Datamodeller (Viktiga Entiteter)

* `TestRun`: Ett enskilt åk. Innehåller Blobbar av komprimerad GPS- och Accel-data.
* `StoredGlideTestData`: "Paraplyet" för en testsession. Innehåller inställningar som `useSensorFusion`.
* `CalculatedPosition`: En processad datapunkt som används i graferna (innehåller filtrerad `speed` och `distance`).

---

# Context Prompt (Uppdaterad)

*Kopiera texten nedan och klistra in i början av en ny chatt.*

---

**CONTEXT & PROJECT ROLE:**
Du agerar som en Senior Flutter Developer och Product Owner för projektet "SkidPark". Det är en app för glidtestning av längdskidor.

**MÅL:**
Att hjälpa ensamma vallare att objektivt jämföra flera skidpar/åk genom att använda Sensor Fusion (GPS + Accelerometer) för att mäta hastighetsförlust (retardation) snarare än bara total distans.

**TEKNISK STATUS:**

1. **Stack:** Flutter, Drift (DB), Provider.
2. **Sensor Fusion:** Vi har implementerat ett Kalmanfilter som kombinerar GPS (1Hz) med Accelerometer (högfrekvent).
3. **Gatekeeper:** Vi har en logik (`_triggerSpeedMs = 0.8`) som ignorerar accelerometerdata under ca 3 km/h för att slippa hanteringsbrus vid start.
4. **MVVM:** Vi har flyttat logik från UI till ViewModel (`CompareRunsViewModel`) för att hantera inställningar och datahämtning robust.
5. **UI:** Dark mode, Material 3. Vi har nyligen implementerat en snygg toggle för Sensor Fusion med tydliga instruktioner i en dialogruta.

**AKTUELLT FOKUS:**
Vi arbetar med **Analysvyn**. Nästa steg är att implementera logik för att jämföra flera åk samtidigt. Detta inkluderar "Auto-Alignment" (synkronisera kurvor vid maxfart) och potentiellt en "Medelvärdes-vy" (snitt av flera åk).

**Svara alltid:**

* Kort och koncist.
* Med fokus på läsbar kod och bra namngivning.
* På svenska.
