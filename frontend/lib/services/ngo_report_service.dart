import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_config.dart';

enum ReportFormat { pdf, csv }

/// A report downloaded from the backend, ready to be saved or shared.
class ReportFile {
  final String fileName;
  final ReportFormat format;
  final Uint8List bytes;

  const ReportFile({
    required this.fileName,
    required this.format,
    required this.bytes,
  });

  String get mimeType =>
      format == ReportFormat.pdf ? 'application/pdf' : 'text/csv';
}

class ReportService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<ReportFile> downloadImpactReport({
    required String token,
    required ReportFormat format,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/impact/report?format=${format.name}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      String message = 'Failed to generate report';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['error']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final date = DateTime.now().toIso8601String().substring(0, 10);
    return ReportFile(
      fileName: 'community-impact-report-$date.${format.name}',
      format: format,
      bytes: response.bodyBytes,
    );
  }

  /// Lets the coordinator choose where on the phone to store the file.
  /// Returns false when the dialog is cancelled.
  static Future<bool> saveToDevice(ReportFile report) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save report',
      fileName: report.fileName,
      bytes: report.bytes,
    );
    return path != null;
  }

  /// Opens the system share sheet (Drive, Gmail, Messages, ...).
  static Future<void> share(ReportFile report) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${report.fileName}',
    );
    await file.writeAsBytes(report.bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: report.mimeType, name: report.fileName),
        ],
        subject: 'Community Impact Report',
        text: 'Community Impact Report',
      ),
    );
  }
}
