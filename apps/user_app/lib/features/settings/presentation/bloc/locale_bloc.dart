import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_event.dart';
part 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String _localeKey = 'selected_locale';

  LocaleBloc() : super(const LocaleState(Locale('en'))) {
    on<LocaleLoadRequested>(_onLocaleLoadRequested);
    on<LocaleChanged>(_onLocaleChanged);
  }

  Future<void> _onLocaleLoadRequested(
    LocaleLoadRequested event,
    Emitter<LocaleState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);
      
      debugPrint('🌍 Loading saved locale: $localeString');
      
      if (localeString != null) {
        // Support only English and French
        final locale = localeString == 'fr' 
            ? const Locale('fr') 
            : const Locale('en');
        
        debugPrint('🌍 Emitting loaded locale: ${locale.languageCode}');
        emit(LocaleState(locale));
      } else {
        debugPrint('🌍 No saved locale found, using default (en)');
        emit(const LocaleState(Locale('en')));
      }
    } catch (e) {
      debugPrint('❌ Error loading locale: $e');
      // If loading fails, default to English
      emit(const LocaleState(Locale('en')));
    }
  }

  Future<void> _onLocaleChanged(
    LocaleChanged event,
    Emitter<LocaleState> emit,
  ) async {
    try {
      debugPrint('🌍 Changing locale to: ${event.locale.languageCode}');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, event.locale.languageCode);
      
      debugPrint('✅ Locale saved successfully');
      emit(LocaleState(event.locale));
    } catch (e) {
      debugPrint('❌ Error saving locale: $e');
      // If saving fails, still emit the new locale but log the error
      emit(LocaleState(event.locale));
    }
  }
} 