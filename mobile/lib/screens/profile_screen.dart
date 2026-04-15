import 'package:flutter/material.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';

/// Profile screen — Premium user profile with proper SafeArea.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Safe header area (avoids status bar) ──
          SizedBox(height: topPad + 24),

          // ── Profile Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildProfileHeader(),
          ),
          const SizedBox(height: 32),

          // ── Metrics Bento Grid ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildBentoGrid(),
          ),
          const SizedBox(height: 32),

          // ── Achievements ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildAchievements(),
          ),
          const SizedBox(height: 32),

          // ── Logout ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildLogoutButton(),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar with glow ring + Premium badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Outer glow
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5B4).withOpacity(0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Gradient ring
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00E5B4), Color(0xFF0A2A2A)],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: SynapseTheme.surfaceContainerHigh,
                  child: Icon(
                    Icons.person,
                    size: 52,
                    color: SynapseTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            // Premium badge — positioned below avatar with enough space
            Positioned(
              bottom: -14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: SynapseTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: SynapseTheme.primaryContainer.withOpacity(0.55),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  'PREMIUM',
                  style: SynapseTheme.headline(
                    fontSize: 10,
                    color: SynapseTheme.onPrimary,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Space for the badge that sticks out below
        const SizedBox(height: 32),

        Text(
          'Alex Rivera',
          style: SynapseTheme.headline(fontSize: 30, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Tier 4  •  Global Rank #412',
          style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        // Total Profit (full width)
        GlassCard(
          borderRadius: 28,
          child: SizedBox(
            height: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL PROFIT',
                      style: SynapseTheme.label(fontSize: 12, letterSpacing: 2, color: SynapseTheme.onSurfaceVariant),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SynapseTheme.primaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.trending_up, color: SynapseTheme.primaryContainer, size: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$15,420.88',
                      style: SynapseTheme.headline(
                        fontSize: 36,
                        color: SynapseTheme.primaryContainer,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+12.4% this month',
                      style: SynapseTheme.label(
                        fontSize: 11,
                        color: SynapseTheme.primaryContainer.withOpacity(0.65),
                      ),
                    ),
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
                borderRadius: 28,
                child: SizedBox(
                  height: 116,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT STREAK',
                        style: SynapseTheme.label(fontSize: 11, letterSpacing: 1.5, color: SynapseTheme.onSurfaceVariant),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('5', style: SynapseTheme.headline(fontSize: 32)),
                          const SizedBox(width: 6),
                          Text(
                            'WINS',
                            style: SynapseTheme.headline(fontSize: 14, color: SynapseTheme.primaryContainer),
                          ),
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
                borderRadius: 28,
                borderColor: Colors.white.withOpacity(0.05),
                child: SizedBox(
                  height: 116,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACCOUNT TIER',
                        style: SynapseTheme.label(fontSize: 11, letterSpacing: 1.5, color: SynapseTheme.onSurfaceVariant),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Executive', style: SynapseTheme.headline(fontSize: 20)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: 0.75,
                              backgroundColor: SynapseTheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(SynapseTheme.primaryContainer),
                              minHeight: 5,
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
            Text(
              'View All',
              style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.primaryContainer),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 126,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _achievementCard(Icons.workspace_premium, 'Top Analyst', SynapseTheme.primaryContainer),
              const SizedBox(width: 12),
              _achievementCard(Icons.bolt, 'Fast Executor', const Color(0xFF7B8FF5)),
              const SizedBox(width: 12),
              _achievementCard(Icons.military_tech, 'Bull Market\nKing', SynapseTheme.secondary),
              const SizedBox(width: 12),
              _achievementCard(Icons.auto_graph, 'Streak Pro', const Color(0xFFF5A623)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _achievementCard(IconData icon, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.25)),
                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: SynapseTheme.headline(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GlassCard(
      borderRadius: 18,
      borderColor: SynapseTheme.secondary.withOpacity(0.15),
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 20, color: SynapseTheme.secondary),
          const SizedBox(width: 10),
          Text(
            'Logout Account',
            style: SynapseTheme.headline(fontSize: 16, color: SynapseTheme.secondary),
          ),
        ],
      ),
    );
  }
}
