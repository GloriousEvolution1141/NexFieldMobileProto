import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'revision_foto_page.dart';
import '../widgets/sincronizacion_dialog.dart';

class SuministroDetallePage extends StatefulWidget {
  final Map<String, dynamic> suministro;

  const SuministroDetallePage({super.key, required this.suministro});

  @override
  State<SuministroDetallePage> createState() => _SuministroDetallePageState();
}

class _SuministroDetallePageState extends State<SuministroDetallePage> {
  bool _isLoading = true;
  bool isExiting = false;
  List<dynamic> _fotos = [];

  String _localPathBase = '';

  @override
  void initState() {
    super.initState();
    _initPath();
    _cargarFotos();
  }

  Future<void> _initPath() async {
    final directory = await getApplicationDocumentsDirectory();
    _localPathBase = directory.path;
  }

  Future<void> _cargarFotos() async {
    try {
      final suId = widget.suministro['id'].toString();

      if (_localPathBase.isEmpty) {
        await _initPath();
      }

      final fotosLocal = await DatabaseHelper.instance.getFotosBySuministro(
        suId,
      );

      final List<dynamic> fotosProcesadas = [];
      for (var f in fotosLocal) {
        final String fotoId = f['id'].toString();
        final File localFile = File('$_localPathBase/$fotoId.jpg');
        final bool existeLocal = await localFile.exists();

        fotosProcesadas.add({
          ...f,
          '_localFile': existeLocal ? localFile : null,
        });
      }

      if (mounted) {
        setState(() {
          _fotos = fotosProcesadas;
          _isLoading = false;
        });
      }

      if (fotosProcesadas.isNotEmpty) return;

      if (!SyncService.instance.isOnline) return;

      final response = await Supabase.instance.client
          .from('fotos')
          .select('*')
          .eq('suministro_id', suId);

      if (response.isNotEmpty) {
        await DatabaseHelper.instance.syncFotos(suId, response);

        final refFotos =
            await DatabaseHelper.instance.getFotosBySuministro(suId);

        final List<dynamic> refFotosProcesadas = [];
        for (var f in refFotos) {
          final String fotoId = f['id'].toString();
          final File testFile = File('$_localPathBase/$fotoId.jpg');
          final bool existe = await testFile.exists();

          refFotosProcesadas.add({
            ...f,
            '_localFile': existe ? testFile : null,
          });
        }

        if (mounted) {
          setState(() {
            _fotos = refFotosProcesadas;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al sincronizar fotos.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _tomarFoto() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de GPS denegado.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de GPS denegados permanentemente.'),
          ),
        );
        return;
      }

      final Future<Position> positionFuture = Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) return;

      if (mounted) _mostrarDialogoInput(photo, positionFuture);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
      }
    }
  }

  void _mostrarDialogoInput(XFile photo, Future<Position> positionFuture) {
    final notaCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Datos de la Foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notaCtrl,
                decoration: const InputDecoration(labelText: 'Nota (Opcional)'),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Position>(
                future: positionFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Obteniendo GPS...', style: TextStyle(fontSize: 12)),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'GPS: No disponible',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    );
                  }
                  final p = snapshot.data!;
                  return Text(
                    'GPS: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Position? pos;
                try {
                  pos = await positionFuture.timeout(const Duration(seconds: 5));
                } catch (_) {
                }
                
                if (context.mounted) {
                   Navigator.pop(context);
                   _guardarFotoLocal(photo, pos, notaCtrl.text);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarFotoLocal(
    XFile photo,
    Position? position,
    String nota,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final suId = widget.suministro['id'].toString();

      final newFotoId = const Uuid().v4();
      final String fileName = '$newFotoId.jpg';
      final dir = await getApplicationDocumentsDirectory();
      final String localPath = '${dir.path}/$fileName';
      await File(photo.path).copy(localPath);

      final int numeroFoto = _fotos.length + 1;
      final String suministroNombreRaw = widget.suministro['nombre'] ?? 'Suministro';
      final String nombreFoto = '${suministroNombreRaw}_$numeroFoto';

      final fotoData = {
        'id': newFotoId,
        'suministro_id': int.parse(suId),
        'nombre': nombreFoto,
        'direccion': localPath,
        'creado_por': user?.id,
        'created_at': DateTime.now().toIso8601String(),
        'latitud': position?.latitude.toString() ?? '0.0',
        'longitud': position?.longitude.toString() ?? '0.0',
        'nota': nota,
      };

      await DatabaseHelper.instance.insertFotoLocal(fotoData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Foto adjuntada localmente. Usa "Marcar como Completado" para subirla.',
            ),
          ),
        );
      }

      _cargarFotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la foto: $e')),
        );
      }
    }
  }

  Future<void> _eliminarFoto(Map<String, dynamic> foto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: const Text('¿Estás seguro de que deseas eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);
    try {
      final String id = foto['id'].toString();
      final String? rutaLocal = foto['direccion'];

      if (rutaLocal != null && !rutaLocal.startsWith('http')) {
        try {
          final file = File(rutaLocal);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error al borrar archivo físico: $e');
        }
      }

      if (rutaLocal != null &&
          rutaLocal.startsWith('http') &&
          SyncService.instance.isOnline) {
        await Supabase.instance.client.from('fotos').delete().eq('id', id);
      }

      await DatabaseHelper.instance.eliminarFotoLocal(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto eliminar correctamente.')),
        );
      }
      _cargarFotos();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          setState(() => isExiting = true);
          await Future.delayed(const Duration(milliseconds: 300));
          if (context.mounted) {
            Navigator.pop(context, result);
          }
        },
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0652C5)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            TweenAnimationBuilder(
              tween: Tween<Offset>(
                begin: const Offset(0, -1),
                end: isExiting ? const Offset(0, -1) : Offset.zero,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return FractionalTranslation(
                  translation: offset,
                  child: child,
                );
              },
              child: Container(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 20,
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          border: Border(
                            bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  size: 20,
                                ),
                              onPressed: () async {
                                setState(() => isExiting = true);
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                            Expanded(
                              child: Text(
                                widget.suministro['nombre'] ??
                                    'Detalle del Suministro',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.suministro['estado'] != 'completado')
                              InkWell(
                                onTap: _tomarFoto,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          size: 40,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tomar Foto',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Se requieren al menos 4 fotos',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (widget.suministro['estado'] != 'completado')
                              const SizedBox(height: 32),
                            Text(
                              'FOTOS TOMADAS (${_fotos.length})',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_fotos.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    "No hay fotos registradas.",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.0,
                                    ),
                                itemCount: _fotos.length,
                                itemBuilder: (context, index) {
                                  final foto = _fotos[index];
                                  final String url = foto['direccion'] ?? '';
                                  final File? localFile = foto['_localFile'];

                                  return Stack(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  RevisionFotoPage(
                                                    foto: foto,
                                                    localFile: localFile,
                                                    url: url,
                                                  ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.15),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: double.infinity,
                                              height: double.infinity,
                                              child: Hero(
                                                tag: 'imageHero_${foto['id']}',
                                                child: localFile != null
                                                    ? Image.file(
                                                        localFile,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : (url.isNotEmpty &&
                                                            url.startsWith('http')
                                                        ? CachedNetworkImage(
                                                            imageUrl: url,
                                                            fit: BoxFit.cover,
                                                            placeholder: (context, url) => Container(
                                                              color: Colors.grey.shade200,
                                                              child: const Center(
                                                                child: CircularProgressIndicator(strokeWidth: 2),
                                                              ),
                                                            ),
                                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                                          )
                                                        : (url.isNotEmpty
                                                            ? Image.file(
                                                                File(url),
                                                                fit: BoxFit.cover,
                                                              )
                                                            : Container(
                                                                color: Colors.grey
                                                                    .shade200,
                                                              ))),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (widget.suministro['estado'] != 'completado')
                                        Positioned(
                                        top: 8,
                                        right: 8,
                                        child: InkWell(
                                          onTap: () => _eliminarFoto(foto),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (widget.suministro['estado'] != 'completado')
                      TweenAnimationBuilder(
                        tween: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: isExiting ? const Offset(0, 1) : Offset.zero,
                        ),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, offset, child) {
                          return FractionalTranslation(
                            translation: offset,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            border: Border(
                              top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _fotos.length >= 4
                                  ? () async {
                                      try {
                                        final suId = widget.suministro['id']
                                            .toString();

                                        await DatabaseHelper.instance
                                            .actualizarEstadoSuministroLocal(
                                              suId,
                                              'completado',
                                            );

                                        final localFotos = await DatabaseHelper
                                            .instance
                                            .getFotosBySuministro(suId);
                                        final pendientes = localFotos
                                            .where(
                                              (f) => !f['direccion']
                                                  .toString()
                                                  .startsWith('http'),
                                            )
                                            .toList();
                                        for (var f in pendientes) {
                                          await DatabaseHelper.instance
                                              .encolarTarea(
                                                'UPLOAD_PHOTO',
                                                'fotos',
                                                f,
                                                rutaArchivoLocal:
                                                    f['direccion'],
                                              );
                                        }

                                        await DatabaseHelper.instance
                                            .encolarTarea(
                                              'UPDATE',
                                              'suministro',
                                              {
                                                'id': suId,
                                                'estado': 'completado',
                                              },
                                            );

                                        if (!context.mounted) return;

                                        if (SyncService.instance.isOnline) {
                                          await showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (ctx) =>
                                                SincronizacionDialog(
                                                  tareaSincronizacion:
                                                      (onProgress) async {
                                                        await SyncService
                                                            .instance
                                                            .syncPendingTasks(
                                                              onProgress:
                                                                  onProgress,
                                                            );
                                                      },
                                                ),
                                          );
                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '¡Suministro subido y completado con éxito!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Guardado localmente. Se enviará al reconectar.',
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }

                                        Navigator.pop(context, true);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error al guardar: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text(
                                'Marcar como completado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                disabledBackgroundColor: Theme.of(context).disabledColor,
                                disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
  }
}
