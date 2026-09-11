import 'package:flutter_test/flutter_test.dart';
import 'package:scys/page_load_state.dart';

void main() {
  group('PageLoadState', () {
    test('starts in a loading state', () {
      final state = PageLoadState();

      expect(state.progress, 0);
      expect(state.isLoading, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('updates progress and finishes at one hundred percent', () {
      final state = PageLoadState();

      state.updateProgress(42);
      expect(state.progress, 42);
      expect(state.isLoading, isTrue);

      state.updateProgress(100);
      expect(state.progress, 100);
      expect(state.isLoading, isFalse);
    });

    test('records a main page error', () {
      final state = PageLoadState();

      state.showError('网络连接失败');

      expect(state.errorMessage, '网络连接失败');
      expect(state.isLoading, isFalse);
    });

    test('retry clears the error and restarts loading', () {
      final state = PageLoadState()..showError('网络连接失败');

      state.startLoading();

      expect(state.errorMessage, isNull);
      expect(state.progress, 0);
      expect(state.isLoading, isTrue);
    });
  });
}
