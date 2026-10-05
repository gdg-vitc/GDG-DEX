import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/http_helper.dart';
import 'capture_scan_screen.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String role;
  final int connections;
  final String? regNo;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.role,
    required this.connections,
    this.regNo,
    this.isCurrentUser = false,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? name,
    String? role,
    int? connections,
    String? regNo,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      role: role ?? this.role,
      connections: connections ?? this.connections,
      regNo: regNo ?? this.regNo,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

class LeaderboardScreen extends StatefulWidget {
  final String? currentUserName;
  final String? currentUserRole;
  final String? currentUserRegNo;
  final String? currentUserEmail;

  const LeaderboardScreen({
    super.key,
    this.currentUserName,
    this.currentUserRole,
    this.currentUserRegNo,
    this.currentUserEmail,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<LeaderboardEntry> _allEntries = [];
  LeaderboardEntry? _currentUserEntry;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dynamic response = await HttpHelper.get('/api/leaderboard');
      List<dynamic> rawList = [];

      if (response is Map) {
        if (response['leaderboard'] is List) {
          rawList = response['leaderboard'] as List;
        } else if (response['data'] is List) {
          rawList = response['data'] as List;
        }
      } else if (response is List) {
        rawList = response;
      }

      final List<LeaderboardEntry> apiEntries = [];
      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map) {
          final name = item['name']?.toString().trim() ?? 'Trainer ${i + 1}';
          final role = item['role']?.toString().trim() ?? 'Member';
          final connections = (item['connections'] as num?)?.toInt() ?? 0;
          final regNo =
              item['reg_no']?.toString().trim() ??
              item['reg']?.toString().trim();

          apiEntries.add(
            LeaderboardEntry(
              rank: i + 1,
              name: name,
              role: role,
              connections: connections,
              regNo: regNo,
            ),
          );
        }
      }

      // Sort by connections descending
      apiEntries.sort((a, b) => b.connections.compareTo(a.connections));

      // Re-assign ranks 1..N based on actual sorted order
      final List<LeaderboardEntry> rankedList = [];
      for (int i = 0; i < apiEntries.length; i++) {
        rankedList.add(apiEntries[i].copyWith(rank: i + 1));
      }

      // Check if current user is present in the API leaderboard
      final currentUserName =
          (widget.currentUserName ?? HttpHelper.userName ?? '').trim();
      final cleanUserName = currentUserName.toLowerCase();

