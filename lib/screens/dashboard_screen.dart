import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  Map<String, List<dynamic>> _groups = {};
  List<int> _counts = [0, 0, 0, 0];
  final List<String> _intervals = [
    '0-7 días',
    '8-14 días',
    '15-21 días',
    '22+ días'
  ];
  String? _selectedGroup;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('coches')
          .select(
              'uuid, matricula, marca, modelo, ubicacion, ubicacion_update, estado_coche')
          .not('ubicacion_update', 'is', null)
          .inFilter('estado_coche', ['Disponible', 'Reservado']);

      if (mounted) {
        final now = DateTime.now();
        final Map<String, List<dynamic>> groups = {
          _intervals[0]: [],
          _intervals[1]: [],
          _intervals[2]: [],
          _intervals[3]: [],
        };

        for (var coche in response) {
          final updateStr = coche['ubicacion_update'];
          if (updateStr == null) continue;
          final update = DateTime.parse(updateStr).toLocal();
          final days = now.difference(update).inDays;

          String key;
          if (days <= 7) {
            key = _intervals[0];
          } else if (days <= 14) {
            key = _intervals[1];
          } else if (days <= 21) {
            key = _intervals[2];
          } else {
            key = _intervals[3];
          }
          groups[key]!.add(coche);
        }

        setState(() {
          _groups = groups;
          _counts = _intervals.map((i) => _groups[i]!.length).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    // Calcular maxY como el siguiente múltiplo de 20 del conteo máximo
    final maxCount =
        _counts.isNotEmpty ? _counts.reduce((a, b) => a > b ? a : b) : 0;
    final maxY = ((maxCount / 20).ceil() * 20).toDouble();

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
                      icon: const Icon(Icons.arrow_back,
                          size: 19.2, color: Colors.white),
                      tooltip: 'Volver',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Dashboard',
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
                  ), // Espacio vacío para simetría
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFE6F0FA),
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            // Título "Inventario"
                            const Padding(
                              padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                              child: Text(
                                'Inventario',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0053A0),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Parte superior: Gráfico de barras (40%)
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxY,
                                    barTouchData: BarTouchData(
                                      enabled: false,
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 60,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index < _intervals.length) {
                                              final isSelected =
                                                  _selectedGroup ==
                                                      _intervals[index];
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedGroup =
                                                          isSelected
                                                              ? null
                                                              : _intervals[
                                                                  index];
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 70,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4.0,
                                                        vertical: 4.0),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFF0053A0)
                                                          : Colors
                                                              .grey.shade300,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.0),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _intervals[index],
                                                          style: TextStyle(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        Text(
                                                          _counts[index]
                                                              .toString(),
                                                          style: TextStyle(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          interval: 20,
                                          getTitlesWidget: (value, meta) {
                                            if (value % 20 == 0) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: List.generate(
                                      4,
                                      (index) => BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: _counts[index].toDouble(),
                                            color: index == 0
                                                ? Colors.green
                                                : index == 1
                                                    ? const Color(0xFFFFB300)
                                                    : index == 2
                                                        ? Colors.orange
                                                        : Colors.red,
                                            width: 25,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 20,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.shade300,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Parte inferior: Lista de coches del intervalo seleccionado (60%)
                            Expanded(
                              flex: 6,
                              child: _selectedGroup == null
                                  ? const Center(
                                      child: Text(
                                        'Selecciona una barra para ver detalles',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount:
                                          _groups[_selectedGroup]!.length,
                                      itemBuilder: (context, index) {
                                        // Sort cars by ubicacion_update (most recent to oldest)
                                        final sortedCoches = _groups[
                                            _selectedGroup]!
                                          ..sort((a, b) {
                                            final aUpdate = a[
                                                        'ubicacion_update'] !=
                                                    null
                                                ? DateTime.parse(
                                                        a['ubicacion_update'])
                                                    .toLocal()
                                                : DateTime(0);
                                            final bUpdate = b[
                                                        'ubicacion_update'] !=
                                                    null
                                                ? DateTime.parse(
                                                        b['ubicacion_update'])
                                                    .toLocal()
                                                : DateTime(0);
                                            return bUpdate.compareTo(aUpdate);
                                          });
                                        final coche = sortedCoches[index];
                                        final updateStr =
                                            coche['ubicacion_update'];
                                        final formattedUpdate = updateStr !=
                                                null
                                            ? DateFormat('dd/MM/yyyy HH:mm')
                                                .format(
                                                    DateTime.parse(updateStr)
                                                        .toLocal())
                                            : 'N/A';
                                        final carInfo =
                                            '${coche['matricula'] ?? 'N/A'} ${coche['marca'] ?? 'N/A'} ${coche['modelo'] ?? 'N/A'}';
                                        final locationInfo =
                                            '${coche['ubicacion'] ?? 'N/A'} $formattedUpdate';

                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 3.0),
                                          elevation: 2.0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            side: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  carInfo,
                                                  style: const TextStyle(
                                                    fontSize: 15.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  locationInfo,
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
}
