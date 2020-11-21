import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

import 'mathutils.dart';
import 'sun.dart' as sun;
import 'moon.dart' as moon;
import 'ephemeris/planets.dart';
import 'ephemeris/nutation.dart';
import 'ephemeris/obliquity.dart';
import 'ephemeris/pert.dart';

/// Ecliptic posiion of a celestial body
///
/// * [lambda] : geocentric ecliptic longitude, arc-degrees
/// * [beta]: geocentric ecliptic latitude, arc-degrees
/// * [delta] : distance from the Earth, A
class EclipticPosition {
  final double lambda;
  final double beta;
  final double delta;

  /// Constructor
  const EclipticPosition(this.lambda, this.beta, this.delta);
}

class Ephemeris {
  final _djd; // days since Jan 1900, 0
  double _t; // time in centuries since Jan 1900, 0
  double _ms; // Sun mean anomaly in arc-degrees

  double _dpsi; // nutation in longitude, arc-degrees
  double _deps; // nutation in eclipic obliquity, arc-degrees
  double _eps; // obliquity of the elipic, arc-degrees
  double _lsn; // longitude of Sun, arc-degrees
  double _rsn; // Sun-Earth distance, AU

  bool _apparent;
  bool _trueNode;

  final Map<PlanetId, EclipticPosition> _positions = {};
  final Map<PlanetId, double> _dailyMotions = {};
  final Map<PlanetId, double> _meanAnomalies = {};
  final Map<PlanetId, double> _eccentricities = {};

  Ephemeris _prev;
  Ephemeris _next;

  // _positions = Map();

  Ephemeris(this._djd, {bool apparent = false, bool trueNode = true}) {
    _trueNode = trueNode;
    _apparent = apparent;
    _t = _djd / 36525;
    nutation(_t, (dpsi, deps) {
      _dpsi = dpsi;
      _deps = deps;
      _eps = obliquity(djd, deps: _deps);
      _ms = sun.meanAnomaly(_t);
      sun.trueGeocentric(_t, ms: _ms, callback: (tmp_lsn, tmp_rsn) {
        _lsn = tmp_lsn;
        _rsn = tmp_rsn;
      });
    });

    // Pre-calculate mean anomalies
  }

  /// Days from Jan 0.5 1900
  double get djd => _djd;

  /// Centuries from Jan 0.5 1900
  double get t => _t;

  ///  Apparent flag
  bool get apparent => _apparent;

  /// True Node flag
  bool get trueNode => _trueNode;

  /// Sun mean anomaly
  double get ms => _ms;

  /// Getter for Delta-Psi
  double get dpsi => _dpsi;

  /// Nutation in obliquity, arc-degrees
  double get deps => _deps;

  /// Obliquity of the ecliptic, arc-degrees
  double get eps => _eps;

  /// Longitude of the Sun, arc-degrees
  double get lsn => _lsn;

  /// DSun-Earth distance (AU)
  double get rsn => _rsn;

  /// Ephemeris instance 12h before
  Ephemeris get prev {
    _prev ??= Ephemeris(_djd - 0.5, apparent: _apparent, trueNode: _trueNode);
    return _prev;
  }

  /// Ephemeris instance 12h ahead
  Ephemeris get next {
    _next ??= Ephemeris(_djd + 0.5, apparent: _apparent, trueNode: _trueNode);
    return _next;
  }

  EclipticPosition _calculateSun() {
    var x = lsn;
    if (apparent) {
      // nutation and aberration
      x = lsn + dpsi - 5.69e-3;
      // XXX: Peter Duffett-Smith does not menion light-time travel correction
      // in case of the Sun.
      // // light travel
      // final lt = 1.365 * rsn; // seconds
      // x -= lt * 15 / 3600;
      x = reduceDeg(x);
    }
    return EclipticPosition(x, 0.0, rsn);
  }

  EclipticPosition _calculateMoon() {
    var pos;
    moon.truePosition(djd, (lambda, beta, delta, hp, dm) {
      if (apparent) {
        lambda = reduceDeg(lambda + dpsi);
      }
      pos = EclipticPosition(lambda, beta, delta);
      _dailyMotions[PlanetId.Moon] = dm;
    });
    return pos;
  }

  /// Mean Anomaly of a planet [pla] in radians.
  /// Once calculated, it is saved in a cache.
  /// [dt] named parameter is a time corection necessary when calculating *true*
  /// (light-time corrected) planetary positions.
  double meanAnomaly(Planet pla, {dt = 0}) {
    var ma;

    if (_meanAnomalies.containsKey(pla.id)) {
      ma = _meanAnomalies[pla.id];
    } else {
      ma = radians(pla.orbit.meanAnomaly(t));
      _meanAnomalies[pla.id] = ma;
    }
    return ma - radians(dt * pla.orbit.DM);
  }

