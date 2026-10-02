import 'dart:async';

/// Runs async actions one at a time, in the order they were requested.
///
/// A failing or throwing action does not block later actions. Callers that
/// must not surface errors should catch inside [action] and return a result.
class MutationQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        final value = await action();
        if (!result.isCompleted) result.complete(value);
      } catch (error, stackTrace) {
        if (!result.isCompleted) {
          result.completeError(error, stackTrace);
        }
      }
    });
    return result.future;
  }
}
