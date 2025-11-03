class Event {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime date;
  final String location;
  final String category;
  final bool isFeatured;

  Event({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.category,
    this.isFeatured = false,
  });
}
