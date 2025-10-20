import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pdf_generators/speech_pdf_generator.dart';
import '../utils/pdf_utils.dart';

class SpeechHandler {
  static Future<void> generateAndUpload({
    required Map<String, dynamic> cocheData,
    required String cocheUuid,
    required List<String> caracteristicasSeleccionadas,
    required VoidCallback refresh,
  }) async {
    try {
      final pdfBytes = await generateSpeechPdf(
        cocheData['marca'] ?? '',
        cocheData['modelo'] ?? '',
        cocheData['precio']?.toString() ?? '',
        cocheData['fecha_itv'] ?? '',
        cocheData['matricula'] ?? '',
        cocheData['fecha_matriculacion'] ?? '',
        cocheData['km']?.toString() ?? '',
        cocheData['bastidor'] ?? '',
        cocheData['tipo_combustible'] ?? '',
        cocheData['cc']?.toString() ?? '',
        cocheData['cv']?.toString() ?? '',
        cocheData['transmision'] ?? '',
        caracteristicasAdicionales: caracteristicasSeleccionadas,
      );

      final fileName =
          'Speech_${cocheData['matricula'] ?? 'unknown'}_${cocheData['marca'] ?? 'unknown'}.pdf';
      final pdfUrl = await PdfUtils.uploadPdfToSupabase(fileName, pdfBytes);

      if (pdfUrl != null) {
        await Supabase.instance.client.from('coches').update({
          'pdf_speech_url': pdfUrl,
          'estado_publicacion': 'Publicado',
          'fecha_publicado': DateTime.now().toIso8601String(),
        }).eq('uuid', cocheUuid);
        refresh();
      } else {
        throw Exception('Error al subir el PDF a Supabase');
      }
    } catch (e) {
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  static Future<bool> _showConfirmDialog(
      BuildContext context, String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text("Sí, continuar"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<List<String>?> _showSpeechOptionsDialog(
      BuildContext context) async {
    final List<String> opciones = [
      'llantas de aleación',
      'descapotable',
      'techo solar',
      'volante multifunción',
      'luces xenon',
      'sensores de parking',
      'asientos calefactados',
      'asientos de cuero',
      'asientos deportivos',
      'pantalla central',
      'acabados en madera',
      'control de velocidad',
      'aire acondicionado',
      'asientos abatibles',
      'enganche de remolque',
      'ordenador a bordo',
      '7 plazas',
    ];

    Map<String, bool> selecciones = {
      for (var opcion in opciones) opcion: false
    };

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Selecciona características adicionales'),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
          content: SizedBox(
            width: 300.0,
            height: 350.0,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: opciones.map((opcion) {
                    return CheckboxListTile(
                      title: Text(
                        opcion,
                        style: const TextStyle(fontSize: 15.0), // Font size 15
                      ),
                      value: selecciones[opcion],
                      onChanged: (bool? value) {
                        setState(() {
                          selecciones[opcion] = value ?? false;
                        });
                      },
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.6), // Reduced vertical spacing by 20%
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Generar PDF'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return null;
    return selecciones.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  static Future<void> handleGenerate({
    required BuildContext context,
    required Map<String, dynamic> cocheData,
    required String cocheUuid,
    required VoidCallback refresh,
  }) async {
    if (cocheData['pdf_speech_url'] != null) {
      final confirm = await _showConfirmDialog(
        context,
        "Regenerar Speech",
        "¿Está seguro que desea regenerar el PDF de Speech?",
      );
      if (!confirm) return;
    }

    final caracteristicasSeleccionadas =
        await _showSpeechOptionsDialog(context);
    if (caracteristicasSeleccionadas != null) {
      try {
        await generateAndUpload(
          cocheData: cocheData,
          cocheUuid: cocheUuid,
          caracteristicasSeleccionadas: caracteristicasSeleccionadas,
          refresh: refresh,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech generado exitosamente'),
              duration: Duration(seconds: 1), // 1 second duration
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al generar speech: $e'),
              duration: const Duration(seconds: 1), // 1 second duration
            ),
          );
        }
      }
    }
  }
}
