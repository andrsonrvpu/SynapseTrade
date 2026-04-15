import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/synapse_theme.dart';

/// Splash / Login screen — "The Kinetic Observatory" entrance.
/// Kinetic aura (green + gold radial gradients), glassmorphic logo panel,
/// Google + Institutional ID glass buttons.
class SplashScreen extends StatelessWidget {
  final VoidCallback onLogin;

  const SplashScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── Kinetic Aura Background ──
          Positioned.fill(
            child: CustomPaint(painter: _KineticAuraPainter()),
          ),
          // ── Film Grain Overlay (subtle) ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          // ── Main Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Top Security Badge ──
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 14, color: SynapseTheme.onSurfaceVariant.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text(
                        'QUANTUM ENCRYPTED ENVIRONMENT',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3,
                          color: SynapseTheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Center: Logo ──
                const Spacer(),
                _buildLogoSection(),
                const SizedBox(height: 32),
                // ── Tagline ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'The intelligence layer for elite market navigation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: SynapseTheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Dots ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(SynapseTheme.primaryContainer, pulse: true),
                    const SizedBox(width: 6),
                    _dot(SynapseTheme.surfaceContainerHighest),
                    const SizedBox(width: 6),
                    _dot(SynapseTheme.surfaceContainerHighest),
                  ],
                ),
                const Spacer(),
                // ── Bottom: Glass Buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _glassButton(
                        onTap: onLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.network(
                                'https://www.google.com/favicon.ico',
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: SynapseTheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _glassButton(
                        onTap: onLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.mail_outline, size: 20, color: SynapseTheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Access via Institutional ID',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: SynapseTheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // ── Invitation prompt ──
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                            color: SynapseTheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          children: [
                            const TextSpan(text: 'NEW PARTNERSHIPS REQUIRE '),
                            TextSpan(
                              text: 'INVITATION CODES',
                              style: TextStyle(color: SynapseTheme.primaryFixedDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // ── Bottom line gradient ──
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        SynapseTheme.primaryContainer.withOpacity(0.2),
                        Colors.transparent,
                      ],
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

  Widget _buildLogoSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Decorative blurs ──
        Positioned(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SynapseTheme.primaryContainer.withOpacity(0.05),
              boxShadow: [
                BoxShadow(
                  color: SynapseTheme.primaryContainer.withOpacity(0.05),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SynapseTheme.gold.withOpacity(0.05),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        // ── Glass Logo Container ──
        Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon with gold dot ──
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00FF88), Color(0xFF60FF99)],
                        ).createShader(bounds),
                        child: const Icon(Icons.show_chart, size: 60, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: SynapseTheme.gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SynapseTheme.gold,
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── "Synapse" gold gradient ──
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFF9F295), Color(0xFFD4AF37)],
                ).createShader(bounds),
                child: Text(
                  'Synapse',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
              ),
              // ── "Trade" green gradient ──
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF00FF88), Color(0xFF60FF99)],
                ).createShader(bounds),
                child: Text(
                  'Trade',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 0.85,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glassButton({required VoidCallback onTap, required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _dot(Color color, {bool pulse = false}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _KineticAuraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Green aura at top-left
    final greenPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.4),
        radius: 0.8,
        colors: [
          const Color(0xFF00FF88).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), greenPaint);

    // Gold aura at bottom-right
    final goldPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.6, 0.4),
        radius: 0.8,
        colors: [
          const Color(0xFFD4AF37).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
