import 'package:applensys/auth/loader.dart';
import 'package:applensys/auth/login.dart';
import 'package:applensys/auth/recovery.dart';
import 'package:applensys/auth/register.dart';
import 'package:applensys/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/custom/configurations.dart';
import 'package:applensys/custom/service_locator.dart';
import 'package:applensys/evaluacion/providers/text_size_provider.dart';
import 'package:applensys/evaluacion/providers/theme_provider.dart';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:applensys/evaluacion/widgets/actualizaciones.dart';
import 'package:applensys/evaluacion/services/local_storage_service.dart';
import 'package:applensys/evaluacion/services/sincronizacion_service.dart';

Future<void> verificarActualizacion(BuildContext context) async {
  final response = await Supabase.instance.client
      .from('actualizaciones')
      .select('version, descripcion, url')
      .order('id', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response != null) {
    final String nuevaVersion = response['version'];
    final String descripcion = response['descripcion'];
    final String url = response['url'];

    const String versionActual = '1.0.0'; // Cambia esto según tu versión actual

    if (nuevaVersion != versionActual) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Nueva Actualización Disponible'),
            content: Text('Versión: $nuevaVersion\n\n$descripcion'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Abre el enlace de descarga
                  launchUrl(Uri.parse(url));
                },
                child: const Text('Actualizar'),
              ),
            ],
          );
        },
      );
    }
  }
}

final sincronizacionServiceProvider = Provider((ref) => SincronizacionService());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Configurations.mSupabaseUrl,
    anonKey: Configurations.mSupabaseKey,
  );
  setupLocator();
  await locator<EvaluacionCacheService>().init();

  // Inicializar Hive para persistencia local
  final localStorageService = LocalStorageService();
  await localStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        sincronizacionServiceProvider.overrideWithValue(SincronizacionService()),
      ],
      child: const ActualizacionesWrapper(child: MyApp()),
    ),
  );
}

class ActualizacionesWrapper extends StatelessWidget {
  final Widget child;

  const ActualizacionesWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActualizacionesWidget.mostrarDialogoActualizacion(context);
    });
    return child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);
    final scaleFactor = textSize / 14.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'applensys',
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
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF000000),
        scaffoldBackgroundColor: const Color.fromARGB(75, 206, 206, 206),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(75, 206, 206, 206),
          foregroundColor: Colors.black,
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
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