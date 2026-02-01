import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/services/installation_service.dart';
import '../../domain/models/installation.dart';

class ScanKeyScreen extends StatefulWidget {
  const ScanKeyScreen({super.key});

  @override
  State<ScanKeyScreen> createState() => _ScanKeyScreenState();
}

class _ScanKeyScreenState extends State<ScanKeyScreen> {
  final TextEditingController _pasteController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  Future<void> _importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _pasteController.text = data!.text!;
      _processInput();
    }
  }

  Future<void> _processInput() async {
    final input = _pasteController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = "Please paste or enter the Golden Key data.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> json = jsonDecode(input);
      final installation = Installation.fromJson(json);

      await context.read<InstallationService>().saveInstallation(installation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome, ${installation.customerName}! Installation imported."),
            backgroundColor: const Color(0xFFD4AF37),
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Invalid Golden Key format. Please try again.";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "IMPORT KEY",
          style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 2),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner, size: 64, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 24),

            Text(
              "Receive Your Home",
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Your installer has provided a Golden Key.\nPaste the code below to claim control.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Paste Area
            TextField(
              controller: _pasteController,
              maxLines: 6,
              style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
              decoration: InputDecoration(
                hintText: '{"id": "...", "customerName": "..."}',
                hintStyle: GoogleFonts.robotoMono(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Error
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.outfit(color: Colors.redAccent),
                ),
              ),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importFromClipboard,
                    icon: const Icon(Icons.content_paste, color: Colors.white70),
                    label: Text("PASTE", style: GoogleFonts.outfit(color: Colors.white70)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processInput,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text("IMPORT", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Camera Scan Placeholder (For Mobile)
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Camera scanning available on mobile devices.")),
                );
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white30),
              label: Text("Scan with Camera", style: GoogleFonts.outfit(color: Colors.white30)),
            ),
          ],
        ),
      ),
    );
  }
}
