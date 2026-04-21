import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../models/client_dashboard_data.dart';
import 'local_aura_store.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final ValueNotifier<AuthSession?> sessionListenable = ValueNotifier<AuthSession?>(null);

  static const String _tokenKey = 'aura_auth_token';
  static const String _expiresInKey = 'aura_auth_expires_in';
  static const String _rememberMeKey = 'aura_auth_remember_me';
  static const String _userKey = 'aura_auth_user';

  bool get isConfigured => true;
  String get backendBaseUrl => '';
  bool get isAuthenticated => sessionListenable.value != null;
  AuthSession? get currentSession => sessionListenable.value;
  AppUser? get currentUser => sessionListenable.value?.user;
  String? get authToken => sessionListenable.value?.token;
  String? get currentUserId => sessionListenable.value?.user.id;

  Future<void> initialize() async {
    final session = await LocalAuraStore.instance.restoreSession();
    sessionListenable.value = session;
    if (session == null) {
      await LocalAuraStore.instance.saveSession(null);
    }
  }

  Map<String, String> authHeaders({bool jsonContent = true}) {
    final headers = <String, String>{};
    if (jsonContent) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    final session = await LocalAuraStore.instance.registerUser(
      name: name,
      email: email,
      phone: phone,
      password: password,
      rememberMe: rememberMe,
    );
    await _setSession(session);
    return session;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final session = await LocalAuraStore.instance.loginUser(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
    await _setSession(session);
    return session;
  }

  Future<AppUser> refreshMe() async {
    _assertAuthenticated();
    final user = await LocalAuraStore.instance.refreshUser(currentUserId!);
    final current = currentSession!;
    final updatedSession = AuthSession(
      token: current.token,
      expiresIn: current.expiresIn,
      rememberMe: current.rememberMe,
      user: user,
    );
    await _setSession(updatedSession);
    return user;
  }

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
    required AppUserProfile profile,
  }) async {
    _assertAuthenticated();
    final user = await LocalAuraStore.instance.updateUser(
      userId: currentUserId!,
      name: name,
      phone: phone,
      profile: profile,
    );
    final current = currentSession!;
    final updatedSession = AuthSession(
      token: current.token,
      expiresIn: current.expiresIn,
      rememberMe: current.rememberMe,
      user: user,
    );
    await _setSession(updatedSession);
    return user;
  }

  Future<ClientDashboardData> fetchDashboard() async {
    _assertAuthenticated();
    final dashboard = await LocalAuraStore.instance.buildDashboard(currentUserId!);

    final current = currentSession!;
    final updatedSession = AuthSession(
      token: current.token,
      expiresIn: current.expiresIn,
      rememberMe: current.rememberMe,
      user: dashboard.user,
    );
    await _setSession(updatedSession);

    return dashboard;
  }

  Future<void> logout() async {
    sessionListenable.value = null;
    await LocalAuraStore.instance.logout();
  }

  Future<void> setBackendBaseUrl(String value) async {
    return;
  }

  Future<String> ensureBackendBaseUrl({bool forceRefresh = false}) async {
    return '';
  }

  Future<void> _setSession(AuthSession session) async {
    sessionListenable.value = session;
    final prefs = await SharedPreferences.getInstance();
    if (session.rememberMe) {
      await prefs.setString(_tokenKey, session.token);
      await prefs.setString(_expiresInKey, session.expiresIn);
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_userKey, jsonEncode(session.user.toJson()));
      return;
    }

    await _clearStoredSession(prefs);
  }

  Future<void> _clearStoredSession(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresInKey);
    await prefs.remove(_userKey);
    await prefs.remove(_rememberMeKey);
  }

  void _assertAuthenticated() {
    if (!isAuthenticated) {
      throw Exception('You are not signed in');
    }
  }

  void dispose() {
    return;
  }
}
