import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

class FiltrosAdicionalesScreen extends StatefulWidget {
  final String? initialEstadoDocumentos;
  final String? initialEstadoPublicacion;
  final String? initialDiagnostico;
  final String? initialEstadoItv;
  final Set<String>? initialUbicacion;

  const FiltrosAdicionalesScreen({
    super.key,
    this.initialEstadoDocumentos,
    this.initialEstadoPublicacion,
    this.initialDiagnostico,
    this.initialEstadoItv,
    this.initialUbicacion,
  });

  @override
  FiltrosAdicionalesScreenState createState() =>
      FiltrosAdicionalesScreenState();
}

class FiltrosAdicionalesScreenState extends State<FiltrosAdicionalesScreen> {
  String? _selectedEstadoDocumentos;
  String? _selectedEstadoPublicacion;
  String? _selectedDiagnostico;
  String? _selectedEstadoItv;
  Set<String> _selectedUbicacion = {};
  List<String> _allUbicaciones = [];

  static const double buttonHeight = 34;

  static const List<String> predefinedLocations = [
    'CURVA',
    'LINEA',
    'PALENQUE',
    'DECATHLON',
    'C/PASCAL',
    'ESCUELA',
    'IGLESIA',
    'LA PARADA',
    'CONFORAMA',
    'CANTARO',
    'PRESTADO',
    'FINAL POLIGONO',
    'EXPLANADA',
    'MEZQUITILLA',
    'N340',
    'CHILCHES',
    'DANI ESTRELLA',
    'CARLOS CHAPA',
    'FELIX',
    'POR LLEGAR',
  ];

  @override
  void initState() {
    super.initState();
    _selectedEstadoDocumentos = widget.initialEstadoDocumentos;
    _selectedEstadoPublicacion = widget.initialEstadoPublicacion;
    _selectedDiagnostico = widget.initialDiagnostico;
    _selectedEstadoItv = widget.initialEstadoItv;
    _selectedUbicacion = widget.initialUbicacion ?? {};
    dev.log('Inicializando filtros - Ubicación inicial: $_selectedUbicacion');
    _fetchUbicaciones();
  }

