import 'package:dio/dio.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/data/repositories/event_repository.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
import 'package:event_connect/features/event_management/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeEventRepository implements EventRepositoryContract {
  FakeEventRepository({this.throwAll = false, this.throwFeatured = false});

  final bool throwAll;
  final bool throwFeatured;

  @override
  Future<List<Event>> getAllEvents() async {
    if (throwAll) throw Exception('fake-all');
    return _sampleEvents;
  }

  @override
  Future<List<Event>> getFeaturedEvents() async {
    if (throwFeatured) throw Exception('fake-featured');
    return _featuredEvents;
  }

  // Unused in these tests
  @override
  Future<Event> getEventById(String id) async => _sampleEvents.first;
  @override
  Future<List<Event>> searchEvents(String query) async => _sampleEvents;
  @override
  Future<List<Event>> filterEventsByCategory(String category) async => _sampleEvents;
  @override
  Future<bool> registerForEvent(String eventId) async => true;
  @override
  Future<bool> unregisterFromEvent(String eventId) async => true;
  @override
  Future<List<Event>> getMyRegisteredEvents() async => [];
  @override
  Future<bool> submitFeedback(String eventId, double rating, String comment) async => true;
  @override
  Future<List<dynamic>> getEventFeedbacks(String eventId) async => [];
  @override
  Future<List<Event>> getSavedEvents({int page = 1}) async => [];
  @override
  Future<bool> saveEvent(String eventId) async => true;
  @override
  Future<bool> unsaveEvent(String eventId) async => true;
}

abstract class EventRepositoryContract {
  Future<List<Event>> getAllEvents();
  Future<Event> getEventById(String id);
  Future<List<Event>> getFeaturedEvents();
  Future<List<Event>> searchEvents(String query);
  Future<List<Event>> filterEventsByCategory(String category);
  Future<bool> registerForEvent(String eventId);
  Future<bool> unregisterFromEvent(String eventId);
  Future<List<Event>> getMyRegisteredEvents();
  Future<bool> submitFeedback(String eventId, double rating, String comment);
  Future<List<dynamic>> getEventFeedbacks(String eventId);
  Future<List<Event>> getSavedEvents({int page = 1});
  Future<bool> saveEvent(String eventId);
  Future<bool> unsaveEvent(String eventId);
}

class EventServiceAdapter extends EventService {
  EventServiceAdapter({required this.fakeRepository})
      : super(repository: _EventRepositoryShim(fakeRepository));

  final EventRepositoryContract fakeRepository;
}

class _EventRepositoryShim extends EventRepository {
  _EventRepositoryShim(this.fake) : super(api: _NoopApi());
  final EventRepositoryContract fake;

  @override
  Future<List<Event>> getAllEvents() => fake.getAllEvents();
  @override
  Future<Event> getEventById(String id) => fake.getEventById(id);
  @override
  Future<List<Event>> getFeaturedEvents() => fake.getFeaturedEvents();
  @override
  Future<List<Event>> searchEvents(String query) => fake.searchEvents(query);
  @override
  Future<List<Event>> filterEventsByCategory(String category) => fake.filterEventsByCategory(category);
  @override
  Future<bool> registerForEvent(String eventId) => fake.registerForEvent(eventId);
  @override
  Future<bool> unregisterFromEvent(String eventId) => fake.unregisterFromEvent(eventId);
  @override
  Future<List<Event>> getMyRegisteredEvents() => fake.getMyRegisteredEvents();
  @override
  Future<bool> submitFeedback(String eventId, double rating, String comment) => fake.submitFeedback(eventId, rating, comment);
  @override
  Future<List<dynamic>> getEventFeedbacks(String eventId) => fake.getEventFeedbacks(eventId);
  @override
  Future<List<Event>> getSavedEvents({int page = 1}) => fake.getSavedEvents(page: page);
  @override
  Future<bool> saveEvent(String eventId) => fake.saveEvent(eventId);
  @override
  Future<bool> unsaveEvent(String eventId) => fake.unsaveEvent(eventId);
}

class _NoopApi extends EventApi {
  _NoopApi() : super(dio: Dio());
}

final Event _eventFuture = Event(
  id: '1',
  title: 'AI Summit',
  category: 'Công nghệ',
  startAt: DateTime.now().add(const Duration(days: 2)),
  capacity: 100,
  registrationCount: 10,
  isFeatured: true,
);

final Event _eventUpcoming = Event(
  id: '2',
  title: 'Music Fest',
  category: 'Âm nhạc',
  startAt: DateTime.now().add(const Duration(days: 5)),
  capacity: 80,
  registrationCount: 5,
);

List<Event> get _sampleEvents => [_eventFuture, _eventUpcoming];
List<Event> get _featuredEvents => [_eventFuture];

Widget _wrapWithProvider(EventService service) {
  return ChangeNotifierProvider<EventService>.value(
    value: service,
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('HomeScreen renders featured and upcoming events', (tester) async {
    final service = EventServiceAdapter(fakeRepository: FakeEventRepository());

    await tester.pumpWidget(_wrapWithProvider(service));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Sự kiện nổi bật'), findsOneWidget);
    expect(find.text('Sự kiện sắp tới'), findsOneWidget);
    expect(find.text('AI Summit'), findsWidgets);
    expect(find.text('Music Fest'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('HomeScreen shows error when load fails', (tester) async {
    final service = EventServiceAdapter(
      fakeRepository: FakeEventRepository(throwAll: true, throwFeatured: true),
    );

    await tester.pumpWidget(_wrapWithProvider(service));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Lỗi:'), findsOneWidget);
  });
}
