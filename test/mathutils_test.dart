import 'dart:math';
import 'package:test/test.dart';
import 'package:duffett_smith/mathutils.dart';

const DELTA = 1e-6;

void main() {
  group('Decomposing a number', () {
    test('Positive argument', () {
      modf(5.5, (f, i) {
        expect(f, closeTo(0.5, DELTA));
        expect(i, closeTo(5.0, DELTA));
      });
    });
    test('Negative argument', () {
      modf(-5.5, (f, i) {
        expect(f, closeTo(-0.5, DELTA));
        expect(i, closeTo(-5.0, DELTA));
      });
    });
  });

  group('Polynome', () {
    final cases = [
      [321.0, 10.0, 1.0, 2.0, 3.0],
      [
        0.411961500152426,
        -0.127296372347707,
        0.409092804222329,
        -0.0226937890431606,
        -7.51461205719781e-06,
        0.0096926375195824,
        -0.00024909726935408,
        -0.00121043431762618,
        -0.000189319742473274,
        3.4518734094999e-05,
        0.000135117572925228,
        2.80707121362421e-05,
        1.18779351871836e-05
      ]
    ];

    for (var c in cases) {
      final terms = c.sublist(2, c.length);
      test('with ${terms.length} terms', () {
        expect(polynome(c[1], terms), closeTo(c[0], DELTA));
      });
    }
  });

  group('Ranges', () {
    const degCases = [
      [20.0, -700.0],
      [0.0, 0.0],
      [345.0, 345.0],
      [340.0, 700.0],
      [0.0, 360.0],
      [70.45, 324070.45]
    ];

    for (var c in degCases) {
      final exp = c[0];
      final arg = c[1];
      test('reduceDeg(${arg}) should be ${exp}',
          () => expect(reduceDeg(arg), closeTo(exp, DELTA)));
    }

    const radCases = [
      [0.323629385640829, 12.89],
      [5.95955592153876, -12.89],
      [0.0, 0.0],
      [3.71681469282041, 10.0],
      [pi, pi],
      [0.0, pi * 2]
    ];

    for (var c in radCases) {
      final exp = c[0];
      final arg = c[1];
      test('reduceRad(${arg}) should be ${exp}',
          () => expect(reduceRad(arg), closeTo(exp, DELTA)));
    }
  });

  group('Fractional part of a number', () {
    test('frac(5.5) should be 0.5',
        () => expect(frac(5.5), closeTo(0.5, DELTA)));
    test('with a negative argument should be negative',
        () => expect(frac(-5.5), closeTo(-0.5, DELTA)));
  });

  group('frac360', () {
    final k = 23772.99 / 36525;
    final cases = [
      [31.7842235930254, 1.000021358E2 * k],
      [30.6653235575305, 9.999736056E1 * k],
      [42.3428797768338, 1.336855231E3 * k],
      [273.934866366267, 1.325552359E3 * k],
      [178.873057561472, 5.37261666700 * k]
    ];

    for (var c in cases) {
      final exp = c[0];
      final arg = c[1];
      test(
          '${arg} --> ${exp}', () => expect(frac360(arg), closeTo(exp, DELTA)));
    }
  });

  group('Sexadecimalal --> Decimal', () {
    test('Positive, 3 values',
        () => expect(ddd(37, 35, 0), closeTo(37.5833333, DELTA)));
    test('Positive, 2 values',
        () => expect(ddd(37, 35), closeTo(37.5833333, DELTA)));

    test('Negative degrees',
        () => expect(ddd(-37, 35), closeTo(-37.5833333, DELTA)));
    test('Negative minutes',
        () => expect(ddd(0, -35), closeTo(-0.5833333, DELTA)));
  });

  group('Decimal --> Sexadecimal', () {
    dms(55.75833333333333, (d, m, s) {
      test('Positive, degrees', () => expect(d, equals(55)));
      test('Positive, minutes', () => expect(m, equals(45)));
      test('Positive, seconds', () => expect(s, closeTo(30.0, DELTA)));
    });
    dms(-55.75833333333333, (d, m, s) {
      test('Negative, degrees', () => expect(d, equals(-55)));
      test('Negative, minutes', () => expect(m, equals(45)));
      test('Negative, seconds', () => expect(s, closeTo(30.0, DELTA)));
    });
    dms(-0.75833333333333, (d, m, s) {
      test('Negative, zero degrees', () => expect(d, equals(0)));
      test('Negative minutes', () => expect(m, equals(-45)));
    });
  });

  group('DMS class', () {
    group('Positive', () {
      final dms = DMS.fromDecimal(55.75833333333333);
      test('Degrees', () => expect(dms.d, equals(55)));
      test('Minutes', () => expect(dms.m, equals(45)));
      test('Seconds', () => expect(dms.s, closeTo(30.0, DELTA)));
    });

    group('Negative degrees', () {
      final dms = DMS.fromDecimal(-55.75833333333333);
      test('Degrees', () => expect(dms.d, equals(-55)));
      test('Minutes', () => expect(dms.m, equals(45)));
      test('Seconds', () => expect(dms.s, closeTo(30.0, DELTA)));
    });

    group('Negative minutes', () {
      final dms = DMS.fromDecimal(-0.75833333333333);
      test('Degrees', () => expect(dms.d, equals(0)));
      test('Minutes', () => expect(dms.m, equals(-45)));
      test('Seconds', () => expect(dms.s, closeTo(30.0, DELTA)));
    });

    group('Negative seconds', () {
      final dms = DMS.fromDecimal(-0.008333333333333333);
      test('Degrees', () => expect(dms.d, equals(0)));
      test('Minutes', () => expect(dms.m, equals(0)));
      test('Seconds', () => expect(dms.s, closeTo(-30.0, DELTA)));
    });
  });

  group('Arcs', () {
    const cases = [
      {'a': 10.0, 'b': 270.0, 'x': 100.0},
      {'a': 350.0, 'b': 20.0, 'x': 30.0},
      {'a': 10.0, 'b': 20.0, 'x': 10.0}
    ];

    for (var c in cases) {
      final a = c['a'];
      final b = c['b'];
      test('a = ${a}, b = ${b}', () {
        expect(shortestArc(a, b), closeTo(c['x'], DELTA));
      });
    }
  });
}
