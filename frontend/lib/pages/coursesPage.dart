import 'package:flutter/material.dart';
import 'package:frontend/Api/coursesApi.dart';
import 'package:frontend/components/create_course_form.dart';
import 'package:frontend/pages/sessionDetails.dart';

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

class _CourseTheme {
  static const pageBg = Color(0xFFF1F3F6);
  static const card = Colors.white;
  static const primary = Color(0xFF1C4FBF);
  static const primaryDeep = Color(0xFF163B9A);
  static const primarySoft = Color(0xFFEAF0FE);
  static const textPrimary = Color(0xFF1D293D);
  static const textSecondary = Color(0xFF7B8798);
  static const border = Color(0xFFE4E9F1);
  static const success = Color(0xFF1C9B63);
  static const successSoft = Color(0xFFE6F7EF);
  static const danger = Color(0xFFD94B4B);
  static const dangerSoft = Color(0xFFFDECEC);
  static const surfaceSoft = Color(0xFFF6F8FC);
}

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
    if (_searchQuery.isEmpty) {
      return _courses;
    }
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

  Future<void> _goToPreviousPage() async {
    if (_currentPage == 0) {
      return;
    }
    setState(() => _currentPage--);
    await _loadCourses();
  }

  Future<void> _goToNextPage() async {
    if (_currentPage >= _totalPages - 1) {
      return;
    }
    setState(() => _currentPage++);
    await _loadCourses();
  }

  void _confirmDelete(Course course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete course'),
        content: Text(
          'Delete "${course.title}" (${course.code})?',
          style: const TextStyle(color: _CourseTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _CourseTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await deleteCourse(course.id);
              if (!mounted) {
                return;
              }
              Navigator.pop(context);
              setState(() => _courses.removeWhere((c) => c.id == course.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${course.title} deleted.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editCourse(Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "${course.title}" - coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createCourse() {
    showCreateCourseModal(context, onCreated: _loadCourses);
  }

  @override
  Widget build(BuildContext context) {
    final showSummary = !_isLoading && _error == null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        color: _CourseTheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _OverviewCard(
              courseCount: showSummary ? _totalElements : 0,
              sessionCount: showSummary ? _totalSessions : 0,
            ),
            const SizedBox(height: 14),
            _SearchBar(controller: _searchController),
            const SizedBox(height: 12),
            _ActionRow(onCreateTap: _createCourse, onRefresh: _loadCourses),
            const SizedBox(height: 16),
            if (_isLoading)
              const _LoadingState()
            else if (_error != null)
              _ErrorState(error: _error!, onRetry: _loadCourses)
            else if (_filtered.isEmpty)
              _EmptyState(onCreateTap: _createCourse)
            else ...[
              ..._filtered.map(
                (course) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CourseCard(
                    course: course,
                    onEdit: () => _editCourse(course),
                    onDelete: () => _confirmDelete(course),
                  ),
                ),
              ),
              if (_totalPages > 1) ...[
                const SizedBox(height: 2),
                _PaginationBar(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPrevious: _goToPreviousPage,
                  onNext: _goToNextPage,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int courseCount;
  final int sessionCount;

  const _OverviewCard({required this.courseCount, required this.sessionCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_CourseTheme.primaryDeep, _CourseTheme.primary],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220A2F7A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -38,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1EFFFFFF),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Course Portfolio',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '#$courseCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Active courses',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _OverviewStat(
                    icon: Icons.menu_book_rounded,
                    label: 'Courses',
                    value: '$courseCount',
                  ),
                  const SizedBox(width: 10),
                  _OverviewStat(
                    icon: Icons.event_note_rounded,
                    label: 'Sessions',
                    value: '$sessionCount',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x40FFFFFF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1,
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CourseTheme.border),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search by title or code',
          hintStyle: const TextStyle(
            color: _CourseTheme.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _CourseTheme.textSecondary,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _CourseTheme.textSecondary,
                  ),
                  onPressed: controller.clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onCreateTap;
  final Future<void> Function() onRefresh;

  const _ActionRow({required this.onCreateTap, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onCreateTap,
            style: FilledButton.styleFrom(
              backgroundColor: _CourseTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'New Course',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: _CourseTheme.primary,
              side: const BorderSide(color: _CourseTheme.border),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'Refresh',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

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
    final room = count > 0 ? c.sessions.first.salle : 'No room';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _CourseTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _CourseTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D122849),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _CourseTheme.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _CourseTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _CourseTheme.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _CourseTheme.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.code,
                        style: const TextStyle(
                          color: _CourseTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _CourseTheme.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: _CourseTheme.textSecondary,
                    size: 19,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onEdit();
                  }
                  if (value == 'delete') {
                    widget.onDelete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: _CourseTheme.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.event_note_rounded,
                text: '$count ${count == 1 ? 'session' : 'sessions'}',
                color: _CourseTheme.primary,
                bg: _CourseTheme.primarySoft,
              ),
              _MetricChip(
                icon: Icons.meeting_room_rounded,
                text: room,
                color: _CourseTheme.success,
                bg: _CourseTheme.successSoft,
              ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Session timeline',
                      style: TextStyle(
                        color: _CourseTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: _CourseTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        children: c.sessions
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _SessionRow(session: s),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;

  const _MetricChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final CourseSession session;

  const _SessionRow({required this.session});

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final date = session.date.split('-').reversed.join('/');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailsPage(sessionId: session.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _CourseTheme.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _CourseTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: _CourseTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: _CourseTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: _CourseTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                        style: const TextStyle(
                          color: _CourseTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _CourseTheme.successSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.salle,
                style: const TextStyle(
                  color: _CourseTheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _CourseTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CourseTheme.border),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: _CourseTheme.primary),
          SizedBox(height: 12),
          Text(
            'Loading courses...',
            style: TextStyle(
              color: _CourseTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _CourseTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: _CourseTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 44,
              color: _CourseTheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No courses found',
            style: TextStyle(
              color: _CourseTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first course to start managing attendance sessions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _CourseTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreateTap,
            style: FilledButton.styleFrom(
              backgroundColor: _CourseTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Create first course',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _CourseTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 50,
            color: _CourseTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load courses',
            style: TextStyle(
              color: _CourseTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _CourseTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: _CourseTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Future<void> Function() onPrevious;
  final Future<void> Function() onNext;

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CourseTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: !isFirst,
            onTap: isFirst ? null : onPrevious,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _CourseTheme.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: const TextStyle(
                color: _CourseTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PaginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: !isLast,
            onTap: isLast ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final Future<void> Function()? onTap;
  final bool enabled;

  const _PaginationButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? _CourseTheme.primary : _CourseTheme.border,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : _CourseTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
