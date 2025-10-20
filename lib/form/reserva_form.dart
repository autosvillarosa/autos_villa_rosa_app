import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pdf_generators/reserva_pdf.dart';
import '../utils/pdf_utils.dart';
import 'dart:developer';

// Función auxiliar para capitalizar la primera letra de cada palabra
String capitalizeEachWord(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

// TextInputFormatter para capitalizar la primera letra de cada palabra
class CapitalizeEachWordFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String newText = capitalizeEachWord(newValue.text);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ReservaForm extends StatefulWidget {
  final String cocheUuid;
  final VoidCallback? onSuccess;
  final Map<String, dynamic>? initialData;

  const ReservaForm({
    super.key,
    required this.cocheUuid,
    this.onSuccess,
    this.initialData,
  });

  // Método para abrir el formulario
  static Future<void> handleGenerate({
    required BuildContext context,
    required Map<String, dynamic> cocheData,
    required String cocheUuid,
    required VoidCallback refresh,
  }) async {
    final estadoCoche = cocheData['estado_coche'];
    final messenger = ScaffoldMessenger.of(context);

    if (estadoCoche == 'Vendido') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se puede generar: el coche ya está vendido.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (estadoCoche == 'Por llegar') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'No se puede generar la reserva: actualice la ubicación del coche.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    bool shouldOpenDialog = true;
    if (cocheData['pdf_reserva_url'] != null) {
      shouldOpenDialog = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Regenerar reserva"),
              content: const Text(
                  "¿Está seguro que desea regenerar el PDF de Reserva?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Sí, continuar"),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!shouldOpenDialog) return;

    Map<String, dynamic>? initialData;
    try {
      initialData = await Supabase.instance.client
          .from('coches')
          .select('nombre, dni, telefono, precio_final, abono, medio_de_pago')
          .eq('uuid', cocheUuid)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error cargando datos iniciales: $e')),
      );
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => ReservaForm(
          cocheUuid: cocheUuid,
          onSuccess: refresh,
          initialData: initialData,
        ),
      );
    }
  }

  @override
  State<ReservaForm> createState() => _ReservaFormState();
}

class _ReservaFormState extends State<ReservaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _precioFinalController = TextEditingController();
  final _abonoController = TextEditingController();
  String? _selectedMedioDePago;
  bool _isLoading = false;
  final List<String> _mediosDePago = ['Transferencia', 'Efectivo', 'Tarjeta'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadFromInitialData(widget.initialData!);
    } else {
      _loadInitialData();
    }
  }

  void _loadFromInitialData(Map<String, dynamic> data) {
    _nombreController.text = capitalizeEachWord(data['nombre'] ?? '');
    _dniController.text = (data['dni'] ?? '').toUpperCase();
    _telefonoController.text = data['telefono'] ?? '';
    _precioFinalController.text = (data['precio_final'] ?? '').toString();
    _abonoController.text = (data['abono'] ?? '').toString();
    _selectedMedioDePago = data['medio_de_pago'];
    _isLoading = false;
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await Supabase.instance.client
          .from('coches')
          .select('nombre, dni, telefono, precio_final, abono, medio_de_pago')
          .eq('uuid', widget.cocheUuid)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (data != null && mounted) _loadFromInitialData(data);
    } catch (e) {
      log('Error cargando datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _precioFinalController.dispose();
    _abonoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final int precioFinal = int.tryParse(_precioFinalController.text) ?? 0;
      final int abono = int.tryParse(_abonoController.text) ?? 0;

      final data = {
        'nombre': capitalizeEachWord(_nombreController.text),
        'dni': _dniController.text.toUpperCase(),
        'telefono': _telefonoController.text,
        'precio_final': precioFinal,
        'abono': abono,
        'medio_de_pago': _selectedMedioDePago,
      };

      await Supabase.instance.client
          .from('coches')
          .update(data)
          .eq('uuid', widget.cocheUuid)
          .select();

      final cocheData = await Supabase.instance.client
          .from('coches')
          .select('marca, modelo, matricula')
          .eq('uuid', widget.cocheUuid)
          .single();

      final reservaData = {
        ...data,
        'marca': cocheData['marca'] ?? '',
        'modelo': cocheData['modelo'] ?? '',
        'matricula': cocheData['matricula'] ?? '',
        'fecha_reserva': DateTime.now().toIso8601String(),
      };

      final pdf = await generateReservaPdf(reservaData: reservaData);
      final fileName =
          'Reserva_${cocheData['matricula'] ?? 'unknown'}_${cocheData['marca'] ?? 'unknown'}.pdf';
      final pdfUrl =
          await PdfUtils.uploadPdfToSupabase(fileName, await pdf.save());

      if (pdfUrl != null) {
        await Supabase.instance.client.from('coches').update({
          'pdf_reserva_url': pdfUrl,
          'fecha_reserva': reservaData['fecha_reserva'],
          'estado_coche': 'Reservado',
        }).eq('uuid', widget.cocheUuid);

        messenger.showSnackBar(
          const SnackBar(content: Text('Reserva y PDF generados exitosamente')),
        );
        widget.onSuccess?.call();
        navigator.pop();
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Error al subir el PDF a Supabase')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al actualizar reserva: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarReserva() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final data = {
        'nombre': null,
        'dni': null,
        'telefono': null,
        'precio_final': null,
        'abono': null,
        'medio_de_pago': null,
        'pdf_reserva_url': null,
        'fecha_reserva': null,
        'estado_coche': 'Disponible',
      };

      await Supabase.instance.client
          .from('coches')
          .update(data)
          .eq('uuid', widget.cocheUuid);

      messenger.showSnackBar(
        const SnackBar(content: Text('Reserva eliminada exitosamente')),
      );
      widget.onSuccess?.call();
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al eliminar reserva: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton.icon(
                          onPressed: _eliminarReserva,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Eliminar Reserva',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const Text(
                        'Formulario de Reserva',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration:
                                  const InputDecoration(labelText: 'Nombre'),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]')),
                                CapitalizeEachWordFormatter(),
                              ],
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Ingrese el nombre'
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _dniController,
                              decoration:
                                  const InputDecoration(labelText: 'DNI'),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9]')),
                              ],
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Ingrese el DNI'
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _telefonoController,
                              decoration:
                                  const InputDecoration(labelText: 'Teléfono'),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9\s+]')),
                              ],
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Ingrese el teléfono'
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _precioFinalController,
                              decoration: const InputDecoration(
                                  labelText: 'Precio Final (€)'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ingrese el precio final';
                                }
                                if (int.tryParse(v) == null) {
                                  return 'Ingrese un número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _abonoController,
                              decoration:
                                  const InputDecoration(labelText: 'Abono (€)'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ingrese el abono';
                                }
                                if (int.tryParse(v) == null) {
                                  return 'Ingrese un número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedMedioDePago,
                              decoration: const InputDecoration(
                                  labelText: 'Medio de Pago'),
                              items: _mediosDePago
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedMedioDePago = v),
                              validator: (v) => v == null
                                  ? 'Seleccione un medio de pago'
                                  : null,
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
