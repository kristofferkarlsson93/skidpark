# SkidPark Android E2E

These flows exercise the installed Android app through Maestro's UI automation.
They use the isolated package `com.krikar.skidpark.skidpark.e2e`; clearing test
state therefore never clears the normal SkidPark installation.

Run the complete suite on a running Android emulator:

```sh
./scripts/run_android_e2e.sh
```

Prerequisites are Flutter, an Android SDK with `adb`, a running Android
emulator, and the Maestro CLI available on `PATH`.

The runner builds and installs the isolated APK, runs four user journeys, feeds
a deterministic GPS route through Maestro, and sends real Android volume-key
events through `adb`. Set `SKIDPARK_E2E_DEVICE` when more than one Android
device is connected.

The files under `_helpers` and `volume_steps` are reusable pieces and are not
standalone tests. Run the suite through the script instead of pointing Maestro
at the whole directory.
