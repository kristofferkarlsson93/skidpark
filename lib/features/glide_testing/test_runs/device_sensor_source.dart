import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors;

abstract interface class DeviceSensorSource {
  Stream<sensors.UserAccelerometerEvent> get userAccelerometerEvents;
  Stream<sensors.GyroscopeEvent> get gyroscopeEvents;
  Stream<sensors.BarometerEvent> get barometerEvents;
  Stream<OrientationEvent> get rotationVectorEvents;
  bool get supportsRotationVector;
}

class PluginDeviceSensorSource implements DeviceSensorSource {
  static const motionSamplingPeriod = Duration(milliseconds: 20);
  static const barometerSamplingPeriod = Duration(milliseconds: 200);

  @override
  Stream<sensors.UserAccelerometerEvent> get userAccelerometerEvents {
    return sensors.userAccelerometerEventStream(
      samplingPeriod: motionSamplingPeriod,
    );
  }

  @override
  Stream<sensors.GyroscopeEvent> get gyroscopeEvents {
    return sensors.gyroscopeEventStream(samplingPeriod: motionSamplingPeriod);
  }

  @override
  Stream<sensors.BarometerEvent> get barometerEvents {
    return sensors.barometerEventStream(
      samplingPeriod: barometerSamplingPeriod,
    );
  }

  @override
  bool get supportsRotationVector => RotationSensor.isPlatformSupported;

  @override
  Stream<OrientationEvent> get rotationVectorEvents {
    RotationSensor.samplingPeriod = motionSamplingPeriod;
    // A glide run only needs a stable local frame. Avoid magnetic north here
    // so nearby metal and magnets cannot steer the fused orientation.
    RotationSensor.referenceFrame = ReferenceFrame.arbitrary;
    RotationSensor.coordinateSystem = CoordinateSystem.device();
    return RotationSensor.orientationStream;
  }
}
