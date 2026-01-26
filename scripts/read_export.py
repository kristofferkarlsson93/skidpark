import json
import base64
import gzip
import sys
import os

def decode_flutter_blob(base64_string):
    """
    Avkodar datan baserat på din Dart-logik:
    Base64 -> GZIP -> UTF-8 JSON -> Objekt
    """
    if not base64_string:
        return []

    try:
        # 1. Avkoda Base64 till komprimerade bytes
        compressed_bytes = base64.b64decode(base64_string)

        # 2. De-komprimera GZIP
        decompressed_bytes = gzip.decompress(compressed_bytes)

        # 3. Avkoda UTF-8 till en JSON-sträng
        json_string = decompressed_bytes.decode('utf-8')

        # 4. Parsa JSON-strängen till en Python-lista
        return json.loads(json_string)

    except Exception as e:
        print(f"Fel vid avkodning: {e}")
        return []

def get_filename():
    """Hämtar filnamn från argument eller input"""
    if len(sys.argv) > 1:
        # Om man kör via terminalen: python read_glidtest.py filnamn.json
        return sys.argv[1]
    else:
        # Annars fråga användaren
        print("--- GlidLabbet Reader ---")
        path = input("Dra filen hit eller skriv sökvägen till json-filen: ").strip()
        # Ta bort citattecken om användaren kopierat sökväg ("C:\Users\...")
        return path.replace('"', '').replace("'", "")

def main():
    filename = get_filename()

    if not os.path.exists(filename):
        print(f"\nFEL: Hittar inte filen: '{filename}'")
        input("\nTryck Enter för att avsluta...")
        return

    try:
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"\nFEL: Kunde inte läsa JSON-filen. Är det rätt format?\n{e}")
        input("\nTryck Enter för att avsluta...")
        return

    print(f"\nLäser in: {data['glideTest']['title']}")
    print(f"Datum:    {data['glideTest']['createdAt']}")
    print(f"Notering: {data['glideTest']['notes'] or 'Inga noteringar'}")
    print("-" * 50)

    for run in data['runs']:
        print(f"\n[ÅK {run['id']}] Skida: {run['skiName']}")
        print(f"Tid: {run['elapsedSeconds']} sek")

        # --- GPS DATA ---
        gps_points = decode_flutter_blob(run['gpsData'])
        print(f"  > GPS: {len(gps_points)} punkter")

        # Visa exempeldata (första och sista punkten)
        if gps_points:
            p_start = gps_points[0]
            p_end = gps_points[-1]
            speed_kmh = p_start.get('speed', 0) * 3.6
            print(f"    Start: Lat {p_start.get('latitude'):.5f}, Fart {speed_kmh:.1f} km/h")
            print(f"    Slut:  Lat {p_end.get('latitude'):.5f}")

        # --- ACCELEROMETER DATA ---
        accel_events = decode_flutter_blob(run['accelerometerData'])
        print(f"  > Accel: {len(accel_events)} events")

    print("\n" + "=" * 50)
    input("Klar! Tryck Enter för att stänga.")

if __name__ == "__main__":
    main()