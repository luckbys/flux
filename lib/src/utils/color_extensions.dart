import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Darkens the color by the specified amount.
  /// The amount should be between 0.0 and 1.0.
  Color darken(double amount) {
    assert(
        amount >= 0.0 && amount <= 1.0, 'Amount must be between 0.0 and 1.0');

    final hsl = HSLColor.fromColor(this);
    final darkenedLightness = (hsl.lightness - amount).clamp(0.0, 1.0);

    return hsl.withLightness(darkenedLightness).toColor();
  }

  /// Lightens the color by the specified amount.
  /// The amount should be between 0.0 and 1.0.
  Color lighten(double amount) {
    assert(
        amount >= 0.0 && amount <= 1.0, 'Amount must be between 0.0 and 1.0');

    final hsl = HSLColor.fromColor(this);
    final lightenedLightness = (hsl.lightness + amount).clamp(0.0, 1.0);

    return hsl.withLightness(lightenedLightness).toColor();
  }

  /// Converts the color to a hexadecimal string representation.
  String toHex() {
    return '#${a.round().toRadixString(16).padLeft(2, '0')}'
        '${r.round().toRadixString(16).padLeft(2, '0')}'
        '${g.round().toRadixString(16).padLeft(2, '0')}'
        '${b.round().toRadixString(16).padLeft(2, '0')}';
  }

  /// Creates a new color with the specified alpha value.
  /// This replaces the deprecated withOpacity method.
  Color withAlpha(double alpha) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha);
  }
}
