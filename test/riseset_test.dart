import 'package:test/test.dart';
import 'package:duffett_smith/riseset.dart';

const delta = 1e-4;

void main() {
  group('Rise / set ', () {
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
        expect(rs.sunRise.utc, closeTo(c['gmtr'], 1e-3));
        expect(rs.sunRise.azimuth, closeTo(c['azr'], 1e-2));
      });
      test('Set on ${djd}', () {
        expect(rs.sunSet.utc, closeTo(c['gmts'], 1e-3));
        expect(rs.sunSet.azimuth, closeTo(c['azs'], 1e-2));
      });
    }
  });
}
