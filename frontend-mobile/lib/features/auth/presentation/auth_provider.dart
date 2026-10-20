import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/oidc_service.dart';

final authProvider = StreamProvider<void>((ref) async* {
  final auth = EventlyAuth.instance;
  await auth.initialize();

  // Emit initial state so restored sessions appear on startup.
  yield null;

  yield* auth.authChanges;
});