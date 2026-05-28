import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ns_transport/core/constants/api_constants.dart';
import 'package:ns_transport/core/theme/app_theme.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NSTransportApp(),
    ),
  );
}

class NSTransportApp extends ConsumerWidget {
  const NSTransportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'NS Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: ThemeData.dark(), // Provide darkTheme implementation if available in AppTheme
      themeMode: themeMode,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
