import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/models/installation.dart';

class GoldenKeyScreen extends StatelessWidget {
  final Installation installation;

  const GoldenKeyScreen({super.key, required this.installation});

  @override
  Widget build(BuildContext context) {
    // Serialize installation to compact JSON
    final jsonData = jsonEncode(installation.toJson());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "GOLDEN KEY",
          style: GoogleFonts.outfit(
            color: const Color(0xFFD4AF37),
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Branding
              const Icon(Icons.vpn_key, size: 48, color: Color(0xFFD4AF37)),
              const SizedBox(height: 12),
              Text(
                "Ownership Transfer",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Have the homeowner scan this code to receive full control.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: jsonData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Customer Info Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: "Customer", value: installation.customerName),
                    const Divider(color: Colors.white10),
                    _InfoRow(label: "Address", value: installation.address),
                    const Divider(color: Colors.white10),
                    _InfoRow(
                      label: "Controllers",
                      value: installation.controllerIps.join(", "),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share Button (Future: Native Share)
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Share sheet with QR image or deep link
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Share functionality coming soon!")),
                  );
                },
                icon: const Icon(Icons.share, color: Color(0xFFD4AF37)),
                label: Text(
                  "SHARE KEY",
                  style: GoogleFonts.outfit(color: const Color(0xFFD4AF37)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white54)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
