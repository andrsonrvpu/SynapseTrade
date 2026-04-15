import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/synapse_theme.dart';

// Web-specific imports are done conditionally via stub files.
// On web: uses HtmlElementView + dart:ui_web
// On native: renders a styled placeholder
import 'trading_view_web.dart' if (dart.library.io) 'trading_view_stub.dart';

/// TradingView live chart widget.
/// On Flutter Web: embeds a full TradingView Advanced Chart with real candles.
/// On mobile: shows styled placeholder.
class TradingViewWidget extends StatefulWidget {
  final String symbol;
  final String timeframe;
  final double height;

  const TradingViewWidget({
    super.key,
    required this.symbol,
    this.timeframe = '60',
    this.height = 380,
  });

  @override
  State<TradingViewWidget> createState() => TradingViewWidgetState();
}

class TradingViewWidgetState extends State<TradingViewWidget> {
  late String _currentViewId;

  @override
  void initState() {
    super.initState();
    _currentViewId = tvViewId(widget.symbol);
    if (kIsWeb) {
      registerTradingViewIframe(widget.symbol, widget.timeframe, _currentViewId);
    }
  }

  @override
  void didUpdateWidget(covariant TradingViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || oldWidget.timeframe != widget.timeframe) {
      _currentViewId = tvViewId(widget.symbol);
      if (kIsWeb) {
        registerTradingViewIframe(widget.symbol, widget.timeframe, _currentViewId);
      }
      // Force rebuild with new view type
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return _buildMobilePlaceholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        child: HtmlElementView(viewType: _currentViewId),
      ),
    );
  }

  Widget _buildMobilePlaceholder() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(painter: _ChartBgPainter()),
          ),
        ),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.candlestick_chart, color: SynapseTheme.primaryContainer, size: 48),
          const SizedBox(height: 12),
          Text(widget.symbol, style: SynapseTheme.headline(fontSize: 20, color: SynapseTheme.primaryContainer)),
          const SizedBox(height: 8),
          Text('Live chart • Web only in debug mode', style: SynapseTheme.label(fontSize: 12)),
        ])),
      ]),
    );
  }
}

String tvViewId(String symbol) => 'tv-$symbol';

class _ChartBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = SynapseTheme.primaryContainer.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..cubicTo(size.width * 0.25, size.height * 0.5, size.width * 0.45, size.height * 0.65, size.width * 0.65, size.height * 0.38)
      ..cubicTo(size.width * 0.75, size.height * 0.32, size.width * 0.85, size.height * 0.42, size.width, size.height * 0.42);
    canvas.drawPath(path, linePaint);
    final gridPaint = Paint()..color = SynapseTheme.onSurfaceVariant.withOpacity(0.06)..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(0, size.height * i / 5), Offset(size.width, size.height * i / 5), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
