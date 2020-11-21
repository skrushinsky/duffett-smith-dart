/// Kepler equation

import 'dart:math';

/// @nodoc
const _DLA_DELTA = 1e-7; // precision for Kepler equation

/// Solve Kepler equation to calculate [ea], the eccentric anomaly,
/// in elliptical motion given [s] `(< 1)`, the eccentricity,
/// and [m], mean anomaly in.
/// All agular values are in radians.
double kepler(double s, double m, [double ea]) {
  ea ??= m;
  var dla = ea - (s * sin(ea)) - m;
  if (dla.abs() < _DLA_DELTA) {
    return ea;
  }
  dla = dla / (1 - (s * cos(ea)));
  return kepler(s, m, ea - dla);
}

/// Given [s], eccentricity, and [ea], eccentric anomaly, find **true anomaly**.
/// All agular values are in radians.
double trueAnomaly(double s, double ea) {
  return 2 * atan(sqrt((1 + s) / (1 - s)) * tan(ea / 2));
}
