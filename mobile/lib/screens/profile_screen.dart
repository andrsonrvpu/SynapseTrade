import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';

/// Profile screen — Stitch perfil_de_usuario design.
/// Avatar with gradient border + Premium badge, bento metrics grid,
/// achievements carousel, logout glass button.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          // ── Profile Header ──
          _buildProfileHeader(),
          const SizedBox(height: 32),
          // ── Metrics Bento Grid ──
          _buildBentoGrid(),
          const SizedBox(height: 32),
          // ── Achievements ──
          _buildAchievements(),
          const SizedBox(height: 32),
          // ── Logout ──
          _buildLogoutButton(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [SynapseTheme.primaryContainer, SynapseTheme.surfaceContainerHigh],
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
              ),
              child: ClipOval(
                child: Container(
                  color: SynapseTheme.surfaceContainerHigh,
                  child: Icon(Icons.person, size: 48, color: SynapseTheme.onSurfaceVariant),
                ),
              ),
            ),
            // Premium badge
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: SynapseTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(color: SynapseTheme.primaryContainer.withOpacity(0.5), blurRadius: 10)],
                ),
                child: Text(
                  'PREMIUM',
                  style: SynapseTheme.headline(fontSize: 10, color: SynapseTheme.onPrimary, letterSpacing: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Alex Rivera', style: SynapseTheme.headline(fontSize: 30, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Tier 4 • Global Rank #412', style: SynapseTheme.label(fontSize: 14)),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        // Total Profit (full width)
        GlassCard(
          borderRadius: 32,
          child: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL PROFIT', style: SynapseTheme.label(fontSize: 12, letterSpacing: 2)),
                    Icon(Icons.trending_up, color: SynapseTheme.primaryContainer),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$15,420.88', style: SynapseTheme.headline(fontSize: 36, color: SynapseTheme.primaryContainer, letterSpacing: -1)),
                    const SizedBox(height: 4),
                    Text('+12.4% this month', style: SynapseTheme.label(fontSize: 10, color: SynapseTheme.primaryContainer.withOpacity(0.6))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Row: Streak + Tier
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: 32,
                child: SizedBox(
                  height: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CURRENT STREAK', style: SynapseTheme.label(fontSize: 12, letterSpacing: 2)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('5', style: SynapseTheme.headline(fontSize: 30)),
                          const SizedBox(width: 8),
                          Text('WINS', style: SynapseTheme.headline(fontSize: 14, color: SynapseTheme.primaryContainer)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                borderRadius: 32,
                borderColor: Colors.white.withOpacity(0.05),
                child: SizedBox(
                  height: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ACCOUNT TIER', style: SynapseTheme.label(fontSize: 12, letterSpacing: 2)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Executive', style: SynapseTheme.headline(fontSize: 20)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: 0.75,
                              backgroundColor: SynapseTheme.surfaceContainerHighest,
                              color: SynapseTheme.primaryContainer,
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Achievements', style: SynapseTheme.headline(fontSize: 18)),
            Text('View All', style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.primaryContainer)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _achievementCard(Icons.workspace_premium, 'Top Analyst', SynapseTheme.primaryContainer),
              const SizedBox(width: 12),
              _achievementCard(Icons.bolt, 'Fast Executor', SynapseTheme.tertiaryFixedDim),
              const SizedBox(width: 12),
              _achievementCard(Icons.military_tech, 'Bull Market\nKing', SynapseTheme.secondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _achievementCard(IconData icon, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: SynapseTheme.headline(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GlassCard(
      borderRadius: 16,
      borderColor: SynapseTheme.secondary.withOpacity(0.1),
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 20, color: SynapseTheme.secondary),
          const SizedBox(width: 8),
          Text('Logout Account', style: SynapseTheme.headline(fontSize: 16, color: SynapseTheme.secondary)),
        ],
      ),
    );
  }
}
