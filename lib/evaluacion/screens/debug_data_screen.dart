// Herramienta de debug para verificar datos reales
import 'package:flutter/material.dart';
import '../services/local/evaluacion_cache_service.dart';
import 'tablas_screen.dart';

class DebugDataScreen extends StatefulWidget {
  final String evaluacionId;
  
  const DebugDataScreen({super.key, required this.evaluacionId});

  @override
  State<DebugDataScreen> createState() => _DebugDataScreenState();
}

class _DebugDataScreenState extends State<DebugDataScreen> {
  Map<String, dynamic> debugInfo = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final cache = EvaluacionCacheService();
      await cache.init();
      
      // Datos del cache
      final cachedData = await cache.cargarTablas();
      
      // Datos estáticos en memoria
      final staticData = TablasDimensionScreen.tablaDatos;
      
      // Conteo de evaluaciones por dimensión
      final counts = <String, Map<String, int>>{};
      
      cachedData.forEach((dimension, evaluaciones) {
        counts[dimension] = {};
        evaluaciones.forEach((evalId, filas) {
          if (evalId == widget.evaluacionId) {
            counts[dimension]![evalId] = filas.length;
          }
        });
      });
      
      setState(() {
        debugInfo = {
          'cachedDataKeys': cachedData.keys.toList(),
          'staticDataKeys': staticData.keys.toList(),
          'evaluationCounts': counts,
          'totalEvaluations': counts.values
              .expand((evalMap) => evalMap.values)
              .fold<int>(0, (sum, count) => sum + count),
          'hasRealData': counts.values.any((evalMap) => 
              evalMap.values.any((count) => count > 0)),
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        debugInfo = {'error': e.toString()};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Verificar Datos'),
        backgroundColor: const Color(0xFF003056),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado de los datos
                  Card(
                    color: debugInfo['hasRealData'] == true 
                        ? Colors.green.shade100 
                        : Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debugInfo['hasRealData'] == true 
                                ? '✅ DATOS REALES ENCONTRADOS'
                                : '❌ NO HAY DATOS REALES',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: debugInfo['hasRealData'] == true 
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total de evaluaciones: ${debugInfo['totalEvaluations'] ?? 0}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Detalle por dimensión
                  const Text(
                    'Evaluaciones por Dimensión:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: ListView(
                      children: (debugInfo['evaluationCounts'] as Map<String, Map<String, int>>? ?? {})
                          .entries
                          .map((dimEntry) {
                        final dimension = dimEntry.key;
                        final evaluaciones = dimEntry.value;
                        
                        return Card(
                          child: ListTile(
                            title: Text(dimension),
                            subtitle: evaluaciones.isEmpty
                                ? const Text('Sin evaluaciones')
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: evaluaciones.entries
                                        .map((evalEntry) => Text(
                                            '${evalEntry.key}: ${evalEntry.value} calificaciones'))
                                        .toList(),
                                  ),
                            trailing: Icon(
                              evaluaciones.values.any((count) => count > 0)
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: evaluaciones.values.any((count) => count > 0)
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Información adicional
                  if (debugInfo['error'] != null)
                    Card(
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error: ${debugInfo['error']}',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
