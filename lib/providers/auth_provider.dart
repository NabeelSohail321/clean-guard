import 'dart:convert';
import 'dart:io'; // Required for Platform check

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/api_service.dart';

import '../notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  User? _user;
  bool _loading = true;

  AuthProvider(this._apiService) {
    _init();
  }

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        print('Error parsing user: $e');
        await prefs.remove('user');
      }
    }
    _loading = false;
    notifyListeners();
  }

  // Updated Login Function
  Future<void> login(String email, String password) async {
    try {
      String? deviceToken;
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final notificationService = NotificationServices();
          deviceToken = await notificationService.getDeviceToken();
          print('Device token retrieved: $deviceToken');
        } catch (e) {}
      }

      final response = await _apiService.dio.post('/users/login', data: {
        'email': email,
        'password': password,
        'fcmToken': deviceToken, 
      });

      _user = User.fromJson(response.data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
      notifyListeners();
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 401) {
        throw Exception(e.response?.data['message'] ?? 'Invalid email or password');
      }
      throw Exception('Login failed. Please check your connection and try again.');
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  // Registration Function
  Future<void> register(String name, String email, String password) async {
    try {
      String? deviceToken;
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final notificationService = NotificationServices();
          deviceToken = await notificationService.getDeviceToken();
        } catch (e) {}
      }

      final response = await _apiService.dio.post('/users', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'admin',
        'fcmToken': deviceToken,
      });

      // Handle success but explicitly DO NOT automatically log in 
      // the user, returning them to the login screen instead.
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 400) {
        // Handle specific server rejections (e.g., 'User already exists')
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception('An unexpected edge error occurred during registration.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    print('Starting logout process...');
    final oldToken = _user?.token;
    
    // Clear local state immediately for instant feedback
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
    
    try {
      if (oldToken != null) {
        print('Informing backend about logout (background)...');
        await _apiService.dio.post('/users/logout');
      }
    } catch (e) {
      print('Logout API error (ignoring): $e');
    } finally {
      print('Logout complete.');
    }
  }
}