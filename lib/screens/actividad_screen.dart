import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';

class ActividadScreen extends StatefulWidget {
  const ActividadScreen({super.key});

  @override
  ActividadScreenState createState() => ActividadScreenState();
}

class ActividadScreenState extends State<ActividadScreen> {
  List<dynamic> _actividades = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 30;
  int _fromIndex = 0;

  static const Map<String, String> _userNames = {
    'e4cbfe59-428f-43ab-81db-c9f0325040ab': 'Mohammed',
    'd790eb6b-6b29-4d3b-be80-4608cca018b6': 'Ricardo',
    'd368721b-daa9-4c2f-8330-c45e9c4a31ba': 'Osvaldo',
    'ac2d2900-01bc-4e84-a965-3f6433adc64f': 'Daniel',
    '41820a1e-1a6b-4280-8599-49da4b39d5ed': 'Lucia',
    'b413c8d5-e618-41e1-a539-20a14156a18f': 'Ursula',
    'aa03ff49-7953-4981-b6a4-42ba3f0b1566': 'Alejandro',
    '49fb7d64-1bfb-446f-8f69-95d1c6aa166d': 'Basilio',
    '02bc6ad4-1940-47f5-96e0-87d867f7addf': 'Lahcen',
    '3b3210ec-ca46-4855-97bd-555e059f0fb8': 'Achraf',
    'a0b7e2a5-81ff-48c5-893c-2bf700478c8c': 'Edinson',
    'ba9e0a41-8889-4d6d-a817-935ae0ab17c6': 'Usuario',
    '229f3b4e-8470-44ab-90db-9eb1d239bf05': 'Luisjavier',
  };

  @override
  void initState() {
    super.initState();
    _fetchActividades();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoading &&
          _hasMore) {
        _fetchActividades(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchActividades({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('actividad')
          .select('''
            id, coche_id, usuario_id, campo, valor_nuevo, fecha_evento,
            coches (marca, modelo, matricula)
          ''')
          .order('fecha_evento', ascending: false)
          .range(loadMore ? _fromIndex : 0, _fromIndex + _pageSize - 1);

      if (mounted) {
        setState(() {
          if (!loadMore) {
            _actividades = response;
            _fromIndex = _pageSize;
          } else {
            _actividades.addAll(response);
            _fromIndex += _pageSize;
          }
          _hasMore = response.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar actividades: $e')),
        );
      }
    }
  }

  Future<void> _refreshActividades() async {
    final double currentOffset = _scrollController.offset;
    setState(() {
      _actividades.clear();
      _fromIndex = 0;
      _hasMore = true;
    });
    await _fetchActividades();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(currentOffset);
      }
    });
  }

