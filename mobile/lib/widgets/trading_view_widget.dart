import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/synapse_theme.dart';

// Web-specific imports via stub files
import 'trading_view_web.dart' if (dart.library.io) 'trading_view_stub.dart';

/// TradingView live chart widget.
/// On Flutter Web: embeds via HtmlElementView + dart:ui_web
/// On iOS/Android: uses WebView with embedded TradingView HTML
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
  WebViewController? _webController;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _currentViewId = tvViewId(widget.symbol);
    if (kIsWeb) {
      registerTradingViewIframe(widget.symbol, widget.timeframe, _currentViewId);
    } else {
      _initWebView();
    }
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D0D0D))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _webViewReady = true);
        },
      ))
      ..loadHtmlString(_buildTradingViewHtml(widget.symbol, widget.timeframe));
    setState(() => _webController = controller);
  }

  String _buildTradingViewHtml(String symbol, String timeframe) {
    // Map symbol to TradingView format
    final tvSymbol = _mapSymbol(symbol);
    final tvInterval = timeframe;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #0D0D0D; overflow: hidden; }
    #chart { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="chart"></div>
  <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
  <script type="text/javascript">
    new TradingView.widget({
      "autosize": true,
      "symbol": "$tvSymbol",
      "interval": "$tvInterval",
      "timezone": "exchange",
      "theme": "dark",
      "style": "1",
      "locale": "es",
      "toolbar_bg": "#0D0D0D",
      "enable_publishing": false,
      "hide_top_toolbar": false,
      "hide_legend": false,
      "save_image": false,
      "container_id": "chart",
      "studies": [
        "MASimple@tv-basicstudies",
        "RSI@tv-basicstudies"
      ],
      "show_popup_button": false,
      "popup_width": "1000",
      "popup_height": "650",
      "no_referral_id": true,
      "overrides": {
        "mainSeriesProperties.candleStyle.upColor": "#00E5B4",
        "mainSeriesProperties.candleStyle.downColor": "#FF4C6E",
        "mainSeriesProperties.candleStyle.borderUpColor": "#00E5B4",
        "mainSeriesProperties.candleStyle.borderDownColor": "#FF4C6E",
        "mainSeriesProperties.candleStyle.wickUpColor": "#00E5B4",
        "mainSeriesProperties.candleStyle.wickDownColor": "#FF4C6E",
        "paneProperties.background": "#0D0D0D",
        "paneProperties.backgroundType": "solid",
        "paneProperties.vertGridProperties.color": "#1A1A2E",
        "paneProperties.horzGridProperties.color": "#1A1A2E",
        "scalesProperties.textColor": "#888888"
      }
    });
  </script>
</body>
</html>
''';
  }

  String _mapSymbol(String symbol) {
    const map = {
      'XAUUSD': 'OANDA:XAUUSD',
      'EURUSD': 'FX:EURUSD',
      'GBPUSD': 'FX:GBPUSD',
      'USDJPY': 'FX:USDJPY',
      'BTCUSD': 'BINANCE:BTCUSDT',
      'BTCUSDT': 'BINANCE:BTCUSDT',
      'ETHUSD': 'BINANCE:ETHUSDT',
      'ETHUSDT': 'BINANCE:ETHUSDT',
      'US30': 'FOREXCOM:DJI',
      'NAS100': 'NASDAQ:NDX',
      'SPX500': 'SP:SPX',
      'USOIL': 'TVC:USOIL',
    };
    return map[symbol] ?? 'FX:$symbol';
  }

  @override
  void didUpdateWidget(covariant TradingViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || oldWidget.timeframe != widget.timeframe) {
      _currentViewId = tvViewId(widget.symbol);
      if (kIsWeb) {
        registerTradingViewIframe(widget.symbol, widget.timeframe, _currentViewId);
        if (mounted) setState(() {});
      } else {
        // Reload WebView with new symbol
        _webController?.loadHtmlString(
          _buildTradingViewHtml(widget.symbol, widget.timeframe),
        );
        if (mounted) setState(() => _webViewReady = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: widget.height,
          child: HtmlElementView(viewType: _currentViewId),
        ),
      );
    }

    // Mobile: WebView with real TradingView chart
    if (_webController == null) {
      return _buildLoadingPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            WebViewWidget(controller: _webController!),
            if (!_webViewReady)
              Container(
                color: const Color(0xFF0D0D0D),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: SynapseTheme.primaryContainer,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cargando gráfico ${widget.symbol}...',
                        style: SynapseTheme.label(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(color: SynapseTheme.primaryContainer),
      ),
    );
  }
}

String tvViewId(String symbol) => 'tv-$symbol';
