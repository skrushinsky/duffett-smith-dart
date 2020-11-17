import 'dart:math';
import 'package:duffett_smith/mathutils.dart';
import 'package:vector_math/vector_math.dart';

/// The 'standard' altitude in arc-degrees, i.e. geometric altitude of the
/// center of the body at the time of apparent rising and setting,
/// for stars and planets
const altStd = -0.5667;

/// Standard altitude of the Sun
const altSun = -0.8333;

/// Mean altitude for Moon; for better accuracy use:
/// `0.7275 * parallax - 0.34`
const altMoon = 0.125;

/// Base class for exceptions in this module.
abstract class RiseSetException implements Exception {
  final String message;
  const RiseSetException(this.message);
  String errMsg() => message;
}

/// Routine can't cope
class ImpossibleCalculation extends RiseSetException {
  const ImpossibleCalculation() : super('Impossible calculation');
}

/// The celectial body is always above the horizon, it never sets.
class CircumpolarException extends RiseSetException {
  const CircumpolarException() : super('Circumpolar');
}

/// The celectial body is always below the horizon, it never rises.
class NeverRisesException extends RiseSetException {
  const NeverRisesException() : super('Never rises');
}

/// Circumstances of **rising** and **setting** of a celestial object
/// whose right ascension and declination are known.
///
/// [alpha] is right ascension in hours, [delta] is declination in arc-degrees,
/// [phi] is geographical latiude in arc-degrees. Optional [displacment] is
/// vertical displacement in arc-degrees, [altStd] by default.
///
/// Caller receives results via [callback] function, which is called with
/// local sidereal times (hours) and azimuths (in arc-degrees) of rise and set.
void riseset(double alpha, double delta, double phi,
    {double displacement = altStd,
    Function(double, double, double, double) callback}) {
  final de = radians(delta);
  final cy = cos(de);
  final dis = radians(displacement);
  final ph = radians(phi);
  final cphi = cos(ph);
  final sphi = sin(ph);

  final a = cy * cphi;
  // Program cannot cope if a is too small.
  if (a.abs() < 1e-10) {
    throw ImpossibleCalculation();
  }

  var cpsi = sphi / cy;
  // correct for possible rounding errors at poles
  if (cpsi > 1) {
    cpsi = 1.0;
  } else if (cpsi < -1) {
    cpsi = -1.0;
  }

  final psi = acos(cpsi);
  final spsi = sin(psi);
  final dh = dis * spsi;
  final y1 = de + dis * cpsi;
  final sy = sin(y1);
  final ty = tan(y1);

  // test fo circumpolar object and for one that never rises
  final ch = (-1 * sphi * ty) / cphi;
  if (ch < -1) {
    throw CircumpolarException();
  }
  if (ch > 1) {
    throw NeverRisesException();
  }

  final h = degrees(acos(ch) + dh) / 15;
  final lstr = toRange(24 + alpha - h, 24);
  final lsts = toRange(alpha + h, 24);
  final azr = reduceDeg(degrees(acos(sy / cphi)));
  final azs = reduceDeg(360 - azr);

  callback(lstr, lsts, azr, azs);
}
