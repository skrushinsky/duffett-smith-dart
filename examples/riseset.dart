import 'dart:io';
import 'package:args/args.dart';
import 'package:duffett_smith/mathutils.dart';
import 'package:duffett_smith/misc.dart';
import 'package:duffett_smith/timeutils.dart';
import 'package:duffett_smith/riseset.dart';

double geoLat;
double geoLon;

String getUsage(parser) {
  return '''
Rise and set of Sun, Moon and the 8 planets.

riseset [OPTIONS] [DATETIME] [PLACE] 

OPTIONS

${parser.usage}

DATETIME format is a subset of ISO 8601 which includes the subset accepted by 
RFC 3339, e.g.:

"2012-02-27 13:27:00"
"2012-02-27T13:27:00"         same as the above
"2012-02-27"                  midnight
"2012-02-27T13:27:00Z"        UTC+0
"2002-02-27T14:00:00-0500"    UTC-5h time zone
"2002-02-27T14:00:00 -05:00"  same as the above
"-123450101 00:00:00 Z"       in the year -12345.

The date must be in range from 271821-04-20 BC to 275760-09-13 AD
If omitted, current date and time will be used.

Example:
riseset --datetime="1965-02-01 11:46" --place="55N45 37E35"

''';
}

void main(List<String> arguments) {
  exitCode = 0;
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h',
        negatable: false,
        defaultsTo: false,
        help: 'Displays this help information')
    ..addOption('time',
        abbr: 't',
        defaultsTo: DateTime.now().toIso8601String(),
        help: 'Date and time, current moment by default')
    ..addOption('place',
        abbr: 'p',
        defaultsTo: '51N28 0W0',
        help: 'Geographical coordinates, Greenwich by default');

  try {
    final argResults = parser.parse(arguments);
    if (argResults['help']) {
      print(getUsage(parser));
      exit(exitCode);
    }

    var utc = DateTime.parse(argResults['time']);
    if (!utc.isUtc) {
      utc = utc.toUtc();
    }
    print('UTC: ${utc.toString()}');

    parseGeoCoords(argResults['place'], (lat, lon) {
      geoLat = lat;
      geoLon = lon;
    });
    print('Lat.: ${geoLat}');
    print('Lon.: ${geoLon}');

    final hm = ddd(utc.hour, utc.minute, utc.second.toDouble());
    final djd = julDay(utc.year, utc.month, utc.day + hm / 24);
  } catch (e) {
    print(e);
    exitCode = 1;
  }
}
