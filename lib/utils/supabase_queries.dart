import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Database Queries Helper
/// This class provides clean methods for Supabase database operations
class SupabaseQueries {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ============ USER QUERIES ============

  /// Get user by ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Create or update the profile row linked to a Supabase Auth user.
  static Future<Map<String, dynamic>> upsertUserProfile(
    Map<String, dynamic> userData,
  ) async {
    final response = await _supabase
        .from('users')
        .upsert(userData)
        .select()
        .single();
    return response;
  }

  /// Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _supabase.from('users').select();
    return response;
  }

  /// Update user profile
  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('users').update(data).eq('id', userId);
  }

  // ============ ROOM QUERIES ============

  /// Get all rooms
  static Future<List<Map<String, dynamic>>> getAllRooms() async {
    final response = await _supabase
        .from('rooms')
        .select()
        .order('createdAt', ascending: false);
    return response;
  }

  /// Get room by ID
  static Future<Map<String, dynamic>?> getRoomById(String roomId) async {
    final response = await _supabase
        .from('rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    return response;
  }

  /// Get rooms by owner
  static Future<List<Map<String, dynamic>>> getRoomsByOwner(
    String ownerId,
  ) async {
    final response = await _supabase
        .from('rooms')
        .select()
        .eq('ownerId', ownerId);
    return response;
  }

  /// Search rooms by location
  static Future<List<Map<String, dynamic>>> searchRooms(String query) async {
    final response = await _supabase
        .from('rooms')
        .select()
        .or('location.ilike.*$query*,title.ilike.*$query*');
    return response;
  }

  /// Create a new room
  static Future<void> createRoom(Map<String, dynamic> roomData) async {
    await _supabase.from('rooms').insert(roomData);
  }

  /// Update room
  static Future<void> updateRoom(
    String roomId,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('rooms').update(data).eq('id', roomId);
  }

  /// Delete room
  static Future<void> deleteRoom(String roomId) async {
    await _supabase.from('rooms').delete().eq('id', roomId);
  }

  // ============ STORAGE QUERIES ============

  /// Upload room image to Supabase Storage
  static Future<String> uploadRoomImage(
    String roomId,
    Uint8List fileBytes,
    String fileName,
    String? contentType,
  ) async {
    final path = '$roomId/$fileName';

    await _supabase.storage
        .from('room-images')
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: contentType,
          ),
        );

    final publicUrl = _supabase.storage.from('room-images').getPublicUrl(path);
    return publicUrl;
  }

  /// Get public URL for an image
  static String getImageUrl(String path) {
    return _supabase.storage.from('room-images').getPublicUrl(path);
  }

  /// Delete room image
  static Future<void> deleteRoomImage(String path) async {
    await _supabase.storage.from('room-images').remove([path]);
  }

  // ============ MESSAGING QUERIES ============

  /// Send a message to room owner
  static Future<void> sendMessage({
    required String roomId,
    required String tenantId,
    required String message,
  }) async {
    await _supabase.from('messages').insert({
      'roomId': roomId,
      'tenantId': tenantId,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get messages for a room
  static Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('roomId', roomId)
        .order('createdAt', ascending: true);
    return response;
  }

  /// Get messages for owner
  static Future<List<Map<String, dynamic>>> getMessagesForOwner(
    String ownerId,
  ) async {
    // First get owner's room IDs
    final rooms = await getRoomsByOwner(ownerId);
    final roomIds = rooms.map((r) => r['id']).toList();

    if (roomIds.isEmpty) return [];

    // Use filter with 'in' - need to use filter() method with proper syntax
    final response = await _supabase
        .from('messages')
        .select()
        .filter('roomId', 'in', roomIds)
        .order('createdAt', ascending: false);
    return response;
  }
}