  Future<void> _fetchUbicaciones() async {
    try {
      final response = await Supabase.instance.client
          .from('coches')
          .select('ubicacion')
          .not('ubicacion', 'is', null);

      final ubicaciones = response
          .map((row) => (row['ubicacion'] as String).trim().toUpperCase())
          .where((u) => u.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _allUbicaciones = ubicaciones;
      });

      dev.log('Ubicaciones únicas cargadas: $_allUbicaciones');
      final nonPredefined =
          ubicaciones.where((u) => !predefinedLocations.contains(u)).toList();
      dev.log('Ubicaciones no predefinidas detectadas: $nonPredefined');
    } catch (e) {
      dev.log('Error al obtener ubicaciones: $e');
      setState(() => _allUbicaciones = []);
    }
  }

  Widget _buildFilterSelection({
    required String label,
    required String? selectedValue,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
    bool twoLines = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0053A0), width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: options.map((option) {
              final String value = option['value']!;
              final String text = option['text']!;
              final bool isSelected = selectedValue == value;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: SizedBox(
                    height: buttonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          onChanged(isSelected ? null : value);
                          dev.log('Filtro $label actualizado a: $value');
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color.fromARGB(255, 0, 114, 15)
                            : Colors.white,
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black87,
                        side: BorderSide(
                            color: isSelected
                                ? const Color.fromARGB(255, 0, 114, 15)
                                : const Color(0xFF0053A0),
                            width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: label == 'Diagnóstico' &&
                                  text == 'REQUIERE MANTENIMIENTO'
                              ? 12
                              : 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: twoLines ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionFilter({
    required String label,
    required Set<String> selectedValues,
    required Map<String, List<Map<String, String>>> groupedOptions,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0053A0), width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2.0),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 3.0;
              const double totalSpacing = spacing * 2;
              double buttonWidth = (constraints.maxWidth - totalSpacing) / 3;
              if (buttonWidth < 0) buttonWidth = constraints.maxWidth / 3;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupedOptions.entries.map((group) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          group.key,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: group.value.map((option) {
                          final String value = option['value']!;
                          final String text = option['text']!;
                          final bool isSelected =
                              selectedValues.contains(value);

                          return SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  final newSelectedValues =
                                      Set<String>.from(selectedValues);
                                  if (value == 'OTROS') {
                                    if (isSelected) {
                                      newSelectedValues.remove('OTROS');
                                      newSelectedValues.removeWhere((v) =>
                                          !predefinedLocations.contains(v));
                                      dev.log('OTROS deseleccionado');
                                    } else {
                                      newSelectedValues.add('OTROS');
                                      newSelectedValues.removeWhere((v) =>
                                          predefinedLocations.contains(v));
                                      dev.log('OTROS seleccionado');
                                    }
                                  } else {
                                    if (isSelected) {
                                      newSelectedValues.remove(value);
                                    } else {
                                      newSelectedValues.add(value);
                                      newSelectedValues.remove('OTROS');
                                      newSelectedValues.removeWhere((v) =>
                                          !predefinedLocations.contains(v));
                                    }
                                  }
                                  onChanged(newSelectedValues);
                                  dev.log(
                                      'Ubicación seleccionada: $newSelectedValues');
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? const Color.fromARGB(255, 0, 114, 15)
                                    : Colors.white,
                                foregroundColor:
                                    isSelected ? Colors.white : Colors.black87,
                                side: BorderSide(
                                    color: isSelected
                                        ? const Color.fromARGB(255, 0, 114, 15)
                                        : const Color(0xFF0053A0),
                                    width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: (text == 'FINAL POLIGONO' ||
                                          text == 'CHILCHES')
                                      ? 13
                                      : 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _returnFilters() {
    final nonPredefined =
        _allUbicaciones.where((u) => !predefinedLocations.contains(u)).toSet();

    final selectedUbicaciones = _selectedUbicacion.contains('OTROS')
        ? {..._selectedUbicacion, ...nonPredefined}
        : _selectedUbicacion;

    dev.log('Ubicaciones no predefinidas (para OTROS): $nonPredefined');
    dev.log('Ubicaciones seleccionadas finales: $selectedUbicaciones');

    final filters = {
      'estado_documentos': _selectedEstadoDocumentos,
      'estado_publicacion': _selectedEstadoPublicacion,
      'diagnostico': _selectedDiagnostico,
      'estado_itv': _selectedEstadoItv,
      'ubicacion':
          selectedUbicaciones.isNotEmpty ? selectedUbicaciones.join(',') : null,
    };

    Navigator.of(context).pop(filters);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, String>>> ubicaciones = {
      'MÁLAGA': [
        {'text': 'CURVA', 'value': 'CURVA'},
        {'text': 'LINEA', 'value': 'LINEA'},
        {'text': 'PALENQUE', 'value': 'PALENQUE'},
        {'text': 'DECATHLON', 'value': 'DECATHLON'},
        {'text': 'C/PASCAL', 'value': 'C/PASCAL'},
        {'text': 'ESCUELA', 'value': 'ESCUELA'},
        {'text': 'IGLESIA', 'value': 'IGLESIA'},
        {'text': 'LA PARADA', 'value': 'LA PARADA'},
        {'text': 'CONFORAMA', 'value': 'CONFORAMA'},
        {'text': 'CANTARO', 'value': 'CANTARO'},
        {'text': 'PRESTADO', 'value': 'PRESTADO'},
        {'text': 'OTROS', 'value': 'OTROS'},
      ],
      'ALGARROBO / TALLERES': [
        {'text': 'FINAL POLIGONO', 'value': 'FINAL POLIGONO'},
        {'text': 'EXPLANADA', 'value': 'EXPLANADA'},
        {'text': 'MEZQUITILLA', 'value': 'MEZQUITILLA'},
        {'text': 'N340', 'value': 'N340'},
        {'text': 'CHILCHES', 'value': 'CHILCHES'},
        {'text': 'DANI ESTRELLA', 'value': 'DANI ESTRELLA'},
        {'text': 'CARLOS CHAPA', 'value': 'CARLOS CHAPA'},
        {'text': 'FELIX', 'value': 'FELIX'},
      ],
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _returnFilters();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE6F0FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0053A0),
          elevation: 0,
          toolbarHeight: 60.0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: _returnFilters,
          ),
          title: const Text(
            'Filtros Adicionales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    children: [
                      _buildFilterSelection(
                        label: 'Estado ITV',
                        selectedValue: _selectedEstadoItv,
                        options: [
                          {'text': 'VENCIDA', 'value': 'VENCIDA'},
                          {'text': 'VIGENTE', 'value': 'VIGENTE'},
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedEstadoItv = val),
                      ),
                      const SizedBox(height: 6.0),
                      _buildFilterSelection(
                        label: 'Estado Documentos',
                        selectedValue: _selectedEstadoDocumentos,
                        options: [
                          {'text': 'PENDIENTE', 'value': 'PENDIENTE'},
                          {'text': 'RECIBIDA', 'value': 'RECIBIDA'},
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedEstadoDocumentos = val),
                      ),
                      const SizedBox(height: 6.0),
                      _buildFilterSelection(
                        label: 'Estado de Publicación',
                        selectedValue: _selectedEstadoPublicacion,
                        options: [
                          {'text': 'POR PUBLICAR', 'value': 'POR PUBLICAR'},
                          {'text': 'PUBLICADO', 'value': 'PUBLICADO'},
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedEstadoPublicacion = val),
                      ),
                      const SizedBox(height: 6.0),
                      _buildFilterSelection(
                        label: 'Diagnóstico',
                        selectedValue: _selectedDiagnostico,
                        options: [
                          {
                            'text': 'REQUIERE MANTENIMIENTO',
                            'value': 'REQUIERE MANTENIMIENTO'
                          },
                          {
                            'text': 'LISTO PARA VENTA',
                            'value': 'LISTO PARA VENTA'
                          },
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedDiagnostico = val),
                      ),
                      const SizedBox(height: 6.0),
                      _buildUbicacionFilter(
                        label: 'Ubicación',
                        selectedValues: _selectedUbicacion,
                        groupedOptions: ubicaciones,
                        onChanged: (val) =>
                            setState(() => _selectedUbicacion = val),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedEstadoDocumentos = null;
                            _selectedEstadoPublicacion = null;
                            _selectedDiagnostico = null;
                            _selectedEstadoItv = null;
                            _selectedUbicacion.clear();
                            dev.log('Filtros limpiados');
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide.none,
                          elevation: 2,
                          shadowColor: Colors.black26,
                        ),
                        child: const Text('Limpiar filtros',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _returnFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0053A0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide.none,
                          elevation: 2,
                          shadowColor: Colors.black26,
                        ),
                        child: const Text('Aplicar filtros',
                            style:
                                TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    ),
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
