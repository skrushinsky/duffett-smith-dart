import 'dart:math';
import 'package:duffett_smith/coco.dart';
import 'package:duffett_smith/ephemeris.dart';
import 'package:duffett_smith/mathutils.dart';
import 'package:duffett_smith/src/timeutils/julian.dart';
import 'package:duffett_smith/src/timeutils/sidereal.dart';
import 'package:vector_math/vector_math.dart';
import 'package:duffett_smith/src/sun.dart' as sun;
import 'package:duffett_smith/src/moon.dart' as moon;

/// The 'standard' altitude in arc-degrees, i.e. geometric altitude of the
/// center of the body at the time of apparent rising and setting,
/// for stars and planets
const ALT_STD = 0.5667;

/// Standard altitude of the Sun
const ALT_SUN = 0.8333;

/// Mean altitude for Moon; for better accuracy use:
/// `0.7275 * parallax - 0.34`
const ALT_MOO = 0.125;

const STD_REFRACTION = 34.0 / 60;

/// Base class for exceptions in this module.
abstract class RiseSetException implements Exception {
  final String message;
  const RiseSetException(this.message);

  String errMsg() => message;

  @override
  String toString() => message;
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
enum RSEventType { Rise, Set }

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
/// [phi] is geographical latiude in arc-degrees. Optional [displacement] is
/// vertical displacement in arc-degrees, [ALT_STD] by default.
///
/// Caller receives results via [callback] function, which is called with
/// local sidereal times (hours) and azimuths (in arc-degrees) of rise and set.
void riseset(double alpha, double delta, double phi,
    {double displacement = ALT_STD,
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

/// Calculates rise and set of a fast moving body.
abstract class RiseSet {
  final _djd;
  final _phi;
  final _lng;

  RSEvent _riseEvent;
  RSEvent _setEvent;

  /// Constructor.
  RiseSet(this._djd, this._phi, this._lng);

  void lstRiseSet(double dj,
      {Function(double, double, double, double) callback,
      bool ignoreDisplacement = false}) {
    final t = dj / DAYS_PER_CENT;
    nutation(t, (dpsi, deps) {
      // obliquity
      final eps = obliquity(dj, deps: deps);
      _apparentPosition(dj, dpsi, (lambda, beta, delta) {
        ecl2equ(lambda, beta, eps, (alpha, delta) {
          final dis = ignoreDisplacement ? 0.0 : _getDisplacement();
          riseset(alpha / 15, delta, _phi,
              displacement: dis, callback: callback);
        });
      });
    });
  }

  double _lst2utc(double lst, double dj) {
    var utc;
    siderealToUTC(lst: lst, djd: dj, lng: _lng, callback: (ut, _) => utc = ut);
    return utc;
  }

  void _calculate() {
    final dj0 = djdMidnight(_djd);
    // rise and set for the noon
    final djNoon = dj0 + 0.5;
    lstRiseSet(djNoon, callback: (lstr, lsts, azr, azs) {
      _riseEvent = RSEvent(_lst2utc(lstr, djNoon), azr);
      _setEvent = RSEvent(_lst2utc(lsts, djNoon), azs);
    });
    _refineResult(dj0);
  }

  void _apparentPosition(
      double dj, double dpsi, Function(double, double, double) callback);

  double _getDisplacement();

  void _refineResult(double dj);

  /// Rise circumstances
  RSEvent get riseEvent {
    if (_riseEvent == null) {
      _calculate();
    }
    return _riseEvent;
  }

  /// Set circumstances
  RSEvent get setEvent {
    if (_setEvent == null) {
      _calculate();
    }
    return _setEvent;
  }
}

/// Rise / Set of the Moon
/// The result is exact within about 2 minutes.
class RiseSetMoon extends RiseSet {
  double _hp; // horizontal parallax

  RiseSetMoon(djd, phi, lng) : super(djd, phi, lng);

  @override
  void _apparentPosition(
      double dj, double dpsi, Function(double, double, double) callback) {
    moon.truePosition(dj, (lambda, beta, delta, hp, dm) {
      _hp = hp;
      callback(lambda + dpsi, beta, delta);
    });
  }

  @override
  double _getDisplacement() {
    // angular radius; assume sea-level
    final th = 2.7249e-1 * sin(radians(_hp));
    // account for refraction, angular radius and parallax
    return th + STD_REFRACTION - _hp;
  }

  @override
  void _refineResult(double dj) {
    for (var i = 0; i < 2; i++) {
      lstRiseSet(dj + _riseEvent.utc / 24, callback: (lstr, lsts, azr, _) {
        _riseEvent = RSEvent(_lst2utc(lstr, dj), azr);
        lstRiseSet(dj + _setEvent.utc / 24, callback: (lstr, lsts, _, azs) {
          _setEvent = RSEvent(_lst2utc(lsts, dj), azs);
        });
      });
    }
  }
}

/// Rise / Set of the Sun
class RiseSetSun extends RiseSet {
  RiseSetSun(djd, phi, lng) : super(djd, phi, lng);

  @override
  void _apparentPosition(
      double dj, double dpsi, Function(double, double, double) callback) {
    sun.trueGeocentric(dj / DAYS_PER_CENT, callback: (lsn, rsn) {
      // correct for nutation and aberration
      final lambda =
          sun.trueToApparent(lsn, dpsi, ignoreLightTravel: false, delta: rsn);
      callback(lambda, 0.0, rsn);
    });
  }

  @override
  double _getDisplacement() => ALT_SUN;

  @override
  void _refineResult(double dj) {
    lstRiseSet(dj + _riseEvent.utc / 24, callback: (lstr, lsts, azr, _) {
      _riseEvent = RSEvent(_lst2utc(lstr, dj), azr);
      lstRiseSet(dj + _setEvent.utc / 24, callback: (lstr, lsts, _, azs) {
        _setEvent = RSEvent(_lst2utc(lsts, dj), azs);
      });
    });
  }
}

class RiseSetPlanet extends RiseSet {
  final PlanetId planetId;
  Ephemeris ephemeris;

  RiseSetPlanet(this.planetId, djd, phi, lng, {this.ephemeris})
      : assert(ephemeris == null || ephemeris.apparent,
            'Apparent ephemeris expected!'),
        super(djd, phi, lng);

  @override
  void _apparentPosition(
      double dj, double dpsi, Function(double, double, double) callback) {
    ephemeris ??= Ephemeris(_djd, apparent: true);
    final pos = ephemeris.geocentricPosition(planetId);
    callback(pos.lambda, pos.beta, pos.delta);
  }

  @override
  double _getDisplacement() {
    return ALT_STD;
  }

  @override
  void _refineResult(double dj) {
    // Not required for the planets
  }
}
