import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';

Future<Uint8List> generateAutorizacionPdf({
  required String marca,
  required String modelo,
  required String matricula,
  required String transporte,
  String? cif,
}) async {
  final pdf = pw.Document();

  // Mapa de transportes predefinidos con empresa y CIF
  final transportesData = {
    'Auto1': {'empresa': 'NO APLICA', 'cif': 'NO APLICA'},
    'Manuel': {'empresa': 'Manuel Campos Fitz', 'cif': '28648766N'},
    'Orencio': {
      'empresa': 'Transporte de vehículos Orencio SL',
      'cif': 'B73301004'
    },
    'Guadalix': {'empresa': 'Autologísca Guadalix SL', 'cif': 'B84913763'},
  };

  // Determina nombre de empresa y CIF, con valores por defecto
  final empresa = transportesData.containsKey(transporte)
      ? transportesData[transporte]!['empresa']!
      : (transporte.isNotEmpty ? transporte : 'No especificado');
  final cifFinal = transportesData.containsKey(transporte)
      ? transportesData[transporte]!['cif']!
      : (cif?.isNotEmpty ?? false ? cif! : 'No especificado');

  // Carga el logo desde los assets
  final logoBytes = await rootBundle.load('assets/images/logo_auto1.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  // Carga la imagen de la firma desde los assets
  final signatureBytes = await rootBundle.load('assets/images/firma.png');
  final signatureImage = pw.MemoryImage(signatureBytes.buffer.asUint8List());

  final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14);
  final normalStyle = pw.TextStyle(fontSize: 12);

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
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Comprador / Company Name: ', style: normalStyle),
                  pw.Text('Avenida Alcorta SL', style: boldStyle),
                ],
              ),
              pw.Image(logoImage,
                  width: 144, height: 36, fit: pw.BoxFit.contain),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('Sr. D. / Company Representative: ', style: normalStyle),
          pw.Text('Alejandro F. Gallego Montero', style: boldStyle),
          pw.SizedBox(height: 10),
          pw.Text('Con DNI / With ID / Passport number: ', style: normalStyle),
          pw.Text('50335399Z', style: boldStyle),
          pw.SizedBox(height: 10),
          pw.Text(
              'Autorizo a la empresa/persona / Authorize the company/person: ',
              style: normalStyle),
          pw.Text(empresa, style: boldStyle),
          pw.SizedBox(height: 10),
          pw.Text('Con DNI-CIF / with ID Number / Company Reg. Number: ',
              style: normalStyle),
          pw.Text(cifFinal, style: boldStyle),
          pw.SizedBox(height: 10),
          pw.Text(
              'Para que efectúe en mi nombre la recogida del vehículo matricula ',
              style: normalStyle),
          pw.Text(
              'To pick up the vehicle with contract number / reference number: ',
              style: normalStyle),
          pw.SizedBox(height: 10),
          pw.Text('Especificar modelo y matrícula / model and plate number: ',
              style: normalStyle),
          pw.SizedBox(height: 10),
          pw.Divider(height: 1, thickness: 1),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text('$marca $modelo',
                    style: boldStyle, textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Text(matricula,
                    style: boldStyle, textAlign: pw.TextAlign.center),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('Firma / Sello del comprador ', style: normalStyle),
          pw.Text('Signature / stamp of the Buyer ', style: normalStyle),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Image(signatureImage,
                width: 200, height: 100, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 10),
          pw.Text('A este impreso se adjuntará DNI de la persona autorizante. ',
              style: normalStyle),
          pw.Text('ID of the buyer must be sent together with this document. ',
              style: normalStyle),
        ],
      ),
    ),
  );

  return await pdf.save();
}
