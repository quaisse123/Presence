import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/Api/QrCodeApi.dart';
import 'package:frontend/Api/sessionsApi.dart';
import 'package:frontend/pages/studentScanTest.dart';

enum StudentAttendanceStatus { present, late, absent }

extension StudentAttendanceStatusX on StudentAttendanceStatus {
  String get label {
    switch (this) {
      case StudentAttendanceStatus.present:
        return 'Present';
      case StudentAttendanceStatus.late:
        return 'Late';
      case StudentAttendanceStatus.absent:
        return 'Absent';
    }
  }

  Color textColor() {
    switch (this) {
      case StudentAttendanceStatus.present:
        return const Color(0xFF1C9B63);
      case StudentAttendanceStatus.late:
        return const Color(0xFFCC8A2E);
      case StudentAttendanceStatus.absent:
        return const Color(0xFFD94B4B);
    }
  }

  Color bgColor() {
    switch (this) {
      case StudentAttendanceStatus.present:
        return const Color(0xFFE6F7EF);
      case StudentAttendanceStatus.late:
        return const Color(0xFFFFF3E3);
      case StudentAttendanceStatus.absent:
        return const Color(0xFFFDECEC);
    }
  }

  IconData get icon {
    switch (this) {
      case StudentAttendanceStatus.present:
        return Icons.check_circle_rounded;
      case StudentAttendanceStatus.late:
        return Icons.access_time_filled_rounded;
      case StudentAttendanceStatus.absent:
        return Icons.cancel_rounded;
    }
  }
}

enum StudentHistoryRange { week, month, all }

extension StudentHistoryRangeX on StudentHistoryRange {
  String get label {
    switch (this) {
      case StudentHistoryRange.week:
        return 'Current Week';
      case StudentHistoryRange.month:
        return 'Current Month';
      case StudentHistoryRange.all:
        return 'All Time';
    }
  }
}

class StudentSessionRecord {
  final int sessionId;
  final String courseTitle;
  final String courseCode;
  final String professorName;
  final String salle;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final DateTime? scanTime;
  final StudentAttendanceStatus status;

  const StudentSessionRecord({
    required this.sessionId,
    required this.courseTitle,
    required this.courseCode,
    required this.professorName,
    required this.salle,
    required this.sessionStart,
    required this.sessionEnd,
    required this.scanTime,
    required this.status,
  });

  bool get attended => status != StudentAttendanceStatus.absent;
}

class _StudentTheme {
  static const pageBg = Color(0xFFF3F5F9);
  static const card = Colors.white;
  static const primary = Color(0xFF1C4FBF);
  static const primaryDeep = Color(0xFF163B9A);
  static const primarySoft = Color(0xFFEAF0FE);
  static const textPrimary = Color(0xFF1D293D);
  static const textSecondary = Color(0xFF7B8798);
  static const border = Color(0xFFE4E9F1);
  static const neutral = Color(0xFF6E7E92);
  static const neutralSoft = Color(0xFFF0F3F8);
}

class StudentDashPage extends StatefulWidget {
  const StudentDashPage({super.key});

  @override
  State<StudentDashPage> createState() => _StudentDashPageState();
}

class _StudentDashPageState extends State<StudentDashPage> {
  List<StudentSessionRecord> _allRecords = [];
  int _totalSessions = 0;
  int _attendedSessions = 0;
  int _missedSessions = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  StudentAttendanceStatus? _selectedStatus;
  StudentHistoryRange _selectedRange = StudentHistoryRange.week;

  int? _loggedUserId;
  bool _loadingUser = true;
  bool _loadingHistory = true;
  bool _showFilters = false;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _loadLoggedUser();

