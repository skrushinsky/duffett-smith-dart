import 'dart:math';
import 'package:vector_math/vector_math.dart';
import '../planets.dart';
import '../orbit.dart';
import '../pert.dart';

/// Venus
class Venus extends Planet {
  Venus() : super.create(PlanetId.Venus, buildOrbit());

  /// Initialize osculating elements of the planet's orbit
  static OElements buildOrbit() {
    final oe = OElements();
    oe.ML = MLTerms([342.767053, 162.5533664, 3.097e-4]);
    oe.PH = Terms([130.163833, 1.4080361, -9.764e-4]);
    oe.EC = Terms([6.82069e-3, -4.774e-5, 9.1e-8]);
    oe.IN = Terms([3.393631, 1.0058e-3, -1e-6]);
    oe.ND = Terms([75.779647, 8.9985e-1, 4.1e-4]);
    oe.SA = 7.233316e-1;
    oe.DI = 16.92;
    oe.MG = -4.4;
    return oe;
  }

  @override
  Map<PertType, double> calculatePerturbations(List<double> args) {
    final t = args[0];
    final ms = args[1];
    final ve = args[2];
    final ju = args[3];
    final res = super.calculatePerturbations(args);
    res[PertType.dl] = .00313 * cos(2 * ms - 2 * ve - 2.587) +
        .00198 * cos(3 * ms - 3 * ve + .044768) +
        .00136 * cos(ms - ve - 2.0788) +
        .00096 * cos(3 * ms - 2 * ve - 2.3721) +
        .00082 * cos(ju - ve - 3.6318);

    res[PertType.dr] = 2.2501e-05 * cos(2 * ms - 2 * ve - 1.01592) +
        1.9045e-05 * cos(3 * ms - 3 * ve + 1.61577) +
        6.887e-06 * cos(ju - ve - 2.06106) +
        5.172e-06 * cos(ms - ve - .508065) +
        3.62e-06 * cos(5 * ms - 4 * ve - 1.81877) +
        3.283e-06 * cos(4 * ms - 4 * ve + 1.10851) +
        3.074e-06 * cos(2 * ju - 2 * ve - .962846);

    res[PertType.dm] =
        res[PertType.dml] = radians(7.7e-4 * sin(4.1406 + t * 2.6227));
    return res;
  }

  @override
  String toString() {
    return 'Venus';
  }
}
