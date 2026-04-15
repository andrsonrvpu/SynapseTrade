import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';

/// History screen — pulls real trade history from broker via backend.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];
  double _totalProfit = 0;
  double _winRate = 0;
  String _mode = 'demo';

  static const String _baseUrl = 'http://192.168.20.15:8000/api/v1';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final provider = context.read<AppProvider>();
    setState(() => _loading = true);

    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/history?limit=50'),
        headers: {
          'X-API-KEY': 'synapse-dev-key-2026',
          if (provider.metaApiToken.isNotEmpty) 'X-MetaApi-Token': provider.metaApiToken,
          if (provider.metaApiAccountId.isNotEmpty) 'X-Account-Id': provider.metaApiAccountId,
        },
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          _history = List<Map<String, dynamic>>.from(data['history'] ?? []);
          _totalProfit = (data['total_profit'] ?? 0).toDouble();
          _winRate = (data['win_rate'] ?? 0).toDouble();
          _mode = data['mode'] ?? 'demo';
          _loading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[History] Error: $e — using provider signals');
    }

    // Fallback: use signals from provider
    final signals = context.read<AppProvider>().signals;
    final closed = signals.where((s) => s.pnl != null).toList();
    final profit = closed.fold(0.0, (sum, s) => sum + (s.pnl ?? 0));
    final wins = closed.where((s) => (s.pnl ?? 0) > 0).length;
    setState(() {
      _history = closed.map((s) => {
        'id': s.id,
        'symbol': s.symbol,
        'type': s.direction,
        'profit': s.pnl ?? 0,
        'openPrice': s.entryPrice,
        'closePrice': s.takeProfit1,
        'volume': 0.1,
        'comment': s.pattern,
      }).toList();
      _totalProfit = profit;
      _winRate = closed.isNotEmpty ? wins / closed.length * 100 : 0;
      _mode = 'demo';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wins = _history.where((h) => (h['profit'] as num? ?? 0) > 0).length;
    final losses = _history.length - wins;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Header ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Historial', style: SynapseTheme.headline(fontSize: 28, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _mode == 'live' ? const Color(0xFFFF4C6E) : SynapseTheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _mode == 'live' ? 'Datos reales del broker' : 'Modo Demo',
                      style: SynapseTheme.label(fontSize: 13, color: SynapseTheme.onSurfaceVariant),
                    ),
                  ]),
                ]),
                GestureDetector(
                  onTap: _fetchHistory,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SynapseTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh, size: 18, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Stats Card ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildStatsCard(wins, losses),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── Trades List Header ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Operaciones', style: SynapseTheme.headline(fontSize: 18)),
              Text('${_history.length} registros',
                  style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.onSurfaceVariant)),
            ]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Content ──────────────────────────────────────────────────────────
        if (_loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_history.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history_edu_outlined, size: 52, color: SynapseTheme.onSurfaceVariant.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('Sin historial aún', style: SynapseTheme.headline(fontSize: 18, color: SynapseTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Ejecuta tu primera orden para verla aquí.',
                      style: SynapseTheme.label(color: SynapseTheme.onSurfaceVariant), textAlign: TextAlign.center),
                ]),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final h = _history[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTradeCard(h),
                  );
                },
                childCount: _history.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStatsCard(int wins, int losses) {
    final isProfit = _totalProfit >= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SynapseTheme.surfaceContainerLow.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(children: [
            // Total Profit
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('TOTAL P&L', style: SynapseTheme.label(fontSize: 11, letterSpacing: 1.5, color: SynapseTheme.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_totalProfit >= 0 ? SynapseTheme.primaryContainer : SynapseTheme.secondary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isProfit ? '▲ GANANCIA' : '▼ PÉRDIDA',
                  style: SynapseTheme.headline(fontSize: 10, letterSpacing: 1,
                      color: isProfit ? SynapseTheme.primaryContainer : SynapseTheme.secondary),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              '${isProfit ? '+' : ''}\$${_totalProfit.toStringAsFixed(2)}',
              style: SynapseTheme.headline(
                fontSize: 40,
                letterSpacing: -1,
                color: isProfit ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(children: [
              _statCell('WIN RATE', '${_winRate.toStringAsFixed(1)}%', SynapseTheme.primaryContainer),
              _vDivider(),
              _statCell('GANADORAS', '$wins', SynapseTheme.primaryContainer),
              _vDivider(),
              _statCell('PERDEDORAS', '$losses', SynapseTheme.secondary),
              _vDivider(),
              _statCell('TOTAL', '${_history.length}', Colors.white70),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(label, style: SynapseTheme.label(fontSize: 9, letterSpacing: 0.8, color: SynapseTheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Text(value, style: SynapseTheme.headline(fontSize: 16, color: color)),
    ]));
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.07));

  Widget _buildTradeCard(Map<String, dynamic> trade) {
    final profit = (trade['profit'] as num? ?? 0).toDouble();
    final isProfit = profit >= 0;
    final isBuy = (trade['type'] as String? ?? 'BUY').toUpperCase() == 'BUY';
    final symbol = trade['symbol'] as String? ?? '—';
    final volume = (trade['volume'] as num? ?? 0).toDouble();
    final openPrice = (trade['openPrice'] as num? ?? 0).toDouble();
    final closePrice = (trade['closePrice'] as num? ?? 0).toDouble();
    final comment = trade['comment'] as String? ?? '';

    return GlassCard(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Direction indicator
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isBuy
                  ? SynapseTheme.primaryContainer.withOpacity(0.12)
                  : SynapseTheme.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                isBuy ? Icons.trending_up : Icons.trending_down,
                color: isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(symbol, style: SynapseTheme.headline(fontSize: 16)),
              Text(
                '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                style: SynapseTheme.headline(
                  fontSize: 16,
                  color: isProfit ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                '${isBuy ? 'COMPRA' : 'VENTA'} · $volume lot',
                style: SynapseTheme.label(fontSize: 11, color: SynapseTheme.onSurfaceVariant),
              ),
              Text(
                '\$${openPrice.toStringAsFixed(openPrice < 10 ? 4 : 2)} → \$${closePrice.toStringAsFixed(closePrice < 10 ? 4 : 2)}',
                style: SynapseTheme.label(fontSize: 11, color: SynapseTheme.onSurfaceVariant),
              ),
            ]),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(comment, style: SynapseTheme.label(fontSize: 10, color: SynapseTheme.onSurfaceVariant.withOpacity(0.7)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ])),
        ]),
      ),
    );
  }
}
