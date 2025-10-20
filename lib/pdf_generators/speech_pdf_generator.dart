import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

Future<Uint8List> generateSpeechPdf(
    String marca,
    String modelo,
    String precio,
    String fechaItv,
    String matricula,
    String fechaMatriculacion,
    String km,
    String bastidor,
    String tipoCombustible,
    String cc,
    String cv,
    String transmision,
    {List<String> caracteristicasAdicionales = const []}) async {
  final pdf = pw.Document();

  // Cargar la fuente LiberationSans con fallback a Times
  pw.Font font;
  try {
    final fontData =
        await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf');
    if (fontData.lengthInBytes == 0) {
      throw Exception('La fuente LiberationSans-Regular.ttf está vacía');
    }
    font = pw.Font.ttf(fontData);
  } catch (e) {
    font = pw.Font.times(); // Fallback a fuente por defecto
  }

  // Verificar si el símbolo del euro se renderiza correctamente
  String euroSymbol = '€';
  try {
    final testPdf = pw.Document();
    testPdf.addPage(pw.Page(
        build: (pw.Context context) =>
            pw.Text('€', style: pw.TextStyle(font: font))));
    await testPdf.save();
  } catch (e) {
    euroSymbol = '\u20AC';
  }

  String formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    final monthNames = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    try {
      final date = DateTime.parse(dateStr); // Intenta parsear directamente
      return 'del ${date.day} de ${monthNames[date.month - 1]} del ${date.year}';
    } catch (e) {
      // Si falla, intenta con formato dd/MM/yyyy
      try {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month =
              int.parse(parts[1]) - 1; // Ajuste para índice de monthNames
          final year = int.parse(parts[2]);
          return 'del $day de ${monthNames[month]} del $year';
        }
      } catch (e) {
        return dateStr; // Devuelve el original si todo falla
      }
      return dateStr;
    }
  }

  final formattedFechaMatriculacion = formatDate(fechaMatriculacion);

  // Formatear fechaItv a DD/MM/YYYY si es válida
  String formattedFechaItv = '';
  bool isItvValid = false;
  final currentDate =
      DateTime(2025, 10, 1); // Fecha actual: 1 de octubre de 2025
  try {
    final itvDate = DateTime.parse(fechaItv);
    if (itvDate.isAfter(currentDate)) {
      isItvValid = true;
      formattedFechaItv = DateFormat('dd/MM/yyyy').format(itvDate);
    }
  } catch (e) {
    try {
      final parts = fechaItv.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final itvDate = DateTime(year, month, day);
        if (itvDate.isAfter(currentDate)) {
          isItvValid = true;
          formattedFechaItv = '$day/${month.toString().padLeft(2, '0')}/$year';
        }
      }
    } catch (e) {
      isItvValid = false; // Si no se puede parsear, no se muestra
    }
  }

  // Une las características adicionales en una cadena separada por comas
  String caracteristicasStr = caracteristicasAdicionales.isNotEmpty
      ? '${caracteristicasAdicionales.join(', ')}, '
      : '';

  // Verificar condiciones para mostrar "financiable"
  bool esFinanciable = false;
  try {
    // Extraer el año de fechaMatriculacion
    int? year;
    if (fechaMatriculacion.isNotEmpty) {
      try {
        year = DateTime.parse(fechaMatriculacion).year;
      } catch (e) {
        final parts = fechaMatriculacion.split('/');
        if (parts.length == 3) {
          year = int.parse(parts[2]);
        }
      }
    }
    // Convertir km a número
    final kmValue =
        double.tryParse(km.replaceAll(',', '').replaceAll('.', '')) ??
            double.infinity;

    // Verificar si cumple las condiciones: año >= 2010 (antigüedad < 15 años desde 2025) y km < 300,000
    final currentYear = 2025;
    esFinanciable =
        (year != null && year >= currentYear - 15) && kmValue < 300000;
  } catch (e) {
    esFinanciable = false; // Si hay algún error, no se muestra "financiable"
  }

  // Construir el texto del precio con o sin "financiable"
  final precioText = esFinanciable
      ? '$marca $modelo. $precio $euroSymbol financiable'
      : '$marca $modelo. $precio $euroSymbol';

  // Construir el texto del estado general con o sin fecha ITV
  final estadoText = isItvValid
      ? 'Muy buen estado general. Fecha ITV $formattedFechaItv.'
      : 'Muy buen estado general.';

  // Combinar precioText y estadoText en un solo párrafo
  final primerParrafo =
      '$precioText\n$estadoText\nMatricula: $matricula, $formattedFechaMatriculacion, $km km.\nN° bastidor: $bastidor.';

  // Configuración de página A4 con márgenes y borde
  final pageTheme = pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.only(
      top: 25 * PdfPageFormat.mm, // 2,5 cm superior
      bottom: 25 * PdfPageFormat.mm, // 2,5 cm inferior
      left: 30 * PdfPageFormat.mm, // 3 cm izquierdo
      right: 30 * PdfPageFormat.mm, // 3 cm derecho
    ),
    buildBackground: (pw.Context context) => pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.black,
          width: 1,
        ),
      ),
      margin: pw.EdgeInsets.all(
          -10 * PdfPageFormat.mm), // 1 cm más grande en todas las direcciones
    ),
  );

  pdf.addPage(
    pw.Page(
      pageTheme: pageTheme,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Paragraph(
            text: primerParrafo,
            style: pw.TextStyle(fontSize: 12, font: font),
          ),
          pw.Paragraph(
            text:
                'Motor $tipoCombustible de $cc CC, $cv CV. Cambio $transmision, $caracteristicasStr'
                'retrovisores y elevalunas eléctricos, ABS, ESP, etc.',
            style: pw.TextStyle(fontSize: 12, font: font),
          ),
          pw.Paragraph(
            text:
                'IMPRESCINDIBLE CITA PREVIA. Atendemos de lunes a viernes de 9:30 a 20:00 hrs, sábados de 10:00 a 20:00 hrs, y domingos de 10:00 a 14:00 hrs, en Málaga Capital, próximo a Leroy Merlín, únicamente con visita concertada. Precio de contado con un año de garantía y transferencia incluida. Puedes reservar y pagar con tarjeta de crédito. We speak English. Send us a message and we will call in your language. Este anuncio no es vinculante, puede contener errores, se muestra a título informativo y no contractual.\n\nVer más coches en venta visitando www.autosvillarosa.com gran variedad de vehículos a excelentes precios en Málaga. Contacto: 645349995 - 635314627',
            style: pw.TextStyle(fontSize: 12, font: font),
          ),
        ],
      ),
    ),
  );

  return await pdf.save();
}
