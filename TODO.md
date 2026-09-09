# SkidPark TODO

## Product direction and validation

- [x] Update project dependencies, including Flutter.
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

- [ ] Make the app compatible with iOS and enable local testing in an iOS Simulator.
- [ ] Reduce battery use during GPS recording. Recording currently starts early and remains active for too long.
- [ ] Let users choose a subset of skis for each test session, for example only skate skis or only the skis brought to the session.
- [ ] Extend the first-use introduction with the real example test planned for Etapp 2.
- [ ] Support testing a ski before and after a change, such as a new structure or wax treatment, while clearly separating runs from before and after the change.

## Approved addition

- [ ] Define a simple data-quality indicator for each run, such as poor GPS accuracy, insufficient glide distance, or unusual sensor data, so unreliable comparisons are not presented with false confidence.
