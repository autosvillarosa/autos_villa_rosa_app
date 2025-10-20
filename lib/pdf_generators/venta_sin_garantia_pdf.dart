import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<Uint8List> generateVentaSinGarantiaPdf({
  required String fechaVenta,
  required String nombre,
  required String dni,
  required String direccion,
  required String cp,
  required String ciudad,
  required String provincia,
  required num precio,
  required String marca,
  required String modelo,
  required String matricula,
  required String bastidor,
  required String km,
  required String fechaMatriculacion,
  String? correo = '',
  String? telefono = '',
  String? horaVenta = '00:00',
}) async {
  // Inicializar localización para español
  await initializeDateFormatting('es_ES', null);

  // Depuración de valores recibidos
  if (kDebugMode) {
    print('Valores recibidos - correo: "$correo", telefono: "$telefono"');
  }

  final pdf = pw.Document();

  // Cargar la fuente LiberationSans con fallback a Times
  pw.Font regularFont;
  pw.Font boldFont;
  try {
    final fontData =
        await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf');
    if (fontData.lengthInBytes == 0) {
      throw Exception('La fuente LiberationSans-Regular.ttf está vacía');
    }
    regularFont = pw.Font.ttf(fontData);
    final boldFontData =
        await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf');
    if (boldFontData.lengthInBytes == 0) {
      throw Exception('La fuente LiberationSans-Bold.ttf está vacía');
    }
    boldFont = pw.Font.ttf(boldFontData);
  } catch (e) {
    if (kDebugMode) {
      print(
          'Error cargando fuentes LiberationSans: $e. Usando Times como fallback.');
    }
    regularFont = pw.Font.times();
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

  // Definir constante para viñeta
  const String bullet = '\u2022';

  // Formato para fechas
  final dateTimeVenta = DateTime.parse(fechaVenta);
  final formattedFechaVenta =
      DateFormat('dd MMMM yyyy', 'es_ES').format(dateTimeVenta);
  final formattedFechaMatriculacion =
      DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaMatriculacion));

  // Formato para precio sin decimales ni separador de miles
  final numberFormat = NumberFormat('#', 'es_ES');
  final formattedPrecioFinal = numberFormat.format(precio);

  // Manejo de correo y teléfono
  final formattedCorreo = correo?.isEmpty ?? true ? 'N/A' : correo!;
  final formattedTelefono = telefono?.isEmpty ?? true ? 'N/A' : telefono!;

  // Depuración de valores formateados
  if (kDebugMode) {
    print(
        'Valores formateados - correo: "$formattedCorreo", telefono: "$formattedTelefono"');
  }

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

  // Página 1: Título, lugar y fecha, datos del vendedor, comprador, cláusulas PRIMERO, SEGUNDO, TERCERO, CUARTO y QUINTO
  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Título
        pw.Center(
          child: pw.Text(
            'CONTRATO DE COMPRA VENTA DE VEHÍCULO SIN GARANTÍA',
            style: boldTextStyle,
          ),
        ),
        pw.SizedBox(height: 10),
        // Lugar y fecha
        pw.Text(
          'En Málaga, a las $horaVenta horas del día $formattedFechaVenta.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // Comerciante vendedor
        pw.Text(
          'Comerciante vendedor:',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.Text(
            'AVENIDA ALCORTA SL; CIF: B-93299725; Dirección: Avenida Brisa del Mar 4, casa 33; Población: Chilches Costa; CP: 29790; Provincia: Málaga; Ciudad: Málaga',
            style: regularTextStyle),
        pw.SizedBox(height: 10),

        // Comprador
        pw.Text(
          'Y Comprador D/Doña:',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.Text(
            'D/Doña: $nombre; DNI/NIE: $dni; Dirección: $direccion; CP: $cp; Provincia: $provincia; Ciudad: $ciudad',
            style: regularTextStyle),
        pw.SizedBox(height: 10),

        // Introducción
        pw.Text(
          'Ambos de común acuerdo y reconociéndose capacidad legal para ello, formalizan la compra-venta, con arreglo a las siguientes condiciones:',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // PRIMERO
        pw.Text(
          'PRIMERO',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El vendedor/a AVENIDA ALCORTA SL vende al comprador, el vehículo:',
          style: regularTextStyle,
        ),
        pw.Text('$bullet Marca: $marca', style: regularTextStyle),
        pw.Text('$bullet Modelo: $modelo', style: regularTextStyle),
        pw.Text('$bullet Matrícula: $matricula', style: regularTextStyle),
        pw.Text('$bullet Nº Bastidor: $bastidor', style: regularTextStyle),
        pw.Text(
            '$bullet Fecha de primera matriculación: $formattedFechaMatriculacion',
            style: regularTextStyle),
        pw.Text('$bullet Kilómetros actuales: $km', style: regularTextStyle),
        pw.SizedBox(height: 5),
        pw.Text(
          'Por la cantidad de $formattedPrecioFinal $euroSymbol.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // SEGUNDO
        pw.Text(
          'SEGUNDO',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El mencionado vehículo tiene las prestaciones que el comprador esperaba encontrar, después de haberlo probado y examinado, estando a su entera conformidad, aceptando su estado, características de uso, kilómetros que marca, y su antigüedad, circunstancias que han sido las determinantes para cuantificar el precio de la compra-venta. Se describe el estado y características en el documento de Declaración de Conformidad que el comprador firma junto a este contrato.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // TERCERO
        pw.Text(
          'TERCERO',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El comprador se compromete a entregar cuantos documentos fueren necesarios para inscribir el vehículo a su nombre en la Jefatura de Tráfico.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // CUARTO
        pw.Text(
          'CUARTO',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'De mutuo acuerdo se pacta la compra-venta del vehículo sin garantía, minorando por este hecho, el valor de PVP anunciado y por tanto eximiendo al vendedor de coberturas de posibles averías que estuviesen cubiertas conforme a la ley y que regulan el RD 1/2007 y la legislación en materia de consumo específicas de la Junta de Andalucía para compra de coche de ocasión.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // QUINTO
        pw.Text(
          'QUINTO',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El comprador se hace cargo desde el mismo momento de la compra-venta de cuantas responsabilidades puedan contraerse como consecuencia de la propiedad del vehículo, tenencia y uso del mismo y como mínimo:',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet A la contratación de una póliza de seguros de Responsabilidad Civil Obligatoria, siendo el comprador responsable de todos los daños causados por el vehículo;',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet El pago de las sanciones impuestas al vehículo con posterioridad a la fecha de la venta.',
          style: regularTextStyle,
        ),
      ],
    ),
  );

  // Página 2: DECLARACIÓN DE CONFORMIDAD y firmas
  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // DECLARACIÓN DE CONFORMIDAD
        pw.Text(
          'DECLARACIÓN DE CONFORMIDAD DE UN VEHÍCULO DE OCASIÓN',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El Comprador D/Doña $nombre con DNI/NIE $dni, con domicilio en $direccion, Código Postal $cp, Ciudad $ciudad, Provincia $provincia${formattedCorreo != 'N/A' ? ', Email $formattedCorreo' : ''}${formattedTelefono != 'N/A' ? ', teléfono $formattedTelefono' : ''}.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Declara a todos los efectos que ha adquirido un vehículo:',
          style: regularTextStyle,
        ),
        pw.Text('$bullet Marca: $marca', style: regularTextStyle),
        pw.Text('$bullet Modelo: $modelo', style: regularTextStyle),
        pw.Text('$bullet Matrícula: $matricula', style: regularTextStyle),
        pw.Text('$bullet Nº Bastidor: $bastidor', style: regularTextStyle),
        pw.Text(
            '$bullet Fecha de primera matriculación: $formattedFechaMatriculacion',
            style: regularTextStyle),
        pw.Text('$bullet Kilómetros actuales: $km', style: regularTextStyle),
        pw.SizedBox(height: 5),
        pw.Text(
          'que se describe en el contrato de compra-venta suscrito entre las partes y que se entrega en este acto. El vehículo se ajusta a la descripción y es conforme al precio convenido con el vendedor, siendo el mismo apto para el uso particular y de ocio.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El comprador asume que el vehículo es usado y por consiguiente existe una devaluación por desgaste del conjunto de piezas y elementos que lo componen en función de su antigüedad y kilómetros.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El comprador ha comprobado el funcionamiento de todos los mecanismos e interruptores eléctricos y manuales así como aparatos eléctricos y sistema de luces siendo conocedor de las especificaciones reseñadas que asume y presta su conformidad, aceptando de forma expresa el comprador su estado de funcionamiento.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'A partir de este instante el comprador se hace cargo de todas las responsabilidades en especial las penales, civiles y administrativas que pudiera contraer como consecuencia del uso y circulación del vehículo.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'De forma expresa el comprador acepta lo indicado en esta Declaración de Conformidad.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'A partir de este instante el comprador será responsable de cuantas infracciones se cometan por el u otra persona y en este caso será también el comprador el responsable de su identificación, todo ello a efectos de la Ley 17/2005 reguladora del permiso y de la licencia por puntos.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'De mutua conformidad se firman dos ejemplares:',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 178),

        // Firmas
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
                pw.Text('CIF: B-93299725', style: regularTextStyle),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}
