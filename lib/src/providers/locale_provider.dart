import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_initialLocale()) {
    _load();
  }

  static Locale _initialLocale() {
    final saved = LocalStorageService.getLocale();
    if (saved != null && saved.isNotEmpty) {
      return Locale(saved);
    }
    return const Locale('de');
  }

  Future<void> _load() async {
    final saved = LocalStorageService.getLocale();
    if (saved != null && saved.isNotEmpty) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await LocalStorageService.setLocale(locale.languageCode);
  }
}
