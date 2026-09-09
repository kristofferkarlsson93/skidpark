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
- [Start-flow implementation plan](docs/product-ux/start-flow-mockup/IMPLEMENTATION_PLAN.md)

Glide-test exports, participant feedback, and analyses derived from them are
kept locally and are intentionally not version-controlled.

## Getting started

```shell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Run `flutter analyze` after Dart changes. The generated Drift database file is
ignored by Git and may need to be rebuilt after a fresh checkout or schema
change.
