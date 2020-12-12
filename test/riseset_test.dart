import 'package:duffett_smith/src/ephemeris/planets.dart';
import 'package:test/test.dart';
import 'package:duffett_smith/riseset.dart';

const delta = 1e-4;

void main() {
  group('Stars & planets, low-level', () {
    const theta = 52.25;
    test('Ordinary case', () {
      riseset(12.266666666666667, 14.566666666666666, theta,
          displacement: 0.5666666666666667, callback: (lstr, lsts, azr, azs) {
        expect(lstr, closeTo(4.892194444444445, delta));
        expect(lsts, closeTo(19.64113888888889, delta));
        expect(azr, closeTo(64.93969444444444, delta));
        expect(azs, closeTo(295.06030555555554, delta));
      });
    });
    test('Circumpolar', () {
      expect(() => riseset(6.601944444444444, 87.35277777777777, theta),
          throwsA(TypeMatcher<CircumpolarException>()));
    });
    test('Never rises', () {
      expect(() => riseset(6.601944444444444, -80.35277777777777, theta),
          throwsA(TypeMatcher<NeverRisesException>()));
    });
  });

  group('Sun', () {
    final cases = [
      {
        'lng': 0.0,
        'lat': 52.0,
        'djd': 30954.5,
        'gmtr': 6.016141666666667,
        'gmts': 17.619680555555554,
        'azr': 94.24374722222223,
        'azs': 265.4521138888889,
      },
      {
        'lng': -15.0,
        'lat': -45.0,
        'djd': 30743.5,
        'gmtr': 4.689016666666666,
        'gmts': 17.686975,
        'azr': 99.87367777777777,
        'azs': 260.4207166666667,
      }
    ];

    for (var c in cases) {
      final djd = c['djd'];
      final rs = RiseSetSun(djd, c['lat'], c['lng']);
      test('Rise on ${djd}', () {
        expect(rs.riseEvent.utc, closeTo(c['gmtr'], 1e-3));
        expect(rs.riseEvent.azimuth, closeTo(c['azr'], 1e-2));
      });
      test('Set on ${djd}', () {
        expect(rs.setEvent.utc, closeTo(c['gmts'], 1e-3));
        expect(rs.setEvent.azimuth, closeTo(c['azs'], 1e-2));
      });
    }
  });

  group('Moon', () {
    const cases = [
      {
        'djd': 30686.5, //  1984 Jan 7
        'lng': 0.0,
        'lat': 30.0,
        'gmtr': 9.966666666666667,
        'gmts': 21.15,
        'azr': 107.733876469,
        'azs': 254.566206282,
        'msg': '1984 Jan 7'
      },
      {
        'djd': 30690.5, //  1984 Jan 11
        'lng': 0.0,
        'lat': 30.0,
        'gmtr': 11.916666666666666,
        'gmts': 0.7333333333333333,
        'azr': 84.9133813111,
        'azs': 278.004394375,
        'msg': '1984 Jan 11'
      },
    ];

    const errorInMinutes = 2.0;

    final timeDiff = (a, b) {
      var x = (a - b).abs();
      return x > 12 ? 24 - x : x;
    };

    for (var c in cases) {
      final rs = RiseSetMoon(c['djd'], c['lat'], c['lng']);
      test('UTC rise on ${c['msg']}, error < 2m', () {
        final delta = timeDiff(rs.riseEvent.utc, c['gmtr']) * 60;
        expect(delta, lessThan(errorInMinutes));
      });
      test('UTC Set on ${c['msg']}, error < 2m', () {
        final delta = timeDiff(rs.setEvent.utc, c['gmts']) * 60;
        expect(delta, lessThan(errorInMinutes));
      });
      test('Azimuth Rise on ${c['msg']}', () {
        expect(rs.riseEvent.azimuth, closeTo(c['azr'], 1.0));
      });
      test('Azimuth Set on ${c['msg']}', () {
        expect(rs.setEvent.azimuth, closeTo(c['azs'], 1.0));
      });
    }

    test('Never rises', () {
      final rs = RiseSetMoon(30735.5, 66.0, 0.0);
      expect(
          () => rs.riseEvent.utc, throwsA(TypeMatcher<NeverRisesException>()));
    });

    test('Circumpolar', () {
      final rs = RiseSetMoon(30778.5, 66.0, 0.0);
      expect(
          () => rs.riseEvent.utc, throwsA(TypeMatcher<CircumpolarException>()));
    });
  });

  group('Planets', () {
    final djd = 44175.37500000;
    final rs = RiseSetPlanet(PlanetId.Venus, djd, 55.75, -37.62);
    test('Rise on ${djd}', () {
      expect(rs.riseEvent.utc, closeTo(3.4, 1e-1));
      // expect(rs.riseEvent.azimuth, closeTo(c['azr'], 1e-2));
    });
    test('Set on ${djd}', () {
      expect(rs.setEvent.utc, closeTo(11.8, 1e-1));
      // expect(rs.setEvent.azimuth, closeTo(c['azs'], 1e-2));
    });
  });
}
