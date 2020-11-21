import 'dart:math';
import 'package:vector_math/vector_math.dart';
import 'package:duffett_smith/mathutils.dart';
import 'package:duffett_smith/src/sun.dart';

enum SolEquType {
  MarchEquinox,
  JuneSolstice,
  SeptemberEquinox,
  DecemberSolstice
}

/// Solstice/quinox event circumstances
class SolEquEvent {
  final _djd;
  final _lambda;

  const SolEquEvent(this._djd, this._lambda);

  /// Number of Julian days since 1900 Jan. 0.5
  double get djd => _djd;

  /// Apparent longitude of the Sun, arc-degrees
  double get lambda => _lambda;
}

/// Find time of solstice or equinox for a given year.
/// The result is accurate within 5 minutes of Universal Time.
SolEquEvent solEqu(int year, SolEquType type) {
  var k;
  switch (type) {
    case SolEquType.MarchEquinox:
      k = 0;
      break;
    case SolEquType.JuneSolstice:
      k = 1;
      break;
    case SolEquType.SeptemberEquinox:
      k = 2;
      break;
    case SolEquType.DecemberSolstice:
      k = 3;
  }
  final k90 = k * 90.0;
  var dj = (year + k / 4.0) * 365.2422 - 693878.7; // shorter but less exact way
  var x;
  do {
    apparent(dj, ignoreLightTravel: true, callback: (lambda, _) {
      x = lambda;
      dj += 58.0 * sin(radians(k90 - x));
    });
  } while (shortestArc(k90, x) >= 1e-6);
  return SolEquEvent(dj, x);
}
