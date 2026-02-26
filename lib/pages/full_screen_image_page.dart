import 'package:flutter/material.dart';
import 'dart:io';

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true, 
              minScale: 0.5,
              maxScale: 4.0, 
              child: Hero(
                tag: tag,
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 100, color: Colors.white),
                      )
                    : Image.file(
                        File(imageUrl),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 100, color: Colors.white),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 40.0,
            left: 16.0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
