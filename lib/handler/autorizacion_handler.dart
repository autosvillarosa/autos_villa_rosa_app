import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pdf_generators/autorizaciones_pdf.dart';
import '../utils/pdf_utils.dart';

class AutorizacionHandler {
  static Future<void> generateAndUpload({
    required BuildContext context,
    required Map<String, dynamic> cocheData,
    required String cocheUuid,
    required String transporte,
    required String cif,
    required VoidCallback refresh,
  }) async {
    try {
      final pdfBytes = await generateAutorizacionPdf(
        marca: cocheData['marca'] ?? '',
        modelo: cocheData['modelo'] ?? '',
        matricula: cocheData['matricula'] ?? '',
        transporte: transporte,
        cif: cif,
      );

      final fileName =
          'Autorizacion_${cocheData['matricula'] ?? 'unknown'}_${cocheData['marca'] ?? 'unknown'}.pdf';
      final pdfUrl = await PdfUtils.uploadPdfToSupabase(fileName, pdfBytes);

      if (pdfUrl != null) {
        await Supabase.instance.client.from('coches').update({
          'pdf_autorizacion_url': pdfUrl,
          'transporte': transporte,
          'estado_traslado': 'Solicitado',
        }).eq('uuid', cocheUuid);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autorización generada exitosamente'),
            duration: Duration(seconds: 1),
          ),
        );
        refresh();
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar autorización: $e'),
          duration: const Duration(seconds: 1),
        ),
      );
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

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static Future<Map<String, String>?> _showTransporteDialog(
      BuildContext context, String initialTransporte) async {
    String? selectedTransporte =
        initialTransporte.isNotEmpty ? initialTransporte : null;
    final transporteController = TextEditingController();
    final cifController = TextEditingController();
    final List<String> transportes = [
      'Auto1',
      'Manuel',
      'Orencio',
      'Guadalix',
      'Otro',
    ];

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Seleccionar Transporte'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...transportes.map((String transporte) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0.8), // Reduced by 20% from 1.0px
                        child: RadioListTile<String>(
                          title: Text(transporte),
                          value: transporte,
                          // ignore: deprecated_member_use
                          groupValue: selectedTransporte,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              selectedTransporte = value;
                            });
                          },
                        ),
                      );
                    }),
                    if (selectedTransporte == 'Otro') ...[
                      TextField(
                        controller: transporteController,
                        decoration: const InputDecoration(
                          labelText: 'Transporte/Empresa',
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: cifController,
                        decoration: const InputDecoration(labelText: 'CIF/DNI'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedTransporte == null) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seleccione un transporte'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    String finalTransporte;
                    String finalCif = '';
                    if (selectedTransporte == 'Otro') {
                      finalTransporte =
                          _capitalize(transporteController.text.trim());
                      finalCif = cifController.text.trim().toUpperCase();
                      if (finalTransporte.isEmpty || finalCif.isEmpty) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Ingrese el nombre del transporte y el CIF'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        return;
                      }
                    } else {
                      finalTransporte = selectedTransporte!;
                    }
                    Navigator.pop(context, {
                      'transporte': finalTransporte,
                      'cif': finalCif,
                    });
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> handleGenerate({
    required BuildContext context,
    required Map<String, dynamic> cocheData,
    required String cocheUuid,
    required String initialTransporte,
    required VoidCallback refresh,
  }) async {
    if (cocheData['pdf_autorizacion_url'] != null) {
      final confirm = await _showConfirmDialog(
        context,
        "Regenerar autorización",
        "¿Está seguro que desea regenerar el PDF de Autorización?",
      );
      if (!confirm) return;
    }
    // ignore: use_build_context_synchronously
    final result = await _showTransporteDialog(context, initialTransporte);
    if (result != null) {
      await generateAndUpload(
        context: context,
        cocheData: cocheData,
        cocheUuid: cocheUuid,
        transporte: result['transporte']!,
        cif: result['cif']!,
        refresh: refresh,
      );
    }
  }
}
