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

The runner builds and installs the isolated APK, runs five user journeys, feeds
a deterministic GPS route through Maestro, and sends real Android volume-key
events through `adb`. Set `SKIDPARK_E2E_DEVICE` when more than one Android
device is connected.

The files under `_helpers` and `volume_steps` are reusable pieces and are not
standalone tests. Run the suite through the script instead of pointing Maestro
at the whole directory.

`04_edit_test_info.yaml` covers editing before and after recording a run:

- Direct note editing and saving with the keyboard open.
- Empty-name validation, rename, cancel and clearing saved notes.
- Back navigation: continue editing or discard, without overwriting saved text.
- Drafts surviving tab changes, and saved text surviving an app restart.
- Existing runs and selected skis remaining available after metadata edits.
- The separate ski-selection screen: empty selection, cancel, back navigation,
  adding a ski and replacing the preferred skis after a recorded run. The old
  run must remain visible and a new run must offer the updated selection.
- Expanded guidance without runs, collapsed guidance with runs, and read-only
  example tests.

The volume journey additionally sends short volume presses during editing and
an actual 800 ms press between steps 04 and 05. It verifies that editing stays
open even after switching to `Översikt`, then saves and sends another long press
to verify `Nytt åk` works again. The selected skis must remain available and an
unselected reserve ski must stay excluded.

To run only the editing journey after building and installing the isolated APK:

```sh
maestro test e2e/maestro/04_edit_test_info.yaml
```

Database-write failure and retry remain deterministic widget tests in
`test/features/glide_testing/compare/analysis_workspace_test.dart`, using a real
SQLite failure. The native journey does not introduce a production failure hook.
The small-screen keyboard layout is also covered there; Maestro uses the current
emulator's screen size. Android volume events do not validate physical iPhone
gestures.