    // Recherche avec petit debounce pour eviter trop d'appels API.
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        _loadSessionHistory();
      });
    });

    _loadSessionHistory();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionHistory() async {
    setState(() {
      _loadingHistory = true;
      _loadingError = null;
    });

    try {
      // Filtre periode envoye au backend.
      final period = switch (_selectedRange) {
        StudentHistoryRange.week => 'LAST_WEEK',
        StudentHistoryRange.month => 'LAST_MONTH',
        StudentHistoryRange.all => 'ALL',
      };

      // Filtre statut envoye au backend.
      final status = _selectedStatus?.name.toUpperCase();

      // Filtre recherche envoye au backend.
      final search = _searchController.text.trim();

      final data = await fetchMySessionHistory(
        period: period,
        status: status,
        search: search.isEmpty ? null : search,
      );

      final items = (data['items'] as List<dynamic>? ?? <dynamic>[]);

      final records = items
          .map((item) => _fromApi(item as Map<String, dynamic>))
          .toList();

      final totalSessions = (data['totalSessions'] as num?)?.toInt() ?? 0;
      final attendedSessions = (data['attendedSessions'] as num?)?.toInt() ?? 0;
      final missedSessions = (data['missedSessions'] as num?)?.toInt() ?? 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _allRecords = records;
        _totalSessions = totalSessions;
        _attendedSessions = attendedSessions;
        _missedSessions = missedSessions;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingHistory = false;
        _loadingError = 'Impossible de charger les sessions.';
        _allRecords = [];
        _totalSessions = 0;
        _attendedSessions = 0;
        _missedSessions = 0;
      });
    }
  }

  StudentSessionRecord _fromApi(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final status = switch (rawStatus) {
      'PRESENT' => StudentAttendanceStatus.present,
      'LATE' => StudentAttendanceStatus.late,
      _ => StudentAttendanceStatus.absent,
    };

    final start = DateTime.parse(json['sessionStartTime'] as String);
    final end = DateTime.parse(json['sessionEndTime'] as String);

    return StudentSessionRecord(
      sessionId: (json['sessionId'] as num).toInt(),
      courseTitle: (json['courseTitle'] ?? 'Session').toString(),
      courseCode: (json['courseCode'] ?? '-').toString(),
      professorName: (json['professorName'] ?? 'Professor').toString(),
      salle: (json['salle'] ?? '-').toString(),
      sessionStart: start,
      sessionEnd: end,
      scanTime: json['scanTime'] == null
          ? null
          : DateTime.parse(json['scanTime'] as String),
      status: status,
    );
  }

  Future<void> _loadLoggedUser() async {
    try {
      final id = await getLoggedUserId();
      if (!mounted) {
        return;
      }
      setState(() {
        _loggedUserId = id;
        _loadingUser = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingUser = false;
      });
    }
  }

  Future<void> _openScanPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StudentScanTestPage()));
  }

  List<StudentSessionRecord> get _filteredRecords {
    final sorted = [..._allRecords];
    sorted.sort((a, b) => b.sessionStart.compareTo(a.sessionStart));
    return sorted;
  }

  double get _weekRatio {
    if (_totalSessions == 0) {
      return 0;
    }
    return _attendedSessions / _totalSessions;
  }

  int get _attendancePercent => (_weekRatio * 100).round().clamp(0, 100);

  StudentSessionRecord? get _currentSession {
    final now = DateTime.now();
    for (final record in _filteredRecords) {
      final isOngoing =
          !record.sessionStart.isAfter(now) && record.sessionEnd.isAfter(now);
      if (isOngoing) {
        return record;
      }
    }
    return null;
  }

  String get _selectedRangeSubtitle {
    switch (_selectedRange) {
      case StudentHistoryRange.week:
        return 'Current Week';
      case StudentHistoryRange.month:
        return 'Current Month';
      case StudentHistoryRange.all:
        return 'All Time';
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _humanReadableDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today';
    }
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return _formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: _StudentTheme.pageBg,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _selectedRange = StudentHistoryRange.week;
            _selectedStatus = null;
            _searchController.clear();
          });
          await _loadSessionHistory();
        },
        color: _StudentTheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          children: [
            _buildTopHeader(),
            const SizedBox(height: 14),
            _buildProgressPanel(),
            const SizedBox(height: 12),
            _buildHeroCard(),
            const SizedBox(height: 12),
            _buildCurrentSessionCard(),
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 12),
            _buildFiltersCard(),
            const SizedBox(height: 12),
            Text(
              'Session history (${records.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _StudentTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_loadingError != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _StudentTheme.border),
                ),
                child: const Text(
                  'Erreur de chargement des sessions.',
                  style: TextStyle(
                    color: _StudentTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (records.isEmpty)
              _buildEmptyState()
            else
              ...records.map(
                (record) => Padding(
                  key: ValueKey(
                    'session-${record.sessionId}-${record.sessionStart.millisecondsSinceEpoch}',
                  ),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SessionHistoryCard(
                    record: record,
                    isCurrent:
                        _currentSession != null &&
                        _currentSession!.sessionId == record.sessionId &&
                        _currentSession!.sessionStart == record.sessionStart &&
                        _currentSession!.sessionEnd == record.sessionEnd,
                    dateLabel: _humanReadableDate(record.sessionStart),
                    timeLabel:
                        '${_formatTime(record.sessionStart)} - ${_formatTime(record.sessionEnd)}',
                    scanLabel: record.scanTime == null
                        ? 'Not scanned'
                        : _formatTime(record.scanTime!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E6F0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF2D4A78),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello Student,',
                  style: TextStyle(
                    color: _StudentTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'My Dashboard',
                  style: TextStyle(
                    color: _StudentTheme.primaryDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 34 / 2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _StudentTheme.border),
            ),
            child: IconButton(
              tooltip: 'Logout',
              onPressed: logout,
              icon: const Icon(
                Icons.logout_rounded,
                color: _StudentTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: Row(
        children: [
          // const Padding(
          //   padding: EdgeInsets.only(left: 4),
          //   child: Text(
          //     'Overall\nProgress',
          //     style: TextStyle(
          //       fontSize: 17,
          //       fontWeight: FontWeight.w800,
          //       color: _StudentTheme.textPrimary,
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: _StudentTheme.neutralSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: StudentHistoryRange.values.map((range) {
                  final selected = _selectedRange == range;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() => _selectedRange = range);
                        _loadSessionHistory();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          switch (range) {
                            StudentHistoryRange.week => 'Week',
                            StudentHistoryRange.month => 'Month',
                            StudentHistoryRange.all => 'All Time',
                          },
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? _StudentTheme.primaryDeep
                                : _StudentTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: _StudentTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D14213D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My session progress - $_selectedRangeSubtitle',
                  style: const TextStyle(
                    color: _StudentTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_loadingUser)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _StudentTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ATTENDANCE RATE',
                      style: TextStyle(
                        color: Color(0xFF057047),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_attendancePercent%',
                      style: const TextStyle(
                        color: _StudentTheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 44,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 98,
                      height: 98,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE6EBF3),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 98,
                      height: 98,
                      child: CircularProgressIndicator(
                        value: _weekRatio.clamp(0.0, 1.0),
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0B7C4E),
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B7C4E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _weekRatio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE0E5EE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _StudentTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openScanPage,
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: _StudentTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text(
                'Scan session QR',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            title: 'Attended',
            value: '$_attendedSessions / $_totalSessions',
            subtitle: _selectedRangeSubtitle,
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF0B7C4E),
            bg: const Color(0xFFEAF8F1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            title: 'Missed',
            value: '$_missedSessions',
            subtitle: 'In current filter',
            icon: Icons.cancel_rounded,
            color: const Color(0xFFB3261E),
            bg: const Color(0xFFFCEDEB),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSessionCard() {
    final current = _currentSession;
    if (current == null) {
      return const SizedBox.shrink();
    }

    final scanned = current.attended;
    final badgeText = scanned ? 'Scanned' : 'Not scanned yet';
    final badgeColor = scanned
        ? const Color(0xFF1C9B63)
        : const Color(0xFFD94B4B);
    final badgeBg = scanned ? const Color(0xFFE6F7EF) : const Color(0xFFFDECEC);
    final liveColor = scanned
        ? const Color(0xFF1C9B63)
        : const Color(0xFFD94B4B);
    final liveBg = scanned ? const Color(0xFFE6F7EF) : const Color(0xFFFDECEC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: liveBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radio_button_checked_rounded,
                      size: 11,
                      color: liveColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: liveColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            current.courseTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _StudentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prof: ${current.professorName}  •  Room ${current.salle}',
            style: const TextStyle(
              fontSize: 12,
              color: _StudentTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_humanReadableDate(current.sessionStart)} • ${_formatTime(current.sessionStart)} - ${_formatTime(current.sessionEnd)}',
            style: const TextStyle(
              fontSize: 12,
              color: _StudentTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    final statusOptions = <StudentAttendanceStatus?>[
      null,
      StudentAttendanceStatus.present,
      StudentAttendanceStatus.late,
      StudentAttendanceStatus.absent,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _StudentTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by course code, title or room...',
                    hintStyle: const TextStyle(
                      color: _StudentTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: _StudentTheme.neutralSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _showFilters
                      ? _StudentTheme.primarySoft
                      : _StudentTheme.neutralSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showFilters
                        ? _StudentTheme.primary
                        : _StudentTheme.border,
                  ),
                ),
                child: IconButton(
                  tooltip: _showFilters ? 'Hide filters' : 'Show filters',
                  onPressed: () {
                    setState(() => _showFilters = !_showFilters);
                  },
                  icon: Icon(
                    _showFilters
                        ? Icons.filter_list_off_rounded
                        : Icons.filter_list_rounded,
                    color: _showFilters
                        ? _StudentTheme.primary
                        : _StudentTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _showFilters
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Range',
                    style: TextStyle(
                      color: _StudentTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: StudentHistoryRange.values.map((range) {
                      final selected = _selectedRange == range;
                      return _buildFilterChip(
                        label: range.label,
                        selected: selected,
                        onTap: () {
                          setState(() => _selectedRange = range);
                          _loadSessionHistory();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: _StudentTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statusOptions.map((status) {
                      final selected = _selectedStatus == status;
                      final label = status == null ? 'All' : status.label;
                      return _buildFilterChip(
                        label: label,
                        selected: selected,
                        onTap: () {
                          setState(() => _selectedStatus = status);
                          _loadSessionHistory();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? _StudentTheme.primarySoft
              : _StudentTheme.neutralSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _StudentTheme.primary : _StudentTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? _StudentTheme.primary
                : _StudentTheme.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.find_in_page_rounded,
            size: 44,
            color: _StudentTheme.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No session found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _StudentTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try adjusting filters to display your history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _StudentTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _StudentTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _StudentTheme.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: _StudentTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final StudentSessionRecord record;
  final bool isCurrent;
  final String dateLabel;
  final String timeLabel;
  final String scanLabel;

  const _SessionHistoryCard({
    super.key,
    required this.record,
    this.isCurrent = false,
    required this.dateLabel,
    required this.timeLabel,
    required this.scanLabel,
  });

  @override
  Widget build(BuildContext context) {
    final status = record.status;
    final attended = record.attended;
    final badgeText = attended ? 'Attended' : 'Not attended';
    final badgeColor = attended
        ? const Color(0xFF1C9B63)
        : const Color(0xFFD94B4B);
    final badgeBg = attended
        ? const Color(0xFFE6F7EF)
        : const Color(0xFFFDECEC);
    final badgeIcon = attended
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final liveColor = attended
        ? const Color(0xFF1C9B63)
        : const Color(0xFFD94B4B);
    final currentBg = attended
        ? const Color(0xFFF6FBF8)
        : const Color(0xFFFFF7F7);
    final currentBorder = attended
        ? const Color(0xFFBEE7CF)
        : const Color(0xFFF1C6C6);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isCurrent ? currentBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? currentBorder : _StudentTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: liveColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radio_button_checked_rounded,
                      size: 11,
                      color: liveColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE SESSION',
                      style: TextStyle(
                        color: liveColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.courseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _StudentTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${record.courseCode} - Prof ${record.professorName} - Room ${record.salle}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _StudentTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Status: ${status.label}',
            style: const TextStyle(
              fontSize: 11,
              color: _StudentTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _StudentTheme.neutralSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: _StudentTheme.neutral,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$dateLabel - $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _StudentTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.qr_code_rounded,
                  size: 15,
                  color: _StudentTheme.neutral,
                ),
                const SizedBox(width: 4),
                Text(
                  scanLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _StudentTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Session #${record.sessionId}',
            style: const TextStyle(
              fontSize: 11,
              color: _StudentTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
