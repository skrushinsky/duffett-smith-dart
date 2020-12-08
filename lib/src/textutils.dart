import 'package:duffett_smith/mathutils.dart';

final latRe = RegExp(r'^\d+[NS]\d+$', caseSensitive: false);
final lonRe = RegExp(r'^\d+[WE]\d+$', caseSensitive: false);
final captureRe = RegExp(r'^(\d+)([SENW])(\d+)$', caseSensitive: false);

/// Base class for exceptions in this module.
class GeoFormatException implements Exception {
  final String message;
  const GeoFormatException(this.message);
  String errMsg() => message;
}

double transformCoords(String s) {
  final match = captureRe.firstMatch(s);
  final d = int.parse(match.group(1));
  final m = int.parse(match.group(3));
  var x = ddd(d, m);
  if (['S', 's', 'E', 'e'].contains(match.group(2))) {
    x = -x;
  }
  return x;
}

void parseGeoCoords(String s, Function(double, double) callback) {
  final vals = s.split(RegExp(r'\s+|\s*,\s*'));
  if (vals.length != 2) {
    throw GeoFormatException('Unsupported geo-coordinates format:: ${s}');
  }
  var lat, lon;
  if (latRe.hasMatch(vals[0]) && lonRe.hasMatch(vals[1])) {
    lat = transformCoords(vals[0]);
    lon = transformCoords(vals[1]);
  } else if (lonRe.hasMatch(vals[0]) && latRe.hasMatch(vals[1])) {
    lat = transformCoords(vals[1]);
    lon = transformCoords(vals[0]);
  } else {
    throw GeoFormatException('Unsupported geo-coordinates format:: ${s}');
  }
  callback(lat, lon);
}
