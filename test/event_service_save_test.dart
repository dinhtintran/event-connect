import 'package:dio/dio.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/data/repositories/event_repository.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository that keeps data in-memory and avoids real HTTP calls.
class FakeEventRepository extends EventRepository {
  FakeEventRepository({List<Event>? events, List<Event>? featured, List<Event>? saved})
      : _events = events ?? [],
        _featured = featured ?? [],
        _saved = saved ?? [],
        super(api: _NoopEventApi());

  List<Event> _events;
  List<Event> _featured;
  List<Event> _saved;

  bool saveCalled = false;
  bool unsaveCalled = false;

  @override
  Future<List<Event>> getAllEvents() async => _events;

  @override
  Future<List<Event>> getFeaturedEvents() async => _featured;

  @override
  Future<List<Event>> getSavedEvents({int page = 1}) async => _saved;

  @override
  Future<bool> saveEvent(String eventId) async {
    saveCalled = true;
    _saved = [
      ..._events.where((e) => e.id == eventId).map(
            (e) => _copyWith(e, isSaved: true, savedAt: DateTime.now()),
          ),
    ];
    return true;
  }

  @override
  Future<bool> unsaveEvent(String eventId) async {
    unsaveCalled = true;
    _saved = [];
    return true;
  }

  // Helpers to set initial data inside tests
  void setEvents(List<Event> events) => _events = events;
  void setFeatured(List<Event> featured) => _featured = featured;
  void setSaved(List<Event> saved) => _saved = saved;

  Event _copyWith(Event e, {required bool isSaved, DateTime? savedAt}) {
    return Event(
      id: e.id,
      title: e.title,
      imageUrl: e.imageUrl,
      date: e.date,
      location: e.location,
      category: e.category,
      isFeatured: e.isFeatured,
      clubName: e.clubName,
      clubId: e.clubId,
      description: e.description,
      locationDetail: e.locationDetail,
      startAt: e.startAt,
      endAt: e.endAt,
      posterUrl: e.posterUrl,
      capacity: e.capacity,
      participantCount: e.participantCount,
      registrationCount: e.registrationCount,
      checkedInCount: e.checkedInCount,
      attendedCount: e.attendedCount,
      totalParticipants: e.totalParticipants,
      isSaved: isSaved,
      savedAt: savedAt,
      status: e.status,
      riskLevel: e.riskLevel,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      createdBy: e.createdBy,
    );
  }
}

class _NoopEventApi extends EventApi {
  _NoopEventApi() : super(dio: Dio(BaseOptions()));
}

Event _mkEvent({required String id, required bool isSaved}) => Event(
      id: id,
      title: 'Event $id',
      category: 'Công nghệ',
      startAt: DateTime.now().add(const Duration(days: 1)),
      capacity: 50,
      registrationCount: 5,
      isSaved: isSaved,
    );

void main() {
  test('toggleSaveEvent marks event as saved and updates cache', () async {
    final repo = FakeEventRepository();
    final service = EventService(repository: repo);
    final event = _mkEvent(id: '1', isSaved: false);

    repo.setEvents([event]);
    await service.loadAllEvents();

    final toggled = await service.toggleSaveEvent(event);

    expect(toggled, isTrue);
    expect(repo.saveCalled, isTrue);
    expect(service.allEvents.first.isSaved, isTrue);
    expect(service.savedEvents.length, equals(1));
  });

  test('toggleSaveEvent marks event as unsaved and clears cache', () async {
    final savedEvent = _mkEvent(id: '2', isSaved: true);
    final repo = FakeEventRepository(saved: [savedEvent]);
    final service = EventService(repository: repo);

    repo.setEvents([savedEvent]);
    await service.loadAllEvents();
    await service.loadSavedEvents();

    final toggled = await service.toggleSaveEvent(savedEvent);

    expect(toggled, isTrue);
    expect(repo.unsaveCalled, isTrue);
    expect(service.allEvents.first.isSaved, isFalse);
    expect(service.savedEvents, isEmpty);
  });
}
