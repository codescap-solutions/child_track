import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/shared_prefs_service.dart';
import '../../repository/notification_repo.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// BLOC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repo;

  NotificationBloc(this.repo) : super(NotificationLoading()) {
    on<LoadNotificationSettings>(_load);
    on<ToggleMasterNotification>(_toggleMaster);
    on<UpdateNotificationItem>(_updateItem);
  }

  Future<void> _load(LoadNotificationSettings event, Emitter emit) async {
    emit(NotificationLoading());
    try { 
      final model = await repo.fetchSettings();

      if (model.isSuccess && model.data != null) {
        emit(NotificationLoaded(model.data!));
      } else {
        emit(NotificationError(model.message));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _toggleMaster(
    ToggleMasterNotification event,
    Emitter emit,
  ) async {
    if (state is! NotificationLoaded) return;

    final current = (state as NotificationLoaded).model;
    final updated = current.copyWith(masterEnabled: event.value);

    emit(NotificationLoaded(updated));

    try {
      await repo.updateAll(updated);
    } catch (_) {
      emit(NotificationLoaded(current)); // rollback
    }
  }

  Future<void> _updateItem(UpdateNotificationItem event, Emitter emit) async {
    if (state is! NotificationLoaded) return;

    final current = (state as NotificationLoaded).model;

    final optimistic = current.updateSingle(
      event.category,
      event.key,
      event.value,
    );

    emit(NotificationLoaded(optimistic));

    try {
      await repo.updateSingle(event.category, event.key, event.value);
    } catch (_) {
      emit(NotificationLoaded(current)); // rollback
    }
  }
}
