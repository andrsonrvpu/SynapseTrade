import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';

/// History screen — Stitch historial_de_señales design.
/// Stats card with Win Rate, Total Signals, Profit Streak.
/// Scrollable feed of past signal cards with sparklines.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // ── Stats Section ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildStatsCard(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        // ── List Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signal Stream', style: SynapseTheme.headline(fontSize: 24, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Real-time performance audit', style: SynapseTheme.label(fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    _iconButton(Icons.filter_list),
                    const SizedBox(width: 8),
                    _iconButton(Icons.search),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // ── Signal Cards ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSignalCard(
                symbol: 'XAUUSD',
                time: 'Closed 14m ago',
                isBuy: true,
                pnl: '+ \$2,450.00',
                entryPrice: '2345.12',
                exitPrice: '2358.45',
                icon: Icons.monetization_on,
                sparklineValues: [0.3, 0.45, 0.4, 0.6, 0.55, 0.85, 1.0],
              ),
              const SizedBox(height: 16),
              _buildSignalCard(
                symbol: 'BTCUSD',
                time: 'Closed 2h ago',
                isBuy: false,
                pnl: '- \$420.15',
                entryPrice: '64,210.00',
                exitPrice: '64,325.50',
                icon: Icons.attach_money,
                sparklineValues: [0.8, 0.7, 0.6, 0.5, 0.3, 0.2, 0.1],
              ),
              const SizedBox(height: 16),
              _buildSignalCard(
                symbol: 'XAUUSD',
                time: 'Closed 5h ago',
                isBuy: true,
                pnl: '+ \$842.20',
                entryPrice: '2321.10',
                exitPrice: '2330.05',
                icon: Icons.layers,
                sparklineValues: [0.1, 0.15, 0.3, 0.25, 0.5, 0.65, 0.8],
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Decorative glow
          Positioned(
            right: -96,
            top: -96,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SynapseTheme.primaryContainer.withOpacity(0.1),
              ),
            ),
          ),
          Row(
            children: [
              // Win Rate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WIN RATE', style: SynapseTheme.label(fontSize: 11, letterSpacing: 3)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('78%', style: SynapseTheme.headline(fontSize: 48, color: SynapseTheme.primaryContainer, letterSpacing: -2)),
                        const SizedBox(width: 8),
                        Icon(Icons.trending_up, color: SynapseTheme.primaryContainer, size: 24),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Total + Streak
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL SIGNALS', style: SynapseTheme.label(fontSize: 11, letterSpacing: 3)),
                  const SizedBox(height: 8),
                  Text('1,248', style: SynapseTheme.headline(fontSize: 36)),
                  const SizedBox(height: 16),
                  Text('PROFIT STREAK', style: SynapseTheme.label(fontSize: 11, letterSpacing: 3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('12', style: SynapseTheme.headline(fontSize: 36)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: SynapseTheme.primaryContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: SynapseTheme.primaryContainer.withOpacity(0.2)),
                        ),
                        child: Text(
                          'NEW HIGH',
                          style: SynapseTheme.headline(fontSize: 10, color: SynapseTheme.primaryContainer, letterSpacing: -0.5),
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

  Widget _buildSignalCard({
    required String symbol,
    required String time,
    required bool isBuy,
    required String pnl,
    required String entryPrice,
    required String exitPrice,
    required IconData icon,
    required List<double> sparklineValues,
  }) {
    final accentColor = isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondaryContainer;
    final textColor = isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondary;

    return GlassCard(
      glowColor: isBuy ? SynapseTheme.primaryContainer : null,
      borderColor: isBuy ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.2)),
                    ),
                    child: Icon(icon, color: textColor),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(symbol, style: SynapseTheme.headline(fontSize: 18)),
                      Text(time, style: SynapseTheme.label(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isBuy ? 'BUY' : 'SELL',
                      style: SynapseTheme.headline(
                        fontSize: 10,
                        color: isBuy ? SynapseTheme.onPrimary : Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(pnl, style: SynapseTheme.headline(fontSize: 20, color: textColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom: Entry, Sparkline, Exit
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ENTRY PRICE', style: SynapseTheme.label(fontSize: 10, letterSpacing: 3)),
                  const SizedBox(height: 4),
                  Text(entryPrice, style: SynapseTheme.headline(fontSize: 14)),
                ],
              ),
              const SizedBox(width: 16),
              // Sparkline
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: sparklineValues.asMap().entries.map((e) {
                      final opacity = 0.1 + (e.value * 0.9);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: 48 * e.value,
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(opacity),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('EXIT PRICE', style: SynapseTheme.label(fontSize: 10, letterSpacing: 3)),
                  const SizedBox(height: 4),
                  Text(exitPrice, style: SynapseTheme.headline(fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Icon(icon, size: 18, color: SynapseTheme.onSurfaceVariant),
    );
  }
}
