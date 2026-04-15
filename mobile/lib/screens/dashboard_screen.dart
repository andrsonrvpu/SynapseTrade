import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/trading_view_widget.dart';

/// Home Dashboard — pixel-perfect from Stitch home_dashboard design.
/// AppBar with avatar + XAUUSD + live price, chart section,
/// IA Signal glass card, Equity/PnL/Margin, Market Performance.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final signal = provider.latestSignal;
    final btcPrice = provider.currentPrices['BTCUSD'] ?? 0.0;
    final xauPrice = provider.currentPrices['XAUUSD'] ?? 2034.42;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── AppBar ──
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          toolbarHeight: 80,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: SynapseTheme.primaryContainer.withOpacity(0.1),
                  blurRadius: 15,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SynapseTheme.primaryFixedDim.withOpacity(0.2),
                        ),
                        color: SynapseTheme.surfaceContainerHigh,
                      ),
                      child: ClipOval(
                        child: Icon(Icons.person, size: 24, color: SynapseTheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Symbol info
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'XAUUSD',
                          style: SynapseTheme.headline(
                            fontSize: 20,
                            color: SynapseTheme.primaryContainer,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'GOLD / US DOLLAR',
                          style: SynapseTheme.label(
                            fontSize: 10,
                            color: SynapseTheme.primaryFixedDim.withOpacity(0.8),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Price + Change
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              xauPrice.toStringAsFixed(2),
                              style: SynapseTheme.headline(
                                fontSize: 24,
                                color: SynapseTheme.primaryContainer,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: SynapseTheme.primaryContainer.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '+0.85%',
                                style: SynapseTheme.headline(
                                  fontSize: 11,
                                  color: SynapseTheme.primaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: Icon(Icons.settings, size: 20, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Body ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              // ── Live TradingView Chart ──
              TradingViewWidget(
                symbol: provider.selectedSymbol,
                timeframe: '60',
                height: 380,
              ),
              const SizedBox(height: 16),
              // ── IA Signal Card ──
              _buildSignalCard(signal),
              const SizedBox(height: 16),
              // ── Balance Cards ──
              _buildBalanceSection(),
              const SizedBox(height: 24),
              // ── Market Performance Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Market Performance', style: SynapseTheme.headline(fontSize: 18)),
                  Text('View All', style: SynapseTheme.headline(fontSize: 13, color: SynapseTheme.primaryContainer)),
                ],
              ),
              const SizedBox(height: 12),
              // ── Resistance / Support Grid ──
              _buildMarketGrid(),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Stack(
        children: [
          // Chart placeholder with gradient
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SynapseTheme.surfaceContainerLow,
                      SynapseTheme.surfaceContainerLow.withOpacity(0.8),
                    ],
                  ),
                ),
                child: CustomPaint(painter: _ChartLinesPainter()),
              ),
            ),
          ),
          // ── Timeframe pills ──
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SynapseTheme.surfaceContainerHigh.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('H4', style: SynapseTheme.headline(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SynapseTheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SynapseTheme.primaryContainer.withOpacity(0.2)),
                  ),
                  child: Text(
                    'REAL TIME',
                    style: SynapseTheme.headline(fontSize: 12, color: SynapseTheme.primaryContainer),
                  ),
                ),
              ],
            ),
          ),
          // ── Live Price Pointer ──
          Positioned(
            right: 0,
            top: 160,
            child: Row(
              children: [
                // Dashed line
                Container(
                  width: 300,
                  height: 1,
                  color: SynapseTheme.primaryContainer.withOpacity(0.15),
                ),
                // Price label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SynapseTheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SynapseTheme.primaryContainer.withOpacity(0.5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Text(
                    '2,034.42',
                    style: SynapseTheme.headline(fontSize: 12, color: SynapseTheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
          // ── Glow dot ──
          Positioned(
            right: 88,
            top: 157,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: SynapseTheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: SynapseTheme.primaryContainer, blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard(dynamic signal) {
    final isBuy = signal == null || (signal?.direction.toLowerCase() ?? 'buy') == 'buy';
    return GlassCard(
      borderRadius: 24,
      child: Stack(
        children: [
          // Decorative glow
          Positioned(
            right: -48,
            top: -48,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SynapseTheme.primaryContainer.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: SynapseTheme.primaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'IA SIGNAL',
                        style: SynapseTheme.headline(
                          fontSize: 12,
                          color: SynapseTheme.onSurfaceVariant,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    signal != null ? 'Calculated 2m ago' : 'Awaiting analysis',
                    style: SynapseTheme.label(
                      fontSize: 12,
                      color: SynapseTheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBuy ? 'COMPRA' : 'VENTA',
                        style: SynapseTheme.headline(
                          fontSize: 36,
                          color: SynapseTheme.primaryContainer,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommended entry: 2,031.10',
                        style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        signal != null ? '${signal.confidence.toInt()}%' : '88%',
                        style: SynapseTheme.headline(
                          fontSize: 36,
                          color: SynapseTheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'CONFIDENCE',
                        style: SynapseTheme.headline(
                          fontSize: 10,
                          color: SynapseTheme.onSurfaceVariant,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Column(
      children: [
        // Equity
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SynapseTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EQUITY', style: SynapseTheme.headline(fontSize: 12, color: SynapseTheme.onSurfaceVariant, letterSpacing: 3)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: '14,240.50 ', style: SynapseTheme.headline(fontSize: 24, letterSpacing: -1)),
                  TextSpan(text: 'USD', style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.onSurfaceVariant)),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Total PnL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SynapseTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border(left: BorderSide(width: 4, color: SynapseTheme.primaryContainer)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL PNL', style: SynapseTheme.headline(fontSize: 12, color: SynapseTheme.onSurfaceVariant, letterSpacing: 3)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: '+1,240.50 ', style: SynapseTheme.headline(fontSize: 24, color: SynapseTheme.primaryContainer, letterSpacing: -1)),
                  TextSpan(text: 'USD', style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.primaryContainer.withOpacity(0.7))),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Margin
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SynapseTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MARGIN', style: SynapseTheme.headline(fontSize: 12, color: SynapseTheme.onSurfaceVariant, letterSpacing: 3)),
              const SizedBox(height: 4),
              Text('25.40%', style: SynapseTheme.headline(fontSize: 24, letterSpacing: -1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketGrid() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SynapseTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.trending_up, color: SynapseTheme.onSurfaceVariant),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2,045.10', style: SynapseTheme.headline(fontSize: 20)),
                    Text('RESISTANCE 1', style: SynapseTheme.headline(fontSize: 10, color: SynapseTheme.onSurfaceVariant, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SynapseTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.trending_down, color: SynapseTheme.onSurfaceVariant),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2,028.15', style: SynapseTheme.headline(fontSize: 20, color: SynapseTheme.secondary)),
                    Text('SUPPORT 1', style: SynapseTheme.headline(fontSize: 10, color: SynapseTheme.onSurfaceVariant, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple chart lines painter for background decoration
class _ChartLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SynapseTheme.onSurfaceVariant.withOpacity(0.08)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // A simulated price line
    final linePaint = Paint()
      ..color = SynapseTheme.primaryContainer.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.cubicTo(
      size.width * 0.15, size.height * 0.55,
      size.width * 0.25, size.height * 0.65,
      size.width * 0.35, size.height * 0.5,
    );
    path.cubicTo(
      size.width * 0.45, size.height * 0.35,
      size.width * 0.55, size.height * 0.45,
      size.width * 0.65, size.height * 0.38,
    );
    path.cubicTo(
      size.width * 0.75, size.height * 0.32,
      size.width * 0.85, size.height * 0.42,
      size.width, size.height * 0.42,
    );
    canvas.drawPath(path, linePaint);

    // Fill under line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          SynapseTheme.primaryContainer.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
