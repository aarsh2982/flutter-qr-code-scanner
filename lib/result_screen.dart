import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

const bgColor = Color(0xFFfafafa);

class ResultScreen extends StatefulWidget {
  final String scannedResult;

  const ResultScreen({
    super.key,
    required this.scannedResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey qrKey = GlobalKey();
  bool isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.scannedResult));
      if (mounted) {
        _showSnackBar("Copied to clipboard");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to copy text", isError: true);
      }
    }
  }

  Future<void> _saveQrCode() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
      });

      // Get the temporary directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/qr_code.png';

      // Create QR code image
      final qrValidationResult = QrValidator.validate(
        data: widget.scannedResult,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode;
        final painter = QrPainter.withQr(
          qr: qrCode!,
          color: const Color(0xFF000000),
          gapless: true,
          embeddedImageStyle: null,
          embeddedImage: null,
        );

        final picData =
            await painter.toImageData(2048, format: ui.ImageByteFormat.png);
        await File(filePath).writeAsBytes(picData!.buffer.asUint8List());

        if (!mounted) return;

        // Share the file
        await Share.shareXFiles([XFile(filePath)],
            text: 'QR Code for: ${widget.scannedResult}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving QR code: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        backgroundColor: Colors.orangeAccent,
        title: const Text(
          "QR Code Scanner",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            key: qrKey,
                            data: widget.scannedResult,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Scanned Result",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.scannedResult,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text(
                        "Copy",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isLoading ? null : _saveQrCode,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.share, color: Colors.white),
                      label: Text(
                        isLoading ? "Sharing..." : "Share",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
