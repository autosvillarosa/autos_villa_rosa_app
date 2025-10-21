import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter

class AddCarForm extends StatefulWidget {
  const AddCarForm({super.key});

  @override
  AddCarFormState createState() => AddCarFormState();
}

class AddCarFormState extends State<AddCarForm> {
  final _formKey = GlobalKey<FormState>();
  final _fechaAltaController = TextEditingController();
  final _fechaMatriculacionController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _bastidorController = TextEditingController();
  final _cvController = TextEditingController();
  final _ccController = TextEditingController();
  final _kmController = TextEditingController();
  final _origenTrasladoController = TextEditingController();
  final _precioController = TextEditingController();
  final _fechaItvController = TextEditingController();

  String? _transmision;
  String? _tipoCoche;
  String? _tipoCombustible;
  String? _origenMarca;

  XFile? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  String _convertToIsoDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _capitalizarPrimera(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Future<void> _addCar() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_transmision == null ||
        _tipoCoche == null ||
        _tipoCombustible == null ||
        _origenMarca == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona todas las opciones'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final marca = _capitalizarPrimera(_marcaController.text.trim());
    final matricula = _matriculaController.text.trim().toUpperCase();
    final modelo = _capitalizarPrimera(_modeloController.text.trim());
    final bastidor = _bastidorController.text.trim().toUpperCase();
    final origenTraslado =
        _capitalizarPrimera(_origenTrasladoController.text.trim());

    int? parseEntero(String v) => v.isNotEmpty ? int.tryParse(v) : null;

    final cv = parseEntero(_cvController.text.trim());
    final cc = parseEntero(_ccController.text.trim());
    final km = parseEntero(_kmController.text.trim());
    final precio = parseEntero(_precioController.text.trim());

    try {
      String? imageUrl;
      if (_image != null) {
        final fileName =
            'imagen_${marca}_${matricula}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageBytes = await _image!.readAsBytes();
        await Supabase.instance.client.storage.from('imagenes').uploadBinary(
              fileName,
              imageBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        imageUrl = Supabase.instance.client.storage
            .from('imagenes')
            .getPublicUrl(fileName);
      }

      final response = await Supabase.instance.client.from('coches').insert({
        'fecha_alta': _convertToIsoDate(_fechaAltaController.text),
        'fecha_matriculacion':
            _convertToIsoDate(_fechaMatriculacionController.text),
        'matricula': matricula,
        'marca': marca,
        'modelo': modelo,
        'bastidor': bastidor,
        'cv': cv,
        'cc': cc,
        'km': km,
        'precio': precio,
        'transmision': _transmision,
        'tipo_coche': _tipoCoche,
        'tipo_combustible': _tipoCombustible,
        'origen_marca': _origenMarca,
        'origen_traslado': origenTraslado,
        'fecha_itv': _convertToIsoDate(_fechaItvController.text),
        'fecha_creacion': DateTime.now().toIso8601String(),
        if (imageUrl != null) 'imagen_url': imageUrl,
      }).select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coche añadido correctamente'),
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.of(context).pop(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _numField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Campo obligatorio' : null,
    );
  }

  @override
  void dispose() {
    _fechaAltaController.dispose();
    _fechaMatriculacionController.dispose();
    _matriculaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _bastidorController.dispose();
    _cvController.dispose();
    _ccController.dispose();
    _kmController.dispose();
    _origenTrasladoController.dispose();
    _precioController.dispose();
    _fechaItvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(null);
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(4.0),
        title: const Text(
          'Añadir Coche',
          style: TextStyle(fontSize: 16.0),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300,
            maxWidth: 300,
            maxHeight: 450,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _fechaAltaController,
                      readOnly: true,
                      onTap: () => _pickDate(_fechaAltaController),
                      decoration: const InputDecoration(
                        labelText: 'Fecha Alta',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _fechaMatriculacionController,
                      readOnly: true,
                      onTap: () => _pickDate(_fechaMatriculacionController),
                      decoration: const InputDecoration(
                        labelText: 'Fecha Matriculación',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _matriculaController,
                      decoration: const InputDecoration(
                        labelText: 'Matrícula',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]')),
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _marcaController,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9 ]')),
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _modeloController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9 ]')),
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _bastidorController,
                      decoration: const InputDecoration(
                        labelText: 'Bastidor',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]')),
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    _numField(_cvController, 'CV'),
                    const SizedBox(height: 6.0),
                    _numField(_ccController, 'CC'),
                    const SizedBox(height: 6.0),
                    _numField(_kmController, 'Kilómetros'),
                    const SizedBox(height: 6.0),
                    _numField(_precioController, 'Precio (€)'),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      initialValue: _transmision,
                      decoration: const InputDecoration(
                        labelText: 'Transmisión',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      items: ['Automático', 'Manual', 'Híbrido']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _transmision = v),
                      validator: (value) =>
                          value == null ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      initialValue: _tipoCoche,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Coche',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      items: [
                        'Berlina',
                        'Hatchback',
                        '4x4',
                        'Coupe',
                        'Descapotable',
                        'Monovolumen',
                        'Furgoneta'
                      ]
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _tipoCoche = v),
                      validator: (value) =>
                          value == null ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      initialValue: _tipoCombustible,
                      decoration: const InputDecoration(
                        labelText: 'Tipo Combustible',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      items: ['Diésel', 'Gasolina']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _tipoCombustible = v),
                      validator: (value) =>
                          value == null ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      initialValue: _origenMarca,
                      decoration: const InputDecoration(
                        labelText: 'Origen Marca',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      items: ['Europeo', 'Asiático', 'Americano']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _origenMarca = v),
                      validator: (value) =>
                          value == null ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _origenTrasladoController,
                      decoration: const InputDecoration(
                        labelText: 'Origen Traslado',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      controller: _fechaItvController,
                      readOnly: true,
                      onTap: () => _pickDate(_fechaItvController),
                      decoration: const InputDecoration(
                        labelText: 'Fecha ITV',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 6.0),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _pickImage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(
                            color: Color(0xFF0053A0),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                        ),
                        child: const Text(
                          'Subir Imagen',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (_image != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Imagen seleccionada: ${_image!.name}',
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(100.0, 38.0)),
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0)),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 14.0),
            ),
          ),
          ElevatedButton(
            onPressed: _addCar,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(100.0, 38.0)),
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0)),
            ),
            child: const Text(
              'Añadir',
              style: TextStyle(fontSize: 14.0),
            ),
          ),
        ],
      ),
    );
  }
}
