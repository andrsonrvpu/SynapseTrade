import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/broker_service.dart';
import '../theme/synapse_theme.dart';
import '../widgets/trading_view_widget.dart';

/// Signal Analysis screen — TradingView chart + IA analysis + trade execution.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> with SingleTickerProviderStateMixin {
  double _riskPercent = 1.0;
  bool _isExecuting = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _executeOrder(bool isBuy) async {
    final provider = context.read<AppProvider>();
    final signal = provider.latestSignal;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildConfirmDialog(ctx, isBuy, signal),
    );

    if (confirmed != true) return;

    setState(() => _isExecuting = true);

    try {
      final result = await provider.executeTrade(
        direction: isBuy ? TradeDirection.buy : TradeDirection.sell,
        symbol: signal?.symbol ?? provider.selectedSymbol,
        stopLoss: signal?.stopLoss ?? 0,
        takeProfit1: signal?.takeProfit1 ?? 0,
        takeProfit2: signal?.takeProfit2,
        riskPercent: _riskPercent,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: result.success
              ? (isBuy ? SynapseTheme.onPrimaryContainer : SynapseTheme.secondaryContainer)
              : Colors.red[900],
          content: Row(
            children: [
              Icon(result.success ? Icons.check_circle : Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.success
                      ? '${isBuy ? "✅ COMPRA" : "🔴 VENTA"} ejecutada — Ticket #${result.orderId}'
                      : '❌ Error: ${result.message}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  Widget _buildConfirmDialog(BuildContext ctx, bool isBuy, TradeSignal? signal) {
    final color = isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondaryContainer;
    return AlertDialog(
      backgroundColor: SynapseTheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        Icon(isBuy ? Icons.trending_up : Icons.trending_down, color: color),
        const SizedBox(width: 12),
        Text(isBuy ? 'Confirmar COMPRA' : 'Confirmar VENTA',
            style: SynapseTheme.headline(fontSize: 20)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('Símbolo', signal?.symbol ?? 'XAUUSD'),
        _row('Dirección', isBuy ? '🟢 COMPRA' : '🔴 VENTA'),
        _row('Precio entrada', signal?.entryPrice.toStringAsFixed(2) ?? '—'),
        _row('Stop Loss', signal?.stopLoss.toStringAsFixed(2) ?? '—'),
        _row('Take Profit 1', signal?.takeProfit1.toStringAsFixed(2) ?? '—'),
        _row('Take Profit 2', signal?.takeProfit2.toStringAsFixed(2) ?? '—'),
        _row('Riesgo', '${_riskPercent.toStringAsFixed(0)}%'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Esta orden se ejecutará en tu broker conectado con dinero real.',
                style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.onSurface),
              ),
            ),
          ]),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancelar', style: SynapseTheme.label(color: SynapseTheme.onSurfaceVariant)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(isBuy ? 'CONFIRMAR COMPRA' : 'CONFIRMAR VENTA',
              style: SynapseTheme.headline(fontSize: 14, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: SynapseTheme.label(color: SynapseTheme.onSurfaceVariant)),
      Text(value, style: SynapseTheme.headline(fontSize: 14)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final signal = provider.latestSignal;
    final isBuy = signal?.isBuy ?? true;
    final symbol = signal?.symbol ?? provider.selectedSymbol;
    final entryPrice = signal?.entryPrice ?? 0.0;
    final stopLoss = signal?.stopLoss ?? 0.0;
    final tp1 = signal?.takeProfit1 ?? 0.0;
    final tp2 = signal?.takeProfit2 ?? 0.0;
    final confidence = signal?.confidence.round() ?? 92;

    return Scaffold(
      backgroundColor: SynapseTheme.surface,
      body: Stack(
        children: [
          // ── Main scrollable content ──
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ════════════════════════════════════════
                  //  1. LIVE TRADING VIEW CHART
                  // ════════════════════════════════════════
                  _buildChartSection(symbol, provider),

                  const SizedBox(height: 16),

                  // ════════════════════════════════════════
                  //  2. ANALIZAR CON IA BUTTON
                  // ════════════════════════════════════════
                  _buildAnalyzeButton(provider),

                  const SizedBox(height: 20),

                  // ════════════════════════════════════════
                  //  3. SIGNAL CARD (if signal exists)
                  // ════════════════════════════════════════
                  _buildSignalSection(signal, isBuy, symbol, entryPrice, stopLoss, tp1, tp2, confidence),

                  const SizedBox(height: 20),

                  // ════════════════════════════════════════
                  //  4. RISK MANAGEMENT
                  // ════════════════════════════════════════
                  _buildRiskSection(),

                  const SizedBox(height: 20),

                  // ════════════════════════════════════════
                  //  5. EXECUTE TRADE BUTTONS
                  // ════════════════════════════════════════
                  _buildTradeButtons(isBuy, signal),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ── Executing overlay ──
          if (_isExecuting) _buildExecutingOverlay(isBuy),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  CHART SECTION — TradingView embed
  // ═══════════════════════════════════════════
  Widget _buildChartSection(String symbol, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symbol selector row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.candlestick_chart, color: SynapseTheme.primaryContainer, size: 20),
              const SizedBox(width: 8),
              Text(symbol, style: SynapseTheme.headline(fontSize: 20, color: SynapseTheme.primaryContainer)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SynapseTheme.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('LIVE', style: SynapseTheme.headline(fontSize: 10, color: SynapseTheme.primaryContainer, letterSpacing: 2)),
              ),
            ]),
            // Timeframe chips
            Row(children: [
              _timeframeChip('M5', provider),
              const SizedBox(width: 4),
              _timeframeChip('M15', provider),
              const SizedBox(width: 4),
              _timeframeChip('H1', provider),
              const SizedBox(width: 4),
              _timeframeChip('H4', provider),
            ]),
          ],
        ),
        const SizedBox(height: 12),
        // TradingView chart
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TradingViewWidget(
            symbol: symbol,
            timeframe: _mapTimeframe(provider.selectedTimeframe),
            height: 340,
          ),
        ),
      ],
    );
  }

  Widget _timeframeChip(String tf, AppProvider provider) {
    final isSelected = provider.selectedTimeframe == tf;
    return GestureDetector(
      onTap: () => provider.setTimeframe(tf),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? SynapseTheme.primaryContainer.withOpacity(0.15)
              : SynapseTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? SynapseTheme.primaryContainer.withOpacity(0.4)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Text(tf, style: SynapseTheme.headline(
          fontSize: 11,
          color: isSelected ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant,
          letterSpacing: 1,
        )),
      ),
    );
  }

  String _mapTimeframe(String tf) {
    const map = {'M1': '1', 'M5': '5', 'M15': '15', 'H1': '60', 'H4': '240', 'D1': 'D', '01H': '60'};
    return map[tf] ?? '60';
  }

  // ═══════════════════════════════════════════
  //  ANALYZE WITH IA BUTTON
  // ═══════════════════════════════════════════
  Widget _buildAnalyzeButton(AppProvider provider) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = 0.1 + _pulseController.value * 0.15;
        return GestureDetector(
          onTap: provider.isAnalyzing ? null : () => provider.analyzeWithAI(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SynapseTheme.primaryContainer.withOpacity(0.15),
                  SynapseTheme.primaryContainer.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SynapseTheme.primaryContainer.withOpacity(0.2 + _pulseController.value * 0.15)),
              boxShadow: [
                BoxShadow(
                  color: SynapseTheme.primaryContainer.withOpacity(glow),
                  blurRadius: 20 + _pulseController.value * 10,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (provider.isAnalyzing)
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: SynapseTheme.primaryContainer,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(Icons.center_focus_strong, color: SynapseTheme.primaryContainer, size: 24),
                const SizedBox(width: 14),
                Text(
                  provider.isAnalyzing ? 'ANALIZANDO CON VISIÓN IA...' : '🧠 CAPTURAR Y ANALIZAR CON VISIÓN IA',
                  style: SynapseTheme.headline(
                    fontSize: 13,
                    color: SynapseTheme.primaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  //  SIGNAL SECTION — detected signal card
  // ═══════════════════════════════════════════
  Widget _buildSignalSection(TradeSignal? signal, bool isBuy, String symbol, double price, double sl, double tp1, double tp2, int conf) {
    final accentColor = isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondary;
    final glowColor = isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondaryContainer;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SynapseTheme.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glowColor.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: glowColor.withOpacity(0.15), blurRadius: 16)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(signal != null ? Icons.verified : Icons.hourglass_empty,
                              size: 14, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            signal != null ? 'SEÑAL IA DETECTADA' : 'ESPERANDO ANÁLISIS',
                            style: SynapseTheme.headline(fontSize: 11, color: accentColor, letterSpacing: 2),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        if (signal != null) ...[
                          Text(
                            '${isBuy ? "COMPRA" : "VENTA"} $symbol',
                            style: SynapseTheme.headline(fontSize: 26, letterSpacing: -1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@ ${price.toStringAsFixed(2)}',
                            style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
                          ),
                        ] else ...[
                          Text(
                            'Presiona "Analizar con IA" para obtener una señal',
                            style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      Text('$conf%', style: SynapseTheme.headline(fontSize: 22, color: accentColor)),
                      Text('CONF', style: SynapseTheme.headline(fontSize: 9, color: accentColor.withOpacity(0.7), letterSpacing: 1)),
                    ]),
                  ),
                ],
              ),

              if (signal != null) ...[
                const SizedBox(height: 16),
                // Pattern
                if (signal.pattern.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.psychology, size: 16, color: accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(signal.pattern,
                            style: SynapseTheme.label(fontSize: 12, color: accentColor)),
                      ),
                    ]),
                  ),
                const SizedBox(height: 16),
                // Levels grid
                _levelBox('STOP LOSS', sl.toStringAsFixed(2), SynapseTheme.secondary),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _levelBox('TAKE PROFIT 1', tp1.toStringAsFixed(2), SynapseTheme.primaryFixedDim)),
                  const SizedBox(width: 10),
                  Expanded(child: _levelBox('TAKE PROFIT 2', tp2.toStringAsFixed(2), SynapseTheme.primaryFixedDim)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: SynapseTheme.label(fontSize: 11, letterSpacing: 0.5)),
        Text(value, style: SynapseTheme.headline(fontSize: 15, color: color)),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  //  RISK MANAGEMENT
  // ═══════════════════════════════════════════
  Widget _buildRiskSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('GESTIÓN DE RIESGO',
                style: SynapseTheme.headline(fontSize: 11, color: SynapseTheme.onSurfaceVariant, letterSpacing: 1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _riskPercent <= 2
                    ? SynapseTheme.primaryContainer.withOpacity(0.12)
                    : SynapseTheme.secondaryContainer.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _riskPercent <= 2 ? 'CONSERVADOR' : 'ALTO RENDIMIENTO',
                style: SynapseTheme.headline(
                  fontSize: 10,
                  color: _riskPercent <= 2 ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Riesgo por operación',
                style: SynapseTheme.label(fontSize: 13, color: SynapseTheme.onSurface)),
            Text('${_riskPercent.toStringAsFixed(1)}%',
                style: SynapseTheme.headline(fontSize: 18, color: SynapseTheme.primaryFixedDim)),
          ]),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: SynapseTheme.primaryContainer,
              inactiveTrackColor: SynapseTheme.surfaceContainerHighest,
              thumbColor: Colors.white,
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayColor: SynapseTheme.primaryContainer.withOpacity(0.2),
            ),
            child: Slider(
              value: _riskPercent, min: 0.5, max: 5.0, divisions: 9,
              onChanged: (v) => setState(() => _riskPercent = v),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TRADE EXECUTION BUTTONS
  // ═══════════════════════════════════════════
  Widget _buildTradeButtons(bool isBuy, TradeSignal? signal) {
    return Column(
      children: [
        // BUY button
        _execButton(
          label: 'EJECUTAR ORDEN COMPRA',
          color: SynapseTheme.primaryContainer,
          textColor: SynapseTheme.onPrimary,
          icon: Icons.trending_up,
          onTap: () => _executeOrder(true),
        ),
        const SizedBox(height: 12),
        // SELL button
        _execButton(
          label: 'EJECUTAR ORDEN VENTA',
          color: SynapseTheme.secondaryContainer,
          textColor: Colors.white,
          icon: Icons.trending_down,
          onTap: () => _executeOrder(false),
        ),
      ],
    );
  }

  Widget _execButton({
    required String label,
    required Color color,
    required Color textColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExecuting ? null : onTap,
        icon: Icon(icon, color: textColor, size: 22),
        label: Text(label, style: SynapseTheme.headline(fontSize: 16, color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: color.withOpacity(0.5),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  EXECUTING OVERLAY
  // ═══════════════════════════════════════════
  Widget _buildExecutingOverlay(bool isBuy) {
    return Positioned.fill(
      child: Container(
        color: SynapseTheme.surface.withOpacity(0.7),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(
                color: isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondaryContainer,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text('EJECUTANDO ORDEN...',
                  style: SynapseTheme.headline(
                    fontSize: 16,
                    color: isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                    letterSpacing: 3,
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}
