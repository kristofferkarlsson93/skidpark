# SkidPark TODO

## Product direction and validation

- [x] Update project dependencies, including Flutter.
- [x] Apply the Flutter/Dart and Gradle security patches and restrict bundled example data to the single public example. Local recordings and feedback stay under the Git-ignored `user_data/` directory.
- [x] Refresh compatible Pub dependencies, preserve the local iOS sensor timestamp patch, and retain strict validation of compressed sensor data.
- [ ] Upgrade the Android build toolchain to Gradle 9, AGP 9, and the compatible Kotlin version when a stable Flutter release supports that combination.
- [ ] Collect exported glide-test data and feedback from pilot users.
- [ ] Evaluate whether the app’s current approach solves the core problem reliably, based on pilot data.
- [ ] Assess whether phone GPS and motion sensors provide sufficient accuracy for meaningful relative ski-glide comparisons, or whether the measurement approach should be reconsidered.
- [ ] Review the glide-test calculation and plotting algorithms to identify potential improvements.
- [ ] Revisit the distance reference model before choosing a production approach. Compare speed integrated over time with GPS positions projected along the shared course. Do not return to summing raw `distanceBetween` segments, because lateral and back-and-forth GPS jitter can only add distance. Validate the alternatives with repeated A–A tests before replacing today’s primary graph.
- [ ] Run a controlled A–A baseline before further algorithm tuning: repeat the same ski or roller skis at least 8–10 times from a marked start, record the physical stopping position, and measure the spread produced by the skier, phone, and app when no ski difference exists. Follow the local validation plan when available, and repeat the test on snow before drawing conclusions about ski glide.
- [ ] Run the downward-camera feasibility test on roller skis and asphalt: record the ground at 60 or 120 fps, include measured visual gates, and determine whether optical flow is stable before building camera support into the app.
- [ ] If the camera signal is promising, prototype synchronized logging of video timestamps, GPS, accelerometer, gyroscope, and rotation vector. Use phone orientation to separate hand rotation from forward acceleration.
- [ ] Repeat the A–A and camera tests on snow when conditions allow; success on textured asphalt is only a best-case indication for optical flow.
- [ ] Validate the working name “SkidPark” against domains and trademarks before a public launch.
- [x] Make glide testing the primary workflow and ski inventory a supporting feature.

## Improvements if we continue in the current direction

- [x] Enable local iOS builds, Simulator testing, and installation on an iPhone. See the [build instructions](docs/ios/README.md).
- [ ] Complete physical iOS checks: denied/reduced location permission, repeated recordings, start/stop/save/cancel/back, screen lock, app switching, calls, sensor interruptions, file import/sharing and iPad layout. Verify gesture selection and countdown, speech/haptics, and restoration of normal screen sleep. Repeat Android short/long volume actions in overview and ski selection.
- [x] Limit location services to the recording route, entered after `Nytt åk`.
- [ ] Measure and reduce battery use during active GPS recording.
- [x] Let users choose a subset of skis for each test session.
- [x] Include a real example test in the first-use introduction.
- [ ] Support testing a ski before and after a change, such as a new structure or wax treatment, while clearly separating runs from before and after the change.

## Approved addition

- [ ] Define a simple data-quality indicator for each run, such as poor GPS accuracy, insufficient glide distance, or unusual sensor data, so unreliable comparisons are not presented with false confidence.

## Reliability and data integrity

- [ ] Refresh release-point analysis when sensor fusion changes, including averages per ski; the overview currently updates while release-point results can remain stale (`CompareRunsViewModel`).
- [ ] Keep the release-point slider within its valid range when filtering out longer runs; invalidate or recompute results when the selected point becomes unusable (`ReleasePointControls`).
- [ ] Handle GPS stream failures explicitly: stop presenting a growing recording timer as healthy after the subscription ends, clear stale speed, preserve collected data, and support controlled recovery (`DataRecorder`). Prioritize this and stale analysis before wider field testing.
- [ ] Require actual movement before automatic stop/save, using fresh valid GPS data and elapsed time rather than only a count of points. Waiting still before a run must not save it automatically (`RunRecorderViewModel`).
- [ ] Define and implement interruption handling for an active recording. Backgrounding, screen lock and sensor gaps must preserve collected data and expose interrupted runs; input pausing and screen wakefulness do not provide that transition.
- [ ] Reject duplicate imported ski IDs and non-integral IDs before storage (`GlideTestImportService`); duplicates currently attach runs to the last matching ski.
- [ ] Bound import file size, decompressed bytes, point counts and numeric/timestamp ranges, and bound analysis work. A finite speed such as `1e12` m/s can otherwise request hundreds of billions of interpolated points. Move expensive processing off the UI isolate after defensive limits exist.
- [ ] Preserve the original recording device/platform and sensor settings through import and re-export, separately from the exporting device (`ExportedGlideTest`).
- [ ] Preserve ski notes in export/import and define whether exports also retain archived state and original creation dates; current exports are not complete ski backups.
- [ ] Await create/edit/delete/export writes and show recoverable errors before discarding drafts. Replace `async void` at persistence boundaries with awaitable operations.
- [ ] Add explicit error/missing-data states to analysis streams, including corrupted stored sensor blobs and deleted tests.
- [ ] Replace the local sibling-repository sensor override with a reproducible pinned source once the timestamp fix is available upstream.

## Before public distribution

- [ ] Configure Android release signing instead of the current debug signing.
- [ ] Add an accessible privacy policy in the app and store metadata. Describe GPS/timestamps, sensor data, notes, deletion, raw-data export and support-file retention.
- [ ] Complete Apple App Privacy and Google Play Data safety declarations from actual app/SDK behavior; assess received pilot/support exports separately from local-only processing.
- [ ] Establish the handling basis, access and retention period for received pilot recordings. Treat timestamped GPS tracks as personal data and verify permission to distribute the bundled example.
- [ ] Explain what shared raw-data exports contain and avoid exporting the personal iOS device name unless needed.
- [ ] Check Android/iOS cloud backup behavior before promising that recordings never leave the phone.
