import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  CitasScreenState createState() => CitasScreenState();
}

class CitasScreenState extends State<CitasScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _allCitas = []; // Todas las citas futuras para marcadores
  List<dynamic> _filteredCitas = []; // Citas filtradas para mostrar
  List<dynamic> _matriculas = [];
  Set<DateTime> _citasDates = {}; // Conjunto de fechas únicas para marcadores
  bool _isLoading = false;
  bool _isMatriculasLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchAllCitas(); // Obtener todas las citas para marcadores
    _fetchMatriculas();
  }

  Future<void> _fetchMatriculas() async {
    if (_isMatriculasLoaded) return; // Evitar recarga innecesaria
    try {
      final response = await Supabase.instance.client
          .from('coches')
          .select('matricula')
          .not('matricula', 'is', null)
          .neq('estado_coche', 'Vendido');
      if (mounted) {
        setState(() {
          _matriculas = response;
          _isMatriculasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMatriculasLoaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar matrículas: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _fetchAllCitas() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('coches')
          .select('marca, modelo, matricula, fecha_cita, ubicacion')
          .gte('fecha_cita', DateTime.now().toIso8601String())
          .order('fecha_cita', ascending: true);

      if (mounted) {
        final citas = response as List<dynamic>;
        // Precomputar fechas únicas para marcadores
        final citasDates =
            citas.where((cita) => cita['fecha_cita'] != null).map((cita) {
          final citaDate = DateTime.parse(cita['fecha_cita']).toLocal();
          return DateTime(citaDate.year, citaDate.month, citaDate.day);
        }).toSet();

        setState(() {
          _allCitas = citas;
          _citasDates = citasDates;
          _filterCitasForDisplay(); // Filtrar para mostrar inicialmente
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar citas: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _filterCitasForDisplay() {
    List<dynamic> newFilteredCitas;
    if (_selectedDay == null) {
      newFilteredCitas = _allCitas;
    } else {
      final startOfDay =
          DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      newFilteredCitas = _allCitas.where((cita) {
        if (cita['fecha_cita'] == null) return false;
        final citaDate = DateTime.parse(cita['fecha_cita']).toLocal();
        return citaDate.isAfter(startOfDay) && citaDate.isBefore(endOfDay);
      }).toList();
    }

    // Solo llamar a setState si los datos han cambiado
    if (_filteredCitas != newFilteredCitas) {
      setState(() {
        _filteredCitas = newFilteredCitas;
      });
    }
  }

  Future<void> _editCita(String matricula, DateTime? newDate) async {
    if (newDate == null || matricula.isEmpty) return;

    try {
      final coche = await Supabase.instance.client
          .from('coches')
          .select('uuid')
          .eq('matricula', matricula)
          .single();

      if (coche['uuid'] != null) {
        final isoDate = newDate.toIso8601String();
        await Supabase.instance.client
            .from('coches')
            .update({'fecha_cita': isoDate}).eq('uuid', coche['uuid']);

        if (mounted) {
          await _fetchAllCitas();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cita registrada exitosamente'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar cita: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _deleteCita(String matricula) async {
    try {
      final coche = await Supabase.instance.client
          .from('coches')
          .select('uuid')
          .eq('matricula', matricula)
          .single();

      if (coche['uuid'] != null) {
        await Supabase.instance.client
            .from('coches')
            .update({'fecha_cita': null}).eq('uuid', coche['uuid']);

        if (mounted) {
          await _fetchAllCitas();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cita eliminada exitosamente'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cita: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _showAddCitaDialog(
      {String? matricula, DateTime? initialDateTime}) async {
    if (!_isMatriculasLoaded) {
      await _fetchMatriculas();
    }

    if (_matriculas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay matrículas disponibles'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    String? selectedMatricula = matricula;
    DateTime initialDate = initialDateTime ?? DateTime.now();
    int adjustedMinute = (initialDate.minute ~/ 15) * 15;
    DateTime selectedDateTime = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      initialDate.hour,
      adjustedMinute,
    );

    if (selectedMatricula != null) {
      final matriculaValida = _matriculas
          .any((m) => m['matricula'].toString() == selectedMatricula);
      if (!matriculaValida) {
        selectedMatricula = null;
      }
    }

    final uniqueMatriculas =
        _matriculas.map((m) => m['matricula'].toString()).toSet().toList();

    if (mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
                shape: Theme.of(context).dialogTheme.shape,
                title: Text(
                  'Nueva Cita',
                  style: Theme.of(context).dialogTheme.titleTextStyle,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return uniqueMatriculas;
                        }
                        return uniqueMatriculas.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setDialogState(() {
                          selectedMatricula = selection;
                        });
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextFormField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Matrícula',
                            hintText: 'Escribe para buscar...',
                            prefixIcon: const Icon(Icons.directions_car,
                                size: 20.0, color: Colors.grey),
                            labelStyle: Theme.of(context)
                                .inputDecorationTheme
                                .labelStyle,
                            filled:
                                Theme.of(context).inputDecorationTheme.filled,
                            fillColor: Theme.of(context)
                                .inputDecorationTheme
                                .fillColor,
                            contentPadding: Theme.of(context)
                                .inputDecorationTheme
                                .contentPadding,
                            border:
                                Theme.of(context).inputDecorationTheme.border,
                            enabledBorder: Theme.of(context)
                                .inputDecorationTheme
                                .enabledBorder,
                            focusedBorder: Theme.of(context)
                                .inputDecorationTheme
                                .focusedBorder,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          validator: (value) => value == null ||
                                  value.isEmpty ||
                                  selectedMatricula == null
                              ? 'Seleccione una matrícula válida'
                              : null,
                        );
                      },
                      optionsViewBuilder: (BuildContext context,
                          AutocompleteOnSelected<String> onSelected,
                          Iterable<String> options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: Container(
                              color:
                                  Theme.of(context).dialogTheme.backgroundColor,
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option =
                                      options.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: Container(
                                      color: Theme.of(context)
                                          .dialogTheme
                                          .backgroundColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      child: Text(
                                        option,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey.shade800,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      initialValue:
                          TextEditingValue(text: selectedMatricula ?? ''),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDateTime,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.utc(2030, 12, 31),
                              );
                              if (date != null) {
                                setDialogState(() {
                                  selectedDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    selectedDateTime.hour,
                                    selectedDateTime.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Fecha',
                                labelStyle: Theme.of(context)
                                    .inputDecorationTheme
                                    .labelStyle,
                                contentPadding: Theme.of(context)
                                    .inputDecorationTheme
                                    .contentPadding,
                                border: Theme.of(context)
                                    .inputDecorationTheme
                                    .border,
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(selectedDateTime),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Hora',
                              labelStyle: Theme.of(context)
                                  .inputDecorationTheme
                                  .labelStyle,
                              contentPadding: Theme.of(context)
                                  .inputDecorationTheme
                                  .contentPadding,
                              border:
                                  Theme.of(context).inputDecorationTheme.border,
                            ),
                            initialValue: selectedDateTime.hour,
                            items:
                                List.generate(24, (index) => index).map((hour) {
                              return DropdownMenuItem<int>(
                                value: hour,
                                child: Text(
                                  hour.toString().padLeft(2, '0'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedDateTime = DateTime(
                                    selectedDateTime.year,
                                    selectedDateTime.month,
                                    selectedDateTime.day,
                                    value,
                                    selectedDateTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Min',
                              labelStyle: Theme.of(context)
                                  .inputDecorationTheme
                                  .labelStyle,
                              contentPadding: Theme.of(context)
                                  .inputDecorationTheme
                                  .contentPadding,
                              border:
                                  Theme.of(context).inputDecorationTheme.border,
                            ),
                            initialValue: selectedDateTime.minute,
                            items: [0, 15, 30, 45].map((minute) {
                              return DropdownMenuItem<int>(
                                value: minute,
                                child: Text(
                                  minute.toString().padLeft(2, '0'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedDateTime = DateTime(
                                    selectedDateTime.year,
                                    selectedDateTime.month,
                                    selectedDateTime.day,
                                    selectedDateTime.hour,
                                    value,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: Theme.of(context).textButtonTheme.style?.copyWith(
                          foregroundColor:
                              WidgetStateProperty.all(Colors.grey.shade600),
                        ),
                    child: Text(
                      'Cancelar',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final currentContext = dialogContext;
                      final navigator = Navigator.of(currentContext);
                      if (selectedMatricula != null) {
                        await _editCita(selectedMatricula!, selectedDateTime);
                        if (navigator.canPop()) {
                          navigator.pop();
                        }
                      } else {
                        if (navigator.canPop()) {
                          navigator.pop();
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Complete todos los campos'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    },
                    style: Theme.of(context).elevatedButtonTheme.style,
                    child: Text(
                      'Guardar',
                      style: Theme.of(context)
                          .elevatedButtonTheme
                          .style
                          ?.textStyle
                          ?.resolve({}),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 37.0,
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Text(
                    'Citas',
                    style: Theme.of(context)
                        .appBarTheme
                        .titleTextStyle
                        ?.copyWith(
                          color: Theme.of(context).appBarTheme.foregroundColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).canvasColor,
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = isSameDay(_selectedDay, selectedDay)
                              ? null
                              : selectedDay;
                          _focusedDay = focusedDay;
                          _filterCitasForDisplay();
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final dateKey =
                              DateTime(date.year, date.month, date.day);
                          if (_citasDates.contains(dateKey)) {
                            return const Positioned(
                              right: 1,
                              bottom: 1,
                              child: SizedBox(
                                width: 6,
                                height: 6,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle:
                            Theme.of(context).textTheme.bodyMedium ??
                                const TextStyle(fontSize: 14.0),
                        weekendTextStyle:
                            Theme.of(context).textTheme.bodyMedium ??
                                const TextStyle(fontSize: 14.0),
                        selectedTextStyle: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        todayDecoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        titleTextStyle:
                            Theme.of(context).textTheme.titleLarge ??
                                const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0053A0),
                                ),
                        formatButtonTextStyle: const TextStyle(fontSize: 14.0),
                        formatButtonDecoration: BoxDecoration(
                          border: Border.fromBorderSide(
                              BorderSide(color: Colors.grey)),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredCitas.isEmpty
                              ? const Center(
                                  child: Text('No hay citas disponibles'))
                              : ListView.builder(
                                  itemCount: _filteredCitas.length,
                                  itemBuilder: (context, index) {
                                    final cita = _filteredCitas[index];
                                    final fechaCita = cita['fecha_cita'] != null
                                        ? DateTime.parse(cita['fecha_cita'])
                                            .toLocal()
                                        : null;
                                    final formattedFecha = fechaCita != null
                                        ? DateFormat('dd/MM/yyyy HH:mm')
                                            .format(fechaCita)
                                        : 'Sin fecha';

                                    return Card(
                                      margin: EdgeInsets.fromLTRB(
                                        4.0,
                                        index == 0 ? 4.0 : 2.0,
                                        4.0,
                                        2.0,
                                      ),
                                      elevation: 4.0,
                                      color: Theme.of(context)
                                          .dialogTheme
                                          .backgroundColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8.0)),
                                        side: BorderSide(
                                            color: Colors.grey, width: 1.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 4.0),
                                                    child: Text(
                                                      '${cita['marca'] ?? 'N/A'} ${cita['modelo'] ?? 'N/A'}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15.0,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 4.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.directions_car,
                                                          size: 16.0,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Expanded(
                                                          child: Text(
                                                            'Matrícula: ${cita['matricula'] ?? 'SIN MATRICULA'}',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontSize:
                                                                      15.0,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 4.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.location_on,
                                                          size: 16.0,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Expanded(
                                                          child: Text(
                                                            'Ubicación: ${cita['ubicacion'] ?? 'N/A'}',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontSize:
                                                                      15.0,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 4.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.schedule,
                                                          size: 16.0,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Expanded(
                                                          child: Text(
                                                            'Cita: $formattedFecha',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontSize:
                                                                      15.0,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    size: 18.0,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                                  onPressed: () async {
                                                    if (fechaCita != null) {
                                                      await _showAddCitaDialog(
                                                        matricula:
                                                            cita['matricula']
                                                                .toString(),
                                                        initialDateTime:
                                                            fechaCita,
                                                      );
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: 18.0,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                                  onPressed: () {
                                                    _deleteCita(
                                                        cita['matricula']
                                                            .toString());
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isMatriculasLoaded
          ? FloatingActionButton(
              onPressed: () async {
                await _showAddCitaDialog();
              },
              tooltip: 'Nueva cita',
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor:
                  Theme.of(context).floatingActionButtonTheme.foregroundColor,
              shape: Theme.of(context).floatingActionButtonTheme.shape,
              child: const Icon(Icons.add, size: 19.2),
            )
          : null,
    );
  }
}
