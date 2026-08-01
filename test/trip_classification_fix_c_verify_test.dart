import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/services/tracking/activity_recognition_service.dart';
import 'package:child_track/core/services/tracking/trip_classification_engine.dart';

Position _pos({required double speed, double heading = 0}) {
  return Position(
    longitude: 76.38,
    latitude: 11.47,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}

ActivityState _ar(NaviQActivityType type, double confidence) {
  return ActivityState(type: type, confidence: confidence, timestamp: DateTime.now());
}

void main() {
  test('Fix C verification — physical-plausibility cap on walking classification', () {
    final engine = TripClassificationEngine();

    ClassificationResult run(double speedMs, NaviQActivityType arType, double arConf, double heading) {
      return engine.classify(
        position: _pos(speed: speedMs, heading: heading),
        arState: _ar(arType, arConf),
      );
    }

    // 093RTB repro: AR confidently says walking, GPS speed implies 27.6 km/h.
    final repro = run(7.67, NaviQActivityType.walking, 0.95, 45);
    print('093RTB repro: 7.67 m/s + AR=walking@0.95 -> ${repro.type.name} (was: walking, unfixed)');
    expect(repro.type, isNot(NaviQActivityType.walking),
        reason: '27.6km/h must never classify as walking regardless of AR vote');

    // Even more extreme: AR walking at highway speed.
    final extreme = run(30.0, NaviQActivityType.walking, 0.99, 10);
    print('extreme: 30 m/s + AR=walking@0.99 -> ${extreme.type.name}');
    expect(extreme.type, isNot(NaviQActivityType.walking));

    // Regression: genuine walking, AR agrees — must stay walking.
    final realWalk = run(1.3, NaviQActivityType.walking, 0.85, 60);
    print('real walk: 1.3 m/s + AR=walking@0.85 -> ${realWalk.type.name}');
    expect(realWalk.type, NaviQActivityType.walking);

    // Regression: genuine walking, AR silent/unknown — GPS alone should still say walking.
    final realWalkNoAr = run(1.3, NaviQActivityType.unknown, 0.0, 60);
    print('real walk no AR: 1.3 m/s + AR=unknown -> ${realWalkNoAr.type.name}');
    expect(realWalkNoAr.type, NaviQActivityType.walking);

    // Regression: genuine drive, AR agrees — must stay vehicle, untouched by the cap.
    final realDrive = run(18.0, NaviQActivityType.vehicle, 0.9, 5);
    print('real drive: 18 m/s + AR=vehicle@0.9 -> ${realDrive.type.name}');
    expect(realDrive.type, NaviQActivityType.vehicle);

    // Regression: genuine drive, AR silent.
    final realDriveNoAr = run(18.0, NaviQActivityType.unknown, 0.0, 5);
    print('real drive no AR: 18 m/s + AR=unknown -> ${realDriveNoAr.type.name}');
    expect(realDriveNoAr.type, NaviQActivityType.vehicle);

    // Edge: exactly at the 2.0 m/s cap boundary with AR walking — should be
    // disqualified (>= cap), falling through to GPS-based classification.
    final boundary = run(2.0, NaviQActivityType.walking, 0.9, 90);
    print('boundary (2.0 m/s exactly) + AR=walking@0.9 -> ${boundary.type.name}');
    expect(boundary.type, isNot(NaviQActivityType.walking));

    // Edge: just under the cap — walking should still be allowed to win if
    // AR/heading support it.
    final justUnder = run(1.99, NaviQActivityType.walking, 0.9, 90);
    print('just under (1.99 m/s) + AR=walking@0.9 -> ${justUnder.type.name}');
    expect(justUnder.type, NaviQActivityType.walking);
  });
}
