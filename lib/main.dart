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
      home: const HomeScreen(),
    );
  }
}
