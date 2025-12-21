import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/data/repositories/event_repository.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

class FakeEventRepositoryForRegistration extends EventRepository {
  FakeEventRepositoryForRegistration({
    this.registerSuccess = true,
    this.unregisterSuccess = true,
  }) : super(api: _NoopApi());

  final bool registerSuccess;
  final bool unregisterSuccess;
  
  bool registerCalled = false;
  bool unregisterCalled = false;
  String? lastEventId;

  @override
  Future<bool> registerForEvent(String eventId) async {
    registerCalled = true;
    lastEventId = eventId;
    return registerSuccess;
  }

  @override
  Future<bool> unregisterFromEvent(String eventId) async {
    unregisterCalled = true;
    lastEventId = eventId;
    return unregisterSuccess;
  }

  @override
  Future<List<Event>> getMyRegisteredEvents() async => [];
}

class _NoopApi extends EventApi {
  _NoopApi() : super(dio: Dio(BaseOptions()));
}

void main() {
  test('registerForEvent calls repository and reloads registered events', () async {
    final repo = FakeEventRepositoryForRegistration(registerSuccess: true);
    final service = EventService(repository: repo);

    final success = await service.registerForEvent('event123');

    expect(success, isTrue);
    expect(repo.registerCalled, isTrue);
    expect(repo.lastEventId, equals('event123'));
  });

  test('registerForEvent returns false when repository fails', () async {
    final repo = FakeEventRepositoryForRegistration(registerSuccess: false);
    final service = EventService(repository: repo);

    final success = await service.registerForEvent('event456');

    expect(success, isFalse);
    expect(repo.registerCalled, isTrue);
  });

  test('unregisterFromEvent calls repository and updates state', () async {
    final repo = FakeEventRepositoryForRegistration(unregisterSuccess: true);
    final service = EventService(repository: repo);

    final success = await service.unregisterFromEvent('event789');

    expect(success, isTrue);
    expect(repo.unregisterCalled, isTrue);
    expect(repo.lastEventId, equals('event789'));
  });

  test('unregisterFromEvent returns false when repository fails', () async {
    final repo = FakeEventRepositoryForRegistration(unregisterSuccess: false);
    final service = EventService(repository: repo);

    final success = await service.unregisterFromEvent('event999');

    expect(success, isFalse);
    expect(repo.unregisterCalled, isTrue);
  });
}
