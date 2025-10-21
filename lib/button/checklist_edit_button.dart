import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';

class ChecklistEditButton extends StatefulWidget {
  final String cocheUuid;
  final String? currentDiagnostico;
  final String? currentFechaItv;

  const ChecklistEditButton({
    super.key,
    required this.cocheUuid,
    this.currentDiagnostico,
    this.currentFechaItv,
  });

  @override
  State<ChecklistEditButton> createState() => _ChecklistEditButtonState();
}

class _ChecklistEditButtonState extends State<ChecklistEditButton> {
  String? _selectedDiagnostico;
  DateTime? fechaItv;
  XFile? _image;
  bool _isLoading = false;
  final List<String> _diagnosticos = [
    'Requiere mantenimiento',
    'Listo para venta',
  ];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fechaItvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDiagnostico = widget.currentDiagnostico != null &&
            _diagnosticos.contains(widget.currentDiagnostico)
        ? widget.currentDiagnostico
        : _diagnosticos[0];
    fechaItv = widget.currentFechaItv != null
        ? DateTime.tryParse(widget.currentFechaItv!)
        : null;
    _fechaItvController.text =
        fechaItv != null ? DateFormat('dd/MM/yyyy').format(fechaItv!) : '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<Uint8List> _compressImage(XFile image) async {
    final imageBytes = await image.readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 1024,
      minHeight: 1024,
      quality: 85,
    );
    return compressedBytes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(
        minWidth: 300,
        maxWidth: 300,
        maxHeight: 450,
      ),
      title: const Text('Editar Checklist'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fechaItvController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fechaItv ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      fechaItv = picked;
                      _fechaItvController.text =
                          DateFormat('dd/MM/yyyy').format(picked);
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Fecha ITV',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Seleccione una fecha'
                    : null,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                initialValue: _selectedDiagnostico,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                ),
                items: _diagnosticos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (mounted && value != null) {
                    setState(() {
                      _selectedDiagnostico = value;
                    });
                  }
                },
                validator: (value) =>
                    value == null ? 'Seleccione un diagnóstico' : null,
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading ? null : _pickImage,
                  child: const Text('Editar imagen'),
                ),
              ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Imagen seleccionada: ${_image!.name}'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    if (fechaItv == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, seleccione una fecha ITV'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _isLoading = true;
                    });
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      final updateData = {
                        'fecha_itv': DateFormat('yyyy-MM-dd').format(fechaItv!),
                        'diagnostico': _selectedDiagnostico,
                      };

                      // Obtener marca y matrícula desde la tabla coches
                      final cocheData = await Supabase.instance.client
                          .from('coches')
                          .select('marca, matricula')
                          .eq('uuid', widget.cocheUuid)
                          .single();

                      final marca = cocheData['marca'] ?? 'unknown';
                      final matricula = cocheData['matricula'] ?? 'unknown';

                      // Subir imagen si se seleccionó
                      if (_image != null) {
                        final fileName =
                            'imagen_${marca}_${matricula}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final imageBytes = await _compressImage(_image!);
                        await Supabase.instance.client.storage
                            .from('imagenes')
                            .uploadBinary(
                              fileName,
                              imageBytes,
                              fileOptions:
                                  const FileOptions(contentType: 'image/jpeg'),
                            );
                        final imageUrl = Supabase.instance.client.storage
                            .from('imagenes')
                            .getPublicUrl(fileName);
                        updateData['imagen_url'] = imageUrl;
                      }

                      await Supabase.instance.client
                          .from('coches')
                          .update(updateData)
                          .eq('uuid', widget.cocheUuid);

                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Checklist actualizado correctamente'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      navigator.pop(true); // Retorna true para refrescar
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar checklist: $e'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fechaItvController.dispose();
    super.dispose();
  }
}
