import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../form/add_car_form.dart';
import '../button/pdf_edit_button.dart';
import '../button/ubicacion_edit_button.dart';
import '../button/checklist_edit_button.dart';
import 'chat_screen.dart';
import 'filtros_adicionales_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CochesScreen extends StatefulWidget {
  const CochesScreen({super.key});

  @override
  CochesScreenState createState() => CochesScreenState();
}

class CochesScreenState extends State<CochesScreen> {
  List<dynamic> _coches = [];
  List<dynamic> _filteredCoches = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;
  String? _selectedEstadoDocumentos;
  String? _selectedEstadoPublicacion;
  String? _selectedDiagnostico;
  String? _selectedEstadoItv;
  Set<String> _selectedUbicacion = {};
  bool _isLoading = false;
  Timer? _debounce;
  List<String> _allUbicaciones = [];

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
    _fetchCoches();
    _fetchUbicaciones();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterCoches();
    });
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

      log('Ubicaciones únicas cargadas en CochesScreen: $_allUbicaciones');
    } catch (e) {
      log('Error al obtener ubicaciones: $e');
      setState(() => _allUbicaciones = []);
    }
  }

  Future<void> _fetchCoches() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.from('coches').select(
          'uuid, matricula, marca, modelo, estado_coche, fecha_creacion, fecha_llegada, fecha_reserva, fecha_venta, fecha_itv, fecha_matriculacion, precio, km, ubicacion, ubicacion_update, imagen_url, diagnostico, estado_documentos, estado_publicacion');
      if (mounted) {
        final coches = response.map((coche) {
          String formattedFechaItv = 'ITV N/A';
          String itvValue = 'N/A';
          if (coche['fecha_itv'] != null) {
            try {
              final date = DateTime.parse(coche['fecha_itv'].toString());
              itvValue = DateFormat('dd/MM/yy').format(date);
              formattedFechaItv = 'ITV $itvValue';
            } catch (e) {
              itvValue = coche['fecha_itv'].toString();
              formattedFechaItv = 'ITV $itvValue';
            }
          }

          String ubicacionDisplay = coche['ubicacion'] ?? 'N/A';
          if (coche['ubicacion_update'] != null) {
            try {
              final updateDate =
                  DateTime.parse(coche['ubicacion_update']).toLocal();
              final formattedUpdate = DateFormat('dd-MMM HH:mm')
                  .format(updateDate)
                  .replaceAll('Jan', 'jan')
                  .replaceAll('Feb', 'feb')
                  .replaceAll('Mar', 'mar')
                  .replaceAll('Apr', 'apr')
                  .replaceAll('May', 'may')
                  .replaceAll('Jun', 'jun')
                  .replaceAll('Jul', 'jul')
                  .replaceAll('Aug', 'aug')
                  .replaceAll('Sep', 'sep')
                  .replaceAll('Oct', 'oct')
                  .replaceAll('Nov', 'nov')
                  .replaceAll('Dec', 'dec');
              ubicacionDisplay = '$ubicacionDisplay $formattedUpdate';
            } catch (e) {
              ubicacionDisplay =
                  '$ubicacionDisplay ${coche['ubicacion_update']}';
            }
          }

          String formattedKm = 'KM N/A';
          String kmValue = 'N/A';
          if (coche['km'] != null) {
            try {
              final kmFormat = NumberFormat('#,##0', 'es_ES');
              kmValue = kmFormat.format(coche['km']);
              formattedKm = 'KM $kmValue';
            } catch (e) {
              kmValue = coche['km'].toString();
              formattedKm = 'KM $kmValue';
            }
          }

          String formattedFechaMatriculacion = 'N/A';
          if (coche['fecha_matriculacion'] != null) {
            try {
              final date =
                  DateTime.parse(coche['fecha_matriculacion'].toString());
              formattedFechaMatriculacion = DateFormat('yyyy').format(date);
            } catch (e) {
              formattedFechaMatriculacion =
                  coche['fecha_matriculacion'].toString();
            }
          }

          String precioValue = coche['precio']?.toString() ?? 'N/A';
          String formattedPrecio = '€ $precioValue';

          DateTime? parseDate(String? date) {
            if (date == null) return null;
            try {
              return DateTime.parse(date);
            } catch (e) {
              return null;
            }
          }

          return {
            ...coche,
            'formattedFechaItv': formattedFechaItv,
            'itvValue': itvValue,
            'ubicacionDisplay': ubicacionDisplay,
            'formattedKm': formattedKm,
            'kmValue': kmValue,
            'formattedFechaMatriculacion': formattedFechaMatriculacion,
            'formattedPrecio': formattedPrecio,
            'parsed_fecha_creacion': parseDate(coche['fecha_creacion']),
            'parsed_fecha_llegada': parseDate(coche['fecha_llegada']),
            'parsed_fecha_reserva': parseDate(coche['fecha_reserva']),
            'parsed_fecha_venta': parseDate(coche['fecha_venta']),
            'parsed_fecha_itv': parseDate(coche['fecha_itv']),
          };
        }).toList();

        setState(() {
          _coches = coches;
          _filterCoches();
          _isLoading = false;
        });

        for (var i = 0; i < coches.length && i < 5; i++) {
          if (coches[i]['imagen_url'] != null) {
            precacheImage(
              CachedNetworkImageProvider(coches[i]['imagen_url']),
              context,
              onError: (e, stackTrace) {
                log('Error precargando imagen ${coches[i]['imagen_url']}: $e');
              },
            );
          }
        }

        for (var i = 0; i < coches.length; i++) {
          log('Coche[$i]:');
          log('  matricula: ${coches[i]['matricula']}');
          log('  estado_coche: ${coches[i]['estado_coche']}');
          log('  fecha_creacion: ${coches[i]['fecha_creacion']}');
          log('  fecha_llegada: ${coches[i]['fecha_llegada']}');
          log('  fecha_reserva: ${coches[i]['fecha_reserva']}');
          log('  fecha_venta: ${coches[i]['fecha_venta']}');
          log('  fecha_itv: ${coches[i]['fecha_itv']}');
          log('  precio: ${coches[i]['precio']}');
          log('  km: ${coches[i]['km']}');
          log('  formattedFechaItv: ${coches[i]['formattedFechaItv']}');
          log('  formattedKm: ${coches[i]['formattedKm']}');
          log('  formattedPrecio: ${coches[i]['formattedPrecio']}');
          log('  estado_documentos: ${coches[i]['estado_documentos']}');
          log('  estado_publicacion: ${coches[i]['estado_publicacion']}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar coches: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _filterCoches() {
    final query = _searchController.text.toLowerCase();
    final nonPredefined =
        _allUbicaciones.where((u) => !predefinedLocations.contains(u)).toSet();
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final newFilteredCoches = _coches.where((coche) {
      final matricula = coche['matricula']?.toLowerCase() ?? '';
      final marca = coche['marca']?.toLowerCase() ?? '';
      final modelo = coche['modelo']?.toLowerCase() ?? '';
      final estado = coche['estado_coche']?.toLowerCase() ?? '';
      final estadoDocumentos = coche['estado_documentos']?.toLowerCase() ?? '';
      final estadoPublicacion =
          coche['estado_publicacion']?.toLowerCase() ?? '';
      final diagnostico = coche['diagnostico']?.toLowerCase() ?? '';
      final ubicacion = coche['ubicacion']?.toLowerCase() ?? '';
      final fechaItv = coche['parsed_fecha_itv'] as DateTime?;

      final matchesSearch = matricula.contains(query) ||
          marca.contains(query) ||
          modelo.contains(query);
      final matchesEstadoFilter =
          _selectedFilter == null || estado == _selectedFilter!.toLowerCase();
      final matchesEstadoDocumentos = _selectedEstadoDocumentos == null ||
          estadoDocumentos == _selectedEstadoDocumentos!.toLowerCase();
      final matchesEstadoPublicacion = _selectedEstadoPublicacion == null ||
          estadoPublicacion == _selectedEstadoPublicacion!.toLowerCase();
      final matchesDiagnostico = _selectedDiagnostico == null ||
          diagnostico == _selectedDiagnostico!.toLowerCase();
      final matchesUbicacion = _selectedUbicacion.isEmpty ||
          (_selectedUbicacion.contains('OTROS')
              ? (nonPredefined.contains(ubicacion.toUpperCase()) ||
                  _selectedUbicacion
                      .map((e) => e.toLowerCase())
                      .contains(ubicacion))
              : _selectedUbicacion
                  .map((e) => e.toLowerCase())
                  .contains(ubicacion));
      final matchesEstadoItv = _selectedEstadoItv == null ||
          (fechaItv != null &&
              (_selectedEstadoItv == 'VENCIDA'
                  ? fechaItv.isBefore(todayMidnight) ||
                      fechaItv.isAtSameMomentAs(todayMidnight)
                  : fechaItv.isAfter(todayMidnight)));

      return matchesSearch &&
          matchesEstadoFilter &&
          matchesEstadoDocumentos &&
          matchesEstadoPublicacion &&
          matchesDiagnostico &&
          matchesUbicacion &&
          matchesEstadoItv;
    }).toList();

    newFilteredCoches.sort((a, b) {
      if (_selectedFilter == null) {
        final dateA = a['parsed_fecha_creacion'] as DateTime?;
        final dateB = b['parsed_fecha_creacion'] as DateTime?;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      } else {
        switch (_selectedFilter!.toLowerCase()) {
          case 'por llegar':
            final dateA = a['parsed_fecha_creacion'] as DateTime?;
            final dateB = b['parsed_fecha_creacion'] as DateTime?;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          case 'disponible':
            final dateA = a['parsed_fecha_llegada'] as DateTime?;
            final dateB = b['parsed_fecha_llegada'] as DateTime?;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          case 'reservado':
            final dateA = a['parsed_fecha_reserva'] as DateTime?;
            final dateB = b['parsed_fecha_reserva'] as DateTime?;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          case 'vendido':
            final dateA = a['parsed_fecha_venta'] as DateTime?;
            final dateB = b['parsed_fecha_venta'] as DateTime?;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          default:
            return 0;
        }
      }
    });

    if (_filteredCoches != newFilteredCoches) {
      setState(() {
        _filteredCoches = newFilteredCoches;
      });
    }
  }

  Future<void> _refreshWithoutScrollLoss() async {
    final double currentOffset = _scrollController.offset;
    await _fetchCoches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(currentOffset);
      }
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desiredCardWidth = 250.0;
    int crossAxisCount = (screenWidth / desiredCardWidth).floor();
    return crossAxisCount.clamp(3, 6);
  }

  Widget _buildCarCard(BuildContext context, int index) {
    final coche = _filteredCoches[index];

    Color estadoColor;
    switch (coche['estado_coche']?.toLowerCase()) {
      case 'por llegar':
        estadoColor = Color(0xFF0053A0);
        break;
      case 'disponible':
        estadoColor = Colors.green.shade600;
        break;
      case 'reservado':
        estadoColor = Colors.orange.shade600;
        break;
      case 'vendido':
        estadoColor = Colors.red.shade600;
        break;
      default:
        estadoColor = Colors.black;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              cocheUuid: coche['uuid'],
              marca: coche['marca'] ?? 'N/A',
              matricula: coche['matricula'] ?? 'N/A',
              modelo: coche['modelo'] ?? 'N/A',
            ),
          ),
        ).then((_) => _refreshWithoutScrollLoss());
      },
      child: Card(
        margin: EdgeInsets.fromLTRB(
          4.0,
          index == 0 ? 0.0 : 2.0,
          4.0,
          2.0,
        ),
        elevation: 4.0,
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          side: BorderSide(color: Colors.grey, width: 1.0),
        ),
        child: kIsWeb
            ? Container(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: coche['imagen_url'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: coche['imagen_url'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Icon(
                                        Icons.car_rental,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.car_rental,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                            ),
                            Positioned(
                              top: 4.0,
                              left: 4.0,
                              right: 4.0,
                              child: Text(
                                coche['matricula'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Positioned(
                              bottom: 4.0,
                              left: 4.0,
                              right: 4.0,
                              child: Text(
                                coche['estado_coche'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: estadoColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRowBold(coche['marca'] ?? 'N/A'),
                          _buildInfoRow(coche['modelo'] ?? 'N/A'),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14.0, color: Colors.grey),
                                    const SizedBox(width: 4.0),
                                    Expanded(
                                      child: _buildInfoRow(
                                          coche['formattedFechaMatriculacion']),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: _buildInfoRowRich(
                                  textSpans: [
                                    TextSpan(
                                      text: 'ITV ',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: coche['itvValue'],
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildInfoRowRich(
                                  textSpans: [
                                    TextSpan(
                                      text: '€ ',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          coche['precio']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: _buildInfoRowRich(
                                  textSpans: [
                                    TextSpan(
                                      text: 'KM ',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: coche['kmValue'],
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14.0, color: Colors.grey),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: _buildInfoRow(coche['ubicacionDisplay']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRoundButton(
                            context,
                            Icons.picture_as_pdf,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfEditButton(
                                  cocheUuid: coche['uuid'],
                                  cocheData: coche,
                                ),
                              ),
                            ).then((_) => _refreshWithoutScrollLoss()),
                          ),
                          const SizedBox(width: 4.0),
                          _buildRoundButton(
                            context,
                            Icons.location_on,
                            () => showDialog(
                              context: context,
                              builder: (context) => UbicacionEditButton(
                                cocheUuid: coche['uuid'],
                                currentUbicacion: coche['ubicacion'],
                              ),
                            ).then((_) => _refreshWithoutScrollLoss()),
                          ),
                          const SizedBox(width: 4.0),
                          _buildRoundButton(
                            context,
                            Icons.checklist,
                            () => showDialog(
                              context: context,
                              builder: (context) => ChecklistEditButton(
                                cocheUuid: coche['uuid'],
                                currentDiagnostico: coche['diagnostico'],
                                currentFechaItv: coche['fecha_itv'],
                              ),
                            ).then((_) => _refreshWithoutScrollLoss()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                height: 154.0,
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        width: 130.0,
                        height: 146.0,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: AspectRatio(
                                aspectRatio: 1 / 1,
                                child: coche['imagen_url'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: coche['imagen_url'],
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Icon(
                                          Icons.car_rental,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.car_rental,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 4.0,
                              left: 4.0,
                              right: 4.0,
                              child: Text(
                                coche['matricula'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Positioned(
                              bottom: 4.0,
                              left: 4.0,
                              right: 4.0,
                              child: Text(
                                coche['estado_coche'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: estadoColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRowBold(coche['marca'] ?? 'N/A'),
                          _buildInfoRow(coche['modelo'] ?? 'N/A'),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14.0, color: Colors.grey),
                                    const SizedBox(width: 4.0),
                                    Expanded(
                                      child: _buildInfoRow(
                                          coche['formattedFechaMatriculacion']),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: _buildInfoRowRich(
                                  textSpans: [
                                    TextSpan(
                                      text: 'ITV ',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: coche['itvValue'],
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildInfoRowRich(
                                  textSpans: [
                                    TextSpan(
                                      text: '€ ',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          coche['precio']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: _buildInfoRowRich(
                                  textSpans: [
                                    TextSpan(
                                      text: 'KM ',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: coche['kmValue'],
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14.0, color: Colors.grey),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: _buildInfoRow(coche['ubicacionDisplay']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRoundButton(
                          context,
                          Icons.picture_as_pdf,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfEditButton(
                                cocheUuid: coche['uuid'],
                                cocheData: coche,
                              ),
                            ),
                          ).then((_) => _refreshWithoutScrollLoss()),
                        ),
                        const SizedBox(height: 1.0),
                        _buildRoundButton(
                          context,
                          Icons.location_on,
                          () => showDialog(
                            context: context,
                            builder: (context) => UbicacionEditButton(
                              cocheUuid: coche['uuid'],
                              currentUbicacion: coche['ubicacion'],
                            ),
                          ).then((_) => _refreshWithoutScrollLoss()),
                        ),
                        const SizedBox(height: 1.0),
                        _buildRoundButton(
                          context,
                          Icons.checklist,
                          () => showDialog(
                            context: context,
                            builder: (context) => ChecklistEditButton(
                              cocheUuid: coche['uuid'],
                              currentDiagnostico: coche['diagnostico'],
                              currentFechaItv: coche['fecha_itv'],
                            ),
                          ).then((_) => _refreshWithoutScrollLoss()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).primaryColor,
              child: Row(
                children: [
                  SizedBox(
                    width: 35.2,
                    height: 35.2,
                    child: IconButton(
                      icon: const Icon(Icons.add,
                          size: 19.2, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddCarForm()),
                        ).then((_) => _refreshWithoutScrollLoss());
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      height: 37.0,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar por marca, modelo o matrícula',
                          hintStyle: TextStyle(fontSize: 13.0),
                          prefixIcon: Icon(Icons.search, size: 20.0),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide:
                                BorderSide(color: Colors.white, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide:
                                BorderSide(color: Colors.white, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                                color: Color(0xFF0053A0), width: 2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    width: 35.2,
                    height: 35.2,
                    child: IconButton(
                      icon: const Icon(Icons.filter_list,
                          size: 19.2, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FiltrosAdicionalesScreen(
                              initialEstadoDocumentos:
                                  _selectedEstadoDocumentos,
                              initialEstadoPublicacion:
                                  _selectedEstadoPublicacion,
                              initialDiagnostico: _selectedDiagnostico,
                              initialEstadoItv: _selectedEstadoItv,
                              initialUbicacion: _selectedUbicacion.isNotEmpty
                                  ? _selectedUbicacion
                                  : null,
                            ),
                          ),
                        ).then((result) {
                          if (result != null) {
                            setState(() {
                              _selectedEstadoDocumentos =
                                  result['estado_documentos'];
                              _selectedEstadoPublicacion =
                                  result['estado_publicacion'];
                              _selectedDiagnostico = result['diagnostico'];
                              _selectedEstadoItv = result['estado_itv'];
                              final ubicacionStr =
                                  result['ubicacion'] as String?;
                              _selectedUbicacion = (ubicacionStr != null &&
                                      ubicacionStr.isNotEmpty)
                                  ? ubicacionStr.split(',').toSet()
                                  : {};
                              _filterCoches();
                            });
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Theme.of(context).canvasColor,
              padding:
                  const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
              child: Row(
                children: [
                  Expanded(child: _buildFilterButton('POR LLEGAR')),
                  const SizedBox(width: 2.0),
                  Expanded(child: _buildFilterButton('DISPONIBLE')),
                  const SizedBox(width: 2.0),
                  Expanded(child: _buildFilterButton('RESERVADO')),
                  const SizedBox(width: 2.0),
                  Expanded(child: _buildFilterButton('VENDIDO')),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).canvasColor,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCoches.isEmpty
                        ? const Center(child: Text('No hay coches disponibles'))
                        : kIsWeb
                            ? GridView.builder(
                                controller: _scrollController,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      _calculateCrossAxisCount(context),
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                ),
                                itemCount: _filteredCoches.length,
                                itemBuilder: (context, index) {
                                  return _buildCarCard(context, index);
                                },
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                cacheExtent: 1000.0,
                                itemCount: _filteredCoches.length,
                                itemBuilder: (context, index) {
                                  return _buildCarCard(context, index);
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        value,
        style: const TextStyle(fontSize: 14.0),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildInfoRowBold(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        value,
        style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildInfoRowRich({required List<TextSpan> textSpans}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(children: textSpans),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRoundButton(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF0053A0), width: 1.0),
        ),
        padding: const EdgeInsets.all(8.0),
        minimumSize: const Size(38.0, 38.0),
        backgroundColor: const Color(0xFF1A6BB8),
      ),
      child: Icon(icon, size: 18.0, color: Colors.white),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _selectedFilter == label;
    return SizedBox(
      height: 30.0,
      child: ChoiceChip(
        label: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : null;
            _filterCoches();
          });
        },
        backgroundColor:
            isSelected ? const Color(0xFF0053A0) : Colors.grey.shade200,
        selectedColor: const Color(0xFF0053A0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0053A0) : Colors.grey.shade400,
            width: 1.0,
          ),
        ),
        showCheckmark: false,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      ),
    );
  }
}
