import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);
final unreadNotificationsProvider = FutureProvider<int>((ref) {
  ref.watch(customerSessionRevisionProvider);
  return ref.watch(notificationRepositoryProvider).unread();
});
final notificationsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsController,
      NotificationView
    >(NotificationsController.new);

class NotificationView {
  const NotificationView(this.result, {this.busy = false, this.error});
  final NotificationList result;
  final bool busy;
  final Object? error;
}

class NotificationsController extends AsyncNotifier<NotificationView> {
  int _epoch = 0;
  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);
  @override
  Future<NotificationView> build() async {
    ref.watch(customerSessionRevisionProvider);
    _epoch++;
    return NotificationView(
      await ref.watch(notificationRepositoryProvider).list(),
    );
  }

  Future<void> refresh() async {
    final epoch = ++_epoch;
    final result = await AsyncValue.guard(
      () async => NotificationView(await _repository.list()),
    );
    if (ref.mounted && epoch == _epoch) {
      state = result;
      ref.invalidate(unreadNotificationsProvider);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.busy ||
        current.result.page >= current.result.lastPage) {
      return;
    }
    final epoch = _epoch;
    state = AsyncData(NotificationView(current.result, busy: true));
    try {
      final next = await _repository.list(page: current.result.page + 1);
      if (!ref.mounted || epoch != _epoch) return;
      final ids = current.result.items.map((e) => e.id).toSet();
      state = AsyncData(
        NotificationView(
          NotificationList(
            items: [
              ...current.result.items,
              ...next.items.where((e) => ids.add(e.id)),
            ],
            page: next.page,
            lastPage: next.lastPage,
            unread: next.unread,
            latestId: current.result.latestId,
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted && epoch == _epoch) {
        state = AsyncData(NotificationView(current.result, error: error));
      }
    }
  }

  Future<bool> mark({int? id}) async {
    final current = state.value;
    if (current == null || current.busy) return false;
    final epoch = _epoch;
    final revision = ref.read(customerSessionRevisionProvider);
    state = AsyncData(NotificationView(current.result, busy: true));
    try {
      if (id == null) {
        await _repository.readAll(current.result.latestId);
      } else {
        await _repository.read(id);
      }
      if (!ref.mounted ||
          epoch != _epoch ||
          revision != ref.read(customerSessionRevisionProvider)) {
        return false;
      }
      ref.invalidate(unreadNotificationsProvider);
      final next = await _repository.list();
      if (!ref.mounted ||
          epoch != _epoch ||
          revision != ref.read(customerSessionRevisionProvider)) {
        return false;
      }
      state = AsyncData(NotificationView(next));
      return true;
    } catch (error) {
      if (ref.mounted &&
          epoch == _epoch &&
          revision == ref.read(customerSessionRevisionProvider)) {
        state = AsyncData(NotificationView(current.result, error: error));
      }
      return false;
    }
  }
}
