import 'package:flutter/material.dart';
import 'package:frontend/Api/coursesApi.dart';

// ─────────────────────────────────────────────
//  THEME CONSTANTS  (mirrors coursesPage.dart)
// ─────────────────────────────────────────────

class _C {
  static const primary = Color(0xFF1A73E8);
  static const primaryLight = Color(0xFFE8F0FE);
  static const surface = Color(0xFFF9FAFB);
  static const divider = Color(0xFFE8EAED);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const green = Color(0xFF1E8B4C);
  // static const greenBg = Color(0xFFE6F4EA);
  static const red = Color(0xFFD93025);
  // static const redBg = Color(0xFFFCE8E6);
}

// ─────────────────────────────────────────────
//  HELPER – show the modal
// ─────────────────────────────────────────────

void showCreateCourseModal(
  BuildContext context, {
  required VoidCallback onCreated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateCourseSheet(onCreated: onCreated),
  );
}

// ─────────────────────────────────────────────
//  BOTTOM-SHEET WRAPPER
// ─────────────────────────────────────────────

class _CreateCourseSheet extends StatelessWidget {
  final VoidCallback onCreated;
  const _CreateCourseSheet({required this.onCreated});

  @override
  Widget build(BuildContext context) {
    // Respect keyboard height
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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _C.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _CreateCourseForm(onCreated: onCreated),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FORM WIDGET
// ─────────────────────────────────────────────

class _CreateCourseForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateCourseForm({required this.onCreated});

  @override
  State<_CreateCourseForm> createState() => _CreateCourseFormState();
}

class _CreateCourseFormState extends State<_CreateCourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _codeAvailable = true;
  bool _checkingCode = false;
  String? _lastCheckedCode;

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkCodeAvailability(String code) async {
    code = code.trim().toUpperCase();
    if (code.isEmpty || code == _lastCheckedCode) return;
    setState(() {
      _checkingCode = true;
      _lastCheckedCode = code;
    });
    try {
      final available = await checkCourseCodeAvailability(code);
      if (mounted) {
        setState(() {
          _codeAvailable = available;
          _checkingCode = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _codeAvailable = false;
          _checkingCode = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await createCourse(
        title: _titleController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
      );
      if (mounted) {
        // Capturer le messenger AVANT de fermer le modal
        final messenger = ScaffoldMessenger.of(context);
        final title = _titleController.text.trim();
        Navigator.pop(context);
        widget.onCreated();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text('"$title" created successfully.'),
              ],
            ),
            backgroundColor: _C.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _C.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Course',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _C.textPrimary,
                    ),
                  ),
                  Text(
                    'Fill in the details below',
                    style: TextStyle(fontSize: 12, color: _C.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: _C.textSecondary),
                style: IconButton.styleFrom(
                  backgroundColor: _C.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Title field ────────────────────────────
          _FieldLabel(label: 'Course Title', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 14, color: _C.textPrimary),
            decoration: _inputDecoration(
              hint: 'e.g. Cyber Security',
              icon: Icons.title_rounded,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Title is required';
              if (v.trim().length < 3)
                return 'Title must be at least 3 characters';
              return null;
            },
          ),

          const SizedBox(height: 18),

          // ── Code field ─────────────────────────────
          _FieldLabel(label: 'Course Code', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 14,
              color: _C.textPrimary,
              letterSpacing: 0.5,
            ),
            onChanged: (v) {
              setState(() {});
              _checkCodeAvailability(v);
            },
            decoration: _inputDecoration(
              hint: 'e.g. CSC-II-24',
              icon: Icons.tag_rounded,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Code is required';
              if (v.trim().length < 2)
                return 'Code must be at least 2 characters';
              if (!_codeAvailable) return 'This code is already taken';
              return null;
            },
          ),

          // ── Code availability hint ─────────────────
          const SizedBox(height: 6),
          AnimatedOpacity(
            opacity: _codeController.text.trim().isEmpty ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                if (_checkingCode)
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_C.primary),
                    ),
                  )
                else
                  Icon(
                    _codeAvailable
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 13,
                    color: _codeAvailable ? _C.green : _C.red,
                  ),
                const SizedBox(width: 5),
                Text(
                  _checkingCode
                      ? 'Checking...'
                      : _codeController.text.trim().isEmpty
                      ? ''
                      : _codeAvailable
                      ? 'This code is available'
                      : 'This code is already taken',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _checkingCode
                        ? _C.primary
                        : _codeAvailable
                        ? _C.green
                        : _C.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Action buttons ─────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _C.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: _C.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _isLoading ? 'Creating…' : 'Create Course',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(color: _C.red, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _C.textSecondary, fontSize: 13),
    prefixIcon: Icon(icon, color: _C.textSecondary, size: 18),
    filled: true,
    fillColor: _C.surface,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.red, width: 1.5),
    ),
  );
}
