// Web implementation — registers TradingView iframe with platformViewRegistry
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Maps asset symbol to TradingView format
String _mapSymbol(String symbol) {
  const mapping = {
    'XAUUSD': 'OANDA:XAUUSD',
    'BTCUSD': 'BINANCE:BTCUSDT',
    'ETHUSD': 'BINANCE:ETHUSDT',
    'NAS100': 'NASDAQ:NDX',
    'SPX500': 'SP:SPX',
    'EURUSD': 'OANDA:EURUSD',
    'GBPUSD': 'OANDA:GBPUSD',
    'USDJPY': 'OANDA:USDJPY',
  };
  return mapping[symbol] ?? 'OANDA:$symbol';
}

String _buildHtml(String symbol, String timeframe) {
  final tvSymbol = _mapSymbol(symbol);
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #131313; overflow: hidden; width: 100vw; height: 100vh; }
    #tv_chart_container { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="tv_chart_container"></div>
  <script src="https://s3.tradingview.com/tv.js"></script>
  <script>
    new TradingView.widget({
      "autosize": true,
      "symbol": "$tvSymbol",
      "interval": "$timeframe",
      "timezone": "Etc/UTC",
      "theme": "dark",
      "style": "1",
      "locale": "es",
      "hide_top_toolbar": false,
      "hide_legend": false,
      "save_image": false,
      "container_id": "tv_chart_container",
      "backgroundColor": "rgba(19,19,19,1)",
      "gridColor": "rgba(53,53,52,0.3)",
      "allow_symbol_change": false,
      "studies": ["MASimple@tv-basicstudies", "RSI@tv-basicstudies"],
      "show_popup_button": false,
      "overrides": {
        "paneProperties.background": "#131313",
        "mainSeriesProperties.candleStyle.upColor": "#00FF88",
        "mainSeriesProperties.candleStyle.downColor": "#D5033C",
        "mainSeriesProperties.candleStyle.borderUpColor": "#00FF88",
        "mainSeriesProperties.candleStyle.borderDownColor": "#D5033C",
        "mainSeriesProperties.candleStyle.wickUpColor": "#00FF88",
        "mainSeriesProperties.candleStyle.wickDownColor": "#D5033C"
      }
    });
  </script>
</body>
</html>''';
}

final _registered = <String>{};

const _allSymbols = ['XAUUSD', 'BTCUSD', 'ETHUSD', 'NAS100', 'SPX500', 'EURUSD', 'GBPUSD', 'USDJPY', 'US30'];

void registerTradingViewIframe(String symbol, String timeframe, String viewId) {
  // Pre-register all symbols on first call to avoid unregistered_view_type errors
  if (_registered.isEmpty) {
    for (final sym in _allSymbols) {
      final id = 'tv-$sym';
      _registered.add(id);
      ui_web.platformViewRegistry.registerViewFactory(id, (int platformId) {
        final iframe = html.IFrameElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..style.background = '#131313'
          ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-popups')
          ..srcdoc = _buildHtml(sym, '60'); // Default timeframe
        return iframe;
      });
    }
  }

  // If this specific viewId wasn't in the pre-registration list, register it now
  if (!_registered.contains(viewId)) {
    _registered.add(viewId);
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int platformId) {
      final iframe = html.IFrameElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.background = '#131313'
        ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-popups')
        ..srcdoc = _buildHtml(symbol, timeframe);
      return iframe;
    });
  }
}
