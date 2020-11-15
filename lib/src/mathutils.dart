import 'dart:math';

/// `2 * PI`
final PI2 = pi * 2;

/// Decompose a floating-point number [x].
/// The result always keeps sign of the argument, e.g.:
/// `modf(-5.5)` will produce `-0.5, -5.0`
///
/// Example:
/// `modf(3.1452)`  `[0.1452, 3.0]`
void modf(double x, Function(double, int) callback) {
  final i = x.truncate();
  if (callback != null) {
    callback(x - i, i);
  }
}

/// Calculates polynome: `a1 + a2*t + a3*t*t + a4*t*t*t...`
/// [t] s a number of Julian centuries elapsed since 1900, Jan 0.5
/// [terms] is a list of coefficients
/// Example `polynome(10.0, 1.0, 2.0, 3.0)` gives `321.0`.
double polynome(double t, List<double> terms) {
  final rev = List.from(terms.reversed);
  return rev.reduce((a, b) => a * t + b);
}

///  Reduces [x] to 0 >= x < [r]
double toRange(double x, double r) {
  final a = x % r;
  return a < 0 ? a + r : a;
}

/// Reduces x to `0 >= x < 360`
double reduceDeg(double x) => toRange(x, 360.0);

/// Reduces x to `0 >= x <  PI * 2`
double reduceRad(double x) => toRange(x, PI2);

/// Fractional part of [x].
/// The result always keeps sign of the argument, e.g.: `frac(-5.5) = -0.5`
double frac(double x) {
  var res = x.abs() % 1.0;
  return x < 0 ? -res : res;
}

/// Used with polinomial function for better accuracy.
double frac360(double x) => frac(x) * 360;

/// Given hours (or degrees), minutes and seconds,
/// return decimal hours (or degrees). In the case of hours (angles) < 0.
double ddd(int d, int m, [double s = 0]) {
  final sgn = d < 0 || m < 0 || s < 0 ? -1 : 1;
  return (d.abs() + (m.abs() + s.abs() / 60.0) / 60.0) * sgn;
}
