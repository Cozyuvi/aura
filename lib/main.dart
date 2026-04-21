import 'package:flutter/material.dart';

import 'src/aura_app.dart';
import 'src/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
  runApp(const AuraApp());
}
