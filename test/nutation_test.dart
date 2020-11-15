import 'package:test/test.dart';
import 'package:duffett_smith/ephemeris.dart';

const DELTA = 1E-4; // result precision

const cases = [
  {
    'djd': -15804.5, // 1856 Sept. 23
    'dpsi': -0.00127601021242336,
    'deps': 0.00256293723137559,
  },
  {
    'djd': 36524.5, // 2000 Jan. 1
    'dpsi': -0.00387728730373955,
    'deps': -0.00159919822661103,
  },
  {
    'djd': 28805.69, // 1978 Nov 17
    'dpsi': -9.195562346652888e-04,
    'deps': -2.635113483663831e-03,
  }
];

void main() {
  group('Nutation', () {
    for (var c in cases) {
      final t = c['djd'] / 36525;
      nutation(t, (dpsi, deps) {
        test('dpsi at DJD #${c['djd']}',
            () => expect(dpsi, closeTo(c['dpsi'], DELTA)));
        test('deps at DJD #${c['djd']}',
            () => expect(deps, closeTo(c['deps'], DELTA)));
      });
    }
  });
}
