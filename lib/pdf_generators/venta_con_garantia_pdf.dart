import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<Uint8List> generateVentaConGarantiaPdf({
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
  required String fechaItv,
  required String km,
  required String fechaMatriculacion,
  String? horaVenta,
}) async {
  // Inicializar localización para español
  await initializeDateFormatting('es_ES', null);

  final pdf = pw.Document();

  // Cargar la fuente LiberationSans-Regular
  pw.Font regularFont;
  try {
    final fontData =
        await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf');
    if (fontData.lengthInBytes == 0) {
      throw Exception('La fuente LiberationSans-Regular.ttf está vacía');
    }
    regularFont = pw.Font.ttf(fontData);
  } catch (e) {
    if (kDebugMode) {
      print(
          'Error cargando fuente LiberationSans-Regular.ttf: $e. Usando Times como fallback.');
    }
    regularFont = pw.Font.times();
  }

  // Cargar la fuente LiberationSans-Bold
  pw.Font boldFont;
  try {
    final boldFontData =
        await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf');
    if (boldFontData.lengthInBytes == 0) {
      throw Exception('La fuente LiberationSans-Bold.ttf está vacía');
    }
    boldFont = pw.Font.ttf(boldFontData);
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

  // Definir constante para viñeta
  const String bullet = '\u2022';

  // Formato para fechas y hora
  final dateTimeVenta = DateTime.parse(fechaVenta);
  final formattedFechaVenta =
      DateFormat('dd MMMM yyyy', 'es_ES').format(dateTimeVenta);
  final formattedHoraVenta =
      horaVenta ?? DateFormat('HH:mm', 'es_ES').format(dateTimeVenta);
  final formattedFechaMatriculacion =
      DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaMatriculacion));
  final formattedFechaItv =
      DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaItv));

  // Depuración de valores recibidos
  if (kDebugMode) {
    print(
        'Valores recibidos - fechaVenta: "$fechaVenta", horaVenta: "$horaVenta", formattedHoraVenta: "$formattedHoraVenta"');
  }

  // Formato para precio sin decimales ni separador de miles
  final numberFormat = NumberFormat('#', 'es_ES');
  final formattedPrecioFinal = numberFormat.format(precio);

  // Estilo de texto común
  final regularTextStyle = pw.TextStyle(fontSize: 11, font: regularFont);
  final boldTextStyle = pw.TextStyle(
      fontSize: 13, fontWeight: pw.FontWeight.bold, font: boldFont);

  // Configuración de página A4 con márgenes
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
                  '${context.pageNumber}/${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Página 1
  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Título principal
        pw.Center(
          child: pw.Text(
            'CONTRATO DE COMPRAVENTA DE VEHÍCULO DE OCASIÓN',
            style: boldTextStyle,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Versión consolidada a partir de modelos GANVAM, contratos sectoriales (2007-2018) y normativa vigente (TRLGDCU reformado en 2022).',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'En Málaga, a las $formattedHoraVenta horas del día $formattedFechaVenta',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // REUNIDOS
        pw.Text(
          'REUNIDOS',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'De una parte, AVENIDA ALCORTA SL, CIF B93299725, con domicilio en Av. Brisa del mar, 4, CP 29004, Málaga, en adelante EL VENDEDOR.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Y de otra parte, D./Dª $nombre, con DNI/NIE: $dni, con domicilio en $direccion, $cp, $ciudad, $provincia, en adelante EL COMPRADOR.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // EXPONEN
        pw.Text(
          'EXPONEN',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '$bullet Que el VENDEDOR se dedica profesionalmente a la compraventa de vehículos de ocasión.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet Que el COMPRADOR declara haber examinado y probado el vehículo, aceptando expresamente que está adquiriendo un VEHÍCULO USADO, es decir NO NUEVO, aceptando su estado y desgaste, propio de su antigüedad y kms.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet Que se entrega anexo Documento de Declaración de Conformidad (firmado) y Checklist de revisión técnica.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 1. Objeto
        pw.Text(
          '1. Objeto',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El VENDEDOR transmite al COMPRADOR el vehículo usado cuyas características básicas son las siguientes:',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Marca: $marca',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Modelo: $modelo',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Matricula: $matricula',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Nº de bastidor: $bastidor',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Fecha ITV: $formattedFechaItv',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Kilometraje: $km',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Fecha de primera matriculación: $formattedFechaMatriculacion',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 2. Precio
        pw.Text(
          '2. Precio',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El precio de la compraventa, teniendo en cuenta las características del vehículo, su estado, antigüedad y kilometraje, se PACTA DE COMÚN ACUERDO en $formattedPrecioFinal $euroSymbol, sirviendo el presente contrato de recibo.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 3. Entrega y transmisión de riesgos
        pw.Text(
          '3. Entrega y transmisión de riesgos',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El VENDEDOR, en este acto hace entrega al COMPRADOR del automóvil que adquiere, libre de cargas y gravámenes, y se compromete a transferir el vehículo, para lo cual el COMPRADOR DEBE APORTAR, en un plazo no mayor a 20 días, la documentación requerida para tal fin. A saber: 1) DNI en vigor, 2) En caso de extranjeros, a) pasaporte en vigor, b) NIE o NIF, y c) certificado de empadronamiento con no más de 90 días de antigüedad.',
          style: regularTextStyle,
        ),
      ],
    ),
  );

  // Página 2
  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Continuación de 3. Entrega y transmisión de riesgos
        pw.Text(
          'Una vez confirmado el pago, el comprador será el nuevo propietario del vehículo, el cual se pone a su disposición a partir de la fecha y hora del presente contrato. Aunque se encuentre en proceso el trámite del cambio de titularidad, el COMPRADOR deberá hacerse cargo de cuantas responsabilidades y mantenimientos puedan contraerse en su condición de propietario, y como mínimo:',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet A la suscripción de una póliza de seguros de Responsabilidad Civil Obligatoria, con servicio de grúa en carretera.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet El pago de las sanciones impuestas al vehículo con posterioridad a la fecha y hora del presente contrato.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'A partir de este instante el comprador se hace cargo de todas las responsabilidades en especial las penales, civiles y administrativas que pudiera contraer como consecuencia del uso y circulación del vehículo.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 4. Obligaciones del COMPRADOR
        pw.Text(
          '4. Obligaciones del COMPRADOR',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '$bullet Realizar los mantenimientos conforme a las indicaciones del fabricante y conservar justificantes.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet Uso de combustibles/lubricantes adecuados.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet Contratar seguro RC Obligatoria desde la entrega.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet Asumir sanciones posteriores a la entrega.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 5. Derecho de desistimiento
        pw.Text(
          '5. Derecho de desistimiento',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'En ventas presenciales no existe. En ventas a distancia: 14 días con devolución en idéntico estado, gastos, traslados y depreciación o deterioro, serán a cargo del COMPRADOR.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 6. Limitación de responsabilidad
        pw.Text(
          '6. Limitación de responsabilidad',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '$bullet El VENDEDOR no responde por pérdidas de uso, lucro cesante, inmovilización, acarreos, traslados, alquileres, ni daños indirectos.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$bullet EN NINGÚN CASO, EL VENDEDOR TIENE LA OBLIGACIÓN DE PRESTAR UN VEHÍCULO DE SUSTITUCIÓN. Podrá darse el caso y sólo de acuerdo a disponibilidad, de que el vendedor brinde en carácter de ATENCIÓN COMERCIAL, el alquiler de un vehículo de sustitución a una tasa reducida de 12 $euroSymbol más IVA por día. En ese caso, se realizará un contrato de alquiler y el usuario deberá dejar un importe de 300 $euroSymbol en concepto de fianza, los cuales serán devueltos al recibir nuevamente el vehículo, una vez pagado los importes del alquiler bonificado y revisado el estado del coche, proceso asimilable al del alquiler de un vehículo.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 7. Garantía legal y responsabilidad
        pw.Text(
          '7. Garantía legal y responsabilidad',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Garantía legal de 12 meses, excluidos defectos derivados de antigüedad, kms o aceptados en la Declaración de Conformidad.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // V. 1- Exclusiones de garantía
        pw.Text(
          'V. 1- Exclusiones de garantía',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'f) Desgaste normal de piezas (neumáticos, frenos, embrague, batería, etc.).',
          style: regularTextStyle,
        ),
        pw.Text(
          'f) Incidencias producidas por suciedad debido al uso normal (inyectores, turbo, catalizadores, válvula egr, filtro de partículas, etc).',
          style: regularTextStyle,
        ),
        pw.Text(
          'f) Mal uso, negligencia, accidentes, falta de mantenimiento, fuerza mayor.',
          style: regularTextStyle,
        ),
        pw.Text(
          'f) Defectos estéticos o ruidos sin incidencia funcional.',
          style: regularTextStyle,
        ),
        pw.Text(
          'f) Defectos eléctricos o electrónicos derivados de desgaste, uso o incidencias surgidas con posterioridad a la entrega y no imputables a defecto de conformidad existente en la entrega.',
          style: regularTextStyle,
        ),
        pw.Text(
          'f) Uso intensivo distinto al declarado, a saber: conducción deportiva (incumpliendo las leyes de velocidad y de tránsito correspondientes), competición, arrendamiento, transporte, etc.',
          style: regularTextStyle,
        ),
      ],
    ),
  );

  // Página 3
  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // V. 2- Procedimiento de garantía
        pw.Text(
          'V. 2- Procedimiento de garantía',
          style: boldTextStyle,
        ),
        pw.Text(
          'Ante síntomas de avería, El COMPRADOR deberá contactar SIEMPRE POR ESCRITO al Departamento de Postventa, sea al email: postventa@autosvillarosa.com, o al Whatsapp: 602423204, desde donde se les indicará el procedimiento a seguir en caso que corresponda. En dicha notificación deberá figurar de forma clara: matrícula, marca, modelo, kilómetros actuales y breve resumen de la incidencia o diagnóstico si lo hubiese.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Los presupuestos o facturas de reparaciones realizadas, no constituyen justificante de averías cubiertas en garantía y en NINGÚN CASO, el vendedor abonará dichas facturas ni presupuestos sin que la misma haya sido constatada por alguno de nuestros talleres concertados, o sin que el personal de Avenida Alcorta SL haya tenido ocasión de verificarlo.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El Departamento Técnico de Postventa tramitará su reclamación lo más rápidamente posible. Le rogamos que tenga en cuenta que el VENDEDOR, no pagará ninguna reparación antes de expedir por escrito, la autorización con anterioridad al inicio de las reparaciones. Rogamos NO CONTACTAR a los teléfonos de venta, o de manera presencial al punto de venta, por cuestiones de postventa, ya que serán automáticamente remitidos a contactar SIEMPRE POR ESCRITO al Departamento de Postventa.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El VENDEDOR no admitirá la recepción de vehículos sin cita previa autorizada por escrito. El incumplimiento de este requisito exime al VENDEDOR de cualquier responsabilidad sobre la custodia del vehículo, corriendo a cargo del COMPRADOR los posibles gastos derivados de estar mal aparcado, acarreo, depósito municipal, etc. Si no se siguiera el procedimiento de reclamación en la forma indicada, el VENDEDOR dará la reclamación por inválida por incumplimientos de forma. Todas las reparaciones pertinentes, deberán realizarse en uno de los talleres concertados, o en caso que sea en otro taller, con un presupuesto que haya sido previamente aceptado por el Departamento Técnico de Postventa.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El COMPRADOR deberá asumir el coste de la reparación, cambio o intercambio de piezas o componentes que no estuviesen cubiertas por la garantía, que sí hubiesen estado cubierta pero que no haya sido autorizado previamente por el VENDEDOR, y todas aquellas intervenciones que constituyan diagnóstico, revisiones y mantenimientos del vehículo. Para la reparación de averías cubiertas en garantía, podrán usarse piezas nuevas, usadas, reacondicionadas o reconstruidas. Sin embargo, el dueño del vehículo puede optar por elegir piezas nuevas y abonar la diferencia entre las piezas nuevas y las usadas o reacondicionadas. El VENDEDOR recomienda al COMPRADOR, que durante el plazo de la garantía, someta el vehículo al uso, mantenimiento y revisiones, recomendadas por el fabricante',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Departamento de Gestión Postventa: postventa@autosvillarosa.com; Whatsapp: +34 602423204; Horario: de Lunes a Viernes de 10:00 a 18:00 hrs',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // V. 3- Garantía externa
        pw.Text(
          'V. 3- Garantía externa',
          style: boldTextStyle,
        ),
        pw.Text(
          'Contratada con la empresa con cobertura nacional. La garantía comercial externa será gestionada exclusivamente por la compañía aseguradora, quedando el VENDEDOR exento de responsabilidad respecto de su tramitación o cobertura.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 8. DECLARACIÓN DE CONFORMIDAD DE UN VEHÍCULO DE OCASIÓN
        pw.Text(
          '8. DECLARACIÓN DE CONFORMIDAD',
          style: boldTextStyle,
        ),
        pw.Text(
          'El COMPRADOR Declara a todos los efectos que ha adquirido el vehículo que se describe en el presente contrato de compraventa suscrito entre las partes y que se entrega en este acto, garantizado por 12 meses, de acuerdo a las especificaciones del artículo V. Declara que el vehículo se ajusta a la descripción y es conforme al precio convenido con el vendedor, siendo el mismo, apto para el uso particular y de ocio.',
          style: regularTextStyle,
        ),
      ],
    ),
  );

  // Página 4
  addPage(
    pdf,
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Continuación de 8. DECLARACIÓN DE CONFORMIDAD
        pw.Text(
          'El comprador asume que el vehículo es usado y por consiguiente existe una devaluación por desgaste del conjunto de piezas y elementos que lo componen en función de su antigüedad y kilómetros, siendo su depreciación contemplada en el precio y en consonancia con las diferentes publicaciones profesionales y oficiales (Ganvam, tablas de valoración de la Agencia Tributaria, etc.)',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El comprador manifiesta que ha examinado personal y directamente el vehículo. Ha probado el vehículo. Está conforme con el estado interior y exterior. Ha comprobado el funcionamiento de todos los mecanismos e interruptores eléctricos y manuales así como aparatos eléctricos y sistema de luces siendo conocedor de las especificaciones reseñadas que asume y presta su conformidad, aceptando de forma expresa el comprador su estado de funcionamiento.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'De forma expresa el comprador acepta lo indicado en esta Declaración de Conformidad, el resultado de la prueba de circulación, así como lo relativo al desgaste y depreciación del vehículo. A partir de este instante el comprador será responsable de cuantas infracciones se cometan por el u otra persona y en este caso será también el comprador el responsable de su identificación, todo ello a efectos de la Ley 1712005 reguladora del permiso y de la licencia por puntos.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),
        // DESGLOSE DEL ESTADO DEL VEHÍCULO AL EFECTUARSE SU ENTREGA
        pw.Text(
          'DESGLOSE DEL ESTADO DEL VEHÍCULO AL EFECTUARSE SU ENTREGA',
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.Text(
          '$bullet Motor: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Caja de cambios: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Embrague: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Frenos: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Dirección: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Diferencial: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Transmisión: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Sistema de alimentación: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Sistema de refrigeración: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Suspensión: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Aire acondicionado: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Sistema eléctrico: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Unidad de control electrónica: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Neumáticos: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Chapa: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Pintura: Correcto',
          style: regularTextStyle,
        ),
        pw.Text(
          '$bullet Tapicería: Correcto',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // 9. Protección de datos
        pw.Text(
          '9. Protección de datos',
          style: boldTextStyle,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'El comprador SÍ autoriza al vendedor de acuerdo con la Ley de protección de datos, a que sus datos sean incorporados al fichero del vendedor y utilizados el envío de ofertas comerciales, pudiendo ejercer los derechos de acceso, rectificación y cancelación, comunicándolo fehacientemente por escrito al vendedor.',
          style: regularTextStyle,
        ),
        pw.SizedBox(height: 10),

        // Firmas
        pw.Text(
          'De mutua conformidad se firman dos ejemplares:',
          style: pw.TextStyle(fontSize: 12, font: regularFont),
        ),
        pw.SizedBox(height: 60),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Text('_______________________',
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
                pw.Text('COMPRADOR',
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
                pw.Text(nombre,
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
                pw.Text(dni,
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
              ],
            ),
            pw.Column(
              children: [
                pw.Text('_______________________',
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
                pw.Text('VENDEDOR',
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
                pw.Text('Avenida Alcorta SL',
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
                pw.Text('CIF: B93299725',
                    style: pw.TextStyle(font: regularFont, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}
