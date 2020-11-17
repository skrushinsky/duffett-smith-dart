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
}
