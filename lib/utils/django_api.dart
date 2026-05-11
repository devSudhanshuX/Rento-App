import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

/// Django API Helper - Connects to Django backend which uses Supabase as database
class DjangoApi {
  // Django server URL (running on port 8000)
  // Use 127.0.0.1 for local, or your IP for simulator
  static String get baseUrl => 'http://127.0.0.1:8000';

  // ============ USER API ============

  /// Register user
  static Future<Map<String, dynamic>> registerUser(
    String name,
    String email,
    String phone,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      }),
    );
    return json.decode(response.body);
  }

  /// Register user (alt)
  static Future<Map<String, dynamic>> registerUserWithData(
    Map<String, dynamic> userData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    return json.decode(response.body);
  }

  /// Get user by ID
  static Future<Map<String, dynamic>> getUser(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/$userId'));
    return json.decode(response.body);
  }

  /// Update user
  static Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$userId/update'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  /// Get profile dashboard summary counts
  static Future<Map<String, dynamic>> getProfileSummary(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$userId/summary'),
    );
    return json.decode(response.body);
  }

  /// Upload profile photo through Django. Django creates/uses the configured
  /// Supabase Storage bucket with the service key.
  static Future<Map<String, dynamic>> uploadProfilePhoto(
    String userId,
    XFile image,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/users/$userId/photo'),
    );
    final bytes = await image.readAsBytes();
    final fileName = image.name.isEmpty ? 'profile-photo.jpg' : image.name;
    final contentType =
        image.mimeType ??
        lookupMimeType(fileName, headerBytes: bytes) ??
        'image/jpeg';

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Profile photo upload failed');
    }

    return data;
  }

  /// Submit support/report issue request
  static Future<Map<String, dynamic>> createSupportTicket(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/support/report'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  // ============ ROOM API ============

  /// Get all rooms
  static Future<List<Map<String, dynamic>>> getAllRooms({
    String? query,
    String? city,
    String? roomType,
    String? furnishing,
    String? preferredTenant,
    double? minPrice,
    double? maxPrice,
    String? amenity,
  }) async {
    final params = <String, String>{};

    void addParam(String key, Object? value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text == 'All') return;
      params[key] = text;
    }

    addParam('q', query);
    addParam('city', city);
    addParam('roomType', roomType);
    addParam('furnishing', furnishing);
    addParam('preferredTenant', preferredTenant);
    addParam('minPrice', minPrice);
    addParam('maxPrice', maxPrice);
    addParam('amenity', amenity);

    final uri = Uri.parse(
      '$baseUrl/api/rooms/',
    ).replace(queryParameters: params);
    final response = await http.get(uri);
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Get room by ID
  static Future<Map<String, dynamic>> getRoom(String roomId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/rooms/$roomId'));
    return json.decode(response.body);
  }

  /// Get rooms by owner
  static Future<List<Map<String, dynamic>>> getRoomsByOwner(
    String ownerId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/owner/$ownerId'),
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Create room
  static Future<Map<String, dynamic>> createRoom(
    Map<String, dynamic> roomData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(roomData),
    );
    return json.decode(response.body);
  }

  /// Upload room images through Django. Django uses the Supabase service key,
  /// so the Storage bucket does not need public upload policies.
  static Future<List<String>> uploadRoomImages(
    String roomId,
    List<XFile> images,
  ) async {
    if (images.isEmpty) return [];

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/rooms/images/upload'),
    );
    request.fields['roomId'] = roomId;

    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final bytes = await image.readAsBytes();
      final fileName = image.name.isEmpty
          ? 'room-photo-$index.jpg'
          : image.name;
      final contentType =
          image.mimeType ??
          lookupMimeType(fileName, headerBytes: bytes) ??
          'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Image upload failed');
    }

    return List<String>.from(data['images'] ?? []);
  }

  /// Update room
  static Future<Map<String, dynamic>> updateRoom(
    String roomId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/rooms/$roomId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  /// Delete room
  static Future<void> deleteRoom(String roomId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/rooms/$roomId'));
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Unable to delete room');
    }
  }

  // ============ SAVED ROOM API ============

  /// Get rooms saved by user
  static Future<List<Map<String, dynamic>>> getSavedRooms(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/saved/$userId'),
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Save or unsave a room
  static Future<Map<String, dynamic>> toggleSavedRoom(
    String userId,
    String roomId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/saved/toggle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'roomId': roomId}),
    );
    return json.decode(response.body);
  }

  // ============ NOTIFICATION API ============

  /// Get notifications for user
  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/notifications/$userId'),
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Create notification
  static Future<Map<String, dynamic>> createNotification(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/notifications/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  /// Mark notification read
  static Future<Map<String, dynamic>> markNotificationRead(
    String notificationId,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/rooms/notifications/$notificationId/read'),
    );
    return json.decode(response.body);
  }

  // ============ INQUIRY API ============

  /// Contact room owner
  static Future<Map<String, dynamic>> createInquiry(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/inquiries/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  /// Get inquiries for room owner
  static Future<List<Map<String, dynamic>>> getOwnerInquiries(
    String ownerId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/inquiries/owner/$ownerId'),
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Get inquiries made by tenant
  static Future<List<Map<String, dynamic>>> getTenantInquiries(
    String tenantId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/inquiries/tenant/$tenantId'),
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // ============ REVIEW API ============

  /// Create a review/rating
  static Future<Map<String, dynamic>> createReview(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/reviews/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  /// Reviews received by user
  static Future<List<Map<String, dynamic>>> getReviewsForUser(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/reviews/received/$userId'),
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Reviews written by user
  static Future<List<Map<String, dynamic>>> getReviewsByUser(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/reviews/given/$userId'),
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // ============ HEALTH CHECK ============

  /// Check if Django server is running
  static Future<bool> checkServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
