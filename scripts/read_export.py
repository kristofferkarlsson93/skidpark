import json
import base64
import gzip
import sys
import os
import math


def pause_if_interactive(message):
    if len(sys.argv) == 1:
        input(message)


def decode_flutter_blob(value):
    """
    Avkodar datan baserat på din Dart-logik:
    Base64 -> GZIP -> UTF-8 JSON -> Objekt
    """
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if not isinstance(value, str) or not value:
        return []

    try:
        # 1. Avkoda Base64 till komprimerade bytes
        compressed_bytes = base64.b64decode(value)

        # 2. De-komprimera GZIP
        decompressed_bytes = gzip.decompress(compressed_bytes)

        # 3. Avkoda UTF-8 till en JSON-sträng
        json_string = decompressed_bytes.decode('utf-8')

        # 4. Parsa JSON-strängen till en Python-lista
        return json.loads(json_string)

    except Exception as e:
        print(f"Fel vid avkodning: {e}")
        return []


def print_stream_summary(
    label,
    samples,
    elapsed_key='elapsedMicroseconds',
):
    print(f"  > {label}: {len(samples)} events")
    elapsed = [
        sample.get(elapsed_key)
        for sample in samples
        if isinstance(sample, dict)
        and isinstance(sample.get(elapsed_key), (int, float))
    ]
    if len(elapsed) >= 2:
        duration_seconds = (max(elapsed) - min(elapsed)) / 1_000_000
        frequency = (
            (len(elapsed) - 1) / duration_seconds
            if duration_seconds > 0
            else 0
        )
        print(
            f"    Tidsintervall: {duration_seconds:.2f} s, "
            f"cirka {frequency:.1f} Hz"
        )


def print_rotation_diagnostics(samples):
    norms = []
    for sample in samples:
        if not isinstance(sample, dict):
            continue
        components = [sample.get(key) for key in ('x', 'y', 'z', 'w')]
        if all(isinstance(value, (int, float)) for value in components):
            norms.append(math.sqrt(sum(value * value for value in components)))
    if norms:
        max_deviation = max(abs(norm - 1.0) for norm in norms)
        print(f"    Största quaternion-avvikelse från 1: {max_deviation:.6f}")


def get_filename():
    """Hämtar filnamn från argument eller input"""
    if len(sys.argv) > 1:
        # Om man kör via terminalen: python read_glidtest.py filnamn.json
        return sys.argv[1]
    else:
        # Annars fråga användaren
        print("--- GlidLabbet Reader ---")
        path = input(
            "Dra filen hit eller skriv sökvägen till json-filen: "
        ).strip()
        # Ta bort citattecken om användaren kopierat sökväg ("C:\Users\...")
        return path.replace('"', '').replace("'", "")


def main():
    filename = get_filename()

    if not os.path.exists(filename):
        print(f"\nFEL: Hittar inte filen: '{filename}'")
        pause_if_interactive("\nTryck Enter för att avsluta...")
        return

    try:
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"\nFEL: Kunde inte läsa JSON-filen. Är det rätt format?\n{e}")
        pause_if_interactive("\nTryck Enter för att avsluta...")
        return

    print(f"\nLäser in exportformat version {data.get('version', 1)}")
    print(f"Test:     {data['glideTest']['title']}")
    print(f"Datum:    {data['glideTest']['createdAt']}")
    print(f"Notering: {data['glideTest']['notes'] or 'Inga noteringar'}")
    print("-" * 50)

    for run in data['runs']:
        run_number = run.get('runNumber', run.get('id', '?'))
        print(f"\n[ÅK {run_number}] Skida: {run['skiName']}")
        print(f"Tid: {run['elapsedSeconds']} sek")

        # --- GPS DATA ---
        gps_points = decode_flutter_blob(run['gpsData'])
        print_stream_summary(
            'GPS',
            gps_points,
            elapsed_key='receivedElapsedMicroseconds',
        )

        # Visa exempeldata (första och sista punkten)
        if gps_points:
            p_start = gps_points[0]
            p_end = gps_points[-1]
            speed_kmh = p_start.get('speed', 0) * 3.6
            print(
                f"    Start: Lat {p_start.get('latitude'):.5f}, "
                f"Fart {speed_kmh:.1f} km/h"
            )
            print(f"    Slut:  Lat {p_end.get('latitude'):.5f}")

        # --- ACCELEROMETER DATA ---
        accel_events = decode_flutter_blob(run['accelerometerData'])
        print_stream_summary('Accel', accel_events)

        sensor_data = run.get('sensorData') or {}
        gyroscope_events = decode_flutter_blob(sensor_data.get('gyroscope'))
        barometer_events = decode_flutter_blob(sensor_data.get('barometer'))
        rotation_events = decode_flutter_blob(
            sensor_data.get('rotationVector')
        )
        print_stream_summary('Gyro', gyroscope_events)
        print_stream_summary('Barometer', barometer_events)
        print_stream_summary('Rotationsvektor', rotation_events)
        print_rotation_diagnostics(rotation_events)

        metadata = sensor_data.get('metadata') or {}
        streams = metadata.get('streams') or {}
        errors = {
            name: stream.get('error')
            for name, stream in streams.items()
            if isinstance(stream, dict) and stream.get('error')
        }
        if errors:
            print("    Sensorfel:")
            for name, error in errors.items():
                print(f"      {name}: {error}")

    print("\n" + "=" * 50)
    pause_if_interactive("Klar! Tryck Enter för att stänga.")


if __name__ == "__main__":
    main()
