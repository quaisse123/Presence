import 'package:flutter/material.dart';
import 'package:frontend/Api/coursesApi.dart';
import 'package:frontend/Api/sessionsApi.dart';

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────

class _C {
  static const primary = Color(0xFF1C4FBF);
  static const primaryLight = Color(0xFFEAF0FE);
  static const divider = Color(0xFFE4E9F1);
  static const textPrimary = Color(0xFF1D293D);
  static const textSecondary = Color(0xFF7B8798);
  static const green = Color(0xFF1C9B63);
  static const red = Color(0xFFD94B4B);
}

// ─────────────────────────────────────────────
//  HELPER – show the modal
// ─────────────────────────────────────────────

void showCreateSessionModal(
  BuildContext context, {
  required VoidCallback onCreated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateSessionSheet(onCreated: onCreated),
  );
}

// ─────────────────────────────────────────────
//  BOTTOM-SHEET WRAPPER
// ─────────────────────────────────────────────

class _CreateSessionSheet extends StatelessWidget {
  final VoidCallback onCreated;
  const _CreateSessionSheet({required this.onCreated});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _C.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _CreateSessionForm(onCreated: onCreated),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FORM WIDGET
// ─────────────────────────────────────────────

class _CreateSessionForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateSessionForm({required this.onCreated});

  @override
  State<_CreateSessionForm> createState() => _CreateSessionFormState();
}

class _CreateSessionFormState extends State<_CreateSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _salleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _radiusController = TextEditingController(text: '50');

  bool _isLoading = false;
  bool _loadingOptions = true;

  // Options (cours + groupes)
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _groups = [];

  // Sélections
  int? _selectedCourseId;
  int? _selectedGroupId;

  // Date/heure
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _salleController.dispose();
    _descriptionController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final coursesResult = await fetchCourses(page: 0, size: 100);
      final groups = await fetchGroups();

      final coursesContent = coursesResult['content'] as List? ?? [];
      if (mounted) {
        setState(() {
          _courses = coursesContent.cast<Map<String, dynamic>>();
          _groups = groups;
          _loadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingOptions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;
    setState(() {
      _startTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      // Si endTime avant startTime, on décale endTime de +1h
      if (!_endTime.isAfter(_startTime)) {
        _endTime = _startTime.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime.subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    if (time == null) return;
    setState(() {
      _endTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$d  $h:$m';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir un cours et un groupe.'),
          backgroundColor: _C.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("L'heure de fin doit être après l'heure de début."),
          backgroundColor: _C.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await createSession(
        startTime: _startTime.toIso8601String(),
        endTime: _endTime.toIso8601String(),
        latitude: null,
        longitude: null,
        radiusInMeters: double.tryParse(_radiusController.text.trim()),
        salle: _salleController.text.trim().isEmpty
            ? null
            : _salleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        courseId: _selectedCourseId!,
        groupId: _selectedGroupId!,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        widget.onCreated();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Session créée avec succès.'),
            backgroundColor: _C.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Créer une session',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Renseignez les informations de la séance.',
              style: TextStyle(fontSize: 13, color: _C.textSecondary),
            ),
            const SizedBox(height: 20),

            if (_loadingOptions)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // ── Cours ──
              DropdownButtonFormField<int>(
                initialValue: _selectedCourseId,
                decoration: _inputDecoration('Cours'),
                items: _courses
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as int,
                        child: Text(
                          '${c['title']} (${c['code']})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCourseId = v),
                validator: (v) => v == null ? 'Choisissez un cours' : null,
              ),
              const SizedBox(height: 16),

              // ── Groupe ──
              DropdownButtonFormField<int>(
                initialValue: _selectedGroupId,
                decoration: _inputDecoration('Groupe'),
                items: _groups
                    .map(
                      (g) => DropdownMenuItem(
                        value: g['id'] as int,
                        child: Text(
                          _groupLabel(g),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedGroupId = v),
                validator: (v) => v == null ? 'Choisissez un groupe' : null,
              ),
              const SizedBox(height: 16),

              // ── Salle ──
              TextFormField(
                controller: _salleController,
                decoration: _inputDecoration('Salle (optionnel)'),
              ),
              const SizedBox(height: 16),

              // ── Description ──
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Description (optionnel)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ── Début / Fin ──
              Row(
                children: [
                  Expanded(
                    child: _dateField('Début', _startTime, _pickStartTime),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _dateField('Fin', _endTime, _pickEndTime)),
                ],
              ),
              const SizedBox(height: 16),

              // ── Rayon GPS ──
              TextFormField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Rayon GPS en mètres (optionnel)'),
              ),
              const SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Créer la session',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _groupLabel(Map<String, dynamic> g) {
    final level = g['level'] ?? '';
    final section = g['section'];
    final filiere = g['filiere'];
    final parts = <String>[level];
    if (section != null && section.toString().isNotEmpty) {
      parts.add('Section ${section}');
    }
    if (filiere != null && filiere.toString().isNotEmpty) {
      parts.add(filiere.toString());
    }
    return parts.join(' - ');
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.primary, width: 1.5),
      ),
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: _C.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDateTime(value),
                style: const TextStyle(fontSize: 14, color: _C.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
