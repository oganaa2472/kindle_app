import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'reader_state.dart';

class ReaderCubit extends Cubit<ReaderState> {
  final Box _settingsBox;

  ReaderCubit(this._settingsBox) : super(ReaderState.initial()) {
    _loadSettings();
  }

  // Hive-аас өмнө хадгалсан тохиргоог ачаалах
  void _loadSettings() {
    final double? savedFontSize = _settingsBox.get('fontSize');
    final String? savedTheme = _settingsBox.get('themeMode');

    ReaderThemeMode mode = ReaderThemeMode.sepia;
    if (savedTheme == 'light') mode = ReaderThemeMode.light;
    if (savedTheme == 'dark') mode = ReaderThemeMode.dark;

    emit(state.copyWith(
      fontSize: savedFontSize ?? 18.0,
      themeMode: mode,
    ));
  }

  // Фонтын хэмжээ солих + Hive-д хадгалах
  void updateFontSize(double newSize) {
    _settingsBox.put('fontSize', newSize);
    emit(state.copyWith(fontSize: newSize));
  }

  // Өнгөний горим солих + Hive-д хадгалах
  void updateThemeMode(ReaderThemeMode mode) {
    _settingsBox.put('themeMode', mode.name);
    emit(state.copyWith(themeMode: mode));
  }
}