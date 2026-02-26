import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final Connectivity _connectivity = Connectivity();
  
  bool isOnline = true;
  Function(int)? onSyncComplete;
  Function(bool)? onConnectionChange;

  SyncService._init();

  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      await _updateConnectionStatus(results);
    });
    
    final results = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(results);
    if (isOnline) {
      syncPendingTasks();
    }
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool hasNetwork = !results.contains(ConnectivityResult.none);
    bool currentlyOnline = false;

    if (hasNetwork) {
      currentlyOnline = await checkRealInternet();
    }
    
    if (currentlyOnline != isOnline) {
      isOnline = currentlyOnline;
      if (onConnectionChange != null) onConnectionChange!(isOnline);
      if (isOnline) {
        syncPendingTasks();
      }
    }
  }

  Future<bool> checkRealInternet() async {
    try {
      final response = await http.get(Uri.parse('http://connectivitycheck.gstatic.com/generate_204'))
          .timeout(const Duration(seconds: 4));
      
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncPendingTasks({Function(String msg)? onProgress}) async {
    final supabase = Supabase.instance.client;
    final tareas = await DatabaseHelper.instance.getTareasPendientes();
    
    if (tareas.isEmpty) return;

    int syncedCount = 0;
    int totalTareas = tareas.length;
    
    int totalFotos = tareas.where((t) => t['tipo_accion'] == 'UPLOAD_PHOTO').length;
    int fotosSubidas = 0;

    for (int i = 0; i < totalTareas; i++) {
      var tarea = tareas[i];
      try {
        final String tipoAccion = tarea['tipo_accion'];
        
        if (onProgress != null) {
            if (tipoAccion == 'UPLOAD_PHOTO') {
                fotosSubidas++;
                onProgress("Subiendo foto $fotosSubidas de $totalFotos...");
            } else {
                onProgress("Finalizando guardado de datos en la nube...");
            }
        }

        final String tabla = tarea['tabla'];
        final Map<String, dynamic> datos = jsonDecode(tarea['datos_json']);
        
        if (tipoAccion == 'UPDATE') {
           final id = datos['id'];
           datos.remove('id'); 
           await supabase.from(tabla).update(datos).eq('id', id);
        } else if (tipoAccion == 'INSERT') {
           await supabase.from(tabla).insert(datos);
        } else if (tipoAccion == 'UPLOAD_PHOTO') {
           final String rutaArchivoLocal = tarea['ruta_archivo_local'];
           final String localUUID = datos['id'].toString();
           datos.remove('id'); 

           final file = File(rutaArchivoLocal);
           if (!await file.exists()) {
              throw Exception('El archivo local de la foto no existe.');
           }

           const String cloudName = 'dg3id8zls'; 
           const String uploadPreset = 'FlutterDani';
           const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

           var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
           request.fields['upload_preset'] = uploadPreset;
           
           request.files.add(await http.MultipartFile.fromPath('file', rutaArchivoLocal));

           final response = await request.send();
           final responseData = await response.stream.bytesToString();

           if (response.statusCode != 200) {
              throw Exception('Error al subir a Cloudinary: $responseData');
           }

           final jsonMap = jsonDecode(responseData);
           final publicUrl = jsonMap['secure_url'];

           datos['direccion'] = publicUrl;

           await supabase.from(tabla).insert(datos);

           await DatabaseHelper.instance.eliminarFotoLocal(localUUID);
        }

        await DatabaseHelper.instance.eliminarTarea(tarea['id']);
        syncedCount++;
      } catch (e) {
        debugPrint("Error sincronizando tarea ${tarea['id']}: $e");
      }
    }

    if (syncedCount > 0 && onSyncComplete != null) {
      onSyncComplete!(syncedCount);
    }
  }
}
