import 'dart:math';

import '../planets.dart';
import '../orbit.dart';

import '../pert.dart';

/// Mercury
class Mercury extends Planet {
  Mercury() : super.create(PlanetId.Mercury, buildOrbit());

  /// Initialize osculating elements of the planet's orbit
  static OElements buildOrbit() {
    final oe = OElements();
    oe.ML = MLTerms([178.179078, 415.2057519, 3.011e-4]);
    oe.PH = Terms([75.899697, 1.5554889, 2.947e-4]);
    oe.EC = Terms([2.0561421e-1, 2.046e-5, -3e-8]);
    oe.IN = Terms([7.002881, 1.8608e-3, -1.83e-5]);
    oe.ND = Terms([47.145944, 1.1852083, 1.739e-4]);
    oe.SA = 3.870986e-1;
    oe.DI = 6.74;
    oe.MG = -0.42;
    return oe;
  }

  @override
  Map<PertType, double> calculatePerturbations(List<double> args) {
    final me = args[0];
    final ve = args[1];
    final ju = args[2];

    final res = super.calculatePerturbations(args);
    res[PertType.dl] = .00204 * cos(5 * ve - 2 * me + .21328) +
        .00103 * cos(2 * ve - me - 2.8046) +
        .00091 * cos(2 * ju - me - .64582) +
        .00078 * cos(5 * ve - 3 * me + .17692);
    res[PertType.dr] = 7.525e-06 * cos(2 * ju - me + .925251) +
        6.802e-06 * cos(5 * ve - 3 * me - 4.53642) +
        5.457e-06 * cos(2 * ve - 2 * me - 1.24246) +
        3.569e-06 * cos(5 * ve - me - 1.35699);
    return res;
  }

  @override
  String toString() {
    return 'Mercury';
  }
}
