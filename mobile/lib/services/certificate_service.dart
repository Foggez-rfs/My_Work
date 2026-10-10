import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificateService {
  /// Генерирует PDF-сертификат волонтёра
  static Future<Uint8List> generateCertificate({
    required String volunteerName,
    required int completedOrders,
    required double totalHours,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape(),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 8),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Заголовок
                pw.Text(
                  'СЕРТИФИКАТ ВОЛОНТЁРА',
                  style: pw.TextStyle(
                    fontSize: 42,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Подзаголовок
                pw.Text(
                  'Платформа «Моё дело»',
                  style: pw.TextStyle(
                    fontSize: 24,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 40),
                
                // Текст сертификата
                pw.Text(
                  'Настоящий сертификат подтверждает, что',
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 20),
                
                // Имя волонтёра
                pw.Text(
                  volunteerName,
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Описание достижений
                pw.Text(
                  'оказал(а) помощь пожилым людям и людям с ограниченными',
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.Text(
                  'возможностями в количестве $completedOrders заказов',
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                
                pw.Text(
                  'общей продолжительностью ${totalHours.toStringAsFixed(1)} часов',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 40),
                
                // Период
                pw.Text(
                  'Период: ${_formatDate(startDate)} — ${_formatDate(endDate)}',
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 60),
                
                // Подпись
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 200,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Администрация платформы',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 200,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Дата выдачи: ${_formatDate(DateTime.now())}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  /// Открывает диалог печати/сохранения PDF
  static Future<void> printCertificate({
    required String volunteerName,
    required int completedOrders,
    required double totalHours,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdfData = await generateCertificate(
      volunteerName: volunteerName,
      completedOrders: completedOrders,
      totalHours: totalHours,
      startDate: startDate,
      endDate: endDate,
    );
    
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
