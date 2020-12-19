import 'dart:io';
import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:ansicolor/ansicolor.dart';

import 'package:sprintf/sprintf.dart';
import 'package:duffett_smith/mathutils.dart';
import 'package:duffett_smith/ephemeris.dart';
import 'package:duffett_smith/timeutils.dart';
import 'package:duffett_smith/riseset.dart';
import 'package:duffett_smith/misc.dart';

const bodies = {
  'SU': PlanetId.Sun,
  'MO': PlanetId.Moon,
  'ME': PlanetId.Mercury,
  'VE': PlanetId.Venus,
  'MA': PlanetId.Mars,
  'JU': PlanetId.Jupiter,
  'SA': PlanetId.Saturn,
  'UR': PlanetId.Uranus,
  'NE': PlanetId.Neptune,
  'PL': PlanetId.Pluto
};

final dateFormat = DateFormat('yyyy MMM dd');
final timeFormat = DateFormat('HH:mm');

DMS geoLat;
DMS geoLon;

String getUsage(parser) {
  return '''
Rise and set of celestial objects.

riseset [OPTIONS] [DATE] [PLACE]

${parser.usage}

Example:
riseset --object=MO --date="1965-02-01" --geo=55N45,37E35 --theme=dark

''';
}

String describeDateFormat() {
  return '''

DATE format is "YYYY-MM-DD, e.g: "2012-02-27". 
The date must be in range from 1 AD to 275760-09-13 AD.
''';
}

String describeGeoFormat() {
  return '''

PLACE is represented by a pair of geographic coordinates, 
space or comma separated, in any order e.g.:

40N43,73W59
"40N43, 73W59"
"40N43 73W59"
"40n43 73w59"
"73W59 40n43"

"55N45,37E58"  Moscow
"037e35 55n45"

Please, note: space-separated coordinates must be surrounded by double quotes.
  ''';
}

DateTime buildEventDate(int year, int month, int day, double hours) {
  final hms = DMS.fromDecimal(hours);
  return DateTime.utc(year, month, day, hms.d, hms.m, hms.s.truncate())
      .toLocal();
}

void displayHeader(Theme theme, String text) {
  print(theme.headingPen(text));
}

void displayError(Theme theme, String text) {
  print(theme.errorPen(text));
}

void displayTitleAndData(Theme theme, String title, String data) {
  print(theme.titlePen(sprintf('%-10s:', [title])) +
      theme.dataPen(sprintf(' %s', [data])));
}

void main(List<String> arguments) {
  exitCode = 0;
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h',
        negatable: false,
        defaultsTo: false,
        help: 'Displays this help information')
    ..addFlag('help-date',
        negatable: false, defaultsTo: false, help: 'Describe date format')
    ..addFlag('help-geo',
        negatable: false,
        defaultsTo: false,
        help: 'Describe geo-coordinates format')
    ..addOption('object',
        abbr: 'o',
        allowed: ['SU', 'MO', 'VE', 'ME', 'MA', 'JU', 'SA', 'UR', 'NE', 'PL'],
        defaultsTo: 'SU',
        help: 'Celestial body',
        allowedHelp: {
          'SU': 'Sun',
          'MO': 'Moon',
          'ME': 'Mercury',
          'VE': 'Venus',
          'MA': 'Mars',
          'JU': 'Jupiter',
          'SA': 'Saturn',
          'UR': 'Uranus',
          'NE': 'Neptune',
          'PL': 'Pluto'
        })
    ..addOption('date',
        abbr: 'd', defaultsTo: 'current local date', help: 'Date')
    ..addOption('geo',
        abbr: 'p', defaultsTo: 'Greenwich', help: 'Geographical coordinates')
    ..addOption('theme',
        allowed: ['dark', 'light', 'disabled'],
        defaultsTo: 'disabled',
        help: 'Color theme',
        allowedHelp: {
          'dark': 'light colors on dark background',
          'light': 'dark colors on white background',
          'disabled': 'disable colors'
        });

  try {
    final argResults = parser.parse(arguments);
    if (argResults['help']) {
      print(getUsage(parser));
      exit(exitCode);
    }
    if (argResults['help-date']) {
      print(describeDateFormat());
      exit(exitCode);
    }
    if (argResults['help-geo']) {
      print(describeGeoFormat());
      exit(exitCode);
    }

    var theme;
    if (argResults['theme'] == 'disabled') {
      ansiColorDisabled = true;
      theme = Theme.createDefault();
    } else {
      ansiColorDisabled = false;
      theme = Theme.create(argResults['theme']);
    }

    print('');
    final date = argResults['date'] != 'current local date'
        ? DateTime.parse(argResults['date']).toLocal()
        : DateTime.now();
    final timeZone = date.timeZoneName;
    displayTitleAndData(theme, 'Date', dateFormat.format(date));

    final geo =
        argResults['geo'] == 'Greenwich' ? '51N28,0W0' : argResults['geo'];
    parseGeoCoords(geo, (lat, lon) {
      geoLat = lat;
      geoLon = lon;
      displayTitleAndData(
          theme, 'Place', '${formatGeoLat(geoLat)}, ${formatGeoLon(geoLon)}');
    });

    print('');

    final djd = julDay(date.year, date.month, date.day + 0.5);
    final eph = Ephemeris(djd, apparent: true);

    RiseSet rs;
    var name;
    final la = geoLat.toDecimal();
    final lo = geoLon.toDecimal();
    final id = bodies[argResults['object']];
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

    final displayEvent = (title) {
      displayHeader(theme, '$name $title');
      try {
        final evt = title == 'Rise' ? rs.riseEvent : rs.setEvent;
        calDay(djd, (ye, mo, da) {
          final d = buildEventDate(ye, mo, da.truncate(), evt.utc);
          displayTitleAndData(
              theme, 'Time', '${timeFormat.format(d)} $timeZone');
          displayTitleAndData(
              theme, 'Azimuth', format360(DMS.fromDecimal(evt.azimuth)));
        });
      } catch (e) {
        displayError(theme, e.toString());
      }
    };

    displayEvent('Rise');
    print('');
    displayEvent('Set');
  } catch (e) {
    print(e);
    exitCode = 1;
  }
}
