import 'dart:math';
import 'package:vector_math/vector_math.dart';
import '../planets.dart';
import '../orbit.dart';

import '../pert.dart';

/// Mars
class Mars extends Planet {
  Mars() : super.create(PlanetId.Mars, buildOrbit());

  /// Initialize osculating elements of the planet's orbit
  static OElements buildOrbit() {
    final oe = OElements();
    oe.ML = MLTerms([293.737334, 53.17137642, 3.107e-4]);
    oe.PH = Terms([3.34218203e2, 1.8407584, 1.299e-4, -1.19e-6]);
    oe.EC = Terms([9.33129e-2, 9.2064e-5, -7.7e-8]);
    oe.IN = Terms([1.850333, -6.75e-4, 1.26e-5]);
    oe.ND = Terms([48.786442, 7.709917e-1, -1.4e-6, -5.33e-6]);
    oe.SA = 1.5236883;
    oe.DI = 9.36;
    oe.MG = -1.52;
    return oe;
  }

  @override
  Map<PertType, double> calculatePerturbations(List<double> args) {
    final ms = args[0];
    final ve = args[1];
    final ma = args[2];
    final ju = args[3];
    final a = 3 * ju - 8 * ma + 4 * ms;
    final sa = sin(a);
    final ca = cos(a);
    final res = super.calculatePerturbations(args);

    res[PertType.dl] = .00705 * cos(ju - ma - .85448) +
        .00607 * cos(2 * ju - ma - 3.2873) +
        .00445 * cos(2 * ju - 2 * ma - 3.3492) +
        .00388 * cos(ms - 2 * ma + .35771) +
        .00238 * cos(ms - ma + .61256) +
        .00204 * cos(2 * ms - 3 * ma + 2.7688) +
        .00177 * cos(3 * ma - ve - 1.0053) +
        .00136 * cos(2 * ms - 4 * ma + 2.6894) +
        .00104 * cos(ju + .30749);
    res[PertType.dr] = 5.3227e-05 * cos(ju - ma + .717864) +
        5.0989e-05 * cos(2 * ju - 2 * ma - 1.77997) +
        3.8278e-05 * cos(2 * ju - ma - 1.71617) +
        1.5996e-05 * cos(ms - ma - .969618) +
        1.4764e-05 * cos(2 * ms - 3 * ma + 1.19768) +
        8.966e-06 * cos(ju - 2 * ma + .761225) +
        7.914e-06 * cos(3 * ju - 2 * ma - 2.43887) +
        7.004e-06 * cos(2 * ju - 3 * ma - 1.79573) +
        6.62e-06 * cos(ms - 2 * ma + 1.97575) +
        4.93e-06 * cos(3 * ju - 3 * ma - 1.33069) +
        4.693e-06 * cos(3 * ms - 5 * ma + 3.32665) +
        4.571e-06 * cos(2 * ms - 4 * ma + 4.27086) +
        4.409e-06 * cos(3 * ju - ma - 2.02158);
    res[PertType.dm] =
        res[PertType.dml] = radians(-(.01133 * sa + .00933 * ca));
    ;
    return res;
  }

  @override
  String toString() {
    return 'Mars';
  }
}
