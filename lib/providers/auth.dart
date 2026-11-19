import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_role.dart';
import '../core/api.dart';
import '../models/models.dart';

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

/// The logged-in account (null when signed out). Restores the saved session on start.
final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AppUser?> {
  ApiClient get _api => ref.read(apiProvider);

  @override
  Future<AppUser?> build() async {
    _api.onUnauthorized = () {
      _api.setToken(null);
      state = const AsyncData(null);
    };
    final token = await _api.loadToken();
    if (token == null) return null;
    try {
      final res = await _api.get('/auth/me');
      return AppUser.fromJson(res['user']);
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.statusCode == 403) {
        await _api.setToken(null);
        return null;
      }
      rethrow;
    }
  }

  Future<void> _accept(Map<String, dynamic> res) async {
    await _api.setToken(res['token'] as String);
    state = AsyncData(AppUser.fromJson(res['user']));
  }

  Future<void> login(String email, String password) async {
    final res = await _api.post('/auth/login', {'email': email.trim(), 'password': password, 'role': kAppRole});
    await _accept(res);
  }

  Future<void> labourLogin(String phone, String pin) async {
    final res = await _api.post('/auth/labour/login', {'phone': phone.trim(), 'pin': pin.trim()});
    await _accept(res);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String? profession,
    String? company,
  }) async {
    final res = await _api.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': phone.trim(),
      'role': kAppRole,
      'profession': ?profession,
      if (company != null && company.trim().isNotEmpty) 'company': company.trim(),
    });
    await _accept(res);
  }

  Future<void> refresh() async {
    final res = await _api.get('/auth/me');
    state = AsyncData(AppUser.fromJson(res['user']));
  }

  Future<void> updateProfile(Map<String, dynamic> changes) async {
    final res = await _api.patch('/auth/me', changes);
    state = AsyncData(AppUser.fromJson(res['user']));
  }

  Future<void> changePassword(String current, String next) =>
      _api.post('/auth/change-password', {'currentPassword': current, 'newPassword': next});

  Future<void> deleteAccount(String password) async {
    await _api.delete('/auth/me', {'password': password});
    await logout();
  }

  Future<void> logout() async {
    await _api.setToken(null);
    state = const AsyncData(null);
  }
}

/// Whether the onboarding slides have been seen on this device.
final onboardingSeenProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends AsyncNotifier<bool> {
  static const _key = 'onboarding_seen';
  final _storage = const FlutterSecureStorage();

  @override
  Future<bool> build() async {
    try {
      return await _storage.read(key: _key) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> markSeen() async {
    state = const AsyncData(true);
    try {
      await _storage.write(key: _key, value: '1');
    } catch (_) {}
  }
}
