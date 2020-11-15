import 'package:test/test.dart';
import 'package:duffett_smith/coco.dart';
import 'package:duffett_smith/mathutils.dart';

const DELTA = 1E-4; // result precision

final EQUECL = [
  {
    'ob': 23.44574451788568,
    'ra': ddd(14, 26, 57) * 15,
    'de': ddd(32, 21, 5),
    'lo': ddd(200, 19, 6.66),
    'la': ddd(43, 47, 13.83)
  },
  {
    'ob': 23.43871898795463,
    'ra': ddd(0, 0, 5.5) * 15,
    'de': ddd(-87, 12, 12),
    'lo': ddd(277, 0, 6.26),
    'la': ddd(-66, 24, 19.75)
  }
];

final EQUHOR = [
  {
    'gl': ddd(51, 15, 0),
    'ha': ddd(8, 37, 20),
    'de': ddd(14, 23, 55),
    'az': ddd(310, 15, 33.6),
    'al': ddd(-10, 58, 20.8)
  },
  {
    'gl': ddd(-20, 31, 13),
    'ha': ddd(23, 19, 0),
    'de': ddd(-43, 0, 0),
    'az': ddd(161, 23, 19),
    'al': ddd(65, 56, 6.1)
  }
];

void main() {
  group('Equatorial -> Eclipical', () {
    for (var c in EQUECL) {
      equ2ecl(c['ra'], c['de'], c['ob'], (lo, la) {
        test('Lambda for ${c['ra']}, ${c['de']}',
            () => expect(lo, closeTo(c['lo'], DELTA)));
        test('Beta for ${c['ra']}, ${c['de']}',
            () => expect(la, closeTo(c['la'], DELTA)));
      });
    }
  });

  group('Eclipical -> Equatorial', () {
    for (var c in EQUECL) {
      ecl2equ(c['lo'], c['la'], c['ob'], (ra, de) {
        test('Alpha for ${c['lo']}, ${c['la']}',
            () => expect(ra, closeTo(c['ra'], DELTA)));
        test('Delta for ${c['lo']}, ${c['la']}',
            () => expect(de, closeTo(c['de'], DELTA)));
      });
    }
  });

  group('Equatorial -> Horizontal', () {
    for (var c in EQUHOR) {
      equ2hor(c['ha'] * 15, c['de'], c['gl'], (az, al) {
        test('Azimuth for ${c['ha']}, ${c['de']}',
            () => expect(az, closeTo(c['az'], DELTA)));
        test('Altitude for ${c['ha']}, ${c['de']}',
            () => expect(al, closeTo(c['al'], DELTA)));
      });
    }
  });

  group('Horizontal -> Equatorial', () {
    for (var c in EQUHOR) {
      hor2equ(c['az'], c['al'], c['gl'], (ha, de) {
        test('Hour angle for ${c['az']}, ${c['al']}',
            () => expect(ha / 15, closeTo(c['ha'], DELTA)));
        test('Declination for ${c['az']}, ${c['al']}',
            () => expect(de, closeTo(c['de'], DELTA)));
      });
    }
  });
}
