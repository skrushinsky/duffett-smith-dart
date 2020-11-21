import 'dart:math';
import 'package:duffett_smith/coco.dart';
import 'package:duffett_smith/ephemeris.dart';
import 'package:duffett_smith/mathutils.dart';
import 'package:duffett_smith/src/timeutils/julian.dart';
import 'package:duffett_smith/src/timeutils/sidereal.dart';
import 'package:vector_math/vector_math.dart';
import 'package:duffett_smith/src/ephemeris/sun.dart' as sun;

/// The 'standard' altitude in arc-degrees, i.e. geometric altitude of the
/// center of the body at the time of apparent rising and setting,
/// for stars and planets
const altStd = 0.5667;

/// Standard altitude of the Sun
const altSun = 0.8333;

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

/// Types of event
enum EventType { Rise, Set }

/// Event description
class RSEvent {
  final double _utc;
  final double _azimuth;

  const RSEvent(this._utc, this._azimuth);

  /// UTC of the event
  double get utc => _utc;

  /// Azimuth of the body, arc-degrees
  double get azimuth => _azimuth;
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

/// Calculates rise and set of the Sun.
class RiseSetSun {
  final _djd;
  final _phi;
  final _lng;

  RSEvent _sunRise;
  RSEvent _sunSet;

  /// Constructor.
  RiseSetSun(this._djd, this._phi, this._lng);

  void _riseset(double dj, callback) {
    final t = dj / daysPerCentury;
    nutation(t, (dpsi, deps) {
      sun.trueGeocentric(t, callback: (lsn, rsn) {
        // correct for nutation and aberration
        final lambda = sun.trueToApparent(lsn, dpsi, ignoreLightTravel: true);
        // obliquity
        final eps = obliquity(dj, deps: deps);
        ecl2equ(lambda, 0.0, eps, (alpha, delta) {
          riseset(alpha / 15, delta, _phi,
              displacement: altSun, callback: callback);
        });
      });
    });
  }

  void _gmt(double dj, Function(RSEvent, RSEvent) callback) {
    _riseset(dj, (lstr, lsts, azr, azs) {
      var r, s;
      siderealToUTC(
          lst: lstr,
          djd: dj,
          lng: _lng,
          callback: (utc, _) {
            r = RSEvent(utc, azr);
          });
      siderealToUTC(
          lst: lsts,
          djd: dj,
          lng: _lng,
          callback: (utc, _) {
            s = RSEvent(utc, azs);
          });
      callback(r, s);
    });
  }

  void _calculate() {
    final dj0 = djdMidnight(_djd);
    // rise/set for the noon
    _gmt(dj0 + 0.5, (r0, s0) {
      // set DJD to first approx. of time of sunrise/sunset
      _gmt(dj0 + r0.utc / 24, (r1, s1) {
        _sunRise = r1;
        _gmt(dj0 + s0.utc / 24, (r2, s2) {
          _sunSet = s2;
        });
      });
    });
  }

  /// Sunrise circumstances
  RSEvent get sunRise {
    if (_sunRise == null) {
      _calculate();
    }
    return _sunRise;
  }

  /// Sunset circumstances
  RSEvent get sunSet {
    if (_sunSet == null) {
      _calculate();
    }
    return _sunSet;
  }
}
