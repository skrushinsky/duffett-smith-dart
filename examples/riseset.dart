import 'dart:io';
import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'package:duffett_smith/mathutils.dart';
import 'package:duffett_smith/misc.dart';
import 'package:duffett_smith/src/ephemeris.dart';
import 'package:duffett_smith/src/ephemeris/planets.dart';
import 'package:duffett_smith/timeutils.dart';
import 'package:duffett_smith/riseset.dart';

const bodies = [
  PlanetId.Sun,
  PlanetId.Moon,
  PlanetId.Mercury,
  PlanetId.Venus,
  PlanetId.Mars,
  PlanetId.Jupiter,
  PlanetId.Saturn,
  PlanetId.Uranus,
  PlanetId.Neptune,
  PlanetId.Pluto
];

DMS geoLat;
DMS geoLon;

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

PLACE is a pair of geographic coordinates, space or comma separated, in any
order e.g.:

"40N43 73W59"  New-York
"40N43,73W59"
"40n43 73w59"
"73W59 40N43"

"55N45,37E58"  Moscow
"037e35 55n45"

Example:
riseset --datetime="1965-02-01 11:46" --place="55N45 37E35"

''';
}

DateTime buildEventDate(int year, int month, int day, double hours) {
  final hms = DMS.fromDecimal(hours);
  return DateTime.utc(year, month, day, hms.d, hms.m, hms.s.truncate())
      .toLocal();
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
    final dateTimeFormat = DateFormat("y MMM dd',' HH:mm 'UTC'");
    final timeFormat = DateFormat('HH:mm:ss');

    final argResults = parser.parse(arguments);
    if (argResults['help']) {
      print(getUsage(parser));
      exit(exitCode);
    }
    print('');
    var utc = DateTime.parse(argResults['time']);
    if (!utc.isUtc) {
      utc = utc.toUtc();
    }
    print(dateTimeFormat.format(utc));

    parseGeoCoords(argResults['place'], (lat, lon) {
      geoLat = lat;
      geoLon = lon;
      print('${formatGeoLat(geoLat)}, ${formatGeoLon(geoLon)}');
    });

    print('');

    final hm = ddd(utc.hour, utc.minute, utc.second.toDouble());
    final djd = julDay(utc.year, utc.month, utc.day + hm / 24);
    final eph = Ephemeris(djd, apparent: true);

    RiseSet rs;
    var name;
    final la = geoLat.toDecimal();
    final lo = geoLon.toDecimal();
    print('             Rise (time, az.)      Set (time, az.)       ');
    //print('             HH:MM:SS   Az.        HH:MM:SS   Az.      ');
    print('_' * 54);
    print('');
    bodies.forEach((id) {
      switch (id) {
        case PlanetId.Sun:
          name = 'Sun';
          rs = RiseSetSun(djd, la, lo);
          break;
        case PlanetId.Moon:
          name = 'Moon';
          rs = RiseSetMoon(djd, la, lo);
          break;
        default:
          // planets
          name = Planet(id).toString();
          rs = RiseSetPlanet(id, djd, la, lo, ephemeris: eph);
          break;
      }
      // final sName = name.padRight(8);
      final r = buildEventDate(utc.year, utc.month, utc.day, rs.riseEvent.utc);
      final s = buildEventDate(utc.year, utc.month, utc.day, rs.setEvent.utc);
      print(sprintf('%-8s  |  %s   %s  |  %s   %s   ', [
        name,
        timeFormat.format(r),
        format360(DMS.fromDecimal(rs.riseEvent.azimuth)),
        timeFormat.format(s),
        format360(DMS.fromDecimal(rs.setEvent.azimuth))
      ]));

      //print(sprintf())
    });
  } catch (e) {
    print(e);
    exitCode = 1;
  }
}
