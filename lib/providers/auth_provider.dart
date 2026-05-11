import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as user_model;
import '../utils/django_api.dart';
import '../utils/supabase_queries.dart';

class AuthProvider with ChangeNotifier {
  user_model.User? _currentUser;
  bool _isLoading = false;
  String? _message;
  final SupabaseClient _supabase = Supabase.instance.client;

  user_model.User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get hasSupabaseSession => _supabase.auth.currentSession != null;

  bool get isLoading => _isLoading;

  String? get message => _message;

  Future<bool> login(String email, String password) async {
    return _runAuthAction(() async {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        await _loadProfile(response.user!);
        return true;
      }

      _message = 'Unable to sign in. Please check your details.';
      return false;
    });
  }

  Future<bool> signup(
    String name,
    String email,
    String phone,
    String password,
    user_model.UserRole role,
  ) async {
    return _runAuthAction(() async {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim(), 'phone': phone.trim(), 'role': role.name},
      );

      if (response.user != null) {
        if (response.session == null) {
          _currentUser = null;
          _message = 'Account created. Please confirm your email, then log in.';
          return false;
        }

        await _saveProfile(
          id: response.user!.id,
          name: name,
          email: email,
          phone: phone,
          role: role,
        );

        if (_currentUser == null) {
          _currentUser = user_model.User(
            id: response.user!.id,
            name: name.trim(),
            email: email.trim(),
            phone: phone.trim(),
            role: role,
          );
          await _saveUserLocally();
        }

        return true;
      }

      _message = 'Unable to create your account. Please try again.';
      return false;
    });
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      final response = await DjangoApi.updateUser(_currentUser!.id, data);
      if (response['error'] != null &&
          response['error'].toString().contains('not found')) {
        final registered = await DjangoApi.registerUserWithData({
          ..._currentUser!.toJson(),
          ...data,
        });
        _currentUser = user_model.User.fromJson(
          Map<String, dynamic>.from(registered['user'] ?? registered),
        );
      } else if (response['user'] != null) {
        _currentUser = user_model.User.fromJson(
          Map<String, dynamic>.from(response['user']),
        );
      } else {
        _currentUser = _currentUserFromPatch(data);
      }

      await _syncSupabaseProfile(data);
      await _saveUserLocally();
      return true;
    } catch (_) {
      _currentUser = _currentUserFromPatch(data);
      await _syncSupabaseProfile(data);
      await _saveUserLocally();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfilePhoto(XFile image) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      final response = await DjangoApi.uploadProfilePhoto(_currentUser!.id, image);
      final userData = response['user'];
      if (userData is Map<String, dynamic>) {
        _currentUser = user_model.User.fromJson(userData);
      } else {
        _currentUser = _currentUser!.copyWith(
          profilePhotoUrl: response['profilePhotoUrl']?.toString() ?? '',
        );
      }
      await _syncSupabaseProfile({
        'profilePhotoUrl': _currentUser!.profilePhotoUrl,
      });
      await _saveUserLocally();
      return true;
    } catch (e) {
      if (e.toString().contains('User not found')) {
        await _registerOrUpdateDjangoProfile();
        try {
          final response = await DjangoApi.uploadProfilePhoto(
            _currentUser!.id,
            image,
          );
          final userData = response['user'];
          if (userData is Map<String, dynamic>) {
            _currentUser = user_model.User.fromJson(userData);
          }
          await _saveUserLocally();
          return true;
        } catch (_) {}
      }
      _message = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String password) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(UserAttributes(password: password));
      return true;
    } on AuthException catch (e) {
      _message = e.message;
      return false;
    } catch (_) {
      _message = 'Unable to update password. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadProfile(session.user);
      notifyListeners();
      return;
    }

    await prefs.remove('user');
    _currentUser = null;
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<bool> Function() action) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      return await action();
    } on AuthException catch (e) {
      _message = e.message;
      return false;
    } catch (_) {
      _message = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(User supabaseUser) async {
    final metadata = supabaseUser.userMetadata ?? {};

    try {
      final apiUser = await DjangoApi.getUser(supabaseUser.id);
      if (apiUser['error'] == null) {
        _currentUser = user_model.User.fromJson(apiUser);
        await _saveUserLocally();
        return;
      }
    } catch (_) {
      // Fall back to the Supabase profile row below when Django is offline.
    }

    try {
      var userData = await SupabaseQueries.getUserById(supabaseUser.id);

      userData ??= await SupabaseQueries.upsertUserProfile({
        'id': supabaseUser.id,
        'name': metadata['name'] ?? '',
        'email': supabaseUser.email ?? '',
        'phone': metadata['phone'] ?? '',
        'role': metadata['role'] ?? user_model.UserRole.tenant.name,
      });

      _currentUser = user_model.User.fromJson(userData);
      await _registerOrUpdateDjangoProfile();
    } on PostgrestException {
      _currentUser = _userFromSupabaseAuth(supabaseUser);
      await _registerOrUpdateDjangoProfile();
    }

    await _saveUserLocally();
  }

  Future<void> _saveProfile({
    required String id,
    required String name,
    required String email,
    required String phone,
    required user_model.UserRole role,
  }) async {
    try {
      final userData = await SupabaseQueries.upsertUserProfile({
        'id': id,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role.name,
      });

      _currentUser = user_model.User.fromJson(userData);
      await _registerOrUpdateDjangoProfile();
      await _saveUserLocally();
    } on PostgrestException {
      _currentUser = user_model.User(
        id: id,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
      );
      await _registerOrUpdateDjangoProfile();
      await _saveUserLocally();
    }
  }

  Future<void> _saveUserLocally() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('user', json.encode(_currentUser!.toJson()));
    }
  }

  user_model.User _userFromSupabaseAuth(User supabaseUser) {
    final metadata = supabaseUser.userMetadata ?? {};
    final roleName = metadata['role']?.toString();

    return user_model.User(
      id: supabaseUser.id,
      name: metadata['name']?.toString() ?? '',
      email: supabaseUser.email ?? '',
      phone: metadata['phone']?.toString() ?? '',
      role: user_model.UserRole.values.firstWhere(
        (role) => role.name == roleName,
        orElse: () => user_model.UserRole.tenant,
      ),
    );
  }

  Future<void> _registerOrUpdateDjangoProfile() async {
    if (_currentUser == null) return;

    try {
      final response = await DjangoApi.registerUserWithData(_currentUser!.toJson());
      final userData = response['user'];
      if (userData is Map<String, dynamic>) {
        _currentUser = user_model.User.fromJson(userData);
        return;
      }
    } catch (_) {
      // The update attempt below handles existing users and offline servers.
    }

    try {
      final response = await DjangoApi.updateUser(
        _currentUser!.id,
        _currentUser!.toJson(),
      );
      final userData = response['user'];
      if (userData is Map<String, dynamic>) {
        _currentUser = user_model.User.fromJson(userData);
      }
    } catch (_) {
      // Local auth should continue even if the optional Django mirror is down.
    }
  }

  Future<void> _syncSupabaseProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    try {
      await SupabaseQueries.updateUser(_currentUser!.id, data);
    } catch (_) {
      // Some older Supabase profile tables may not have the newer columns yet.
    }

    final metadata = <String, dynamic>{};
    if (data['name'] != null) metadata['name'] = data['name'];
    if (data['phone'] != null) metadata['phone'] = data['phone'];
    if (data['role'] != null) metadata['role'] = data['role'];
    if (metadata.isNotEmpty) {
      try {
        await _supabase.auth.updateUser(UserAttributes(data: metadata));
      } catch (_) {}
    }
  }

  user_model.User _currentUserFromPatch(Map<String, dynamic> data) {
    final current = _currentUser!;
    final roleName = data['role']?.toString();

    return current.copyWith(
      name: data['name']?.toString(),
      phone: data['phone']?.toString(),
      role: roleName == null
          ? null
          : user_model.UserRole.values.firstWhere(
              (role) => role.name == roleName,
              orElse: () => current.role,
            ),
      profilePhotoUrl: data['profilePhotoUrl']?.toString(),
      alternateContact: data['alternateContact']?.toString(),
      gender: data['gender']?.toString(),
      dateOfBirth: data['dateOfBirth'] == null
          ? null
          : DateTime.tryParse(data['dateOfBirth'].toString()),
      clearDateOfBirth: data.containsKey('dateOfBirth') &&
          (data['dateOfBirth']?.toString().isEmpty ?? true),
      isVerified: data['isVerified'],
      emailNotifications: data['emailNotifications'],
      smsNotifications: data['smsNotifications'],
      language: data['language']?.toString(),
      appTheme: data['appTheme']?.toString(),
      locationEnabled: data['locationEnabled'],
      profileVisibility: data['profileVisibility']?.toString(),
      twoFactorEnabled: data['twoFactorEnabled'],
    );
  }
}
