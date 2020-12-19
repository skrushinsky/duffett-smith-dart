import 'package:duffett_smith/mathutils.dart';
import 'package:sprintf/sprintf.dart';

final latRe = RegExp(r'^\d+[NS]\d+$', caseSensitive: false);
final lonRe = RegExp(r'^\d+[WE]\d+$', caseSensitive: false);
final captureRe = RegExp(r'^(\d+)([SENW])(\d+)$', caseSensitive: false);

/// Base class for exceptions in this module.
class GeoFormatException implements Exception {
  final String message;
  const GeoFormatException(this.message);
  String errMsg() => message;
  @override
  String toString() => message;
}

DMS transformCoords(String s) {
  final match = captureRe.firstMatch(s);
  var d = int.parse(match.group(1));
  var m = int.parse(match.group(3));
  final p = match.group(2).toUpperCase();
  if (p == 'S' || p == 'E') {
    if (d != 0) {
      d = -d;
    } else if (m != 0) {
      m = -m;
    }
  }
  return DMS(d, m, 0);
}

void parseGeoCoords(String s, Function(DMS, DMS) callback) {
  final vals = s.split(RegExp(r'\s+|\s*,\s*'));
  if (vals.length != 2) {
    throw GeoFormatException('Unsupported geo-coordinates format: ${s}');
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

String formatGeoLat(DMS dms) => sprintf('%02d%s%02d', [
      dms.d.abs(),
      dms.d < 0 || dms.m < 0 || dms.s < 0 ? 'S' : 'N',
      dms.m.abs()
    ]);

String formatGeoLon(DMS dms) => sprintf('%03d%s%02d', [
      dms.d.abs(),
      dms.d < 0 || dms.m < 0 || dms.s < 0 ? 'E' : 'W',
      dms.m.abs()
    ]);

String format360(DMS dms) => sprintf('%03d:%02d', [dms.d, dms.m]);

extension StringExtension on String {
  String truncateTo(int maxLenght) =>
      // ignore: unnecessary_this
      (this.length <= maxLenght) ? this : '${this.substring(0, maxLenght)}...';
}
