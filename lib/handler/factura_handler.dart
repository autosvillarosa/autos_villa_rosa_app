import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../pdf_generators/factura_pdf.dart';
import '../utils/pdf_utils.dart';

class FacturaHandler {
  static Future<void> generateAndUpload({
    required BuildContext context,
    required Map<String, dynamic> cocheData,
    required String cocheUuid,
    required String numeroFactura,
    required String numeroCliente,
    required int montoFacturar,
    required String tipoIva,
    required VoidCallback refresh,
  }) async {
    try {
      final pdfBytes = await generateFacturaPdf(
        marca: cocheData['marca'] ?? '',
        matricula: cocheData['matricula'] ?? '',
        nombre: cocheData['nombre'] ?? '',
        dni: cocheData['dni'] ?? '',
        numeroFactura: numeroFactura,
        numeroCliente: numeroCliente,
        montoFacturar: montoFacturar,
        tipoIva: tipoIva,
        direccion: cocheData['direccion'] ?? '',
        cp: cocheData['cp']?.toString() ?? '',
        provincia: cocheData['provincia'] ?? '',
        ciudad: cocheData['ciudad'] ?? '',
        modelo: cocheData['modelo'] ?? '',
        transmision: cocheData['transmision'] ?? '',
        fechaMatriculacion: cocheData['fecha_matriculacion'] ?? '',
        km: cocheData['km'] ?? 0,
        bastidor: cocheData['bastidor'] ?? '',
      );

      final fileName =
          'Factura_${cocheData['matricula'] ?? 'unknown'}_${cocheData['marca'] ?? 'unknown'}.pdf';
      final pdfUrl = await PdfUtils.uploadPdfToSupabase(fileName, pdfBytes);

      if (pdfUrl != null) {
        await Supabase.instance.client
            .from('coches')
            .update({'pdf_factura_url': pdfUrl}).eq('uuid', cocheUuid);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura generada exitosamente'),
            duration: Duration(seconds: 1),
          ),
        );
        refresh();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar factura: $e'),
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

  static Future<Map<String, dynamic>?> _showFacturaDialog(
      BuildContext context) async {
    final numeroFacturaController = TextEditingController();
    final numeroClienteController = TextEditingController();
    final montoFacturarController = TextEditingController();
    String? tipoIva;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Detalles de Factura'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numeroFacturaController,
                    decoration:
                        const InputDecoration(labelText: 'Número Factura'),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: numeroClienteController,
                    decoration:
                        const InputDecoration(labelText: 'Número Cliente'),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: montoFacturarController,
                    decoration: const InputDecoration(
                        labelText: 'Monto a Facturar (€)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de IVA'),
                      Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<String>(
                            // ignore: deprecated_member_use
                            value: 'General',
                            // ignore: deprecated_member_use
                            groupValue: tipoIva,
                            // ignore: deprecated_member_use
                            onChanged: (value) {
                              setState(() {
                                tipoIva = value;
                              });
                            },
                          ),
                          const Text('General (21%)'),
                        ],
                      ),
                      Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<String>(
                            // ignore: deprecated_member_use
                            value: 'Rebu',
                            // ignore: deprecated_member_use
                            groupValue: tipoIva,
                            // ignore: deprecated_member_use
                            onChanged: (value) {
                              setState(() {
                                tipoIva = value;
                              });
                            },
                          ),
                          const Text('Rebu'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (numeroFacturaController.text.isEmpty ||
                        numeroClienteController.text.isEmpty ||
                        montoFacturarController.text.isEmpty ||
                        tipoIva == null) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Complete todos los campos'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    final monto =
                        int.tryParse(montoFacturarController.text) ?? 0;
                    Navigator.pop(dialogContext, {
                      'numeroFactura': numeroFacturaController.text,
                      'numeroCliente': numeroClienteController.text,
                      'montoFacturar': monto,
                      'tipoIva': tipoIva!,
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
    required VoidCallback refresh,
  }) async {
    final estadoCoche = cocheData['estado_coche'];
    if (cocheData['pdf_factura_url'] != null) {
      if (estadoCoche != 'Vendido') {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se puede regenerar: el coche aún no está vendido.'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      if (!context.mounted) return;
      final confirm = await _showConfirmDialog(
        context,
        "Regenerar factura",
        "¿Está seguro que desea regenerar el PDF de Factura?",
      );
      if (!confirm) return;
    } else {
      if (cocheData['pdf_venta_url'] == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se puede generar factura: primero debe existir el PDF de venta.'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      if (estadoCoche != 'Vendido') {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se puede generar factura: el coche aún no está vendido.'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;
    final result = await _showFacturaDialog(context);
    if (result != null) {
      await generateAndUpload(
        context: context,
        cocheData: cocheData,
        cocheUuid: cocheUuid,
        numeroFactura: result['numeroFactura'],
        numeroCliente: result['numeroCliente'],
        montoFacturar: result['montoFacturar'],
        tipoIva: result['tipoIva'],
        refresh: refresh,
      );
    }
  }
}
