import 'package:flutter/foundation.dart';

class PageLoadState extends ChangeNotifier {
  int _progress = 0;
  String? _errorMessage;

  int get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _errorMessage == null && _progress < 100;

  void startLoading() {
    _progress = 0;
    _errorMessage = null;
    notifyListeners();
  }

  void updateProgress(int value) {
    _progress = value.clamp(0, 100);
    notifyListeners();
  }

  void finishLoading() {
    _progress = 100;
    _errorMessage = null;
    notifyListeners();
  }

  void showError(String message) {
    _errorMessage = message;
    _progress = 100;
    notifyListeners();
  }
}
