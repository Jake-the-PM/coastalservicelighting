import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/services/schedule_service.dart';
import '../../data/repositories/lighting_repository.dart';
import 'package:uuid/uuid.dart';

class AutomationScreen extends StatelessWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final schedules = scheduleService.schedules;

    return Scaffold(
      backgroundColor: const Color(0xFF050E1C),
      appBar: AppBar(
        title: Text("AUTOMATION", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: schedules.isEmpty 
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: schedules.length,
              itemBuilder: (context, index) => _ScheduleCard(schedule: schedules[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleSheet(context),
        backgroundColor: const Color(0xFFD4AF37),
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text("NEW TIMER", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text(
            "No active automations",
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Schedule scenes by sunset or time.",
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddScheduleSheet(),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final LightingSchedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final nextTrigger = context.read<ScheduleService>().getNextTriggerTime(schedule);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTriggerText(),
                ],
              ),
              Switch(
                value: schedule.enabled,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (val) => context.read<ScheduleService>().toggleSchedule(schedule.id, val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.history, size: 14, color: Colors.white24),
              const SizedBox(width: 8),
              Text(
                nextTrigger != null 
                    ? "Next: ${_formatTime(nextTrigger)}" 
                    : "No upcoming events",
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.read<ScheduleService>().deleteSchedule(schedule.id),
                child: const Text("DELETE", style: TextStyle(color: Color(0xFFCF6679), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerText() {
    String text = "";
    IconData icon = Icons.access_time;
    
    switch (schedule.trigger.type) {
      case TriggerType.sunrise:
        text = "Sunrise";
        icon = Icons.wb_sunny_outlined;
        break;
      case TriggerType.sunset:
        text = "Sunset";
        icon = Icons.bedtime_outlined;
        break;
      case TriggerType.fixedTime:
        final time = schedule.trigger.fixedTime;
        text = time != null ? "${time.hour}:${time.minute.toString().padLeft(2, '0')}" : "Fixed Time";
        break;
    }

    if (schedule.trigger.offsetMinutes != 0) {
      final sign = schedule.trigger.offsetMinutes > 0 ? "+" : "";
      text += " ($sign${schedule.trigger.offsetMinutes}m)";
    }

    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.white),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}

class _AddScheduleSheet extends StatefulWidget {
  const _AddScheduleSheet();

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  TriggerType _type = TriggerType.sunset;
  ActionType _actionType = ActionType.turnOn;
  TimeOfDay _time = TimeOfDay.now();
  int _offset = 0;
  String _name = "Night Lights";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 32, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1629),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SET AUTOMATION", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          Text("WHEN", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeChip(TriggerType.sunset, "Sunset", Icons.bedtime_outlined),
              const SizedBox(width: 8),
              _buildTypeChip(TriggerType.sunrise, "Sunrise", Icons.wb_sunny_outlined),
              const SizedBox(width: 8),
              _buildTypeChip(TriggerType.fixedTime, "Time", Icons.access_time),
            ],
          ),
          
          if (_type == TriggerType.fixedTime) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: Text("${_time.hour}:${_time.minute.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Text("DO", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<ActionType>(
            value: _actionType,
            dropdownColor: const Color(0xFF0A1629),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: ActionType.values.map((a) => DropdownMenuItem(value: a, child: Text(a.name.toUpperCase()))).toList(),
            onChanged: (val) => setState(() => _actionType = val!),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("ACTIVATE TIMER", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(TriggerType type, String label, IconData icon) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _save() {
    final now = DateTime.now();
    final fixedTime = _type == TriggerType.fixedTime 
        ? DateTime(now.year, now.month, now.day, _time.hour, _time.minute)
        : null;

    final schedule = LightingSchedule(
      id: const Uuid().v4(),
      name: _type == TriggerType.sunset ? "Sunset Glow" : (_type == TriggerType.sunrise ? "Morning Rise" : "Custom Timer"),
      trigger: ScheduleTrigger(
        type: _type,
        fixedTime: fixedTime,
        offsetMinutes: _offset,
      ),
      action: ScheduleAction(type: _actionType),
    );

    context.read<ScheduleService>().addSchedule(schedule);
    Navigator.pop(context);
  }
}
