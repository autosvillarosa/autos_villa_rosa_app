import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../utils/pdf_utils.dart';
import '../form/reserva_form.dart';
import '../form/venta_form.dart';
import '../handler/autorizacion_handler.dart';
import '../handler/speech_handler.dart';
import '../handler/factura_handler.dart';
import 'package:intl/intl.dart';

// Enum para tipos de PDF
enum PdfType {
  autorizacion,
  speech,
  reserva,
  venta,
  factura,
  documentacion,
}

class PdfEditButton extends StatefulWidget {
  final String cocheUuid;
  final Map<String, dynamic>? cocheData;

  const PdfEditButton({
    super.key,
    required this.cocheUuid,
    this.cocheData,
  });

  @override
  State<PdfEditButton> createState() => _PdfEditButtonState();
}

class _PdfEditButtonState extends State<PdfEditButton> {
  Map<String, dynamic>? _cocheData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCocheData();
  }

  Future<void> _fetchCocheData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await Supabase.instance.client
          .from('coches')
          .select()
          .eq('uuid', widget.cocheUuid)
          .single();
      if (mounted) {
        setState(() {
          _cocheData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos del coche: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    if (!mounted) return false;
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

  Future<void> _uploadDocumentacion() async {
    if (_cocheData!['pdf_documentacion_url'] != null) {
      final confirm = await _showConfirmDialog(
        "Reemplazar documentación",
        "¿Está seguro que desea reemplazar el PDF de documentación?",
      );
      if (!confirm) return;
    }
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null && result.files.isNotEmpty) {
        Uint8List? fileBytes = result.files.first.bytes;
        if (fileBytes == null) {
          final String? filePath = result.files.first.path;
          if (filePath != null) {
            try {
              fileBytes = await File(filePath).readAsBytes();
            } catch (e) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al leer bytes desde path: $e'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
              return;
            }
          } else {
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Path y bytes son null. Selección fallida.'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
            return;
          }
        }
        final fileName = '${widget.cocheUuid}_documentacion.pdf';
        final pdfUrl = await PdfUtils.uploadPdfToSupabase(fileName, fileBytes);
        if (pdfUrl != null) {
          await Supabase.instance.client.from('coches').update(
              {'pdf_documentacion_url': pdfUrl}).eq('uuid', widget.cocheUuid);
          if (mounted) {
            await _fetchCocheData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Documentación subida exitosamente'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          }
        } else {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error en subida a Supabase'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      } else {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se seleccionó ningún archivo o fue cancelado'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documentación: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _openPdf(String url) async {
    if (mounted) {
      final pdfPath = await PdfUtils.openPdf(url, widget.cocheUuid);
      if (pdfPath != null && mounted && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(pdfPath: pdfPath),
          ),
        );
      }
    }
  }

  String _getCustomSubtitle(PdfType type) {
    switch (type) {
      case PdfType.autorizacion:
        final transporte = _cocheData?['transporte'];
        return transporte != null && transporte.isNotEmpty
            ? 'Solicitado a $transporte'
            : 'Por solicitar';
      case PdfType.speech:
        final estado = _cocheData?['estado_publicacion'];
        if (estado == 'Publicado') {
          final fecha = _cocheData?['fecha_publicado'];
          String formattedFecha = 'N/A';
          if (fecha != null) {
            try {
              final date = DateTime.parse(fecha).toLocal();
              formattedFecha = DateFormat('dd/MM/yyyy HH:mm').format(date);
            } catch (e) {
              formattedFecha = fecha;
            }
          }
          return 'Publicado el $formattedFecha';
        } else {
          return 'Por publicar';
        }
      case PdfType.reserva:
        if (_cocheData!['pdf_reserva_url'] == null) return '';
        final fecha = _cocheData?['fecha_reserva'];
        if (fecha != null) {
          try {
            final date = DateTime.parse(fecha).toLocal();
            return 'Reservado el ${DateFormat('dd/MM/yyyy HH:mm').format(date)}';
          } catch (e) {
            return 'Reservado';
          }
        }
        return '';
      case PdfType.venta:
        if (_cocheData!['pdf_venta_url'] == null) return '';
        final fecha = _cocheData?['fecha_venta'];
        if (fecha != null) {
          try {
            final date = DateTime.parse(fecha).toLocal();
            return 'Vendido el   ${DateFormat('dd/MM/yyyy HH:mm').format(date)}';
          } catch (e) {
            return 'Vendido';
          }
        }
        return '';
      case PdfType.factura:
      case PdfType.documentacion:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFE6F0FA), // Light blue background
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final estadoCoche = _cocheData!['estado_coche'];

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0053A0), // Dark blue AppBar
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bitácora y PDFs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_cocheData!['matricula'] ?? ''} - ${_cocheData!['marca'] ?? ''} ${_cocheData!['modelo'] ?? ''}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Autorización
          PdfTile(
            title: 'Autorización',
            url: _cocheData!['pdf_autorizacion_url'],
            type: PdfType.autorizacion,
            onGenerate: () async {
              await AutorizacionHandler.handleGenerate(
                context: context,
                cocheData: _cocheData!,
                cocheUuid: widget.cocheUuid,
                initialTransporte: _cocheData!['transporte'] ?? '',
                refresh: _fetchCocheData,
              );
            },
            customSubtitle: Text(_getCustomSubtitle(PdfType.autorizacion)),
            onView: _cocheData!['pdf_autorizacion_url'] != null
                ? () => _openPdf(_cocheData!['pdf_autorizacion_url'])
                : null,
            isAllowed: true,
          ),

          // Speech
          PdfTile(
            title: 'Speech',
            url: _cocheData!['pdf_speech_url'],
            type: PdfType.speech,
            onGenerate: () async {
              await SpeechHandler.handleGenerate(
                context: context,
                cocheData: _cocheData!,
                cocheUuid: widget.cocheUuid,
                refresh: _fetchCocheData,
              );
            },
            customSubtitle: Text(_getCustomSubtitle(PdfType.speech)),
            onView: _cocheData!['pdf_speech_url'] != null
                ? () => _openPdf(_cocheData!['pdf_speech_url'])
                : null,
            isAllowed: true,
          ),

          // Reserva
          PdfTile(
            title: 'Reserva',
            url: _cocheData!['pdf_reserva_url'],
            type: PdfType.reserva,
            onGenerate: () async {
              await ReservaForm.handleGenerate(
                context: context,
                cocheData: _cocheData!,
                cocheUuid: widget.cocheUuid,
                refresh: _fetchCocheData,
              );
            },
            customSubtitle: Text(_getCustomSubtitle(PdfType.reserva)),
            onView: _cocheData!['pdf_reserva_url'] != null
                ? () => _openPdf(_cocheData!['pdf_reserva_url'])
                : null,
            isAllowed: estadoCoche != 'Vendido' && estadoCoche != 'Por llegar',
          ),

          // Venta
          PdfTile(
            title: 'Venta',
            url: _cocheData!['pdf_venta_url'],
            type: PdfType.venta,
            onGenerate: () async {
              await VentaForm.handleGenerate(
                context: context,
                cocheData: _cocheData!,
                cocheUuid: widget.cocheUuid,
                refresh: _fetchCocheData,
              );
            },
            customSubtitle: Text(_getCustomSubtitle(PdfType.venta)),
            onView: _cocheData!['pdf_venta_url'] != null
                ? () => _openPdf(_cocheData!['pdf_venta_url'])
                : null,
            isAllowed: estadoCoche != 'Vendido' && estadoCoche != 'Por llegar',
          ),

          // Factura
          PdfTile(
            title: 'Factura',
            url: _cocheData!['pdf_factura_url'],
            type: PdfType.factura,
            onGenerate: () async {
              await FacturaHandler.handleGenerate(
                context: context,
                cocheData: _cocheData!,
                cocheUuid: widget.cocheUuid,
                refresh: _fetchCocheData,
              );
            },
            customSubtitle: Text(_getCustomSubtitle(PdfType.factura)),
            onView: _cocheData!['pdf_factura_url'] != null
                ? () => _openPdf(_cocheData!['pdf_factura_url'])
                : null,
            isAllowed: estadoCoche == 'Vendido' &&
                (_cocheData!['pdf_venta_url'] != null),
          ),

          // Documentación
          PdfTile(
            title: 'Documentación',
            url: _cocheData!['pdf_documentacion_url'],
            type: PdfType.documentacion,
            onGenerate: _uploadDocumentacion,
            customSubtitle: Text(_getCustomSubtitle(PdfType.documentacion)),
            onView: _cocheData!['pdf_documentacion_url'] != null
                ? () => _openPdf(_cocheData!['pdf_documentacion_url'])
                : null,
            isAllowed: true,
            generateIcon: Icons.upload,
            generateColor: const Color.fromARGB(255, 189, 120, 0),
            generateTooltip: 'Subir/Reemplazar Documentación',
          ),
        ],
      ),
    );
  }
}

