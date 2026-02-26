import 'package:flutter/material.dart';

/// Un overlay reutilizable que muestra la imagen [loading.png] latiendo
/// sobre un fondo oscuro para indicar estado de carga.
class LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.6), // Overlay oscuro
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/loading3.png'
                      : 'assets/loading2.png',
                  width: 500,
                  height: 500,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