  String _generateDescription(Map<String, dynamic> actividad) {
    final campo = actividad['campo'] ?? 'N/A';
    final valorNuevo = actividad['valor_nuevo'] ?? 'N/A';

    switch (campo) {
      case 'creacion':
        return 'Añadido al stock';
      case 'ubicacion':
        return 'Movido a $valorNuevo';
      case 'estado_coche':
        switch (valorNuevo) {
          case 'Disponible':
            return 'Recibido';
          case 'Reservado':
            return 'Reservado';
          case 'Vendido':
            return 'Vendido';
          case 'Reserva cancelada':
            return 'Reserva cancelada';
          default:
            return 'Modificó estado: $valorNuevo';
        }
      case 'fecha_cita':
        if (valorNuevo == 'Cita cancelada') {
          return 'Cita cancelada';
        }
        final fechaCitaStr = valorNuevo.toString();
        final fechaCita = DateTime.parse(fechaCitaStr).toLocal();
        final ahora = DateTime.now().toLocal();
        final hoy = DateTime(ahora.year, ahora.month, ahora.day);
        final manana = hoy.add(const Duration(days: 1));
        final fechaCitaDia =
            DateTime(fechaCita.year, fechaCita.month, fechaCita.day);
        final horaMinuto = DateFormat('HH:mm').format(fechaCita);

        if (fechaCitaDia == hoy) {
          return 'Agendado hoy $horaMinuto';
        } else if (fechaCitaDia == manana) {
          return 'Agendado para mañana $horaMinuto';
        } else {
          final fechaFormateada =
              DateFormat('dd/MM/yyyy HH:mm').format(fechaCita);
          return 'Agendado para $fechaFormateada';
        }
      default:
        return 'Modificó $campo: $valorNuevo';
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0053A0),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            Container(
              height: 37.0,
              color: const Color(0xFF0053A0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 35.2,
                    height: 35.2,
                    child: IconButton(
                      icon: const Icon(Icons.dashboard,
                          size: 19.2, color: Colors.white),
                      tooltip: 'Ver Dashboard',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DashboardScreen()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Actividad Reciente',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 35.2,
                    height: 35.2,
                    child: IconButton(
                      icon: const Icon(Icons.logout,
                          size: 19.2, color: Colors.white),
                      tooltip: 'Cerrar sesión',
                      onPressed: _signOut,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFE6F0FA),
                child: RefreshIndicator(
                  onRefresh: _refreshActividades,
                  child: _isLoading && _actividades.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _actividades.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay actividades disponibles',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount:
                                  _actividades.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _actividades.length && _hasMore) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final actividad = _actividades[index];
                                final fechaEventoStr =
                                    actividad['fecha_evento'];
                                final fechaEvento =
                                    DateTime.parse(fechaEventoStr).toLocal();
                                final formattedFecha =
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(fechaEvento);
                                final userName =
                                    _userNames[actividad['usuario_id']] ??
                                        'Desconocido';
                                final coche = actividad['coches'] ?? {};
                                final marca = coche['marca'] ?? 'N/A';
                                final modelo = coche['modelo'] ?? 'N/A';
                                final matricula =
                                    coche['matricula'] ?? 'SIN MATRICULA';
                                final valorNuevo =
                                    actividad['valor_nuevo'] ?? 'N/A';

                                Color estadoColor = Colors.black;
                                if (actividad['campo'] == 'estado_coche') {
                                  switch (valorNuevo) {
                                    case 'Disponible':
                                      estadoColor = Colors.green;
                                      break;
                                    case 'Reservado':
                                      estadoColor = Colors.orange.shade600;
                                      break;
                                    case 'Vendido':
                                      estadoColor = Colors.red;
                                      break;
                                  }
                                }

                                final actionText =
                                    _generateDescription(actividad);
                                final isBoldAction = [
                                  'Recibido',
                                  'Reservado',
                                  'Vendido'
                                ].contains(actionText);
                                IconData actionIcon;
                                switch (actionText) {
                                  case 'Añadido al stock':
                                    actionIcon = Icons.add;
                                    break;
                                  case 'Reserva cancelada':
                                    actionIcon = Icons.cancel;
                                    break;
                                  case 'Recibido':
                                    actionIcon = Icons.home;
                                    break;
                                  case 'Reservado':
                                    actionIcon = Icons.lock;
                                    break;
                                  case 'Vendido':
                                    actionIcon = Icons.attach_money;
                                    break;
                                  case 'Cita cancelada':
                                    actionIcon = Icons.calendar_today;
                                    break;
                                  default:
                                    actionIcon =
                                        actionText.startsWith('Movido a')
                                            ? Icons.location_on
                                            : actionText.startsWith('Agendado')
                                                ? Icons.calendar_today
                                                : Icons.build;
                                }

                                return Card(
                                  key: ValueKey(actividad['id']),
                                  margin: EdgeInsets.fromLTRB(
                                    4.0,
                                    index == 0 ? 4.0 : 2.0,
                                    4.0,
                                    2.0,
                                  ),
                                  elevation: 4.0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: const BorderSide(
                                        color: Colors.grey, width: 1.0),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(5.5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 🔹 Primera línea: matricula + marca + modelo a la izquierda
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 1.5),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.directions_car,
                                                size: 16.0,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8.0),
                                              Flexible(
                                                child: Text(
                                                  '$matricula  $marca $modelo',
                                                  style: const TextStyle(
                                                    fontSize: 15.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Segunda línea: acción e icono
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 1.5),
                                          child: Row(
                                            children: [
                                              Icon(
                                                actionIcon,
                                                size: 16.0,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(
                                                  actionText,
                                                  style: TextStyle(
                                                    fontSize: 15.0,
                                                    color: actividad['campo'] ==
                                                            'estado_coche'
                                                        ? estadoColor
                                                        : Colors.black,
                                                    fontWeight: isBoldAction
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Tercera línea: usuario + fecha
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 6),
                                          child: Text(
                                            '$userName - $formattedFecha',
                                            style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