      LeaderboardEntry? userEntry;
      if (cleanUserName.isNotEmpty) {
        for (final entry in rankedList) {
          final entryName = entry.name.toLowerCase().trim();
          if (entryName == cleanUserName ||
              cleanUserName == entryName.replaceAll('trainer ', '') ||
              entryName == cleanUserName.replaceAll('trainer ', '') ||
              cleanUserName.contains(entryName) ||
              entryName.contains(cleanUserName)) {
            userEntry = entry.copyWith(isCurrentUser: true);
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _allEntries = rankedList;
          _currentUserEntry = userEntry;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry1 = _allEntries.isNotEmpty ? _allEntries[0] : null;
    final entry2 = _allEntries.length > 1 ? _allEntries[1] : null;
    final entry3 = _allEntries.length > 2 ? _allEntries[2] : null;

    // Feed entries: strictly only entries from the API starting from rank 4
    final feedEntries = _allEntries.where((e) => e.rank >= 4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF0D9488),
          onRefresh: _fetchLeaderboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Hero Mint/Teal Section with Watermark & Top 3 Podium
                _buildTopHeroSection(
                  rank1: entry1,
                  rank2: entry2,
                  rank3: entry3,
                ),

                // Floating "YOU" Rank Card
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildUserRankCard(_currentUserEntry),
                  ),
                ),

                // Error / Offline Banner if fetch failed
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFDC2626),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Could not refresh leaderboard. Check connection.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF991B1B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _fetchLeaderboard,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Club Encounters Feed Section Header
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 2,
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Club Encounters Feed',
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ranked by verified companion dex links',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Feed List Cards or Empty State
                if (_isLoading && _allEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0D9488),
                        ),
                      ),
                    ),
                  )
                else if (feedEntries.isNotEmpty)
                  ...feedEntries.map((entry) => _buildFeedCard(entry))
                else
                  _buildEmptyFeedPlaceholder(),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // EMPTY FEED PLACEHOLDER
  // -------------------------------------------------------------
  Widget _buildEmptyFeedPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 24,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No additional trainers in the feed',
              style: GoogleFonts.outfit(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Make a connection first to appear on the leaderboard!',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP HERO SECTION (MINT / TEAL GRADIENT + WATERMARK + PODIUM)
  // -------------------------------------------------------------
  Widget _buildTopHeroSection({
    required LeaderboardEntry? rank1,
    required LeaderboardEntry? rank2,
    required LeaderboardEntry? rank3,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF38D5BB), Color(0xFF26C28F), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          // Pokéball Watermark in the upper-right corner
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              child: CustomPaint(painter: _PokeballWatermarkPainter()),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              child: Column(
                children: [
                  // App Bar / Top Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular Back Button
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      // Title & Subtitle (Pokédex Club / Leaderboard)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'POKÉDEX CLUB',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.88),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Leaderboard',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Top 3 Podium Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // #2 Podium (Left)
                      Expanded(
                        child: _buildPodiumColumn(entry: rank2, isSecond: true),
                      ),
                      const SizedBox(width: 8),

                      // #1 Podium (Center, Elevated with Crown)
                      Expanded(
                        child: _buildPodiumColumn(entry: rank1, isFirst: true),
                      ),
                      const SizedBox(width: 8),

                      // #3 Podium (Right)
                      Expanded(
                        child: _buildPodiumColumn(entry: rank3, isThird: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PODIUM COLUMN BUILDER
  // -------------------------------------------------------------
  Widget _buildPodiumColumn({
    required LeaderboardEntry? entry,
    bool isFirst = false,
    bool isSecond = false,
    bool isThird = false,
  }) {
    final borderColor = isFirst
        ? const Color(0xFFFDE68A)
        : (isSecond ? const Color(0xFF99F6E4) : const Color(0xFFFECDD3));

    final badgeColor = isFirst
        ? const Color(0xFF0F766E)
        : (isSecond ? const Color(0xFF0D9488) : const Color(0xFFE11D48));

    final medalNumber = isFirst ? '#1' : (isSecond ? '#2' : '#3');
    final name = entry?.name ?? '-';
    final role = entry?.role ?? (entry == null ? 'Awaiting trainer' : 'Member');
    final connections = entry?.connections ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown above #1
        if (isFirst)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              width: 32,
              height: 24,
              child: CustomPaint(painter: _CrownPainter()),
            ),
          )
        else
          const SizedBox(height: 30),

        // Rounded Medal Card
        Container(
          width: isFirst ? 78 : 70,
          height: isFirst ? 72 : 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.military_tech_rounded,
                size: isFirst ? 24 : 20,
                color: badgeColor,
              ),
              Text(
                medalNumber,
                style: GoogleFonts.outfit(
                  fontSize: isFirst ? 18 : 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Name
        Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: isFirst ? 15 : 13.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Role
        Text(
          role,
          style: GoogleFonts.inter(
            fontSize: isFirst ? 11 : 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 6),

        // Score Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.grid_view_rounded,
                size: 11,
                color: Color(0xFF0D9488),
              ),
              const SizedBox(width: 4),
              Text(
                '$connections',
                style: GoogleFonts.outfit(
                  fontSize: isFirst ? 13 : 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Podium Step / Base
        Container(
          width: isFirst ? 98 : 82,
          height: isFirst ? 76 : 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isFirst ? 0.38 : 0.28),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          alignment: Alignment.center,
          child: isFirst
              ? Text(
                  'LEADER',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                )
              : Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  child: Icon(
                    isSecond ? Icons.verified_rounded : Icons.bolt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // FLOATING "YOU" RANK CARD
  // -------------------------------------------------------------
  Widget _buildUserRankCard(LeaderboardEntry? userEntry) {
    final bool isRanked = userEntry != null;
    final fallbackName =
        widget.currentUserName ?? HttpHelper.userName ?? 'Trainer Ash';
    final name = isRanked ? userEntry.name : fallbackName;
    final role = isRanked
        ? userEntry.role
        : (widget.currentUserRole ?? HttpHelper.role ?? 'Member');
    final regNo = isRanked
        ? (userEntry.regNo ?? widget.currentUserRegNo ?? '')
        : (widget.currentUserRegNo ?? '');
    final connections = isRanked ? userEntry.connections : 0;
    final rankText = isRanked ? '#${userEntry.rank}' : '-';
    final rankBadgeLabel = isRanked ? 'Rank #${userEntry.rank}' : 'Unranked';

    // Milestone text and progress
    String milestoneTitle;
    String milestoneSubtitle;
    double progressValue;

    if (isRanked) {
      if (userEntry.rank == 1) {
        milestoneTitle = 'Leader: Rank #1';
        milestoneSubtitle = 'Holding #1 spot!';
        progressValue = 1.0;
      } else {
        final targetRank = userEntry.rank - 1;
        final competitor = _allEntries[targetRank - 1];
        final needed = (competitor.connections - userEntry.connections) + 1;
        milestoneTitle = 'Next Milestone: Top $targetRank';
        milestoneSubtitle = '$needed to pass ${competitor.name}';
        progressValue = competitor.connections > 0
            ? (userEntry.connections / competitor.connections).clamp(0.15, 0.95)
            : 0.5;
      }
    } else {
      milestoneTitle = 'Make a connection first';
      milestoneSubtitle = 'to appear on the leaderboard';
      progressValue = 0.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRanked ? const Color(0xFF2DD4BF) : const Color(0xFFE2E8F0),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top Row: Avatar Badge + User Details + Dex Count
          Row(
            children: [
              // Circular Rank Avatar with Teal Ring
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRanked
                      ? const Color(0xFFF0FDFA)
                      : const Color(0xFFF8FAFC),
                  border: Border.all(
                    color: isRanked
                        ? const Color(0xFF2DD4BF)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rankText,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isRanked
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF64748B),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'YOU',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isRanked
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // User Info (Name, Rank pill, RegNo • Role)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isRanked
                                ? const Color(0xFFEEF2F6)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            rankBadgeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isRanked
                                  ? const Color(0xFF334155)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isRanked
                          ? (regNo.isNotEmpty ? '$regNo • $role' : role)
                          : 'Make a connection first to get ranked',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isRanked
                            ? const Color(0xFF64748B)
                            : const Color(0xFF0D9488),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right Score Count & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        size: 14,
                        color: Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$connections',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Dex Encounters',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom Row: Milestone Tracker & Boost Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              milestoneTitle,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (milestoneSubtitle.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                milestoneSubtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0D9488),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CaptureScanScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isRanked ? 'Scan' : 'Connect',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2DD4BF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FEED LIST ITEM CARD (RANKS 4+) - ONLY FROM API
  // -------------------------------------------------------------
  Widget _buildFeedCard(LeaderboardEntry entry) {
    // Dynamic color coding matching ranks
    Color rankBg;
    Color rankBorder;
    Color rankText;

    switch (entry.rank % 6) {
      case 4:
        rankBg = const Color(0xFFEFF6FF);
        rankBorder = const Color(0xFFBFDBFE);
        rankText = const Color(0xFF2563EB);
        break;
      case 5:
        rankBg = const Color(0xFFF0FDFA);
        rankBorder = const Color(0xFF99F6E4);
        rankText = const Color(0xFF0D9488);
        break;
      case 0:
        rankBg = const Color(0xFFFFFBEB);
        rankBorder = const Color(0xFFFDE68A);
        rankText = const Color(0xFFD97706);
        break;
      case 1:
        rankBg = const Color(0xFFFFF1F2);
        rankBorder = const Color(0xFFFECDD3);
        rankText = const Color(0xFFE11D48);
        break;
      case 2:
        rankBg = const Color(0xFFF0F9FF);
        rankBorder = const Color(0xFFBAE6FD);
        rankText = const Color(0xFF0284C7);
        break;
      default:
        rankBg = const Color(0xFFF1F5F9);
        rankBorder = const Color(0xFFE2E8F0);
        rankText = const Color(0xFF475569);
    }

    // Role badge color scheme
    Color roleBg = const Color(0xFFF1F5F9);
    Color roleText = const Color(0xFF475569);
    final lowerRole = entry.role.toLowerCase();

    if (lowerRole.contains('dev') || lowerRole.contains('tech')) {
      roleBg = const Color(0xFFEFF6FF);
      roleText = const Color(0xFF2563EB);
    } else if (lowerRole.contains('design') || lowerRole.contains('creative')) {
      roleBg = const Color(0xFFF0FDFA);
      roleText = const Color(0xFF0D9488);
    } else if (lowerRole.contains('research') || lowerRole.contains('sec')) {
      roleBg = const Color(0xFFFFFBEB);
      roleText = const Color(0xFFD97706);
    } else if (lowerRole.contains('market') || lowerRole.contains('lead')) {
      roleBg = const Color(0xFFFFF1F2);
      roleText = const Color(0xFFE11D48);
    }

    final subtitle = entry.regNo != null && entry.regNo!.isNotEmpty
        ? '${entry.regNo} • ${entry.connections} ${entry.connections == 1 ? 'connection' : 'connections'}'
        : '${entry.role} • ${entry.connections} ${entry.connections == 1 ? 'connection' : 'connections'}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry.isCurrentUser
              ? const Color(0xFF2DD4BF)
              : const Color(0xFFF1F5F9),
          width: entry.isCurrentUser ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Rank Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankBg,
              border: Border.all(color: rankBorder, width: 1.5),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: rankText,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name, Role tag & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        entry.role,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: roleText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Connections Score & Chevron
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.connections}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Encounters',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// POKÉBALL WATERMARK CUSTOM PAINTER
// -------------------------------------------------------------
class _PokeballWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.84, size.height * 0.22);
    final radius = size.width * 0.40;

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    // Outer circle
    canvas.drawCircle(center, radius, ringPaint);

    // Horizontal line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx - radius * 0.34, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.34, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );

    // Center button ring
    canvas.drawCircle(center, radius * 0.32, ringPaint);

    // Center inner dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.13, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// GOLD CROWN CUSTOM PAINTER FOR RANK #1
// -------------------------------------------------------------
class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.90);
    path.lineTo(size.width, size.height * 0.90);
    path.lineTo(size.width * 0.96, size.height * 0.24);
    path.lineTo(size.width * 0.72, size.height * 0.62);
    path.lineTo(size.width * 0.50, size.height * 0.04);
    path.lineTo(size.width * 0.28, size.height * 0.62);
    path.lineTo(size.width * 0.04, size.height * 0.24);
    path.close();

    canvas.drawPath(path, paint);

    // Jewel points on tips
    final dotPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.04, size.height * 0.24),
      2.0,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.04),
      2.5,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.96, size.height * 0.24),
      2.0,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
