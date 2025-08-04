// lib/evaluacion/screens/home_screen.dart
// ignore_for_file: unused_import, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../custom/appcolors.dart';
import 'package:applensys/evaluacion/providers/text_size_provider.dart';
import 'package:applensys/evaluacion/screens/empresas_screen.dart';
import 'package:applensys/evaluacion/screens/perfil_screen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _selectedIndex;
  late PageController _pageController;
  static const List<Widget> _pages = [
    _DashboardView(),
    EmpresasScreen(),
    PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _pages.length) {
      // Logout
      Supabase.instance.client.auth.signOut();
      Navigator.pushReplacementNamed(context, '/loader');
      return;
    }
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 60,
        backgroundColor: AppColors.primary,
        elevation: 1,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Diagnóstico'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
          NavigationDestination(icon: Icon(Icons.logout), label: 'Salir'),
        ],
      ),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = ref.watch(textSizeProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: () async {
                        final response = await Supabase.instance.client
                            .from('usuarios')
                            .select('foto_url')
                            .eq('id', user?.id ?? '')
                            .maybeSingle();
                        return response != null ? Map<String, dynamic>.from(response) : <String, dynamic>{};
                      }(),
                      builder: (context, snapshot) {
                        final fotoUrl = snapshot.data?['foto_url'] ??
                            user?.userMetadata?['avatar_url'] ??
                            '';
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 30,
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }
                        if (fotoUrl.isNotEmpty) {
                          return CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(fotoUrl),
                          );
                        }
                        return const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person, size: 30),
                        );
                      },
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Sin email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: textSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Bienvenido', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
                const _WeatherWidget(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(child: _DashboardCards()),
        ],
      ),
    );
  }
}

class _DashboardCards extends StatefulWidget {
  const _DashboardCards();

  @override
  State<_DashboardCards> createState() => _DashboardCardsState();
}

class _DashboardCardsState extends State<_DashboardCards> {
  final ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    final newOffset = (_scrollController.offset - 200)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _scrollRight() {
    final newOffset = (_scrollController.offset + 200)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          children: [
            _DashboardCard(
              title: 'Diagnóstico',
              icon: Icons.analytics_outlined,
              bgColor: const Color(0xFFE0E0E0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmpresasScreen()),
              ),
            ),
            const SizedBox(width: 20),
            const _DashboardCard(
              title: 'Próximamente EVSM',
              icon: Icons.upcoming,
              bgColor: Color(0xFFE0E0E0),
            ),
            const SizedBox(width: 20),
            const _DashboardCard(
              title: 'No Disponible',
              icon: Icons.extension,
              bgColor: Color(0xFFE0E0E0),
            ),
          ],
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _scrollLeft,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _scrollRight,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bgColor;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title == 'Diagnóstico')
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/shingomodel.webp',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              )
            else
              Icon(icon, size: 50, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherWidget extends StatelessWidget {
  const _WeatherWidget();

  static const double _defaultLat = 19.432608;
  static const double _defaultLon = -99.133209;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.thermostat, color: Colors.white),
        const SizedBox(width: 5),
        FutureBuilder<double>(
          future: fetchWeatherCelsius(_defaultLat, _defaultLon),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...', style: TextStyle(color: Colors.white));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Sin datos', style: TextStyle(color: Colors.white));
            }
            final temp = snapshot.data!;
            return Text('${temp.toStringAsFixed(1)} °C', style: const TextStyle(color: Colors.white));
          },
        ),
      ],
    );
  }
}

Future<double> fetchWeatherCelsius(double lat, double lon) async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': lat.toString(),
    'longitude': lon.toString(),
    'current_weather': 'true',
    'timezone': 'auto',
  });

  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('Error al obtener clima: ${resp.statusCode}');
  }

  final Map<String, dynamic> data = json.decode(resp.body);
  final tempCelsius = (data['current_weather']['temperature'] as num).toDouble();
  return tempCelsius;
}
