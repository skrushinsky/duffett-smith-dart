# Astronomical calculations

The main purpose of the library is to calculate positions of the Sun, the Moon,
and the planets with precision that is approximately the same as that found in
astronomical yearbooks. Other modules contain time-related routines, coordinates
conversions, calculation of the ecliptic obliquity and nutation, etc. Over time,
the range of utility functions will grow.

Most of the calculations are based on _"Astronomy With Your Personal Computer"_,
by _Peter Duffett-Smith_, _2nd edition_.

## Installing & testing

```console
$ pub get
$ pub run test test
```

## API docs

```console
$ dartdoc
$ pub global activate dhttpd
$ dhttpd --path doc/api   
```
