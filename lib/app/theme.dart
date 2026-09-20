import 'package:flutter/material.dart';

/// ThemeData dari design/tokens.css. Nilai warna 1:1 dengan CSS.
/// Warna semantik di luar ColorScheme (income/over/near) ada di [GemiColors].

class GemiColors extends ThemeExtension<GemiColors> {
  const GemiColors({
    required this.ink2,
    required this.ink3,
    required this.rule,
    required this.income,
    required this.over,
    required this.near,
    required this.surface2,
  });

  /// surface2: latar tombol keypad / kartu tenang (tokens --surface-2).
  final Color ink2, ink3, rule, income, over, near, surface2;

  /// Warna kategori cat-1..cat-5 + cat-other, indeks = kolom `color` di tabel categories.
  static const _katLight = [
    Color(0xFF1F7A52),
    Color(0xFF2F5FA8),
    Color(0xFFB8862B),
    Color(0xFF8A4FA3),
    Color(0xFFC4553A),
    Color(0xFF6B756F),
  ];
  static const _katDark = [
    Color(0xFF3FA574),
    Color(0xFF5F88D0),
    Color(0xFFB4862E),
    Color(0xFFA97AC2),
    Color(0xFFD06A50),
    Color(0xFF7E8882),
  ];
  Color kategori(int i) =>
      (this == light ? _katLight : _katDark)[i.clamp(0, 5)];

  static const light = GemiColors(
    ink2: Color(0xFF5E6863),
    ink3: Color(0xFF8C948F),
    rule: Color(0xFFD8DCD7),
    income: Color(0xFF1F7A52),
    over: Color(0xFFB23A2B),
    near: Color(0xFF8A6414),
    surface2: Color(0xFFF6F7F5),
  );
  static const dark = GemiColors(
    ink2: Color(0xFFA3ACA6),
    ink3: Color(0xFF737C76),
    rule: Color(0xFF2E3631),
    income: Color(0xFF3FA574),
    over: Color(0xFFD06A50),
    near: Color(0xFFB4862E),
    surface2: Color(0xFF222925),
  );

  @override
  GemiColors copyWith({
    Color? ink2,
    Color? ink3,
    Color? rule,
    Color? income,
    Color? over,
    Color? near,
    Color? surface2,
  }) => GemiColors(
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    rule: rule ?? this.rule,
    income: income ?? this.income,
    over: over ?? this.over,
    near: near ?? this.near,
    surface2: surface2 ?? this.surface2,
  );

  @override
  GemiColors lerp(GemiColors? other, double t) =>
      t < .5 ? this : (other ?? this);
}

extension GemiTheme on BuildContext {
  GemiColors get gemi => Theme.of(this).extension<GemiColors>()!;
}

ThemeData _build({
  required Brightness brightness,
  required Color ground,
  required Color surface,
  required Color ink,
  required GemiColors ext,
}) {
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: surface,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: ground,
      secondary: ext.income,
      onSecondary: ground,
      error: ext.over,
      onError: ground,
      surface: surface,
      onSurface: ink,
    ),
    // Tipe dari tokens: fs-2 13, fs-3 15 (body), fs-4 17, fs-5 22, fs-6 34.
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 15, height: 1.45),
      bodySmall: TextStyle(fontSize: 13, height: 1.45),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ).apply(bodyColor: ink, displayColor: ink),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: ground,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      labelStyle: TextStyle(fontSize: 13, color: ext.ink2),
      hintStyle: TextStyle(color: ext.ink3),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: ink,
      side: BorderSide(color: ext.rule),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontSize: 15, color: ink),
      secondaryLabelStyle: TextStyle(fontSize: 15, color: ground),
      showCheckmark: false,
    ),
    dividerTheme: DividerThemeData(color: ext.rule, thickness: 1, space: 1),
    extensions: [ext],
  );
}

final lightTheme = _build(
  brightness: Brightness.light,
  ground: const Color(0xFFEEF0EC),
  surface: const Color(0xFFFFFFFF),
  ink: const Color(0xFF16201B),
  ext: GemiColors.light,
);

final darkTheme = _build(
  brightness: Brightness.dark,
  ground: const Color(0xFF121614),
  surface: const Color(0xFF1B211D),
  ink: const Color(0xFFECEFEA),
  ext: GemiColors.dark,
);
