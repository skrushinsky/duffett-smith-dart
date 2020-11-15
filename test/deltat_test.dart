import 'package:test/test.dart';
import 'package:duffett_smith/timeutils.dart';

void main() {
  group('DeltaT', () {
    const cases = [
      [-102146.5, 119.51, 'historical start'], // 1620-05-01
      [-346701.5, 1820.325, 'after 948'], // # 950-10-01
      [44020.5, 93.81, 'after 2010'], // 2020-07-10
      [109582.5, 407.2, 'after 2100'], // ?
    ];

    for (var c in cases) {
      test('${c[2]} - DJD ${c[0]} should be ${c[1]}s.',
          () => expect(deltaT(c[0]), closeTo(c[1], 0.1)));
    }
  });
}
