// ignore_for_file: unrelated_type_equality_checks

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';

class SincronizacionService {
  final SupabaseClient _client = Supabase.instance.client;
  final LocalStorageService _localStorage = LocalStorageService();
  final Connectivity _connectivity = Connectivity();

  Future<void> sincronizarDatos(String key, dynamic data) async {
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      try {
        // Intentar sincronizar con Supabase
        await _client.from('datos').upsert({'key': key, 'data': data});
      } catch (e) {
        // Si falla, guardar en Hive
        await _localStorage.saveData(key, data);
      }
    } else {
      // Sin conexión, guardar en Hive
      await _localStorage.saveData(key, data);
    }
  }

  Future<dynamic> obtenerDatos(String key) async {
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      try {
        // Intentar obtener datos de Supabase
        final response = await _client.from('datos').select().eq('key', key).single();
        return response['data'];
      } catch (e) {
        // Si falla, obtener de Hive
        return _localStorage.getData(key);
      }
    } else {
      // Sin conexión, obtener de Hive
      return _localStorage.getData(key);
    }
  }
}