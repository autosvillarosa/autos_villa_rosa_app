import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pdf_generators/venta_con_garantia_pdf.dart';
import '../pdf_generators/venta_sin_garantia_pdf.dart';
import '../utils/pdf_utils.dart';
import 'package:intl/intl.dart';
import 'dart:developer'; // Para logs

// Función auxiliar para capitalizar la primera letra de cada palabra
String capitalizeWords(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
          : word)
      .join(' ');
}

// Función auxiliar para capitalizar la primera letra
String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

class VentaForm extends StatefulWidget {
  final String cocheUuid;
  final VoidCallback? onSuccess;

  const VentaForm({
    super.key,
    required this.cocheUuid,
    this.onSuccess,
  });

  static Future<void> handleGenerate({
    required BuildContext context,
    required Map<String, dynamic> cocheData,
    required String cocheUuid,
    required VoidCallback refresh,
  }) async {
    final estadoCoche = cocheData['estado_coche'];
    final messenger = ScaffoldMessenger.of(context);
    if (estadoCoche == 'Vendido') {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'No se puede generar/regenerar: el coche ya está vendido.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (estadoCoche == 'Por llegar') {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'No se puede generar la venta: actualice la ubicación del coche porque está por llegar.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (cocheData['pdf_venta_url'] != null) {
      final confirm = await _showConfirmDialog(
        context,
        "Generar contrato de venta",
        "¿Está seguro que desea regenerar el PDF de Venta?",
      );
      if (!confirm) return;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => VentaForm(
          cocheUuid: cocheUuid,
          onSuccess: refresh,
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

  @override
  State<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends State<VentaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _cpController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _correoController = TextEditingController();
  final _precioFinalController = TextEditingController();
  bool? _garantia;
  bool _isDataLoading = true;
  Map<String, dynamic>? _cocheData;
  String? _errorLoading;

  @override
  void initState() {
    super.initState();
    log('Iniciando _fetchCocheData para uuid: ${widget.cocheUuid}');
    _fetchCocheData();
  }

  Future<void> _fetchCocheData() async {
    if (mounted) setState(() => _isDataLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('coches')
          .select(
              'nombre, dni, telefono, direccion, ciudad, cp, provincia, correo, precio_final, garantia, marca, modelo, matricula, bastidor, fecha_itv, km, fecha_matriculacion')
          .eq('uuid', widget.cocheUuid)
          .single()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      setState(() {
        _cocheData = response;
        _nombreController.text = response['nombre'] ?? '';
        _dniController.text = response['dni'] ?? '';
        _telefonoController.text = response['telefono'] ?? '';
        _direccionController.text = response['direccion'] ?? '';
        _ciudadController.text = response['ciudad'] ?? '';
        _cpController.text = response['cp']?.toString() ?? '';
        _provinciaController.text = response['provincia'] ?? '';
        _correoController.text = response['correo'] ?? '';
        _precioFinalController.text =
            response['precio_final']?.toString() ?? '';
        _garantia = response['garantia'] == 'Sí'
            ? true
            : response['garantia'] == 'No'
                ? false
                : null;
        _errorLoading = null;
      });
      log('Formulario listo para renderizar');
    } catch (e, stackTrace) {
      log('Error en _fetchCocheData: $e', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _cocheData = null;
          _errorLoading = 'Error al cargar los datos del coche: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isDataLoading = false);
    }
  }

  @override
  void dispose() {
    log('Disposing VentaForm');
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _cpController.dispose();
    _provinciaController.dispose();
    _correoController.dispose();
    _precioFinalController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _garantia != null) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      try {
        final precioFinalInt = int.tryParse(_precioFinalController.text) ?? 0;
        final garantiaStr = _garantia == true ? 'Sí' : 'No';
        final fechaVenta = DateTime.now();
        final formattedFechaVenta = DateFormat('yyyy-MM-dd').format(fechaVenta);
        final formattedHoraVenta = DateFormat('HH:mm').format(fechaVenta);
        log('Enviando datos para actualizar en Supabase: precio=$precioFinalInt, garantia=$garantiaStr, fecha_venta=$formattedFechaVenta, hora_venta=$formattedHoraVenta');
        log('Correo: "${_correoController.text.trim()}", Teléfono: "${_telefonoController.text.trim()}"');

        if (_garantia == true) {
          if (_cocheData == null ||
              _cocheData!['marca'] == null ||
              _cocheData!['modelo'] == null ||
              _cocheData!['matricula'] == null ||
              _cocheData!['bastidor'] == null ||
              _cocheData!['fecha_itv'] == null ||
              _cocheData!['km'] == null ||
              _cocheData!['fecha_matriculacion'] == null) {
            throw Exception(
                'Datos del coche incompletos para PDF con garantía');
          }

          Uint8List pdfBytes = await generateVentaConGarantiaPdf(
            fechaVenta: formattedFechaVenta,
            nombre: capitalizeWords(_nombreController.text.trim()),
            dni: _dniController.text.trim().toUpperCase(),
            direccion: capitalizeFirstLetter(_direccionController.text.trim()),
            cp: _cpController.text.trim(),
            ciudad: capitalizeFirstLetter(_ciudadController.text.trim()),
            provincia: capitalizeFirstLetter(_provinciaController.text.trim()),
            precio: precioFinalInt,
            marca: _cocheData!['marca'],
            modelo: _cocheData!['modelo'],
            matricula: _cocheData!['matricula'],
            bastidor: _cocheData!['bastidor'],
            fechaItv: _cocheData!['fecha_itv'],
            km: _cocheData!['km'].toString(),
            fechaMatriculacion: _cocheData!['fecha_matriculacion'],
            horaVenta: formattedHoraVenta,
          );

          final fileName =
              'Venta_${_cocheData!['matricula'] ?? 'unknown'}_${_cocheData!['marca'] ?? 'unknown'}.pdf';
          final pdfUrl = await PdfUtils.uploadPdfToSupabase(fileName, pdfBytes);

          if (pdfUrl != null) {
            await Supabase.instance.client.from('coches').update({
              'pdf_venta_url': pdfUrl,
              'estado_coche': 'Vendido',
              'fecha_venta': fechaVenta.toIso8601String(),
              'precio_final': precioFinalInt,
              'garantia': garantiaStr,
              'nombre': capitalizeWords(_nombreController.text.trim()),
              'dni': _dniController.text.trim().toUpperCase(),
              'telefono': _telefonoController.text.trim(),
              'direccion':
                  capitalizeFirstLetter(_direccionController.text.trim()),
              'ciudad': capitalizeFirstLetter(_ciudadController.text.trim()),
              'cp': int.tryParse(_cpController.text.trim()),
              'provincia':
                  capitalizeFirstLetter(_provinciaController.text.trim()),
              'correo': _correoController.text.trim(),
            }).eq('uuid', widget.cocheUuid);

            log('PDF con garantía generado y datos actualizados');
          } else {
            throw Exception('Error al subir PDF con garantía');
          }
        } else {
          if (_cocheData == null ||
              _cocheData!['marca'] == null ||
              _cocheData!['matricula'] == null) {
            throw Exception(
                'Datos del coche incompletos para PDF sin garantía');
          }

          Uint8List pdfBytes = await generateVentaSinGarantiaPdf(
            fechaVenta: formattedFechaVenta,
            nombre: capitalizeWords(_nombreController.text.trim()),
            dni: _dniController.text.trim().toUpperCase(),
            direccion: capitalizeFirstLetter(_direccionController.text.trim()),
            cp: _cpController.text.trim(),
            ciudad: capitalizeFirstLetter(_ciudadController.text.trim()),
            provincia: capitalizeFirstLetter(_provinciaController.text.trim()),
            precio: precioFinalInt,
            marca: _cocheData!['marca'],
            modelo: _cocheData!['modelo'],
            matricula: _cocheData!['matricula'],
            bastidor: _cocheData!['bastidor'],
            km: _cocheData!['km'].toString(),
            fechaMatriculacion: _cocheData!['fecha_matriculacion'],
            correo: _correoController.text.trim(),
            telefono: _telefonoController.text.trim(),
            horaVenta: formattedHoraVenta,
          );

          final fileName =
              'Venta_${_cocheData!['matricula'] ?? 'unknown'}_${_cocheData!['marca'] ?? 'unknown'}.pdf';
          final pdfUrl = await PdfUtils.uploadPdfToSupabase(fileName, pdfBytes);

          if (pdfUrl != null) {
            await Supabase.instance.client.from('coches').update({
              'pdf_venta_url': pdfUrl,
              'estado_coche': 'Vendido',
              'fecha_venta': fechaVenta.toIso8601String(),
              'precio_final': precioFinalInt,
              'garantia': garantiaStr,
              'nombre': capitalizeWords(_nombreController.text.trim()),
              'dni': _dniController.text.trim().toUpperCase(),
              'telefono': _telefonoController.text.trim(),
              'direccion':
                  capitalizeFirstLetter(_direccionController.text.trim()),
              'ciudad': capitalizeFirstLetter(_ciudadController.text.trim()),
              'cp': int.tryParse(_cpController.text.trim()),
              'provincia':
                  capitalizeFirstLetter(_provinciaController.text.trim()),
              'correo': _correoController.text.trim(),
            }).eq('uuid', widget.cocheUuid);

            log('PDF sin garantía generado y datos actualizados');
          } else {
            throw Exception('Error al subir PDF sin garantía');
          }
        }

        if (mounted && context.mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Venta registrada exitosamente'),
              duration: Duration(seconds: 1),
            ),
          );
          navigator.pop();
          if (widget.onSuccess != null) widget.onSuccess!();
        }
      } catch (e) {
        log('Error en _submitForm: $e');
        if (mounted && context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error al registrar la venta: $e'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, complete todos los campos y seleccione garantía.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLoading != null) {
      return Center(child: Text(_errorLoading!));
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500.0),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Formulario de Venta',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el nombre'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _dniController,
                      decoration: const InputDecoration(labelText: 'DNI'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'))
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el DNI'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el teléfono'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese la dirección'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _correoController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el correo'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _ciudadController,
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese la ciudad'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _cpController,
                      decoration:
                          const InputDecoration(labelText: 'Código Postal'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el CP'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _provinciaController,
                      decoration: const InputDecoration(labelText: 'Provincia'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese la provincia'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _precioFinalController,
                      decoration:
                          const InputDecoration(labelText: 'Precio Final (€)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el precio final';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Ingrese un número entero válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6.0),
                    const Text('Garantía',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _garantia == true,
                          onChanged: (val) {
                            setState(() {
                              _garantia = true;
                            });
                          },
                        ),
                        const Text('Sí'),
                        const SizedBox(width: 20),
                        Checkbox(
                          value: _garantia == false,
                          onChanged: (val) {
                            setState(() {
                              _garantia = false;
                            });
                          },
                        ),
                        const Text('No'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Guardar'),
                        ),
                        TextButton(
                          onPressed: () {
                            log('Formulario cancelado');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
