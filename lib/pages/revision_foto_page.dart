import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'full_screen_image_page.dart';

class RevisionFotoPage extends StatelessWidget {
  final Map<String, dynamic> foto;
  final File? localFile;
  final String url;

  const RevisionFotoPage({
    super.key,
    required this.foto,
    this.localFile,
    required this.url,
  });

  String _formatDate(String isoDate) {
    try {
      DateTime parsed = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {
      return 'Fecha Desconocida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateString = _formatDate(foto['created_at']?.toString() ?? '');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
            ),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Revisión de Foto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Hero(
                            tag: 'imageHero_${foto['id']}',
                            child: SizedBox(
                              height: 300,
                              width: double.infinity,
                              child: localFile != null
                                  ? Image.file(localFile!, fit: BoxFit.cover)
                                  : (url.isNotEmpty && url.startsWith('http')
                                      ? Image.network(url, fit: BoxFit.cover)
                                      : (url.isNotEmpty
                                          ? Image.file(File(url),
                                              fit: BoxFit.cover)
                                          : Container(
                                              color: Colors.grey.shade200))),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen,
                                    color: Colors.white),
                                tooltip: 'Maximizar',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImagePage(
                                        imageUrl: localFile?.path ?? url,
                                        tag: 'imageHero_${foto['id']}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Capturada el $dateString',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildDetailCard(context, 'NOMBRE DE LA FOTO', foto['nombre']?.toString() ?? 'Sin nombre'),
                          const SizedBox(height: 16),
                          _buildLocationCard(context, foto['latitud']?.toString(), foto['longitud']?.toString()),
                          const SizedBox(height: 16),
                          _buildNotesCard(context, foto['nota']?.toString()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.menu),
                  label: const Text(
                    'Volver a la lista',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildDetailCard(BuildContext context, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, String? lat, String? lon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UBICACIÓN',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latitud', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                  Text(lat ?? 'N/A', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Longitud', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                  Text(lon ?? 'N/A', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, String? notes) {
    final hasNotes = notes != null && notes.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTAS',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasNotes ? notes : 'Sin notas para esta foto.',
            style: TextStyle(
              color: hasNotes ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
              fontSize: 14,
              fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
