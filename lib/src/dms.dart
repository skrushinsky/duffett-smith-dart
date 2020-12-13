import 'package:sprintf/sprintf.dart';
import './mathutils.dart';

/// Degrees, minutes, seconds
class DMS {
  final int _d;
  final int _m;
  final double _s;

  const DMS(this._d, this._m, this._s);

  factory DMS.fromDecimal(double x) {
    return _initVals(x);
  }

  static DMS _initVals(double x, {List vals, int count = 0}) {
    vals ??= List(3);
    if (count < 3) {
      modf(x, (f, i) {
        if (i != 0 && f < 0) {
          f = -f;
        }
        vals[count] = count < 2 ? i : x;
        return _initVals(f * 60.0, vals: vals, count: count + 1);
      });
    }
    return DMS(vals[0], vals[1], vals[2]);
  }

  /// Arc-degrees
  int get d => _d;

  /// Arc-minutes
  int get m => _m;

  /// Arc-seconds
  double get s => _s;
}

String formatHMS(DMS dms) {
  return sprintf('%02d:%02d:%04.1f', [dms.d, dms.m, dms.s]);
}
