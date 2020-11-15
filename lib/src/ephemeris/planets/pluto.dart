import '../orbit.dart';
import '../planets.dart';

/// Pluto
class Pluto extends Planet {
  Pluto() : super.create(PlanetId.Pluto, buildOrbit());

  /// Initialize osculating elements of the planet's orbit
  static OElements buildOrbit() {
    final oe = OElements();
    oe.ML = MLTerms([95.3113544, 3.980332167e-1]);
    oe.PH = Terms([224.017]);
    oe.EC = Terms([2.5515e-1]);
    oe.IN = Terms([17.1329]);
    oe.ND = Terms([110.191]);
    oe.SA = 39.8151;
    oe.DI = 8.2;
    oe.MG = -1.0;
    return oe;
  }

  @override
  String toString() {
    return 'Pluto';
  }
}
