// rumipa3/lib/src/models/room_model.dart

class RoomModel {
  final String id;
  final String name;
  final int capacity;
  final String description;
  final bool isAvailable;

  RoomModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.description,
    required this.isAvailable,
  });

  factory RoomModel.fromMap(Map<String, dynamic> m) => RoomModel(
    id: m['id'],
    name: m['name'],
    capacity: m['capacity'] ?? 0,
    description: m['description'] ?? '',
    isAvailable: m['is_available'] ?? true,
  );
}
