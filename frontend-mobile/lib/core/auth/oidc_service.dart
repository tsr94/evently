
import 'package:flutter/foundation.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';
import 'dart:convert';
import 'dart:async';

class EventlyAuth {
  EventlyAuth._();

  static final instance = EventlyAuth._();

  static const realm = 'event-ticket-platform';
  static const clientId = 'evently-frontend';

  // The Web callback must be served from the Flutter Web origin.
  static const webRedirect = 'http://localhost:62100/redirect.html';

  static const androidRedirect =
      'com.example.eventlymobile:/oauth2redirect';

  static const webKeycloak = 'http://localhost:9090';

  // Android emulator
  static const androidKeycloak = 'http://10.0.2.2:9090';

  // Physical Android phone: replace with your PC's IPv4 address.
  static const androidPhysicalKeycloak =
      'http://192.168.29.104:9090';

  // Set true for a physical phone; false for an emulator.
  static const bool usePhysicalAndroid = true;

  late final OidcUserManager manager;
  bool _initialized = false;
  final _authChanges = StreamController<void>.broadcast();

  Stream<void> get authChanges => _authChanges.stream;

  String? get userName {
    final claims = manager.currentUser?.claims;
    return claims?['preferred_username'] as String? ??
        claims?['name'] as String?;
  }

  String? get userEmail =>
      manager.currentUser?.claims['email'] as String?;

  String? get userPicture =>
      manager.currentUser?.claims['picture'] as String?;

  String get keycloakUrl {
    if (kIsWeb) return webKeycloak;

    if (defaultTargetPlatform == TargetPlatform.android &&
        usePhysicalAndroid) {
      return androidPhysicalKeycloak;
    }

    return androidKeycloak;
  }

  Uri get redirectUri => Uri.parse(
        kIsWeb ? webRedirect : androidRedirect,
      );

  Uri get discoveryUri => Uri.parse(
        '$keycloakUrl/realms/$realm/.well-known/openid-configuration',
      );

  Future<void> initialize() async {
    if (_initialized) return;

    manager = OidcUserManager.lazy(
      discoveryDocumentUri: discoveryUri,
      clientCredentials: const OidcClientAuthentication.none(
        clientId: clientId,
      ),
      store: OidcDefaultStore(),
      settings: OidcUserManagerSettings(
        redirectUri: redirectUri,
        postLogoutRedirectUri: redirectUri,
        scope: const ['openid', 'profile', 'email'],
      ),
    );

    await manager.init();
    manager.userChanges().listen((_) {
      _authChanges.add(null);
    });
    _initialized = true;
  }

  Future<Set<String>> getRoles() async {
    await initialize();

    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return {};
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};

      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(normalized)),
      ) as Map<String, dynamic>;

      final realmAccess = payload['realm_access'];
      if (realmAccess is! Map) return {};

      final roles = realmAccess['roles'];
      if (roles is! List) return {};

      return roles.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> isStaff() async {
    final roles = await getRoles();
    return roles.contains('ROLE_STAFF');
  }

  Future<void> login() async {
    await initialize();
    await manager.loginAuthorizationCodeFlow();
    _authChanges.add(null);
  }

  Future<void> logout() async {
    await initialize();
    await manager.logout();
    _authChanges.add(null);
  }

  Future<String?> getAccessToken() async {
    await initialize();
    return manager.getAccessToken();
  }

  bool get isLoggedIn => _initialized && manager.currentUser != null;
}
