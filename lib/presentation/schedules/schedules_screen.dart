import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/schedule_service.dart';
import '../widgets/gold_button.dart';
import '../widgets/feedback_widgets.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Schedules",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddScheduleSheet(context),
          ),
        ],
      ),
      body: Consumer<ScheduleService>(
        builder: (context, service, child) {
          if (service.schedules.isEmpty) {
            return EmptyState(
              icon: Icons.schedule,
              title: "No Schedules",
              subtitle: "Automate your lights with sunrise, sunset, or timed schedules.",
              actionLabel: "CREATE SCHEDULE",
              onAction: () => _showAddScheduleSheet(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: service.schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final schedule = service.schedules[index];
              return _ScheduleCard(
                schedule: schedule,
                onToggle: (enabled) => service.toggleSchedule(schedule.id, enabled),
                onEdit: () => _showEditScheduleSheet(context, schedule),
                onDelete: () => _confirmDelete(context, service, schedule.id),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ScheduleFormSheet(),
    );
  }

  void _showEditScheduleSheet(BuildContext context, LightingSchedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScheduleFormSheet(existingSchedule: schedule),
    );
  }

  void _confirmDelete(BuildContext context, ScheduleService service, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Delete Schedule?", style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          "This schedule will be permanently removed.",
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              service.deleteSchedule(id);
              Navigator.pop(ctx);
            },
            child: Text("DELETE", style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final LightingSchedule schedule;
  final void Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getTriggerColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getTriggerIcon(), color: _getTriggerColor(), size: 24),
        ),
        title: Text(
          schedule.name,
          style: GoogleFonts.outfit(
            color: schedule.enabled ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getTriggerDescription(),
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: schedule.enabled,
              onChanged: onToggle,
              activeColor: const Color(0xFFD4AF37),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF1E293B),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: GoogleFonts.outfit(color: Colors.white)),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTriggerIcon() {
    switch (schedule.trigger.type) {
      case TriggerType.sunrise:
        return Icons.wb_sunny;
      case TriggerType.sunset:
        return Icons.nights_stay;
      case TriggerType.fixedTime:
        return Icons.access_time;
    }
  }

  Color _getTriggerColor() {
    switch (schedule.trigger.type) {
      case TriggerType.sunrise:
        return Colors.orange;
      case TriggerType.sunset:
        return Colors.deepPurple;
      case TriggerType.fixedTime:
        return const Color(0xFFD4AF37);
    }
  }

  String _getTriggerDescription() {
    final trigger = schedule.trigger;
    String base;
    
    switch (trigger.type) {
      case TriggerType.sunrise:
        base = "At Sunrise";
        if (trigger.offsetMinutes != 0) {
          base += trigger.offsetMinutes > 0 
              ? " + ${trigger.offsetMinutes}m" 
              : " - ${trigger.offsetMinutes.abs()}m";
        }
        break;
      case TriggerType.sunset:
        base = "At Sunset";
        if (trigger.offsetMinutes != 0) {
          base += trigger.offsetMinutes > 0 
              ? " + ${trigger.offsetMinutes}m" 
              : " - ${trigger.offsetMinutes.abs()}m";
        }
        break;
      case TriggerType.fixedTime:
        if (trigger.fixedTime != null) {
          final hour = trigger.fixedTime!.hour;
          final minute = trigger.fixedTime!.minute.toString().padLeft(2, '0');
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          base = "$displayHour:$minute $period";
        } else {
          base = "Time not set";
        }
        break;
    }
    
    // Action description
    switch (schedule.action.type) {
      case ActionType.turnOn:
        base += " → Turn On";
        break;
      case ActionType.turnOff:
        base += " → Turn Off";
        break;
      case ActionType.setBrightness:
        base += " → ${((schedule.action.brightness ?? 0) / 255 * 100).round()}% Brightness";
        break;
      case ActionType.applyPreset:
        base += " → Preset ${schedule.action.presetId}";
        break;
    }
    
    return base;
  }
}

class _ScheduleFormSheet extends StatefulWidget {
  final LightingSchedule? existingSchedule;

  const _ScheduleFormSheet({this.existingSchedule});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _nameController = TextEditingController();
  TriggerType _triggerType = TriggerType.sunset;
  int _offsetMinutes = 0;
  TimeOfDay _fixedTime = const TimeOfDay(hour: 18, minute: 0);
  ActionType _actionType = ActionType.turnOn;
  double _brightness = 255;

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      final s = widget.existingSchedule!;
      _nameController.text = s.name;
      _triggerType = s.trigger.type;
      _offsetMinutes = s.trigger.offsetMinutes;
      if (s.trigger.fixedTime != null) {
        _fixedTime = TimeOfDay(
          hour: s.trigger.fixedTime!.hour,
          minute: s.trigger.fixedTime!.minute,
        );
      }
      _actionType = s.action.type;
      _brightness = (s.action.brightness ?? 255).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.existingSchedule == null ? "New Schedule" : "Edit Schedule",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Name
            TextField(
              controller: _nameController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Schedule Name",
                labelStyle: GoogleFonts.outfit(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Trigger Type
            Text("Trigger", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<TriggerType>(
              segments: const [
                ButtonSegment(value: TriggerType.sunrise, icon: Icon(Icons.wb_sunny), label: Text("Sunrise")),
                ButtonSegment(value: TriggerType.sunset, icon: Icon(Icons.nights_stay), label: Text("Sunset")),
                ButtonSegment(value: TriggerType.fixedTime, icon: Icon(Icons.access_time), label: Text("Time")),
              ],
              selected: {_triggerType},
              onSelectionChanged: (set) => setState(() => _triggerType = set.first),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? Colors.black : Colors.white70),
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? const Color(0xFFD4AF37) : Colors.transparent),
              ),
            ),
            const SizedBox(height: 16),
            
            // Offset (for sunrise/sunset)
            if (_triggerType != TriggerType.fixedTime) ...[
              Text("Offset: $_offsetMinutes minutes", 
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
              Slider(
                value: _offsetMinutes.toDouble(),
                min: -60,
                max: 60,
                divisions: 24,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (v) => setState(() => _offsetMinutes = v.round()),
              ),
            ],
            
            // Fixed Time Picker
            if (_triggerType == TriggerType.fixedTime) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Time", style: GoogleFonts.outfit(color: Colors.white70)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _fixedTime,
                    );
                    if (picked != null) setState(() => _fixedTime = picked);
                  },
                  child: Text(
                    _fixedTime.format(context),
                    style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 18),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Action Type
            Text("Action", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<ActionType>(
              segments: const [
                ButtonSegment(value: ActionType.turnOn, label: Text("On")),
                ButtonSegment(value: ActionType.turnOff, label: Text("Off")),
                ButtonSegment(value: ActionType.setBrightness, label: Text("Dim")),
              ],
              selected: {_actionType},
              onSelectionChanged: (set) => setState(() => _actionType = set.first),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? Colors.black : Colors.white70),
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? const Color(0xFFD4AF37) : Colors.transparent),
              ),
            ),
            
            // Brightness slider
            if (_actionType == ActionType.setBrightness) ...[
              const SizedBox(height: 16),
              Text("Brightness: ${(_brightness / 255 * 100).round()}%", 
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
              Slider(
                value: _brightness,
                min: 0,
                max: 255,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (v) => setState(() => _brightness = v),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Save Button
            GoldButtonFull(
              label: widget.existingSchedule == null ? "CREATE SCHEDULE" : "SAVE CHANGES",
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a schedule name")),
      );
      return;
    }

    final schedule = LightingSchedule(
      id: widget.existingSchedule?.id ?? const Uuid().v4(),
      name: _nameController.text,
      trigger: ScheduleTrigger(
        type: _triggerType,
        offsetMinutes: _triggerType != TriggerType.fixedTime ? _offsetMinutes : 0,
        fixedTime: _triggerType == TriggerType.fixedTime 
            ? DateTime(2026, 1, 1, _fixedTime.hour, _fixedTime.minute)
            : null,
      ),
      action: ScheduleAction(
        type: _actionType,
        brightness: _actionType == ActionType.setBrightness ? _brightness.round() : null,
      ),
      enabled: widget.existingSchedule?.enabled ?? true,
    );

    final service = context.read<ScheduleService>();
    
    if (widget.existingSchedule == null) {
      service.addSchedule(schedule);
    } else {
      service.updateSchedule(schedule);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
