import 'package:ansicolor/ansicolor.dart';

abstract class Theme {
  static final Map<String, Theme> _cache = {};
  final Map<String, AnsiPen> _pens;

  const Theme(this._pens);

  factory Theme.create(name) => _getOrCreate(name);
  factory Theme.createDefault() => _getOrCreate('dark');

  static Theme _getOrCreate(String name) {
    var theme;
    if (_cache.containsKey(name)) {
      theme = _cache[name];
    } else {
      switch (name) {
        case 'dark':
          theme = DarkTheme();
          break;
        case 'light':
          theme = LightTheme();
          break;
      }
    }
    return theme;
  }

  AnsiPen get titlePen => _pens['title'];
  AnsiPen get headingPen => _pens['heading'];
  AnsiPen get dataPen => _pens['data'];
  AnsiPen get errorPen => _pens['error'];
}

class DarkTheme extends Theme {
  DarkTheme() : super(createColors());
  static Map<String, AnsiPen> createColors() {
    return {
      'title': AnsiPen()..white(),
      'heading': AnsiPen()..rgb(r: 1.0, g: 0.8, b: 0.0),
      'data': AnsiPen()..white(bold: true),
      'error': AnsiPen()..red(bold: true),
    };
  }
}

class LightTheme extends Theme {
  LightTheme() : super(createColors());
  static Map<String, AnsiPen> createColors() {
    return {
      'title': AnsiPen()..black(),
      'heading': AnsiPen()..black(bold: true),
      'data': AnsiPen()..blue(bold: true),
      'error': AnsiPen()..red(bold: true),
    };
  }
}
