import AVFoundation
import CoreMotion
import Flutter
import UIKit

/// Native iOS controls and display policy. Never records run data.
final class IosHandsFreeBridge: NSObject, FlutterStreamHandler {
  private lazy var motion = CMMotionManager()
  private let speech = AVSpeechSynthesizer()
  private var sink: FlutterEventSink?
  private var generation = 0
  private var previousIdleTimerDisabled: Bool?
  private var keepAwakeRequested = false

  init(messenger: FlutterBinaryMessenger) {
    super.init()
    speech.usesApplicationAudioSession = false
    FlutterEventChannel(
      name: "com.skidpark.app/ios_hands_free_motion",
      binaryMessenger: messenger
    ).setStreamHandler(self)

    let feedback = FlutterMethodChannel(
      name: "com.skidpark.app/ios_hands_free_feedback",
      binaryMessenger: messenger
    )
    feedback.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "speak":
        guard let text = call.arguments as? String else {
          return result(FlutterError(code: "invalid_text", message: nil, details: nil))
        }
        self.speech.stopSpeaking(at: .immediate)
        if UIApplication.shared.applicationState == .active {
          let utterance = AVSpeechUtterance(string: text)
          utterance.voice = AVSpeechSynthesisVoice(language: "sv-SE")
          self.speech.speak(utterance)
        }
        result(nil)
      case "stop":
        self.speech.stopSpeaking(at: .immediate)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    FlutterMethodChannel(
      name: "com.skidpark.app/ios_recording_display",
      binaryMessenger: messenger
    ).setMethodCallHandler { [weak self] call, result in
      guard call.method == "setKeepAwake" else {
        return result(FlutterMethodNotImplemented)
      }
      guard let enabled = call.arguments as? Bool else {
        return result(FlutterError(code: "invalid_enabled", message: nil, details: nil))
      }
      self?.keepAwakeRequested = enabled
      self?.updateIdleTimer()
      result(nil)
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(pause),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(resume),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    stopMotion()
    guard motion.isDeviceMotionAvailable else {
      events(FlutterError(
        code: "motion_unavailable",
        message: "Device motion requires a supported physical iPhone.",
        details: nil
      ))
      return nil
    }
    sink = events
    startMotionIfActive()
    return nil
  }

  private func startMotionIfActive() {
    // Flutter's resumed notification and UIKit's active state can arrive in
    // either order. Wait for UIKit instead of permanently failing the route.
    guard sink != nil, !motion.isDeviceMotionActive,
          UIApplication.shared.applicationState == .active else { return }
    let currentGeneration = generation
    // Core Motion supplies co-timed gravity and user acceleration in g, with
    // angular velocity in rad/s and a monotonic timestamp in seconds since boot.
    motion.deviceMotionUpdateInterval = 0.02
    motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, error in
      guard let self, self.generation == currentGeneration else { return }
      if let error {
        self.sink?(FlutterError(code: "motion_failed", message: error.localizedDescription, details: nil))
        self.stopMotion()
        return
      }
      guard let data else { return }
      let rate = data.rotationRate
      self.sink?([
        data.timestamp,
        data.gravity.x,
        data.userAcceleration.x,
        data.userAcceleration.y,
        data.userAcceleration.z,
        sqrt(rate.x * rate.x + rate.y * rate.y + rate.z * rate.z),
      ])
    }
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopMotion()
    sink = nil
    return nil
  }

  @objc private func pause() {
    stopMotion()
    speech.stopSpeaking(at: .immediate)
    restoreIdleTimer()
  }

  @objc private func resume() {
    startMotionIfActive()
    updateIdleTimer()
  }

  private func updateIdleTimer() {
    if keepAwakeRequested && UIApplication.shared.applicationState == .active {
      if previousIdleTimerDisabled == nil {
        previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
      }
      UIApplication.shared.isIdleTimerDisabled = true
    } else {
      restoreIdleTimer()
    }
  }

  private func restoreIdleTimer() {
    if let previous = previousIdleTimerDisabled {
      UIApplication.shared.isIdleTimerDisabled = previous
      previousIdleTimerDisabled = nil
    }
  }

  private func stopMotion() {
    generation += 1
    motion.stopDeviceMotionUpdates()
  }

  deinit {
    restoreIdleTimer()
    NotificationCenter.default.removeObserver(self)
    motion.stopDeviceMotionUpdates()
    speech.stopSpeaking(at: .immediate)
  }
}
