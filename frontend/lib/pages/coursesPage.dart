import 'package:flutter/material.dart';
import 'package:frontend/Api/coursesApi.dart';
import 'package:frontend/components/create_course_form.dart';
import 'package:frontend/pages/sessionDetails.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────

class CourseSession {
  final int id;
  final String date;
  final DateTime startTime;
  final DateTime endTime;
  final String salle;

  const CourseSession({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.salle,
  });

  factory CourseSession.fromJson(Map<String, dynamic> json) => CourseSession(
    id: json['id'] as int,
    date: json['date'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    salle: json['salle'] as String,
  );
}

class Course {
  final int id;
  final String title;
  final String code;
  final List<CourseSession> sessions;

  const Course({
    required this.id,
    required this.title,
    required this.code,
    required this.sessions,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as int,
    title: json['title'] as String,
    code: json['code'] as String,
    sessions: (json['sessions'] as List? ?? [])
        .map((s) => CourseSession.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

// ─────────────────────────────────────────────
//  THEME CONSTANTS  (mirrors profDash.dart)
// ─────────────────────────────────────────────

class _AppColors {
  static const primary = Color(0xFF1A73E8);
  static const primaryLight = Color(0xFFE8F0FE);
  static const surface = Color(0xFFF9FAFB);
  static const cardBg = Colors.white;
  static const divider = Color(0xFFE8EAED);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const green = Color(0xFF1E8B4C);
  static const greenBg = Color(0xFFE6F4EA);
  static const red = Color(0xFFD93025);
  static const redBg = Color(0xFFFCE8E6);
}

// ─────────────────────────────────────────────
//  PAGE WIDGET
// ─────────────────────────────────────────────

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await fetchCourses(page: _currentPage, size: 10);
      setState(() {
        _courses = (data['content'] as List)
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
        _totalPages = data['totalPages'] as int;
        _totalElements = data['totalElements'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Course> get _filtered {
    if (_searchQuery.isEmpty) return _courses;
    return _courses
        .where(
          (c) =>
              c.title.toLowerCase().contains(_searchQuery) ||
              c.code.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  int get _totalSessions =>
      _courses.fold(0, (sum, c) => sum + c.sessions.length);

  void _confirmDelete(Course course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.title}" (${course.code})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _AppColors.red),
            onPressed: () async {
              await deleteCourse(course.id);
              Navigator.pop(context);
              setState(() => _courses.removeWhere((c) => c.id == course.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${course.title} deleted.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // TODO: call DELETE /courses/{id}
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editCourse(Course course) {
    // TODO: push EditCoursePage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "${course.title}" – coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createCourse() {
    showCreateCourseModal(context, onCreated: _loadCourses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──────────────────────────────
          _SearchBar(controller: _searchController),

          // ── Summary stats ───────────────────────────
          if (!_isLoading && _error == null)
            _SummaryRow(
              courseCount: _totalElements,
              sessionCount: _totalSessions,
            ),

          // ── List ────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _AppColors.primary),
                  )
                : _error != null
                ? _ErrorState(error: _error!, onRetry: _loadCourses)
                : RefreshIndicator(
                    onRefresh: _loadCourses,
                    color: _AppColors.primary,
                    child: _filtered.isEmpty
                        ? _EmptyState(onCreateTap: _createCourse)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filtered.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i == _filtered.length) {
                                return _totalPages > 1
                                    ? _PaginationBar(
                                        currentPage: _currentPage,
                                        totalPages: _totalPages,
                                        onPrevious: () {
                                          setState(() => _currentPage--);
                                          _loadCourses();
                                        },
                                        onNext: () {
                                          setState(() => _currentPage++);
                                          _loadCourses();
                                        },
                                      )
                                    : const SizedBox.shrink();
                              }
                              final course = _filtered[i];
                              return _CourseCard(
                                course: course,
                                onEdit: () => _editCourse(course),
                                onDelete: () => _confirmDelete(course),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCourse,
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Course',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search by title or code…',
          hintStyle: const TextStyle(
            color: _AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _AppColors.textSecondary,
                  ),
                  onPressed: controller.clear,
                )
              : null,
          filled: true,
          fillColor: _AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUMMARY ROW
// ─────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int courseCount;
  final int sessionCount;

  const _SummaryRow({required this.courseCount, required this.sessionCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              icon: Icons.menu_book_rounded,
              value: '$courseCount',
              label: courseCount == 1 ? 'Course' : 'Courses',
              color: _AppColors.primary,
              bg: _AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryChip(
              icon: Icons.event_note_rounded,
              value: '$sessionCount',
              label: sessionCount == 1 ? 'Session' : 'Sessions',
              color: _AppColors.green,
              bg: _AppColors.greenBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  const _SummaryChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  COURSE CARD
// ─────────────────────────────────────────────

class _CourseCard extends StatefulWidget {
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final count = c.sessions.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon + title/code + menu ──────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book icon container
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: _AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Code badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.code,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 3-dot action menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: _AppColors.textSecondary,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    if (v == 'edit') widget.onEdit();
                    if (v == 'delete') widget.onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: _AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: TextStyle(color: _AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: _AppColors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(color: _AppColors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: _AppColors.divider),
            const SizedBox(height: 12),

            // ── Stats row ───────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  size: 14,
                  color: _AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  '$count ${count == 1 ? 'session' : 'sessions'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // ── Sessions accordion ──────────────────────
            if (count > 0) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Session History',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: c.sessions
                              .map((s) => _SessionRow(session: s))
                              .toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SESSION ROW  (inside accordion)
// ─────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final CourseSession session;
  const _SessionRow({required this.session});

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailsPage(sessionId: session.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _AppColors.divider),
        ),
        child: Row(
          children: [
            // Date + time column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: _AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        session.date.split('-').reversed.join('-'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: _AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_fmt(session.startTime)} – ${_fmt(session.endTime)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Room badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _AppColors.greenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.meeting_room_rounded,
                    size: 12,
                    color: _AppColors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.salle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: _AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 52,
                color: _AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No courses found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first course to start\nmanaging attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onCreateTap,
              style: FilledButton.styleFrom(
                backgroundColor: _AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create First Course',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: _AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PAGINATION BAR  (mirrors profDash.dart)
// ─────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = currentPage == 0;
    final isLast = currentPage >= totalPages - 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationButton(
            icon: Icons.chevron_left_rounded,
            onTap: isFirst ? null : onPrevious,
            enabled: !isFirst,
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentPage + 1} of $totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _PaginationButton(
            icon: Icons.chevron_right_rounded,
            onTap: isLast ? null : onNext,
            enabled: !isLast,
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _PaginationButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? _AppColors.primary : _AppColors.divider,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : _AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
