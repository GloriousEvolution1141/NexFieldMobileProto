import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/loading_overlay.dart';
import '../services/sync_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/fondo1.webp'), context);
  }

  Future<void> _signIn() async {
    try {
      setState(() => _isLoading = true);

      final isOnline = await SyncService.instance.checkRealInternet();
      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay conexión a Internet. Verifica tu señal para iniciar sesión.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      String email = _emailController.text.trim();
      if (!email.contains('@')) {
        email = '$email@gmail.com';
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        String mensaje = 'Ocurrió un error inesperado';
        
        if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
          mensaje = 'Error de conexión. Asegúrate de tener internet.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: LoadingOverlay(
        isLoading: _isLoading,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/fondo1.webp',
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Gestión de Suministros',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ingresa tus credenciales para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 32),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937).withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Usuario o Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.blueGrey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _emailController,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    hintText: 'nombre@ejemplo.com',
                                    hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.black.withValues(alpha: 0.05)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).colorScheme.primary),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Contraseña',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.blueGrey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _passwordController,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.black.withValues(alpha: 0.05)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).colorScheme.primary),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.shade200,
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor:
                                          Theme.of(context).colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
