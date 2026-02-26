import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'suministro_detalle_page.dart';
import '../widgets/loading_overlay.dart';
import '../app.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? nombreCompleto;
  String? rol;
  bool isOnline = true;
  bool isLoading = true;
  bool isExiting = false;
  int _selectedIndex = 0;

  List<dynamic> pendientes = [];
  List<dynamic> completados = [];

  @override
  void initState() {
    super.initState();
    SyncService.instance.onConnectionChange = (online) {
      if (mounted) {
        setState(() => isOnline = online);
        if (online) {
          _cargarDatos();
        }
      }
    };
    SyncService.instance.onSyncComplete = (count) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sincronizados $count cambios pendientes.'),
            backgroundColor: Colors.blue,
          ),
        );
        _cargarDatos();
      }
    };

    _cargarDatos(initialLoad: true);
  }

  Future<void> _cargarDatos({bool initialLoad = false}) async {
    if (mounted && !isLoading) {
      setState(() => isLoading = true);
    }

    await Future.delayed(const Duration(seconds: 1));

    try {
      if (initialLoad) {
        await SyncService.instance.initialize();
        if (mounted) setState(() => isOnline = SyncService.instance.isOnline);
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final localSuministros = await DatabaseHelper.instance.getSuministros(
        user.id,
      );
      if (mounted) {
        setState(() {
          pendientes = localSuministros
              .where((s) => s['estado'] == 'pendiente')
              .toList();
          completados = localSuministros
              .where((s) => s['estado'] == 'completado')
              .toList();
        });
      }

      if (SyncService.instance.isOnline) {
        final usuarioData = await Supabase.instance.client
            .from('usuario')
            .select('nombres, apellidos, rol:rol_id(nombre)')
            .eq('id', user.id)
            .single();

        final suministroData = await Supabase.instance.client
            .from('suministro')
            .select('id, nombre, estado')
            .eq('asignado_a', user.id);

        await DatabaseHelper.instance.syncSuministros(suministroData, user.id);

        final refSuministros = await DatabaseHelper.instance.getSuministros(
          user.id,
        );

        if (mounted) {
          setState(() {
            nombreCompleto =
                '${usuarioData['nombres']} ${usuarioData['apellidos']}';
            rol = (usuarioData['rol']?['nombre'] ?? 'TECNICO')
                .toString()
                .toUpperCase();
            pendientes = refSuministros
                .where((s) => s['estado'] == 'pendiente')
                .toList();
            completados = refSuministros
                .where((s) => s['estado'] == 'completado')
                .toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error en _cargarDatos: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildCardEfecto(dynamic item, int index, bool isPendiente) {
    return StaggeredFadeScale(
      index: index,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            setState(() => isExiting = true);
            await Future.delayed(const Duration(milliseconds: 400));
            if (!mounted) return;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SuministroDetallePage(suministro: item),
              ),
            );

            if (mounted) {
              setState(() => isExiting = false);
            }

            if (result == true) {
              _cargarDatos();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPendiente
                        ? Icons.assignment_outlined
                        : Icons.assignment_turned_in_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  (item['nombre'] ?? 'Suministro sin nombre').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPendiente ? 'Pendiente' : 'Completado',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListaGrid(List<dynamic> lista) {
    if (lista.isEmpty) {
      return Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            "No hay suministros asignados",
            key: ValueKey('empty_$_selectedIndex'),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
      );
    }

    final bool isPendiente = _selectedIndex == 0;

    return GridView.builder(
      key: ValueKey('grid_$_selectedIndex'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final item = lista[index];
        return _buildCardEfecto(item, index, isPendiente);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            TweenAnimationBuilder(
              tween: Tween<Offset>(
                begin: const Offset(0, -1),
                end: isExiting ? const Offset(0, -1) : Offset.zero,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return FractionalTranslation(translation: offset, child: child);
              },
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${(nombreCompleto != null && nombreCompleto!.trim().isNotEmpty) ? nombreCompleto : "Usuario"}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (rol != null && rol!.trim().isNotEmpty)
                                ? rol!
                                : 'TECNICO',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(
                                  color: isOnline ? Colors.green : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: MainApp.themeNotifier,
                          builder: (context, currentMode, _) {
                            return IconButton(
                              icon: Icon(
                                currentMode == ThemeMode.dark
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                MainApp.themeNotifier.value =
                                    currentMode == ThemeMode.light
                                    ? ThemeMode.dark
                                    : ThemeMode.light;
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () async {
                            final currentlyOnline = await SyncService.instance
                                .checkRealInternet();

                            if (context.mounted) {
                              setState(() => isOnline = currentlyOnline);

                              if (currentlyOnline) {
                                _cargarDatos();
                              } else {
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sin conexión. No se puede sincronizar.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() => isLoading = true);
                            await Future.delayed(const Duration(seconds: 1));
                            await Supabase.instance.client.auth.signOut();
                          },
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Salir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 24, bottom: 8),
              child: Text(
                'Mis Suministros',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
            ),
            Expanded(
              child: _buildListaGrid(
                _selectedIndex == 0 ? pendientes : completados,
              ),
            ),
            TweenAnimationBuilder(
              tween: Tween<Offset>(
                begin: const Offset(0, 1),
                end: isExiting ? const Offset(0, 1) : Offset.zero,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return FractionalTranslation(translation: offset, child: child);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double tabWidth = constraints.maxWidth / 2;
                    return SizedBox(
                      height: 70,
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            left: _selectedIndex == 0 ? 0 : tabWidth,
                            top: 0,
                            width: tabWidth,
                            child: Container(
                              height: 3,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      setState(() => _selectedIndex = 0),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: _selectedIndex == 0
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pendientes',
                                          style: TextStyle(
                                            color: _selectedIndex == 0
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontWeight: _selectedIndex == 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      setState(() => _selectedIndex = 1),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: _selectedIndex == 1
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Completados',
                                          style: TextStyle(
                                            color: _selectedIndex == 1
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontWeight: _selectedIndex == 1
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaggeredFadeScale extends StatefulWidget {
  final Widget child;
  final int index;

  const StaggeredFadeScale({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<StaggeredFadeScale> createState() => _StaggeredFadeScaleState();
}

class _StaggeredFadeScaleState extends State<StaggeredFadeScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
