import 'package:flutter/material.dart';
import '../models/room.dart';
import '../utils/django_api.dart';

class RoomProvider with ChangeNotifier {
  List<Room> _rooms = [];

  List<Room> get rooms => _rooms;

  Future<void> loadRooms({
    String? query,
    String? city,
    String? roomType,
    String? furnishing,
    String? preferredTenant,
    double? minPrice,
    double? maxPrice,
    String? amenity,
  }) async {
    try {
      final response = await DjangoApi.getAllRooms(
        query: query,
        city: city,
        roomType: roomType,
        furnishing: furnishing,
        preferredTenant: preferredTenant,
        minPrice: minPrice,
        maxPrice: maxPrice,
        amenity: amenity,
      );
      _rooms = response.map((json) => Room.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load rooms error: $e');
    }
  }

  Future<void> addRoom(Room room) async {
    try {
      await DjangoApi.createRoom(room.toJson());
      _rooms.add(room);
      notifyListeners();
    } catch (e) {
      debugPrint('Add room error: $e');
      rethrow;
    }
  }

  Future<void> updateRoom(Room updatedRoom) async {
    try {
      await DjangoApi.updateRoom(updatedRoom.id, updatedRoom.toJson());
      final index = _rooms.indexWhere((r) => r.id == updatedRoom.id);
      if (index != -1) {
        _rooms[index] = updatedRoom;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update room error: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await DjangoApi.deleteRoom(roomId);
      _rooms.removeWhere((r) => r.id == roomId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete room error: $e');
      rethrow;
    }
  }

  List<Room> getRoomsByOwner(String ownerId) {
    return _rooms.where((r) => r.ownerId == ownerId).toList();
  }
}
