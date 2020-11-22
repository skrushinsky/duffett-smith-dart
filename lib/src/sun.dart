import 'dart:math';
import 'package:duffett_smith/ephemeris.dart';
import 'package:duffett_smith/src/timeutils/julian.dart';
import 'package:vector_math/vector_math.dart';
import 'mathutils.dart';
import 'ephemeris/kepler.dart';

const ABERRATION = 5.69e-3; // aberration in degrees

/// Mean longitude of the Sun, arc-degrees
double meanLongitude(double t) =>
    reduceDeg(2.7969668e2 + 3.025e-4 * t * t + frac360(1.000021359e2 * t));

/// Mean anomaly of the Sun, arc-degrees
double meanAnomaly(double t) => reduceDeg(
    3.5847583e2 - (1.5e-4 + 3.3e-6 * t) * t * t + frac360(9.999736042e1 * t));

/// Calculates true geocentric longitude of the Sun for the mean equinox
/// of date (degrees), and the Sun-Earth distance (AU) for moment [t],
/// Julian centuries since 1900 Jan, 0.5.
/// If [ms], mean anomaly of the Sun, named argument is not provided by the
/// caller, it will be calculated automatically.
void trueGeocentric(double t, {double ms, Function(double, double) callback}) {
  ms ??= meanAnomaly(t);
  final ls = meanLongitude(t);
  final ma = radians(ms);
  final s = polynome(t, [1.675104e-2, -4.18e-5, -1.26e-7]); // eccentricity
  final ea = kepler(s, ma - PI2 * (ma / PI2).floor()); // eccentric anomaly
  final nu = trueAnomaly(s, ea); // true anomaly
  final t2 = t * t;

  final calcPert = (a, b) => radians(a + frac360(b * t));
  final a = calcPert(153.23, 6.255209472e1); // Venus
  final b = calcPert(216.57, 1.251041894e2); // ?
  final c = calcPert(312.69, 9.156766028e1); // ?
  final d = calcPert(350.74 - 1.44e-3 * t2, 1.236853095e3); // Moon
  final h = calcPert(353.4, 1.831353208e2); // ?
  final e = radians(231.19 + 20.2 * t); // inequality of long period

  // correction in orbital longitude
  final dl = 1.34e-3 * cos(a) +
      1.54e-3 * cos(b) +
      2e-3 * cos(c) +
      1.79e-3 * sin(d) +
      1.78e-3 * sin(e);
  // correction in radius-vector
  final dr = 5.43e-6 * sin(a) +
      1.575e-5 * sin(b) +
      1.627e-5 * sin(c) +
      3.076e-5 * cos(d) +
      9.27e-6 * sin(h);
  final lsn = reduceDeg(degrees(nu) + ls - ms + dl);
  final rsn = 1.0000002 * (1 - s * cos(ea)) + dr;
  callback(lsn, rsn);
}

/// Find apparent geocentric ecliptical longitude of the Sun, given:
/// [lambda], true longitude and [deltaPsi],  nutation in longitude.
///
/// If optional named [ignoreLightTravel] argument is set to _false_,
/// light-time travel correction will not be applied. In that case,
/// optional [delta] named argument (Sun-Earth distance) is required.
/// By default, [ignoreLightTravel] is `false`.
///
/// All angles in degrees.
double trueToApparent(double lambda, double deltaPsi,
    {double delta = 0.0, bool ignoreLightTravel = true}) {
  lambda += deltaPsi; // nutation
  lambda -= ABERRATION; // aberration

  if (!ignoreLightTravel) {
    final dt = 1.365 * delta; // seconds
    lambda -= dt * 15 / 3600; // convert to degrees and substract
  }
  return lambda;
}

void apparent(double djd,
    {double dpsi,
    bool ignoreLightTravel = true,
    Function(double, double) callback}) {
  final t = djd / DAYS_PER_CENT;
  trueGeocentric(t, callback: (lsn, rsn) {
    if (dpsi == null) {
      nutation(t, (dp, _) => dpsi = dp);
    }
    final lambda = trueToApparent(lsn, dpsi,
        ignoreLightTravel: ignoreLightTravel, delta: rsn);
    callback(lambda, rsn);
  });
}
