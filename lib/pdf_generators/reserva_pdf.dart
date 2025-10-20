import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<pw.Document> generateReservaPdf({
  required Map<String, dynamic> reservaData,
}) async {
  // Inicializa locales
  await initializeDateFormatting('es_ES', null);

  final pdf = pw.Document();

  // Cargar la fuente LiberationSans-Regular con validación estricta
  pw.Font regularFont;
  try {
    final fontData =
        await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf');
    if (fontData.lengthInBytes == 0) {
      throw Exception(
          'La fuente LiberationSans-Regular.ttf está vacía o no encontrada');
    }
    regularFont = pw.Font.ttf(fontData);
    if (kDebugMode) {
      print('Fuente LiberationSans-Regular.ttf cargada correctamente');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
          'Error cargando fuente LiberationSans-Regular.ttf: $e. Usando Times como fallback.');
    }
    regularFont = pw.Font.times();
  }

  // Cargar la fuente LiberationSans-Bold con validación estricta
  pw.Font boldFont;
  try {
    final boldFontData =
        await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf');
    if (boldFontData.lengthInBytes == 0) {
      throw Exception(
          'La fuente LiberationSans-Bold.ttf está vacía o no encontrada');
    }
    boldFont = pw.Font.ttf(boldFontData);
    if (kDebugMode) {
      print('Fuente LiberationSans-Bold.ttf cargada correctamente');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
          'Error cargando fuente LiberationSans-Bold.ttf: $e. Usando Times Bold como fallback.');
    }
    boldFont = pw.Font.timesBold();
  }

  // Verificar renderizado del símbolo euro
  String euroSymbol = '€';
  try {
    final testPdf = pw.Document();
    testPdf.addPage(pw.Page(
        build: (pw.Context context) =>
            pw.Text('€', style: pw.TextStyle(font: regularFont))));
    await testPdf.save();
  } catch (e) {
    euroSymbol = '\u20AC';
    if (kDebugMode) {
      print(
          'El símbolo € no se renderiza, usando \u20AC como fallback. Error: $e');
    }
  }

  // Unicode para viñeta
  const String bullet = '\u2022';

  // Datos (obligatorios, sin verificaciones de nulos)
  final String nombre = reservaData['nombre'];
  final String dni = reservaData['dni'];
  final String telefono = reservaData['telefono'];
  final String medioPago = reservaData['medio_de_pago'];
  final String marca = reservaData['marca'];
  final String modelo = reservaData['modelo'];
  final String matricula = reservaData['matricula'];

  final int precioFinal = int.parse(reservaData['precio_final'].toString());
  final int abono = int.parse(reservaData['abono'].toString());
  final int saldoPendiente = precioFinal - abono;

  final DateTime fechaReserva = DateTime.parse(reservaData['fecha_reserva']);
  final DateTime fechaVencimiento =
      DateTime(fechaReserva.year, fechaReserva.month + 1, fechaReserva.day);
  final DateFormat fechaFormateada = DateFormat('dd MMMM yyyy', 'es_ES');
  final DateFormat horaFormateada = DateFormat('HH:mm');
  final String fechaReservaTexto = fechaFormateada.format(fechaReserva);
  final String horaReservaTexto = horaFormateada.format(fechaReserva);
  final String fechaVencimientoTexto = fechaFormateada.format(fechaVencimiento);

  // Estilo de texto común
  final regularTextStyle = pw.TextStyle(fontSize: 11, font: regularFont);
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
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construcción PDF
  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'DOCUMENTO DE SEÑAL',
            style: boldTextStyle,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'En Málaga, a las $horaReservaTexto horas del día $fechaReservaTexto.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'DE UNA PARTE',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.Text(
          'AVENIDA ALCORTA, S.L., con domicilio en Av. Brisa del mar, N.º 4, casa 33, 29790 Chilches Costa (Málaga), CIF B93299725, en calidad de VENDEDOR.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'RECIBE',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.Text(
          'De $nombre, con NIF/DNI $dni, teléfono $telefono, en adelante el COMPRADOR, '
          'la cantidad de $abono $euroSymbol en $medioPago, en concepto de reserva y arras penitencial por '
          'la compra del siguiente vehículo:',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '$bullet Marca: $marca',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Modelo: $modelo',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Matrícula: $matricula',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Precio: $precioFinal $euroSymbol',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Saldo pendiente: $saldoPendiente $euroSymbol',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'La entrega por el comprador de la cantidad expresada se realiza por voluntad de ambas partes, en el concepto y función de reserva y señal durante un plazo que finalizará el día $fechaVencimientoTexto, por lo que, dentro del plazo expresado, podrá el comprador desistir libremente y separarse del contrato con pérdida de la cantidad entregada en este acto.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Por su parte, el VENDEDOR no podrá vender el vehículo de referencia a ninguna otra persona, física o jurídica, hasta el vencimiento del presente contrato. Si por alguna razón ajena a la voluntad del VENDEDOR (robo, destrucción, desastre natural, etc.), éste no pudiere entregar el bien reservado, deberá devolver ipso facto al COMPRADOR la cantidad recibida en concepto de reserva y señal.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Para que el desistimiento por parte del COMPRADOR se tenga por válido bastará con que notifique al VENDEDOR en cualquier forma, considerándose también producido tácitamente por el hecho de no concurrir dentro del plazo convenido a finalizar el proceso de compra.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'En tales supuestos de desistimiento, a partir de la indicada fecha el VENDEDOR podrá disponer libremente del vehículo.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'De mutua conformidad se firman dos ejemplares:',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 158),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Text('_______________________', style: regularTextStyle),
                pw.Text('COMPRADOR', style: regularTextStyle),
                pw.Text(nombre, style: regularTextStyle),
                pw.Text(dni, style: regularTextStyle),
              ],
            ),
            pw.Column(
              children: [
                pw.Text('_______________________', style: regularTextStyle),
                pw.Text('VENDEDOR', style: regularTextStyle),
                pw.Text('Avenida Alcorta SL', style: regularTextStyle),
                pw.Text('CIF: B93299725', style: regularTextStyle),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return pdf;
}
