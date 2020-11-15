import 'dart:math';
import 'package:vector_math/vector_math.dart';

import './kepler.dart';
import 'planets/mercury.dart';
import 'planets/venus.dart';
import 'planets/mars.dart';
import 'planets/jupiter.dart';
import 'planets/saturn.dart';
import 'planets/uranus.dart';
import 'planets/neptune.dart';
import 'planets/pluto.dart';

import './orbit.dart';
import './pert.dart';
import '../mathutils.dart';

/// Planets identifiers
enum PlanetId {
  Sun,
  Moon,
  Mercury,
  Venus,
  Mars,
  Jupiter,
  Saturn,
  Uranus,
  Neptune,
  Pluto,
  LunarNode
}

///  Base class for the planets
abstract class Planet {
  /// Osculating elements of the orbit
  final OElements orbit;

  /// Planet identifier
  final PlanetId id;

  /// @nodoc
  static final Map<PlanetId, Planet> _cache = <PlanetId, Planet>{};

  /// Constructor
  Planet.create(this.id, this.orbit);

  factory Planet(PlanetId id) {
    if (_cache.containsKey(id)) {
      return _cache[id];
    }
    Planet pla;
    switch (id) {
      case PlanetId.Sun:
      case PlanetId.Moon:
      case PlanetId.LunarNode:
        break; // not handled in this module
      case PlanetId.Mercury:
        pla = Mercury();
        break;
      case PlanetId.Venus:
        pla = Venus();
        break;
      case PlanetId.Mars:
        pla = Mars();
        break;
      case PlanetId.Jupiter:
        pla = Jupiter();
        break;
      case PlanetId.Saturn:
        pla = Saturn();
        break;
      case PlanetId.Uranus:
        pla = Uranus();
        break;
      case PlanetId.Neptune:
        pla = Neptune();
        break;
      case PlanetId.Pluto:
        pla = Pluto();
        break;
    }
    _cache[id] = pla;
    return pla;
  }

  /// @nodoc
  static List<double> auxSun(double t) {
    final x = List<double>(6);
    x[0] = t / 5 + 0.1;
    x[1] = reduceRad(4.14473 + 5.29691e1 * t);
    x[2] = reduceRad(4.641118 + 2.132991e1 * t);
    x[3] = reduceRad(4.250177 + 7.478172 * t);
    x[4] = 5 * x[2] - 2 * x[1];
    x[5] = 2 * x[1] - 6 * x[2] + 3 * x[3];

    return x;
  }

  /// Return corrections for orbital elements.
  /// By default, each one is initialized to zero.
  ///
  /// [args] list contains arguments, which are different for each planet.
  /// All angular values in the arguments list and the result are in
  /// arc-degrees.
  Map<PertType, double> calculatePerturbations(List<double> args) {
    return {
      PertType.dl: 0.0,
      PertType.dr: 0.0,
      PertType.dml: 0.0,
      PertType.ds: 0.0,
      PertType.dm: 0.0,
      PertType.da: 0.0,
      PertType.dhl: 0.0
    };
  }

  /// Core part of heliocentric position calculation.
  /// [t] is iime in centuries since epoch 1900, 0.
  ///
  /// Named parameters are osculating elements of the obit instantiated for
  /// that moment:
  /// * [s] - Eccentricity
  /// * [sa] - Semiaxis
  /// * [ph] - perihelion
  /// * [nd] - Ascending node
  /// * [ic] - Inclination
  /// * [ma] - Mean Anomaly
  /// * [re] - Sun-Earth distance
  /// * [lg] - lonitude of the Earth
  ///
  /// [pertFunc] is closure function for calculating perturbations, returning
  /// Map<PertType, double>.

  Map<String, double> heliocentric(double t,
      {double s,
      double sa,
      double ph,
      double nd,
      double ic,
      double ma,
      double re,
      double lg,
      Function pertFunc}) {
    final pert = pertFunc();
    s += pert[PertType.ds]; // eccentricity corrected
    ma += pert[PertType.dm]; // mean anomaly corrected
    final ea = kepler(s, ma - PI2 * (ma / PI2).floor()); // eccentric anomaly
    final nu = trueAnomaly(s, ea); // true anomaly
    final rp = (sa + pert[PertType.da]) * (1 - s * s) / (1 + s * cos(nu)) +
        pert[PertType.dr]; // radius-vector
    final lp = nu +
        ph +
        (pert[PertType.dml] - pert[PertType.dm]); // planet's orbital longitude
    final lo = lp - nd;
    final sin_lo = sin(lo);
    final spsi = sin_lo * sin(ic);
    final y = sin_lo * cos(ic);
    final psi = asin(spsi) + pert[PertType.dhl]; // heliocentric latitude
    final lpd = atan2(y, cos(lo)) + nd + radians(pert[PertType.dl]);
    final cpsi = cos(psi);
    final ll = lpd - lg;
    final rho = sqrt(re * re +
        rp * rp -
        2 * re * rp * cpsi * cos(ll)); // distance from the Earth

    return {
      'll': ll,
      'rpd': rp * cpsi,
      'lpd': lpd,
      'spsi': sin(psi), // not the same as spsi, for psi is corrected
      'cpsi': cpsi,
      'rho': rho
    };
  }

  /// @nodoc
  /// Calculate geocentric coordinates.
  List<double> geocentric(
      {double lg,
      double rsn,
      double lpd,
      double rpd,
      double cpsi,
      double spsi,
      double ll,
      bool apparent,
      double dpsi}) {
    // Geocentric
    final sll = sin(ll);
    final cll = cos(ll);

    var lam; // geocentric ecliptic longitude
    if (id == PlanetId.Mercury || id == PlanetId.Venus) {
      // inner planets
      lam = atan2(-1 * rpd * sll, rsn - rpd * cll) + lg + pi;
    } else {
      // outer planets
      lam = atan2(rsn * sll, rpd - rsn * cll) + lpd;
    }
    // geocentric latitude
    var bet = atan(rpd * spsi * sin(lam - lpd) / (cpsi * rsn * sll));

    if (apparent) {
      lam += dpsi; // nutation
      // aberration
      final a = lg + pi - lam;
      final ca = cos(a);
      final sa = sin(a);
      lam -= (9.9387e-5 * ca / cos(bet));
      bet -= (9.9387e-5 * sa * sin(bet));
    }
    lam = reduceRad(lam);

    return [degrees(lam), degrees(bet)];
  }
}
