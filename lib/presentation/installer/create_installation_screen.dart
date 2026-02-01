import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/installation_service.dart';
import '../../domain/models/installation.dart';

class CreateInstallationScreen extends StatefulWidget {
  const CreateInstallationScreen({super.key});

  @override
  State<CreateInstallationScreen> createState() => _CreateInstallationScreenState();
}

class _CreateInstallationScreenState extends State<CreateInstallationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _address = '';
  String _customerEmail = '';
  final List<String> _ips = [];
  final Map<String, String> _ipToMac = {};
  bool _isAdding = false;
  
  // Controller for IP input
  final TextEditingController _ipController = TextEditingController();

  void _addIp() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    
    setState(() => _isAdding = true);
    
    try {
      final repo = context.read<LightingRepository>();
      final success = await repo.addController(ip);
      
      if (success) {
        final mac = repo.getMac(ip);
        setState(() {
          if (!_ips.contains(ip)) {
            _ips.add(ip);
            if (mac != null) _ipToMac[ip] = mac;
          }
          _ipController.clear();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not connect to controller. Check IP.")),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final installation = Installation(
        id: const Uuid().v4(),
        customerName: _name,
        address: _address,
        dateInstalled: DateTime.now(),
        controllerIps: _ips.isNotEmpty ? _ips : ['192.168.4.1'], // Default AP
        controllerMacs: _ips.map((ip) => _ipToMac[ip] ?? 'unknown').toList(),
        customerEmail: _customerEmail.isNotEmpty ? _customerEmail : null,
      );

      await context.read<InstallationService>().saveInstallation(installation);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("NEW CLIENT", style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Customer Details", style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Name
              TextFormField(
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDec("Name", Icons.person),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDec("Address", Icons.location_on),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => _address = v!,
              ),
              const SizedBox(height: 16),

              // Customer Email (Optional for Local, Required for Handover)
              TextFormField(
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDec("Customer Email", Icons.email),
                onSaved: (v) => _customerEmail = v?.trim() ?? '',
              ),
              const SizedBox(height: 32),
              
              Text("Equipment", style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // IP List Builder
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: _inputDec("Controller IP", Icons.wifi),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isAdding 
                    ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                    : IconButton(
                        onPressed: _addIp,
                        icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37), size: 32),
                      )
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _ips.map((ip) => Chip(
                  label: Text("$ip (${_ipToMac[ip]?.substring(max(0, _ipToMac[ip]!.length - 6)) ?? '?'})"),
                  backgroundColor: Colors.white10,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white54),
                  onDeleted: () => setState(() {
                    _ips.remove(ip);
                    _ipToMac.remove(ip);
                  }),
                )).toList(),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("CREATE RECORD", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