  /// Eccentricity of a planet [pla].
  /// Once calculated, it is saved in a cache.
  double eccentricity(Planet pla) {
    var ec;
    if (_eccentricities.containsKey(pla.id)) {
      ec = _meanAnomalies[pla.id];
    } else {
      ec = pla.orbit.EC.assemble(t);
      _eccentricities[pla.id] = ec;
    }
    return ec;
  }

  Map<String, double> _planetHelio(pla,
      {lg: double,
      double s,
      double sa,
      double ph,
      double nd,
      double ic,
      double dt = 0.0}) {
    final m = meanAnomaly(pla, dt: dt);
    Map<PertType, double> Function() calcPert;
    switch (pla.id) {
      case PlanetId.Mercury:
        calcPert = () {
          final ve = meanAnomaly(Planet(PlanetId.Venus), dt: dt);
          final ju = meanAnomaly(Planet(PlanetId.Jupiter), dt: dt);
          return pla.calculatePerturbations([m, ve, ju]);
        };
        break;
      case PlanetId.Venus:
        calcPert = () {
          final ju = meanAnomaly(Planet(PlanetId.Jupiter), dt: dt);
          final sm = radians(ms); // Sun, radians
          return pla.calculatePerturbations([t, sm, m, ju]);
        };
        break;
      case PlanetId.Mars:
        calcPert = () {
          final ve = meanAnomaly(Planet(PlanetId.Venus), dt: dt);
          final ju = meanAnomaly(Planet(PlanetId.Jupiter), dt: dt);
          final sm = radians(ms); // Sun, radians
          return pla.calculatePerturbations([sm, ve, m, ju]);
        };
        break;
      case PlanetId.Pluto:
        calcPert = () {
          return pla.calculatePerturbations(<double>[]);
        };
        break;
      default:
        calcPert = () {
          return pla.calculatePerturbations([t, s]);
        };
        break;
    }

    return pla.heliocentric(t,
        s: s,
        sa: sa,
        ph: ph,
        nd: nd,
        ic: ic,
        ma: m,
        re: rsn,
        lg: lg,
        pertFunc: calcPert);
  }

  EclipticPosition _calculatePlanet(PlanetId id) {
    final pla = Planet(id);

    final lg = radians(lsn) + pi;
    final s = eccentricity(pla);

    final sa = pla.orbit.SA;
    final ph = radians(pla.orbit.PH.assemble(t));
    final nd = radians(pla.orbit.ND.assemble(t));
    final ic = radians(pla.orbit.IN.assemble(t));

    final h1 = _planetHelio(pla, lg: lg, s: s, sa: sa, ph: ph, nd: nd, ic: ic);
    final h2 = _planetHelio(pla,
        lg: lg,
        s: s,
        sa: sa,
        ph: ph,
        nd: nd,
        ic: ic,
        dt: h1['rho'] * 5.775518e-3);

// ll, rpd, lpd, sin(psi), cpsi, rho

    final geo = pla.geocentric(
        lg: lg,
        rsn: rsn,
        lpd: h2['lpd'],
        rpd: h2['rpd'],
        cpsi: h2['cpsi'],
        spsi: h2['spsi'],
        ll: h2['ll'],
        apparent: apparent,
        dpsi: dpsi);

    return EclipticPosition(geo[0], geo[1], h1['rho']);
  }

  /// Given a planet id, return its geocentric ecliptic position.
  ///
  /// Latitide and longitude are corrected for light time.
  /// These are the apparent values as seen from the center of the Earth
  /// at the given instant. If Ephemeris instance 'apparent' flag is set
  /// to 'true' (default), then corrections for nutation and aberration
  /// are also applied.
  EclipticPosition geocentricPosition(PlanetId id) {
    if (_positions.containsKey(id)) {
      return _positions[id];
    }

    var pos;
    switch (id) {
      case PlanetId.Sun:
        pos = _calculateSun();
        break;
      case PlanetId.Moon:
        pos = _calculateMoon();
        break;
      case PlanetId.LunarNode:
        pos =
            EclipticPosition(moon.lunarNode(djd, trueNode: trueNode), 0.0, 0.0);
        break;
      default:
        pos = _calculatePlanet(id);
    }

    _positions[id] = pos;
    return pos;
  }

  /// Daily motion of a celestial body, arc-deg
  double dailyMotion(PlanetId id) {
    if (_dailyMotions.containsKey(id)) {
      return _dailyMotions[id];
    }

    if (id == PlanetId.Moon) {
      geocentricPosition(id);
      return dailyMotion(id);
    }

    final x0 = prev.geocentricPosition(id).lambda;
    final x1 = next.geocentricPosition(id).lambda;
    return x1 - x0;
  }
}
