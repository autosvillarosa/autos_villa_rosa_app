import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File, Directory;
import 'package:universal_html/html.dart' as html;
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfUtils {
  // Abre PDF en web (nueva pestaña) o devuelve la ruta del archivo temporal en móvil
  static Future<String?> openPdf(String url, String cocheUuid) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final pdfUrl =
        url.endsWith('.pdf') ? '$url?t=$timestamp' : '$url.pdf?t=$timestamp';

    if (kIsWeb) {
      final viewUri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(viewUri)) {
        await launchUrl(
          viewUri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
          webViewConfiguration: const WebViewConfiguration(
            headers: {
              'Content-Type': 'application/pdf',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
          ),
        );
        return null; // No se necesita ruta en web
      } else {
        Fluttertoast.showToast(
            msg: 'No se pudo abrir el PDF', toastLength: Toast.LENGTH_LONG);
        return null;
      }
    } else {
      // Limpiar archivos temporales antiguos para evitar conflictos
      final tempDir = await getTemporaryDirectory();
      final tempFiles = tempDir.listSync();
      for (var file in tempFiles) {
        if (file is File && file.path.contains('temp_pdf_')) {
          try {
            await file.delete();
          } catch (e) {
            // Ignorar errores de eliminación
          }
        }
      }

      // Descargar el PDF con headers anti-caché
      final response = await http.get(
        Uri.parse(pdfUrl),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempFile = File(
            '${tempDir.path}/temp_pdf_${cocheUuid}_$timestamp.pdf'); // Nombre único con cocheUuid
        await tempFile.writeAsBytes(bytes);

        if (await tempFile.exists()) {
          return tempFile.path; // Devuelve la ruta del archivo temporal
        } else {
          Fluttertoast.showToast(
              msg: 'Error al crear el archivo PDF',
              toastLength: Toast.LENGTH_LONG);
          return null;
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error al descargar el PDF: ${response.statusCode}',
            toastLength: Toast.LENGTH_LONG);
        return null;
      }
    }
  }

  // Descarga PDF en web (blob) o mobile (external storage)
  static Future<void> downloadPdf(String url, String title) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..setAttribute('download', '$title.pdf')
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      } else {
        final downloadsDir =
            await _getExternalStoragePublicDirectory('Download');
        final filePath =
            '${downloadsDir.path}/${title}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (await file.exists()) {
          Fluttertoast.showToast(
              msg: 'PDF descargado en $filePath',
              toastLength: Toast.LENGTH_LONG);
        }
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Error al descargar el PDF', toastLength: Toast.LENGTH_LONG);
    }
  }

  // Obtiene directorio de descarga para mobile
  static Future<Directory> _getExternalStoragePublicDirectory(
      String type) async {
    final downloadsPath = '/storage/emulated/0/Download';
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  // Sube PDF a Supabase Storage
  static Future<String?> uploadPdfToSupabase(
      String fileName, Uint8List pdfBytes) async {
    await Supabase.instance.client.storage.from('pdfs').uploadBinary(
          fileName,
          pdfBytes,
          fileOptions:
              const FileOptions(contentType: 'application/pdf', upsert: true),
        );
    return Supabase.instance.client.storage.from('pdfs').getPublicUrl(fileName);
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;

  const PdfViewerScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista Previa del PDF')),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        onError: (error) {
          Fluttertoast.showToast(
              msg: 'Error al cargar el PDF: $error',
              toastLength: Toast.LENGTH_LONG);
        },
        onPageError: (page, error) {
          Fluttertoast.showToast(
              msg: 'Error en la página $page: $error',
              toastLength: Toast.LENGTH_LONG);
        },
      ),
    );
  }
}
