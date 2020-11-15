import 'package:test/test.dart';
import 'package:duffett_smith/ephemeris.dart';

void main() {
  group('True geocentric', () {
    const delta = 1E-4; // result precision
    final cases = [
      {
        'planet': PlanetId.Mercury,
        'geo': List<double>.from([275.88530, 1.47425, 0.98587])
      },
      {
        'planet': PlanetId.Venus,
        'geo': List<double>.from([264.15699, 1.42582, 1.22905])
      },
      {
        'planet': PlanetId.Mars,
        'geo': List<double>.from([214.98173, 1.67762, 1.41366])
      },
      {
        'planet': PlanetId.Jupiter,
        'geo': List<double>.from([270.30024, 0.29758, 6.10966])
      },
      {
        'planet': PlanetId.Saturn,
        'geo': List<double>.from([225.37862, 2.33550, 10.04942])
      },
      {
        'planet': PlanetId.Uranus,
        'geo': List<double>.from([252.17354, 0.05160, 19.63393])
      },
      {
        'planet': PlanetId.Neptune,
        'geo': List<double>.from([270.07638, 1.16314, 31.11160])
      },
      {
        'planet': PlanetId.Pluto,
        'geo': List<double>.from([212.07989, 16.88244, 29.86118])
      }
    ];

    final eph = Ephemeris(30700.5);
    for (var c in cases) {
      PlanetId id = c['planet'];
      final pla = Planet(id);
      final pos = eph.geocentricPosition(id);
      final List<double> exp = c['geo'];
      test('${pla} Lon.', () => expect(pos.lambda, closeTo(exp[0], delta)));
      test('${pla} Lat.', () => expect(pos.beta, closeTo(exp[1], delta)));
      test('${pla} Dist.', () => expect(pos.delta, closeTo(exp[2], delta)));
    }
  });

  group('Duffett-Smith examples', () {
    const delta = 1e-3;
    final cases = [
      {
        'planet': PlanetId.Mercury,
        'geo': List<double>.from([45.9319, -2.78797, 0.999897])
      },
      {
        'planet': PlanetId.Saturn,
        'geo': List<double>.from([221.2009, 2.56691, 8.956587])
      }
    ];
    final eph = Ephemeris(30830.5); // 1984 May 30
    for (var c in cases) {
      PlanetId id = c['planet'];
      final pla = Planet(id);
      final pos = eph.geocentricPosition(id);
      final List<double> exp = c['geo'];
      test('${pla} Lon.', () => expect(pos.lambda, closeTo(exp[0], delta)));
      test('${pla} Lat.', () => expect(pos.beta, closeTo(exp[1], delta)));
      test('${pla} Dist.', () => expect(pos.delta, closeTo(exp[2], delta)));
    }
  });

  group('Sun position', () {
    const delta = 1e-3;
    final cases = [
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
        'l': 199.90600618015972,
        'r': .9975999344847888,
        'ap': 199.9047664927989, // Meeus: 199.90734722222223
      }
    ];

    for (var c in cases) {
      final djd = c['djd'];
      final got = Ephemeris(djd).geocentricPosition(PlanetId.Sun);
      final l = c['l'];
      final d = c['r'];
      test('DJD #${djd} true longitude',
          () => expect(got.lambda, closeTo(l, delta)));
      test('DJD #${djd} distance from Earth',
          () => expect(got.delta, closeTo(d, delta)));
    }

    for (var c in cases) {
      final djd = c['djd'];
      final got =
          Ephemeris(djd, apparent: true).geocentricPosition(PlanetId.Sun);
      final l = c['ap'];
      test('DJD #${djd} apparent longitude',
          () => expect(got.lambda, closeTo(l, delta)));
    }
  });

  group('Daily Motions', () {
    const delta = 1e-4;
    final cases = [
      {'planet': PlanetId.Moon, 'motion': 14.0721},
      {'planet': PlanetId.Sun, 'motion': 0.9560},
      {'planet': PlanetId.Mercury, 'motion': 0.0344},
      {'planet': PlanetId.Venus, 'motion': 0.9132},
      {'planet': PlanetId.Mars, 'motion': 0.6832},
      {'planet': PlanetId.Jupiter, 'motion': 0.1600},
      {'planet': PlanetId.Saturn, 'motion': -0.0669},
      {'planet': PlanetId.Uranus, 'motion': 0.0336},
      {'planet': PlanetId.Neptune, 'motion': -0.0001},
      {'planet': PlanetId.Pluto, 'motion': -0.0223}
    ];

    final eph = Ephemeris(42165.900896222796); // 2015 Jun, 12.400896222796291
    for (var c in cases) {
      PlanetId id = c['planet'];
      test(Planet(c['planet']),
          () => expect(eph.dailyMotion(id), closeTo(c['motion'], delta)));
    }
  });

  group('LunarNode', () {
    const djd = 23772.990277;
    const delta = 1e-4;
    test('True', () {
      final eph = Ephemeris(djd, trueNode: true);
      final pos = eph.geocentricPosition(PlanetId.LunarNode);
      expect(pos.lambda, closeTo(81.8665, delta));
    });
    test('Mean', () {
      final eph = Ephemeris(djd, trueNode: false);
      final pos = eph.geocentricPosition(PlanetId.LunarNode);
      expect(pos.lambda, closeTo(80.3117, delta));
    });
  });
}
