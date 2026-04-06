import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _qaSecret  = 'gravitasdev';
const _qaPrefsKey = 'gravity_qa_mode';

/// QA / dev-mode service.
///
/// Activated by two triggers (web only for URL param, all platforms for tap):
///   • URL param  : https://<host>/gravity/?qa=gravitasdev
///   • Tap code   : tap the main-menu title 7× within 3 s
///
/// When active, isPremium is treated as true and ads are skipped.
/// State persists in SharedPreferences so it survives page refreshes.
class QaService extends ChangeNotifier {
  QaService._();
  static final instance = QaService._();

  bool _isQaMode = false;
  bool get isQaMode => _isQaMode;

  Future<void> initialize() async {
    // 1. Check URL query param on web (?qa=gravitasdev)
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters['qa'] == _qaSecret) {
        await _setQaMode(true);
        return;
      }
    }

    // 2. Restore previously persisted state
    final prefs = await SharedPreferences.getInstance();
    _isQaMode = prefs.getBool(_qaPrefsKey) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    await _setQaMode(!_isQaMode);
  }

  Future<void> _setQaMode(bool value) async {
    _isQaMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_qaPrefsKey, value);
    notifyListeners();
  }
}
