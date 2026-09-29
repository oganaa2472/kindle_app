import 'package:equatable/equatable.dart';

enum ReaderThemeMode { sepia, light, dark }

class ReaderState extends Equatable {
  final double fontSize;
  final ReaderThemeMode themeMode;

  const ReaderState({
    required this.fontSize,
    required this.themeMode,
  });

  // Эхлэл төлөв
  factory ReaderState.initial() {
    return const ReaderState(
      fontSize: 18.0,
      themeMode: ReaderThemeMode.sepia,
    );
  }

  // Утга шинэчлэх функц
  ReaderState copyWith({
    double? fontSize,
    ReaderThemeMode? themeMode,
  }) {
    return ReaderState(
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object> get props => [fontSize, themeMode];
}