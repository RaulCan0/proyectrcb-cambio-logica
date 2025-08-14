import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:applensys/auth/loader.dart';
import 'package:applensys/auth/login.dart';
import 'package:applensys/auth/recovery.dart';
import 'package:applensys/auth/register.dart';
import 'package:applensys/home.dart';

import 'package:applensys/custom/configurations.dart';
import 'package:applensys/custom/service_locator.dart';

import 'package:applensys/evaluacion/providers/text_size_provider.dart';
import 'package:applensys/evaluacion/providers/theme_provider.dart';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación opcional (bloquea a portrait; elimina si no lo quieres)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa Supabase
  await Supabase.initialize(
    url: Configurations.mSupabaseUrl,
    anonKey: Configurations.mSupabaseKey,
    // Ajustes útiles para prod
    debug: kDebugMode,
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 5,
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // Service locator + cache local
  setupLocator();
  await locator<EvaluacionCacheService>().init();

  // Widget de error amistoso (evita Red Screen en prod)
  ErrorWidget.builder = (details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ocurrió un error inesperado.\nIntenta nuevamente.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);

    // Evita escalas extremas que rompan layouts
    final clampedScale = (textSize / 14.0).clamp(0.85, 1.35);

    final baseLight = ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF003056),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF003056),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
    );

    final baseDark = ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.black,
        onPrimary: Colors.white,
        surface: Color.fromARGB(75, 206, 206, 206),
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: const Color.fromARGB(75, 206, 206, 206),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(75, 206, 206, 206),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'applensys',
      themeMode: themeMode,
      builder: (context, child) {
        // Escalado global de tipografías controlado por provider
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(clampedScale.toDouble()),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: baseLight,
      darkTheme: baseDark,
      // Rutas declarativas (mantengo tus rutas tal cual)
      routes: {
        '/loaderScreen': (_) => const LoaderScreen(),
        '/login': (_) => const Login(),
        '/register': (_) => const RegisterScreen(),
        '/recovery': (_) => const Recovery(),
        '/home': (_) => const HomeScreen(),
      },
      home: const LoaderScreen(),
    );
  }
}

/*
import 'package:applensys/auth/loader.dart';
import 'package:applensys/auth/login.dart';
import 'package:applensys/auth/recovery.dart';
import 'package:applensys/auth/register.dart';
import 'package:applensys/evaluacion/providers/text_size_provider.dart';
import 'package:applensys/evaluacion/providers/theme_provider.dart';
import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:applensys/home_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:applensys/custom/configurations.dart';
import 'package:applensys/custom/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  await Supabase.initialize(
    url: Configurations.mSupabaseUrl,
    anonKey: Configurations.mSupabaseKey,
  );

  setupLocator();
  await locator<EvaluacionCacheService>().init();

  runApp(const ProviderScope(child: MyApp()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);
    final scaleFactor = (textSize / 14.0).clamp(0.8, 2.0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'applensys',
      navigatorKey: navigatorKey,
      themeMode: themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF003056),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003056),
          foregroundColor: Colors.white,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color.fromARGB(75, 206, 206, 206),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(75, 206, 206, 206),
          foregroundColor: Colors.black,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      routes: {
        '/loaderScreen': (_) => const LoaderScreen(),
        '/login': (_) => const Login(),
        '/register': (_) => const RegisterScreen(),
        '/recovery': (_) => const Recovery(),
        '/home': (_) => const HomeScreen(),
      },
      home: const LoaderScreen(),
    );
  }
}
*/