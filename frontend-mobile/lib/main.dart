import 'package:evently_mobile/core/auth/oidc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EventlyAuth.instance.initialize();
  runApp(const ProviderScope(child: EventlyApp()));
}
