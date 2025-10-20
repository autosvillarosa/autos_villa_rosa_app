import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<Uint8List> generateFacturaPdf({
  required String marca,
  required String matricula,
  required String nombre,
  required String dni,
  required String numeroFactura,
  required String numeroCliente,
  required int montoFacturar,
  required String tipoIva,
  required String direccion,
  required String cp,
  required String provincia,
  required String ciudad,
  required String modelo,
  required String transmision,
  required String fechaMatriculacion,
  required int km,
  required String bastidor,
}) async {
  await initializeDateFormatting('es_ES', null);

  final pdf = pw.Document();

  // Cargar la fuente LiberationSans con fallback a Times
  pw.Font font;
  pw.Font boldFont;
  try {
    final fontData =
        await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf');
    if (fontData.lengthInBytes == 0) {
      throw Exception('La fuente LiberationSans-Regular.ttf está vacía');
    }
    font = pw.Font.ttf(fontData);
    final boldFontData =
        await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf');
    boldFont = pw.Font.ttf(boldFontData);
  } catch (e) {
    if (kDebugMode) {
      print(
          'Error cargando fuentes LiberationSans: $e. Usando Times como fallback.');
    }
    font = pw.Font.times();
    boldFont = pw.Font.timesBold();
  }

  final companyName = 'Avenida Alcorta SL';
  final companyNif = 'B93299725';
  final companyAddress = 'Avenida Brisa del Mar, 4 – Casa 33';
  final companyCp = '29790';
  final companyLocality = 'Chilches Costa';
  final companyCity = 'Málaga';
  final companyPhone = '952550663';

  // Formatear fecha_matriculacion a DD/MM/YYYY
  String formattedFechaMatriculacion;
  try {
    final date = DateTime.parse(fechaMatriculacion);
    formattedFechaMatriculacion = DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    formattedFechaMatriculacion =
        fechaMatriculacion; // Usar tal cual si no se puede parsear
  }

  // Usar Unicode \u20AC como fallback si € no se renderiza
  String euroSymbol = '€';
  try {
    final testPdf = pw.Document();
    testPdf.addPage(pw.Page(
        build: (pw.Context context) =>
            pw.Text('€', style: pw.TextStyle(font: font))));
    await testPdf.save();
  } catch (e) {
    euroSymbol = '\u20AC';
    if (kDebugMode) {
      print(
          'El símbolo € no se renderiza, usando \u20AC como fallback. Error: $e');
    }
  }

  // Capitalizar la primera letra de provincia y ciudad
  String capitalizedProvincia = provincia.isNotEmpty
      ? '${provincia[0].toUpperCase()}${provincia.substring(1).toLowerCase()}'
      : provincia;
  String capitalizedCiudad = ciudad.isNotEmpty
      ? '${ciudad[0].toUpperCase()}${ciudad.substring(1).toLowerCase()}'
      : ciudad;

  // Convertir puntos a comas en los montos decimales
  String formatWithComma(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  // Reformatear la descripción en dos líneas
  String descriptionLine1 = 'Venta de $marca $modelo';
  String descriptionLine2 =
      'matriculado el $formattedFechaMatriculacion, kilómetros actuales: $km';

  // Estilo de texto común
  final regularTextStyle = pw.TextStyle(fontSize: 11, font: font);
  final boldTextStyle = pw.TextStyle(
      fontSize: 13, fontWeight: pw.FontWeight.bold, font: boldFont);

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

  // Función para agregar páginas con pie de página
  void addPage(pw.Document pdf, pw.Widget content) {
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (pw.Context context) => pw.Stack(
          children: [
            content,
            pw.Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: pw.Align(
                alignment: pw.Alignment.bottomCenter,
                child: pw.Text(
                  'Página ${context.pageNumber}/${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Encabezado con datos de la empresa y factura
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              companyName,
              style: boldTextStyle,
            ),
            pw.Text(
              'Nº Factura: ${numeroFactura.padLeft(5)}',
              style: boldTextStyle,
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'NIF: $companyNif',
              style: regularTextStyle,
            ),
            pw.Text(
              'Nº Cliente: ${numeroCliente.padLeft(5)}',
              style: boldTextStyle,
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dirección: $companyAddress',
              style: regularTextStyle,
            ),
            pw.Text(
              'Fecha: ${DateTime.now().toLocal().toString().split(' ')[0].split('-').reversed.join('/')}',
              style: regularTextStyle,
            ),
          ],
        ),
        pw.Text(
          'Código Postal: $companyCp',
          style: regularTextStyle,
        ),
        pw.Text(
          'Localidad: $companyLocality',
          style: regularTextStyle,
        ),
        pw.Text(
          'Ciudad: $companyCity',
          style: regularTextStyle,
        ),
        pw.Text(
          'Teléfono: $companyPhone',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        // Datos del cliente
        pw.Text(
          'Datos del Cliente:',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Nombre: $nombre',
          style: regularTextStyle,
        ),
        pw.Text(
          'DNI/NIF: $dni',
          style: regularTextStyle,
        ),
        pw.Text(
          'Dirección: $direccion',
          style: regularTextStyle,
        ),
        pw.Text(
          'Código Postal: $cp',
          style: regularTextStyle,
        ),
        pw.Text(
          'Ciudad: $capitalizedCiudad',
          style: regularTextStyle,
        ),
        pw.Text(
          'Provincia: $capitalizedProvincia',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        // Detalles de la venta
        pw.Text(
          'Detalles de la Venta:',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Descripción', 'Precio ($euroSymbol)'],
          data: [
            [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(descriptionLine1, style: regularTextStyle),
                  pw.Text(descriptionLine2, style: regularTextStyle),
                ],
              ),
              '$montoFacturar $euroSymbol',
            ],
          ],
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
          },
          cellStyle: pw.TextStyle(fontSize: 11, font: font),
        ),
        pw.SizedBox(height: 10),
        // Cálculo de IVA
        if (tipoIva == 'General') ...[
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Base Imponible: $montoFacturar $euroSymbol',
                  style: regularTextStyle,
                ),
                pw.Text(
                  'IVA (21%): ${formatWithComma(montoFacturar * 0.21)} $euroSymbol',
                  style: regularTextStyle,
                ),
                pw.Text(
                  'Total: ${formatWithComma(montoFacturar * 1.21)} $euroSymbol',
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: boldFont,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Total: $montoFacturar $euroSymbol',
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: boldFont,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Régimen Especial de Bienes Usados (REBU)',
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
              ],
            ),
          ),
        ],
        pw.SizedBox(height: 10),
        // Sección de comentarios
        pw.Text(
          'Comentarios:',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Matrícula del coche: $matricula',
          style: regularTextStyle,
        ),
        pw.Text(
          'Nº de bastidor: $bastidor',
          style: regularTextStyle,
        ),
      ],
    ),
  );

  return pdf.save();
}
