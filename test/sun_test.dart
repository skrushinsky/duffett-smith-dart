import 'package:test/test.dart';
import 'package:duffett_smith/sun.dart';

const DELTA = 1E-4; // result precision

const cases = [
  {
    'djd': 30916.5, // 24 Aug 1984 00:00
    'l': 151.01309547440778,
    'r': 1.010993800005251,
    'ap': 151.0035132296576,
  },
  {
    'djd': 30819.10833333333, // 18 May 1984 14:36
    'l': 57.83143688493146,
    'r': 1.011718488789592,
    'ap': 57.82109236581925,
  },
  {
    'djd': 28804.5, // 12 Nov 1978 00:00
    'l': 229.2517039627867,
    'r': 0.9898375,
    'ap': 229.2450957063683,
  },
  {
    'djd': 33888.5, // 1992, Oct. 13 0h
    'l': 199.90600618015975,
    'r': .9975999344847888,
    'ap': 199.9047664927989, // Meeus: 199.90734722222223
  }
];
void main() {
  group('True geometric position', () {
    for (var c in cases) {
      final t = c['djd'] / 36525;
      trueGeocentric(t, callback: (lsn, rsn) {
        test('longitude for djd ${c['djd']}',
            () => expect(lsn, closeTo(c['l'], DELTA)));
        test('R-vector for djd ${c['djd']}',
            () => expect(rsn, closeTo(rsn, DELTA)));
      });
    }
  });

  group('ApparentPosiion', () {
    for (var c in cases) {
      apparent(c['djd'], ignoreLightTravel: true, callback: (lambda, delta) {
        test('longitude for djd ${c['djd']}',
            () => expect(lambda, closeTo(c['ap'], DELTA)));
      });
    }
  });

  group('Equinoxes/Solstices', () {
    const cases = [
      // from 'Astronomical algorithms' by Jean Meeus, p.168
      {
        'djd': 22817.39,
        'year': 1962,
        'event': SolEquType.JuneSolstice,
        'angle': 90.0,
        'title': 'June solstice (Meeus, "Astronomical Algorithms")'
      },
      // from http://www.usno.navy.mil/USNO/astronomical-applications/data-services/earth-seasons
      {
        'djd': 36603.815972,
        'year': 2000,
        'event': SolEquType.MarchEquinox,
        'angle': 0.0,
        'title': 'March equinox'
      },
      {
        'djd': 36696.575000,
        'year': 2000,
        'event': SolEquType.JuneSolstice,
        'angle': 90.0,
        'title': 'June solstice'
      },
      {
        'djd': 36790.227778,
        'year': 2000,
        'event': SolEquType.SeptemberEquinox,
        'angle': 180.0,
        'title': 'September equinox'
      },
      {
        'djd': 36880.067361,
        'year': 2000,
        'event': SolEquType.DecemberSolstice,
        'angle': 270.0,
        'title': 'December solstice'
      },
    ];

    for (var c in cases) {
      test(c['title'], () {
        final evt = solEqu(c['year'], c['event']);
        expect(evt.djd, closeTo(c['djd'], 1e-2));
        expect(evt.lambda, closeTo(c['angle'], 1e-6));
      });
    }
  });
}
