import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbicacionEditButton extends StatefulWidget {
  final String cocheUuid;
  final String? currentUbicacion;

  const UbicacionEditButton({
    super.key,
    required this.cocheUuid,
    this.currentUbicacion,
  });

  @override
  State<UbicacionEditButton> createState() => _UbicacionEditButtonState();
}

class _UbicacionEditButtonState extends State<UbicacionEditButton> {
  String? _currentUbicacion;
  String? _selectedUbicacion;
  String _customUbicacion = '';

  final Map<String, List<String>> _ubicaciones = {
    'Málaga': [
      'CURVA',
      'LINEA',
      'PALENQUE',
      'DECATHLON',
      'C/PASCAL',
      'ESCUELA',
      'IGLESIA',
      'LA PARADA',
      'CANTARO',
      'PRESTADO',
    ],
    'Algarrobo / Talleres': [
      'FINAL POLÍGONO',
      'EXPLANADA',
      'MEZQUITILLA',
      'N340',
      'CHILCHES',
      'DANI ESTRELLA',
      'CARLOS CHAPA',
      'FELIX',
    ],
  };

  @override
  void initState() {
    super.initState();
    _currentUbicacion = widget.currentUbicacion;
  }

  Future<void> _updateUbicacion(String newUbicacion) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      Map<String, dynamic> updates = {
        'ubicacion': newUbicacion,
        'ubicacion_update': DateTime.now().toIso8601String(),
      };

      if (_currentUbicacion == 'Por llegar' && newUbicacion != 'Por llegar') {
        updates['estado_coche'] = 'Disponible';
        updates['fecha_llegada'] = DateTime.now().toIso8601String();
      }

      await Supabase.instance.client
          .from('coches')
          .update(updates)
          .eq('uuid', widget.cocheUuid);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Ubicación actualizada correctamente'),
            duration: Duration(seconds: 1),
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error al actualizar ubicación: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Editar Ubicación${_currentUbicacion != null ? ' ($_currentUbicacion)' : ''}',
      ),
      contentPadding: const EdgeInsets.all(4.0),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._ubicaciones.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const double spacing = 3.0;
                          const double totalSpacing = spacing * 2;
                          double buttonWidth =
                              (constraints.maxWidth - totalSpacing) / 2;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: entry.value.map((ubicacion) {
                              final isSelected =
                                  _selectedUbicacion == ubicacion;
                              return SizedBox(
                                width: buttonWidth,
                                height: 34.0,
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedUbicacion = ubicacion;
                                      _customUbicacion = '';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? const Color.fromARGB(255, 0, 114, 15)
                                        : Colors.white,
                                    foregroundColor: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    side: BorderSide(
                                        color: isSelected
                                            ? const Color.fromARGB(
                                                255, 0, 114, 15)
                                            : const Color(0xFF0053A0),
                                        width: 1.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                  ),
                                  child: Text(
                                    ubicacion,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize:
                                          (ubicacion == 'FINAL POLÍGONO' ||
                                                  ubicacion == 'CHILCHES')
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
                          );
                        },
                      ),
                      const SizedBox(height: 6.0),
                    ],
                  );
                }),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _customUbicacion = value;
                      _selectedUbicacion = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Nueva ubicación',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontSize: 14.0),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final newUbicacion = _selectedUbicacion ?? _customUbicacion.trim();
            if (newUbicacion.isNotEmpty) {
              final capitalizedUbicacion = newUbicacion.isNotEmpty
                  ? newUbicacion[0].toUpperCase() + newUbicacion.substring(1)
                  : newUbicacion;
              _updateUbicacion(capitalizedUbicacion);
            } else {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, seleccione o ingrese una ubicación válida',
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            }
          },
          child: const Text(
            'Guardar',
            style: TextStyle(fontSize: 14.0),
          ),
        ),
      ],
    );
  }
}
