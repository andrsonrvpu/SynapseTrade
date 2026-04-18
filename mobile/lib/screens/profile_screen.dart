import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';

/// Profile screen — reads real Firebase user data, shows real P&L from AppProvider.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _firestoreProfile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthService>();
    final profile = await auth.getUserProfile();
    if (mounted) {
      setState(() {
        _firestoreProfile = profile;
        _loadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final user = FirebaseAuth.instance.currentUser;
    final provider = context.watch<AppProvider>();

    final displayName = user?.displayName ?? _firestoreProfile?['displayName'] ?? 'Trader';
    final email = user?.email ?? '';
    final photoURL = user?.photoURL;
    final plan = _firestoreProfile?['plan'] ?? 'free';
    final isPremium = plan != 'free';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: topPad + 24),

          // ── Profile Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildProfileHeader(displayName, email, photoURL, isPremium),
          ),
          const SizedBox(height: 32),

          // ── Metrics from real provider ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildBentoGrid(provider),
          ),
          const SizedBox(height: 32),

          // ── Achievements ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildAchievements(),
          ),
          const SizedBox(height: 32),

          // ── Account info ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildAccountInfo(user, _firestoreProfile),
          ),
          const SizedBox(height: 24),

          // ── Logout ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildLogoutButton(context),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String name, String email, String? photoURL, bool isPremium) {
    return Column(children: [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Glow
          Container(
            width: 108, height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SynapseTheme.primaryContainer.withOpacity(0.35),
                  blurRadius: 28, spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Avatar ring
          Container(
            width: 100, height: 100,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF00E5B4), Color(0xFF0A2A2A)],
              ),
            ),
            child: ClipOval(
              child: photoURL != null
                  ? Image.network(photoURL, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar())
                  : _defaultAvatar(),
            ),
          ),
          // Badge
          if (isPremium)
            Positioned(
              bottom: -14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: SynapseTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(
                    color: SynapseTheme.primaryContainer.withOpacity(0.55),
                    blurRadius: 12,
                  )],
                ),
                child: Text('PREMIUM',
                  style: SynapseTheme.headline(
                    fontSize: 10, color: SynapseTheme.onPrimary, letterSpacing: 2.5),
                ),
              ),
            ),
          if (!isPremium)
            Positioned(
              bottom: -14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: SynapseTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text('FREE PLAN',
                  style: SynapseTheme.headline(
                    fontSize: 10, color: SynapseTheme.onSurfaceVariant, letterSpacing: 2.5),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 32),
      Text(name, style: SynapseTheme.headline(fontSize: 28, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text(email, style: SynapseTheme.label(fontSize: 13, color: SynapseTheme.onSurfaceVariant)),
    ]);
  }

  Widget _defaultAvatar() => Container(
    color: SynapseTheme.surfaceContainerHigh,
    child: Icon(Icons.person, size: 52, color: SynapseTheme.onSurfaceVariant),
  );

  Widget _buildBentoGrid(AppProvider provider) {
    final accountInfo = provider.accountInfo;
    final balance = (accountInfo['balance'] as num? ?? 0).toDouble();
    final profit = (accountInfo['profit'] as num? ?? 0).toDouble();
    final winRate = provider.signals.isNotEmpty
        ? provider.signals.where((s) => (s.pnl ?? 0) > 0).length /
            provider.signals.length * 100
        : 0.0;
    final isProfit = profit >= 0;

    return Column(children: [
      // Total P&L
      GlassCard(
        borderRadius: 28,
        child: SizedBox(
          height: 128,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('TOTAL P&L',
                  style: SynapseTheme.label(fontSize: 12, letterSpacing: 2, color: SynapseTheme.onSurfaceVariant)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isProfit ? SynapseTheme.primaryContainer : SynapseTheme.secondary).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isProfit ? Icons.trending_up : Icons.trending_down,
                    color: isProfit ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                    size: 18,
                  ),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                  style: SynapseTheme.headline(
                    fontSize: 36,
                    color: isProfit ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: \$${balance.toStringAsFixed(2)}',
                  style: SynapseTheme.label(
                    fontSize: 11,
                    color: SynapseTheme.onSurfaceVariant,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: GlassCard(
          borderRadius: 28,
          child: SizedBox(height: 116, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WIN RATE',
                style: SynapseTheme.label(fontSize: 11, letterSpacing: 1.5, color: SynapseTheme.onSurfaceVariant)),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('${winRate.toStringAsFixed(0)}',
                  style: SynapseTheme.headline(fontSize: 32)),
                const SizedBox(width: 4),
                Text('%',
                  style: SynapseTheme.headline(fontSize: 16, color: SynapseTheme.primaryContainer)),
              ]),
            ],
          )),
        )),
        const SizedBox(width: 12),
        Expanded(child: GlassCard(
          borderRadius: 28,
          borderColor: Colors.white.withOpacity(0.05),
          child: SizedBox(height: 116, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MODO BROKER',
                style: SynapseTheme.label(fontSize: 11, letterSpacing: 1.5, color: SynapseTheme.onSurfaceVariant)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  provider.brokerConnected
                    ? (accountInfo['mode'] == 'live' ? 'REAL' : 'DEMO')
                    : 'Sin broker',
                  style: SynapseTheme.headline(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.brokerConnected
                        ? (accountInfo['mode'] == 'live'
                            ? const Color(0xFFFF4C6E)
                            : SynapseTheme.primaryContainer)
                        : Colors.grey,
                    boxShadow: [BoxShadow(
                      color: (provider.brokerConnected ? SynapseTheme.primaryContainer : Colors.grey).withOpacity(0.5),
                      blurRadius: 8,
                    )],
                  ),
                ),
              ]),
            ],
          )),
        )),
      ]),
    ]);
  }

  Widget _buildAchievements() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Logros', style: SynapseTheme.headline(fontSize: 18)),
        Text('Ver todos', style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.primaryContainer)),
      ]),
      const SizedBox(height: 16),
      SizedBox(
        height: 126,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _achievementCard(Icons.workspace_premium, 'Top Analyst', SynapseTheme.primaryContainer),
          const SizedBox(width: 12),
          _achievementCard(Icons.bolt, 'Fast Executor', const Color(0xFF7B8FF5)),
          const SizedBox(width: 12),
          _achievementCard(Icons.military_tech, 'Bull Market\nKing', SynapseTheme.secondary),
          const SizedBox(width: 12),
          _achievementCard(Icons.auto_graph, 'Streak Pro', const Color(0xFFF5A623)),
        ]),
      ),
    ]);
  }

  Widget _achievementCard(IconData icon, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: SizedBox(width: 96, child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.25)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center,
            style: SynapseTheme.headline(fontSize: 11),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      )),
    );
  }

  Widget _buildAccountInfo(User? user, Map<String, dynamic>? profile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SynapseTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CUENTA',
            style: SynapseTheme.label(fontSize: 11, letterSpacing: 2, color: SynapseTheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          _infoRow(Icons.email_outlined, 'Correo', user?.email ?? '—'),
          _dividerLine(),
          _infoRow(Icons.verified_user_outlined, 'UID',
            user?.uid.substring(0, 12) ?? '—', small: true),
          _dividerLine(),
          _infoRow(Icons.security, 'Auth',
            user?.providerData.isNotEmpty == true
                ? user!.providerData.first.providerId
                : '—'),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool small = false}) {
    return Row(children: [
      Icon(icon, size: 18, color: SynapseTheme.onSurfaceVariant),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: SynapseTheme.label(fontSize: 10, color: SynapseTheme.onSurfaceVariant, letterSpacing: 0.5)),
        Text(value, style: SynapseTheme.label(fontSize: small ? 11 : 13, color: SynapseTheme.onSurface),
          overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  Widget _dividerLine() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(color: Colors.white.withOpacity(0.06), height: 1),
  );

  Widget _buildLogoutButton(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      borderColor: SynapseTheme.secondary.withOpacity(0.15),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: SynapseTheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Cerrar sesión', style: SynapseTheme.headline(fontSize: 18)),
            content: Text('¿Estás seguro que deseas salir?',
              style: SynapseTheme.label(color: SynapseTheme.onSurfaceVariant)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar', style: SynapseTheme.label(color: SynapseTheme.primaryContainer)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Salir', style: SynapseTheme.label(color: SynapseTheme.secondary)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await context.read<AuthService>().signOut();
          // FirebaseAuth stream will redirect to login automatically
        }
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.logout_rounded, size: 20, color: SynapseTheme.secondary),
        const SizedBox(width: 10),
        Text('Cerrar Sesión',
          style: SynapseTheme.headline(fontSize: 16, color: SynapseTheme.secondary)),
      ]),
    );
  }
}
