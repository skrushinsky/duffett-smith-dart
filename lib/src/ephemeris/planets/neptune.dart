import 'dart:math';
import 'package:vector_math/vector_math.dart';
import '../../mathutils.dart';
import '../planets.dart';
import '../orbit.dart';

import '../pert.dart';

/// Neptune
class Neptune extends Planet {
  Neptune() : super.create(PlanetId.Neptune, buildOrbit());

  /// Initialize osculating elements of the planet's orbit
  static OElements buildOrbit() {
    final oe = OElements();
    oe.ML = MLTerms([84.457994, 6.107942056e-1, 3.205e-4, -6e-7]);
    oe.PH = Terms([4.6727364e1, 1.4245744, 3.9082e-4, -6.05e-7]);
    oe.EC = Terms([8.99704e-3, 6.33e-6, -2e-9]);
    oe.IN = Terms([1.779242, -9.5436e-3, -9.1e-6]);
    oe.ND = Terms([130.681389, 1.098935, 2.4987e-4, -4.718e-6]);
    oe.SA = 30.10957;
    oe.DI = 62.2;
    oe.MG = -6.87;
    return oe;
  }

  @override
  Map<PertType, double> calculatePerturbations(List<double> args) {
    final t = args[0];
    final s = args[1];
    final x = Planet.auxSun(t);
    final x1 = x[0];
    final x2 = x[1];
    final x3 = x[2];
    final x4 = x[3];
    final x8 = reduceRad(1.46205 + 3.81337 * t);
    final x9 = 2 * x8 - x4;
    final x10 = x8 - x2;
    final x11 = x8 - x3;
    final x12 = x8 - x4;
    final sx9 = sin(x9);
    final cx9 = cos(x9);
    final s2x9 = sin(2 * x9);
    final c2x9 = cos(2 * x9);

    final res = super.calculatePerturbations(args);

    res[PertType.dml] = (1.089e-3 * x1 - 5.89833e-1) * sx9 +
        (4.658e-3 * x1 - 5.6094e-2) * cx9 -
        2.4286e-2 * s2x9;
    res[PertType.dml] = radians(res[PertType.dml]);
    final dp =
        2.4039e-2 * sx9 - 2.5303e-2 * cx9 + 6.206e-3 * s2x9 - 5.992e-3 * c2x9;
    res[PertType.dm] = res[PertType.dml] - (radians(dp) / s);
    res[PertType.ds] = 4389 * sx9 + 1129 * s2x9 + 4262 * cx9 + 1089 * c2x9;
    res[PertType.ds] *= 1e-7;
    res[PertType.da] = 8189 * cx9 - 817 * sx9 + 781 * c2x9;
    res[PertType.da] *= 1e-6;
    final s2x12 = sin(2 * x12);
    final c2x12 = cos(2 * x12);
    final sx8 = sin(x8);
    final cx8 = cos(x8);
    res[PertType.dl] = -9.556e-3 * sin(x10) -
        5.178e-3 * sin(x11) +
        2.572e-3 * s2x12 -
        2.972e-3 * c2x12 * sx8 -
        2.833e-3 * s2x12 * cx8;
    res[PertType.dhl] = 3.36e-4 * c2x12 * sx8 + 3.64e-4 * s2x12 * cx8;
    res[PertType.dhl] = radians(res[PertType.dhl]);
    res[PertType.dr] = -40596 +
        4992 * cos(x10) +
        2744 * cos(x11) +
        2044 * cos(x12) +
        1051 * c2x12;
    res[PertType.dr] *= 1e-6;

    return res;
  }

  @override
  String toString() {
    return 'Neptune';
  }
}
