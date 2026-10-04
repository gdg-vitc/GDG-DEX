import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/gdg_logo.dart';
import '../widgets/pokeball_icon.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  final List<Map<String, dynamic>> _trainers = const [
    {'rank': 1, 'name': 'Sagnik Ghosh', 'reg': '21BCE1042', 'captured': 48, 'score': 2400},
    {'rank': 2, 'name': 'Aditya Verma', 'reg': '22BCI0219', 'captured': 42, 'score': 2100},
    {'rank': 3, 'name': 'Riya Sharma', 'reg': '21BDS0084', 'captured': 39, 'score': 1950},
    {'rank': 4, 'name': 'Hardik Kumar', 'reg': '22BCE1590', 'captured': 35, 'score': 1750},
    {'rank': 5, 'name': 'Vatsan S', 'reg': '22BAI0401', 'captured': 31, 'score': 1550},
    {'rank': 6, 'name': 'Pooja Iyer', 'reg': '23BCE0912', 'captured': 27, 'score': 1350},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const GdgLogo(size: 24),
            const SizedBox(width: 8),
            Text(
              'Club Leaderboard',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _trainers.length,
        itemBuilder: (context, index) {
          final trainer = _trainers[index];
          final rank = trainer['rank'] as int;

          Color rankColor;
          Widget rankIcon;

          if (rank == 1) {
            rankColor = const Color(0xFFF59E0B); // Gold
            rankIcon = const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 22);
          } else if (rank == 2) {
            rankColor = const Color(0xFF94A3B8); // Silver
            rankIcon = const Icon(Icons.emoji_events, color: Color(0xFF94A3B8), size: 22);
          } else if (rank == 3) {
            rankColor = const Color(0xFFD97706); // Bronze
            rankIcon = const Icon(Icons.emoji_events, color: Color(0xFFD97706), size: 22);
          } else {
            rankColor = const Color(0xFF64748B);
            rankIcon = Text(
              '#$rank',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: rankColor,
                fontSize: 15,
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                width: rank <= 3 ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: rankIcon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer['name'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trainer['reg'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const PokeballIcon(size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${trainer['captured']}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