class PdfTile extends StatelessWidget {
  final String title;
  final String? url;
  final PdfType type;
  final VoidCallback? onGenerate;
  final VoidCallback? onView;
  final Widget? customSubtitle;
  final bool isAllowed;
  final IconData generateIcon;
  final Color generateColor;
  final String? generateTooltip;

  const PdfTile({
    super.key,
    required this.title,
    this.url,
    required this.type,
    this.onGenerate,
    this.onView,
    this.customSubtitle,
    this.isAllowed = true,
    this.generateIcon = Icons.add_circle,
    this.generateColor = Colors.purple,
    this.generateTooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget? subtitleWidget;
    if (customSubtitle != null &&
        (customSubtitle is Text) &&
        (customSubtitle as Text).data!.isNotEmpty) {
      subtitleWidget = customSubtitle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitleWidget,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onGenerate != null)
              IconButton(
                icon: Icon(
                  generateIcon,
                  color: isAllowed ? generateColor : Colors.grey,
                ),
                onPressed: isAllowed ? onGenerate : null,
                tooltip: generateTooltip ??
                    (isAllowed
                        ? 'Generar/Regenerar $title'
                        : 'Acción no permitida'),
              ),
            if (url != null)
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: onView,
                tooltip: 'Ver PDF',
              ),
            if (url != null)
              IconButton(
                icon: const Icon(Icons.download, color: Colors.green),
                onPressed: () => PdfUtils.downloadPdf(url!, title),
                tooltip: 'Descargar PDF',
              ),
          ],
        ),
      ),
    );
  }
}
