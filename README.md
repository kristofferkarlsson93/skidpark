# SkidPark

SkidPark is a Flutter app that helps a solo cross-country skier compare ski
glide. It records GPS and motion-sensor data and visualizes relative differences
between repeated downhill runs.

The current development focus is measurement validity: determining how much of
the difference between runs comes from the skis and how much comes from GPS,
phone movement, the skier, and the processing algorithm. The app's output is
intended to support the skier's interpretation rather than automatically name a
winning ski.

## Project documentation

- [Agent and project guidance](AGENTS.md)
- [Current product and engineering tasks](TODO.md)
- [Current product and UX decisions](docs/product-ux/PRODUCT_DECISIONS.md)
- [iOS build and device instructions](docs/ios/README.md)

Glide-test exports, participant feedback, and analyses derived from them are
kept locally and are intentionally not version-controlled.

- `user_data/exported_tests/`: local recordings and experimental test exports.
- `user_data/feedback/`: participant feedback, including Markdown notes.
- `docs/glide-data-analysis/`: local reports derived from those recordings.

These directories are excluded from Git and are not Flutter assets. Git ignore
rules control versioning, not app packaging: only the single example file
`assets/example_data/glide_test.json` is declared in `pubspec.yaml` and bundled
for new users. Keep experimental recordings out of `assets/`.

## Getting started

Use Flutter 3.47.9 or newer, with Dart 3.13.7 or newer. Android uses the Gradle
8.14.6 wrapper.

The temporary `sensors_plus` override requires the sibling repository
`../plus_plugins`, containing version 7.1.1 and the iOS sensor timestamp fix
from commit `fc551db1`. The published package does not yet include that fix.

```shell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Run `flutter analyze` after Dart changes. The generated Drift database file is
ignored by Git and may need to be rebuilt after a fresh checkout or schema
change.
