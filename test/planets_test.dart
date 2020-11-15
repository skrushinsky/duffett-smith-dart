import 'package:test/test.dart';
import 'package:duffett_smith/ephemeris.dart';

const DELTA = 1E-4; // result precision

void main() {
  group('Perturbations', () {
    // dl, dr, dml, ds, dm, da, dhl
    final cases = [
      {
        'planet': Planet(PlanetId.Mercury),
        //'args': [1.7277480419370512, 1.3753354318768864, 4.469600429159891],
        'args': List<double>.from(
            [1.7277480419370512, 1.3753354318768864, 4.469600429159891]),
        'values': {
          PertType.dl: -0.00137,
          PertType.dr: -0.00001,
          PertType.dml: 0.00000,
          PertType.ds: 0.00000,
          PertType.dm: 0.00000,
          PertType.da: 0.00000,
          PertType.dhl: 0.00000
        },
      },
      {
        'planet': Planet(PlanetId.Venus),
        'args': List<double>.from([
          0.8405338809034908,
          0.2949033667634708,
          1.3753354318768864,
          4.469600429159891
        ]),
        'values': {
          PertType.dl: -0.00296,
          PertType.dr: -0.00002,
          PertType.dml: 0.00000,
          PertType.ds: 0.00000,
          PertType.dm: 0.00000,
          PertType.da: 0.00000,
          PertType.dhl: 0.00000
        },
      },
      {
        'planet': Planet(PlanetId.Mars),
        'args': List<double>.from([
          0.2949033667634708,
          1.3753354318768864,
          -2.6665898702652084,
          4.469600429159891
        ]),
        'values': {
          PertType.dl: 0.00559,
          PertType.dr: -0.00002,
          PertType.dml: 0.00023,
          PertType.ds: 0.00000,
          PertType.dm: 0.00023,
          PertType.da: 0.00000,
          PertType.dhl: 0.00000
        },
      },
      {
        'planet': Planet(PlanetId.Jupiter),
        'args': List<double>.from([0.8405338809034908, 0.04847241748495448]),
        'values': {
          PertType.dl: 0.00000,
          PertType.dr: 0.00000,
          PertType.dml: 0.00069,
          PertType.ds: -0.00044,
          PertType.dm: -0.02062,
          PertType.da: 0.00020,
          PertType.dhl: 0.00000
        },
      },
      {
        'planet': Planet(PlanetId.Saturn),
        'args': List<double>.from([0.8405338809034908, 0.05560140165362042]),
        'values': {
          PertType.dl: 0.00000,
          PertType.dr: 0.00000,
          PertType.dml: -0.00004,
          PertType.ds: -0.00469,
          PertType.dm: -0.02854,
          PertType.da: 0.01638,
          PertType.dhl: -0.00005
        },
      },
      {
        'planet': Planet(PlanetId.Uranus),
        'args': List<double>.from([0.8405338809034908, 0.04632211300973037]),
        'values': {
          PertType.dl: -0.03708,
          PertType.dr: -0.02201,
          PertType.dml: -0.01396,
          PertType.ds: 0.00097,
          PertType.dm: 0.02726,
          PertType.da: -0.00138,
          PertType.dhl: 0.00002
        },
      },
      {
        'planet': Planet(PlanetId.Neptune),
        'args': List<double>.from([0.8405338809034908, 0.00900235916647171]),
        'values': {
          PertType.dl: -0.00004,
          PertType.dr: -0.03142,
          PertType.dml: 0.00953,
          PertType.ds: -0.00041,
          PertType.dm: 0.07023,
          PertType.da: 0.00314,
          PertType.dhl: -0.00000
        },
      },
      {
        'planet': Planet(PlanetId.Pluto),
        'args': List<double>.from([]),
        'values': {
          PertType.dl: 0.00000,
          PertType.dr: 0.00000,
          PertType.dml: 0.00000,
          PertType.ds: 0.00000,
          PertType.dm: 0.00000,
          PertType.da: 0.00000,
          PertType.dhl: 0.00000
        },
      }
    ];

    for (var c in cases) {
      Planet pla = c['planet'];
      final Map<PertType, double> exp = c['values'];
      final got = pla.calculatePerturbations(c['args']);
      PertType.values.forEach((pt) {
        test('${pla} - ${pt}', () => expect(got[pt], closeTo(exp[pt], DELTA)));
      });
    }
  });

  group('Osculating elements', () {
    const cases = [
      {
        'id': PlanetId.Mercury,
        'ML': 176.191,
        'DM': 4.09238,
        'PH': 77.2073,
        'EC': .205631,
        'IN': 7.00443,
        'ND': 48.1423,
        'SA': .387099,
        'DI': 6.74,
        'MG': -0.42
      },
      {
        'id': PlanetId.Mars,
        'ML': 182.982,
        'DM': .524071,
        'PH': 335.766,
        'EC': 9.33903e-02,
        'IN': 1.84977,
        'ND': 49.4345,
        'SA': 1.52369,
        'DI': 9.36,
        'MG': -1.52
      },
      {
        'id': PlanetId.Jupiter,
        'ML': 270.164,
        'DM': 8.31294e-02,
        'PH': 14.0749,
        'EC': 4.84724e-02,
        'IN': 1.30395,
        'ND': 100.293,
        'SA': 5.20256,
        'DI': 196.74,
        'MG': -9.4
      }
    ];

    const delta = 1e-2;
    final t = 30700.5 / 36525; // 1984 Jan 21

    for (var c in cases) {
      final pla = Planet(c['id']);

      test('${pla} Mean Longitude',
          () => expect(pla.orbit.ML.assemble(t), closeTo(c['ML'], delta)));
      test('${pla} Arument of Perihelion',
          () => expect(pla.orbit.PH.assemble(t), closeTo(c['PH'], delta)));
      test('${pla} Eccentricity',
          () => expect(pla.orbit.EC.assemble(t), closeTo(c['EC'], delta)));
      test('${pla} Inclination',
          () => expect(pla.orbit.IN.assemble(t), closeTo(c['IN'], delta)));
      test('${pla} Ascending Node',
          () => expect(pla.orbit.ND.assemble(t), closeTo(c['ND'], delta)));
      test('${pla} Semi-axis',
          () => expect(pla.orbit.SA, closeTo(c['SA'], delta)));
      test('${pla} Angular Diameter',
          () => expect(pla.orbit.DI, closeTo(c['DI'], delta)));
      test('${pla} Magnitude',
          () => expect(pla.orbit.MG, closeTo(c['MG'], DELTA)));

      test('${pla} Daily motion',
          () => expect(pla.orbit.DM, closeTo(c['DM'], DELTA)));
    }
  });
}
