import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/lighting_repository.dart';
import '../widgets/spectrum_picker.dart';

class SceneEditorSheet extends StatefulWidget {
  final String title;
  final String sceneId; // 'welcome', 'security'
  final bool isDialog;

  const SceneEditorSheet({
    super.key,
    required this.title,
    required this.sceneId,
    this.isDialog = false,
  });

  @override
  State<SceneEditorSheet> createState() => _SceneEditorSheetState();
}

class _SceneEditorSheetState extends State<SceneEditorSheet> {
  // Configuration State (Visual: Triggers Rebuild)
  Color _activeColor = Colors.white;
  int _effectId = 0;
  
  // Logic State (Performance: ValueNotifier)
  final ValueNotifier<double> _startLed = ValueNotifier(0);
  final ValueNotifier<double> _countLed = ValueNotifier(20);
  final ValueNotifier<double> _durationSeconds = ValueNotifier(10);
  
  bool _webhookRevealed = false;

  @override
  void initState() {
    super.initState();
    // Defer loading to access provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }
  
  @override
  void dispose() {
    _startLed.dispose();
    _countLed.dispose();
    _durationSeconds.dispose();
    super.dispose();
  }

  void _loadConfig() {
    final repo = context.read<LightingRepository>();
    final config = repo.getSceneConfig(widget.sceneId);
    setState(() {
      _effectId = config.effectId;
      _activeColor = Color.fromARGB(255, config.color[0], config.color[1], config.color[2]);
    });
    // Update Notifiers (No SetState needed)
    _startLed.value = config.start.toDouble();
    _countLed.value = config.count.toDouble();
    _durationSeconds.value = config.durationSeconds.toDouble();
  }
  
  // Priority based on ID logic
  int get priorityId {
    if (widget.sceneId == 'welcome') return 12; 
    if (widget.sceneId == 'security') return 11;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: widget.isDialog ? 700 : size.height * 0.9,
      width: widget.isDialog ? 500 : double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface, // Standard Surface
        borderRadius: widget.isDialog 
            ? BorderRadius.circular(24) 
            : const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ]
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Header (Pinned)
            _buildHeader(),

            // 2. Scrollable Content (Atomic Flow)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("VISUAL DESIGN"),
                    const SizedBox(height: 16),
                    Center(
                      child: SpectrumPicker(
                        currentColor: _activeColor,
                        size: 260,
                        onChanged: (c) => setState(() => _activeColor = c),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildEffectSelector(),
                    
                    const SizedBox(height: 48),
                    _buildSectionTitle("BEHAVIOR & LOGIC"),
                    const SizedBox(height: 16),
                    _buildLogicControls(),
                    
                    const SizedBox(height: 48),
                    _buildSectionTitle("INTEGRATION"),
                    const SizedBox(height: 16),
                    _buildWebhookVault(),
                    
                    const SizedBox(height: 100), // Bottom Pad
                  ],
                ),
              ),
            ),
            
            // 3. Footer (Pinned)
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                widget.sceneId == 'security' ? Icons.shield_outlined : Icons.door_front_door_outlined,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CONFIGURE SCENE", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
                  Text(widget.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54),
          )
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF081020),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _trigger,
              icon: const Icon(Icons.touch_app, color: Colors.white),
              label: Text("TEST", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.black),
              label: Text("SAVE SETTINGS", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: GoogleFonts.outfit(
        color: Theme.of(context).primaryColor, 
        fontWeight: FontWeight.bold, 
        letterSpacing: 2.0, 
        fontSize: 12
      )
    );
  }

  Widget _buildEffectSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildEffectChip("Solid", 0, Icons.circle),
        _buildEffectChip("Breathe", 2, Icons.air),
        _buildEffectChip("Rainbow", 9, Icons.palette),
        _buildEffectChip("Chase", 28, Icons.arrow_forward),
        _buildEffectChip("Blink", 1, Icons.warning_amber),
        _buildEffectChip("Flash", 11, Icons.flash_on),
      ],
    );
  }

  Widget _buildEffectChip(String label, int id, IconData icon) {
    final isSelected = _effectId == id;
    return GestureDetector(
      onTap: () => setState(() => _effectId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogicControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildSliderWithNotifier("Start LED", _startLed, 0, 150, 0),
          const Divider(color: Colors.white10, height: 32),
          _buildSliderWithNotifier("Length (Count)", _countLed, 1, 150, 0),
          const Divider(color: Colors.white10, height: 32),
          _buildSliderWithNotifier("Duration (Seconds)", _durationSeconds, 1, 60, 1),
        ],
      ),
    );
  }

  Widget _buildSliderWithNotifier(String label, ValueNotifier<double> notifier, double min, double max, int dec) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, val, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(label, style: GoogleFonts.outfit(color: Colors.white70)),
                 Text(val.toStringAsFixed(dec), style: GoogleFonts.outfit(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
               ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Colors.black26,
                thumbColor: Colors.white,
                overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
              child: Slider(
                value: val,
                min: min,
                max: max,
                onChanged: (v) => notifier.value = v, // Updates notifier -> Rebuilds ONLY this builder
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildWebhookVault() {
    final baseUrl = "https://api.coastal-lighting.com/v1/hooks";
    final hookId = "${widget.sceneId}_${priorityId}"; // In real app, this is a UUID
    final fullUrl = "$baseUrl/$hookId";
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)), // Red accent for security warning visually
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text("EXTERNAL TRIGGER", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              TextButton(
                 onPressed: () => setState(() => _webhookRevealed = !_webhookRevealed),
                 child: Text(_webhookRevealed ? "HIDE" : "REVEAL", style: GoogleFonts.outfit(color: Theme.of(context).primaryColor, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
               color: Colors.black,
               borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
               children: [
                 Expanded(
                   child: Text(
                     _webhookRevealed ? fullUrl : "$baseUrl/••••••••••••",
                     style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                    onPressed: () {
                       Clipboard.setData(ClipboardData(text: fullUrl));
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Webhook URL Copied")));
                    },
                 )
               ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Security Warning: Anyone with this URL can trigger your lights. Keep it safe.",
            style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _trigger() {
     final repo = context.read<LightingRepository>();
     final ip = repo.currentIp;
     if (ip != null) {
       repo.triggerReaction(
         ip: ip,
         start: _startLed.value.toInt(),
         count: _countLed.value.toInt(),
         color: [_activeColor.red, _activeColor.green, _activeColor.blue],
         effectId: _effectId,
         durationSeconds: _durationSeconds.value.toInt(),
         priorityId: priorityId,
       );
     }
  }

  void _save() {
    final repo = context.read<LightingRepository>();
    final config = SceneConfig(
      start: _startLed.value.toInt(), 
      count: _countLed.value.toInt(), 
      durationSeconds: _durationSeconds.value.toInt(), 
      effectId: _effectId, 
      color: [_activeColor.red, _activeColor.green, _activeColor.blue],
    );
    repo.saveSceneConfig(widget.sceneId, config);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Scene Saved & Active")),
    );
  }
}
