/// Osculating orbital elements
import '../mathutils.dart';

/// Orbital terms
class Terms {
  final List<double> _terms;

  /// Constructor
  const Terms(this._terms);

  /// Osculating [terms] of the orbit
  List<double> get terms => _terms;

  /// Instaniate osculating elements for moment [t], centuries
  /// passed since the epoch 1900,0
  double assemble(double t) => reduceDeg(polynome(t, terms));
}

/// Mean Lonitude, a special case of Terms
class MLTerms extends Terms {
  /// Constructor
  MLTerms(List<double> terms) : super(makeFour(terms));

  static List<double> makeFour(List<double> terms) {
    final four = List<double>.filled(4, 0.0, growable: false);
    for (var i = 0; i < terms.length; i++) {
      four[i] = terms[i];
    }
    return four;
  }

  /// The mean longitude increases by 360 deg. for every rotation of the PlanetId
  /// about the Sun. In order to preserve accuracy, it is is expressed in such
  /// a manner that integer rotations are subtracted from the second term of the
  /// expression  before adding the other terms.
  @override
  double assemble(double t) {
    final b = frac360(terms[1] * t);
    return reduceDeg(terms[0] + b + (terms[3] * t + terms[2]) * t * t);
  }
}

/// Osculating elements of an orbit
class OElements {
  MLTerms ML; // mean longitude
  Terms PH; // argument of perihelion
  Terms EC; // eccentricity
  Terms IN; // inclination
  Terms ND; // ascending node
  double SA; // major semi-axis
  double DI; // angular diameter at 1 AU
  double MG; // magnitude
  double _DM; // mean daily motion

  /// Mean Daily motion
  double get DM {
    _DM ??= ML.terms[1] * 9.856263e-3 + (ML.terms[2] + ML.terms[3]) / 36525;
    return _DM;
  }

  /// Given [t], time in centuries from epoch 1900.0,
  /// calculate Mean Anomaly in arc-degrees.
  double meanAnomaly(double t) => reduceDeg(ML.assemble(t) - PH.assemble(t));
}
