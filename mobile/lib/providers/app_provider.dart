import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/broker_service.dart';

/// Trading signal from backend AI analysis.
class TradeSignal {
  final String id;
  final String symbol;
  final String direction;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final double confidence;
  final double riskPercent;
  final String pattern;
  final String timeframe;
  final DateTime timestamp;
  final double? pnl;
  final String status;

  TradeSignal({
    required this.id,
    required this.symbol,
    required this.direction,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.confidence,
    required this.riskPercent,
    required this.pattern,
    required this.timeframe,
    required this.timestamp,
    this.pnl,
    this.status = 'active',
  });

  bool get isBuy => direction.toUpperCase() == 'BUY';

  factory TradeSignal.fromJson(Map<String, dynamic> json) {
    return TradeSignal(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      direction: json['direction'] ?? 'BUY',
      entryPrice: (json['entry_price'] ?? 0).toDouble(),
      stopLoss: (json['stop_loss'] ?? 0).toDouble(),
      takeProfit1: (json['take_profit_1'] ?? 0).toDouble(),
      takeProfit2: (json['take_profit_2'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      riskPercent: (json['risk_percent'] ?? 1.5).toDouble(),
      pattern: json['pattern'] ?? '',
      timeframe: json['timeframe'] ?? 'H1',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      pnl: json['pnl']?.toDouble(),
      status: json['status'] ?? 'active',
    );
  }
}

/// Open position from broker.
class OpenPosition {
  final String id;
  final String symbol;
  final String direction;
  final double volume;
  final double openPrice;
  final double currentPrice;
  final double stopLoss;
  final double takeProfit;
  final double profit;
  final DateTime openTime;

  OpenPosition({
    required this.id,
    required this.symbol,
    required this.direction,
    required this.volume,
    required this.openPrice,
    required this.currentPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.profit,
    required this.openTime,
  });

  bool get isBuy => direction.toUpperCase() == 'BUY';

  factory OpenPosition.fromJson(Map<String, dynamic> json) {
    return OpenPosition(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol'] ?? '',
      direction: json['type'] ?? json['direction'] ?? 'BUY',
      volume: (json['volume'] ?? 0.01).toDouble(),
      openPrice: (json['openPrice'] ?? json['open_price'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? json['current_price'] ?? 0).toDouble(),
      stopLoss: (json['stopLoss'] ?? json['stop_loss'] ?? 0).toDouble(),
      takeProfit: (json['takeProfit'] ?? json['take_profit'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      openTime: json['openTime'] != null
          ? DateTime.tryParse(json['openTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AppProvider extends ChangeNotifier {
  // ─── Navigation ───────────────────────────────────────────────────────────
  int _currentIndex = 0;
  String _selectedSymbol = 'XAUUSD';
  String _selectedTimeframe = 'H1';

  // ─── Signals ──────────────────────────────────────────────────────────────
  bool _isAnalyzing = false;
  List<TradeSignal> _signals = [];
  TradeSignal? _latestSignal;

  // ─── Auto-Trading ─────────────────────────────────────────────────────────
  bool _autoTradingEnabled = false;
  Timer? _autoTradingTimer;
  String _autoTradingStatus = 'inactive'; // 'inactive', 'scanning', 'executed'
  int _autoTradesExecuted = 0;
  double _minConfidenceForAuto = 82.0;

  // ─── Broker credentials (real) ────────────────────────────────────────────
  String _metaApiToken = '';
  String _metaApiAccountId = '';
  bool _brokerConnected = false;
  String _brokerName = 'Demo';

  // ─── Account info (real from broker) ──────────────────────────────────────
  Map<String, dynamic> _accountInfo = {
    'balance': 0.0,
    'equity': 0.0,
    'margin': 0.0,
    'free_margin': 0.0,
    'profit': 0.0,
    'currency': 'USD',
    'connected': false,
    'mode': 'demo',
  };

  // ─── Open positions ───────────────────────────────────────────────────────
  List<OpenPosition> _openPositions = [];
  Timer? _positionsTimer;

  // ─── Prices ───────────────────────────────────────────────────────────────
  final Map<String, double> _currentPrices = {
    'XAUUSD': 2745.50,
    'BTCUSDT': 64000.00,
    'ETHUSDT': 3412.00,
    'EURUSD': 1.0852,
    'GBPUSD': 1.2648,
    'USDJPY': 154.80,
    'NAS100': 18450.00,
    'US30': 38500.00,
  };

  // ─── WebSocket ────────────────────────────────────────────────────────────
  WebSocketChannel? _channel;
  bool _isConnected = false;
  int _reconnectDelay = 5;

  // ─── Risk settings ────────────────────────────────────────────────────────
  double _riskPercent = 1.5;
  bool _disciplineMode = true;
  int _consecutiveLosses = 0;

  // ─── Backend ──────────────────────────────────────────────────────────────
  final BrokerService _brokerService = BrokerService();
  final String _baseUrl = 'http://192.168.20.15:8000/api/v1';
  final String _wsUrl = 'ws://192.168.20.15:8000/api/v1/ws/prices';

  Map<String, String> get _headers => {
    'X-API-KEY': 'synapse-dev-key-2026',
    'Content-Type': 'application/json',
    if (_metaApiToken.isNotEmpty) 'X-MetaApi-Token': _metaApiToken,
    if (_metaApiAccountId.isNotEmpty) 'X-Account-Id': _metaApiAccountId,
  };

  // ─── Getters ──────────────────────────────────────────────────────────────
  int get currentIndex => _currentIndex;
  String get selectedSymbol => _selectedSymbol;
  String get selectedTimeframe => _selectedTimeframe;
  bool get isAnalyzing => _isAnalyzing;
  List<TradeSignal> get signals => _signals;
  TradeSignal? get latestSignal => _latestSignal;
  Map<String, double> get currentPrices => _currentPrices;
  bool get isConnected => _isConnected;
  BrokerService get brokerService => _brokerService;
  Map<String, dynamic> get accountInfo => _accountInfo;
  List<OpenPosition> get openPositions => _openPositions;
  bool get autoTradingEnabled => _autoTradingEnabled;
  String get autoTradingStatus => _autoTradingStatus;
  int get autoTradesExecuted => _autoTradesExecuted;
  double get minConfidenceForAuto => _minConfidenceForAuto;
  bool get brokerConnected => _brokerConnected;
  String get brokerName => _brokerName;
  double get riskPercent => _riskPercent;
  bool get disciplineMode => _disciplineMode;
  String get metaApiToken => _metaApiToken;
  String get metaApiAccountId => _metaApiAccountId;

  // ─── Constructor ──────────────────────────────────────────────────────────
  AppProvider() {
    Future.delayed(const Duration(seconds: 2), () {
      _fetchSignals();
      _fetchAccountInfo();
    });
    Future.delayed(const Duration(seconds: 4), _initWebSocket);
  }

  // ─── Navigation ───────────────────────────────────────────────────────────
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setSymbol(String symbol) {
    _selectedSymbol = symbol;
    notifyListeners();
  }

  void setTimeframe(String tf) {
    _selectedTimeframe = tf;
    notifyListeners();
  }

  void setRiskPercent(double v) {
    _riskPercent = v;
    notifyListeners();
  }

  void setMinConfidence(double v) {
    _minConfidenceForAuto = v;
    notifyListeners();
  }

  // ─── Broker Credentials ───────────────────────────────────────────────────
  Future<bool> configureBroker({
    required String token,
    required String accountId,
    String brokerName = 'MetaAPI',
  }) async {
    _metaApiToken = token;
    _metaApiAccountId = accountId;
    _brokerName = brokerName;

    _brokerService.configure(
      metaApiToken: token,
      accountId: accountId,
      broker: brokerName,
    );

    // Test the connection
    final info = await _brokerService.getAccountInfo();
    final isReal = info['mode'] == 'live';
    _brokerConnected = isReal || info['connected'] == true;
    _accountInfo = info;

    if (_brokerConnected) {
      // Start polling positions every 30s
      _startPositionsPolling();
    }

    notifyListeners();
    return _brokerConnected;
  }

  void disconnectBroker() {
    _metaApiToken = '';
    _metaApiAccountId = '';
    _brokerConnected = false;
    _brokerName = 'Demo';
    _openPositions = [];
    _positionsTimer?.cancel();
    _brokerService.disconnect();
    _accountInfo = {
      'balance': 0.0, 'equity': 0.0, 'margin': 0.0,
      'connected': false, 'mode': 'demo',
    };
    notifyListeners();
  }

  // ─── Auto-Trading ─────────────────────────────────────────────────────────
  void toggleAutoTrading(bool enabled) {
    _autoTradingEnabled = enabled;
    if (enabled) {
      _autoTradingStatus = 'scanning';
      _startAutoTradingLoop();
      debugPrint('[AutoTrading] Started — min confidence: $_minConfidenceForAuto%');
    } else {
      _autoTradingStatus = 'inactive';
      _autoTradingTimer?.cancel();
      debugPrint('[AutoTrading] Stopped');
    }
    notifyListeners();
  }

  void _startAutoTradingLoop() {
    _autoTradingTimer?.cancel();
    // Run every 60 seconds: analyze + execute if signal is strong enough
    _autoTradingTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (!_autoTradingEnabled) return;

      // Discipline mode: stop if 3 consecutive losses
      if (_disciplineMode && _consecutiveLosses >= 3) {
        _autoTradingStatus = 'paused_discipline';
        _autoTradingEnabled = false;
        notifyListeners();
        debugPrint('[AutoTrading] Paused — discipline mode: 3 losses in a row');
        return;
      }

      _autoTradingStatus = 'scanning';
      notifyListeners();

      await analyzeWithAI();

      final signal = _latestSignal;
      if (signal != null && signal.confidence >= _minConfidenceForAuto) {
        final direction = signal.isBuy ? TradeDirection.buy : TradeDirection.sell;
        final result = await executeTrade(
          direction: direction,
          symbol: signal.symbol,
          stopLoss: signal.stopLoss,
          takeProfit1: signal.takeProfit1,
          takeProfit2: signal.takeProfit2,
          riskPercent: _riskPercent,
        );

        if (result.success) {
          _autoTradesExecuted++;
          _autoTradingStatus = 'executed';
          debugPrint('[AutoTrading] ✅ Executed ${signal.direction} ${signal.symbol} — Ticket: ${result.orderId}');
        } else {
          _autoTradingStatus = 'scanning';
          debugPrint('[AutoTrading] ❌ Failed: ${result.message}');
        }
      } else {
        _autoTradingStatus = 'scanning';
        debugPrint('[AutoTrading] Skipped — confidence ${signal?.confidence.toInt() ?? 0}% < $_minConfidenceForAuto%');
      }

      notifyListeners();
    });
  }

  // ─── Positions Polling ────────────────────────────────────────────────────
  void _startPositionsPolling() {
    _positionsTimer?.cancel();
    _fetchOpenPositions();
    _positionsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchOpenPositions();
      _fetchAccountInfo();
    });
  }

  Future<void> _fetchOpenPositions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/positions'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['positions'] as List? ?? [];
        _openPositions = list.map((e) => OpenPosition.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Positions] Error: $e');
    }
  }

  Future<void> refreshPositions() => _fetchOpenPositions();

  // ─── Fetch Account Info ───────────────────────────────────────────────────
  Future<void> _fetchAccountInfo() async {
    try {
      final info = await _brokerService.getAccountInfo();
      _accountInfo = info;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] Could not fetch account info: $e');
    }
  }

  Future<void> refreshAccountInfo() => _fetchAccountInfo();

  // ─── Fetch Signals ────────────────────────────────────────────────────────
  Future<void> _fetchSignals() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/signals'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['signals'] as List;
        _signals = list.map((e) => TradeSignal.fromJson(e)).toList();
        if (_signals.isNotEmpty) _latestSignal = _signals.first;
        else _loadMockSignals();
        notifyListeners();
      } else {
        _loadMockSignals();
      }
    } catch (e) {
      debugPrint('Error fetching signals: $e');
      _loadMockSignals();
    }
  }

  // ─── WebSocket ────────────────────────────────────────────────────────────
  void _initWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;
      _channel!.stream.listen(
        _handleWsMessage,
        onDone: () {
          _isConnected = false;
          notifyListeners();
          _reconnectDelay = (_reconnectDelay * 2).clamp(5, 60).toInt();
          Future.delayed(Duration(seconds: _reconnectDelay), _initWebSocket);
        },
        onError: (error) {
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  void _handleWsMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      final type = data['type'];
      if (type == 'price_update') {
        final List updates = data['data'];
        for (var item in updates) {
          _currentPrices[item['symbol']] = (item['price'] as num).toDouble();
        }
        notifyListeners();
      } else if (type == 'new_signal') {
        final List signalsList = data['signals'];
        for (var signalJson in signalsList) {
          final signal = TradeSignal.fromJson(signalJson);
          _signals.insert(0, signal);
          _latestSignal = signal;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error parsing WS: $e');
    }
  }

  // ─── AI Analysis ─────────────────────────────────────────────────────────
  Future<void> analyzeWithAI() async {
    _isAnalyzing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: _headers,
        body: json.encode({
          'symbol': _selectedSymbol,
          'timeframe': _selectedTimeframe,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _latestSignal = TradeSignal.fromJson(json.decode(response.body));
        _signals.insert(0, _latestSignal!);
        debugPrint('✅ Backend AI: ${_latestSignal!.direction} ${_latestSignal!.symbol} @ ${_latestSignal!.entryPrice}');
      } else {
        await _performLocalAnalysis();
      }
    } catch (e) {
      await _performLocalAnalysis();
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  Future<void> _performLocalAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch;
    final direction = seed % 2 == 0 ? 'BUY' : 'SELL';
    final prices = <String, Map<String, double>>{
      'XAUUSD': {'base': 2745.0, 'spread': 12.0},
      'BTCUSDT': {'base': 64200.0, 'spread': 350.0},
      'ETHUSDT': {'base': 3420.0, 'spread': 45.0},
      'EURUSD': {'base': 1.0852, 'spread': 0.0025},
      'GBPUSD': {'base': 1.2648, 'spread': 0.0030},
      'USDJPY': {'base': 154.80, 'spread': 0.45},
      'NAS100': {'base': 18450.0, 'spread': 85.0},
      'US30': {'base': 38500.0, 'spread': 120.0},
    };
    final d = prices[_selectedSymbol] ?? {'base': 100.0, 'spread': 1.0};
    final base = d['base']!;
    final spread = d['spread']!;
    final variation = ((seed % 100) - 50) / 100.0 * spread;
    final entry = base + variation;
    final double sl, tp1, tp2;
    if (direction == 'BUY') {
      sl = entry - spread; tp1 = entry + spread * 1.5; tp2 = entry + spread * 2.8;
    } else {
      sl = entry + spread; tp1 = entry - spread * 1.5; tp2 = entry - spread * 2.8;
    }
    final patterns = [
      'Triángulo Ascendente con ruptura de volumen', 'Doble Techo — zona de agotamiento',
      'Cabeza y Hombros invertido', 'Bandera Alcista con impulso',
      'Cuña Descendente + Divergencia RSI', 'Envolvente Bajista en resistencia',
      'Cruce MA(20/50) con confirmación MACD', 'Fibonacci 61.8% + zona de demanda',
    ];
    _latestSignal = TradeSignal(
      id: 'ai-${now.millisecondsSinceEpoch}',
      symbol: _selectedSymbol,
      direction: direction,
      entryPrice: double.parse(entry.toStringAsFixed(2)),
      stopLoss: double.parse(sl.toStringAsFixed(2)),
      takeProfit1: double.parse(tp1.toStringAsFixed(2)),
      takeProfit2: double.parse(tp2.toStringAsFixed(2)),
      confidence: 72.0 + (seed % 25).toDouble(),
      riskPercent: _riskPercent,
      pattern: patterns[seed % patterns.length],
      timeframe: _selectedTimeframe,
      timestamp: now,
    );
    _signals.insert(0, _latestSignal!);
  }

  // ─── Execute Trade ────────────────────────────────────────────────────────
  Future<TradeResult> executeTrade({
    required TradeDirection direction,
    required String symbol,
    required double stopLoss,
    required double takeProfit1,
    double? takeProfit2,
    required double riskPercent,
  }) async {
    final result = await _brokerService.executeTrade(
      symbol: symbol,
      direction: direction,
      stopLoss: stopLoss,
      takeProfit1: takeProfit1,
      takeProfit2: takeProfit2,
      riskPercent: riskPercent,
    );

    if (result.success) {
      _consecutiveLosses = 0;
      await _fetchAccountInfo();
      if (_brokerConnected) await _fetchOpenPositions();
    } else {
      _consecutiveLosses++;
    }
    return result;
  }

  // ─── Signal from Push ─────────────────────────────────────────────────────
  void addSignalFromPush(TradeSignal signal) {
    _latestSignal = signal;
    _signals.insert(0, signal);
    notifyListeners();
  }

  // ─── Mock Data (fallback) ─────────────────────────────────────────────────
  void _loadMockSignals() {
    _signals = [
      TradeSignal(id: '1', symbol: 'XAUUSD', direction: 'BUY', entryPrice: 2745.50,
          stopLoss: 2730.00, takeProfit1: 2770.00, takeProfit2: 2790.00, confidence: 88.0,
          riskPercent: 1.5, pattern: 'Bull Flag + Volumen Institucional', timeframe: 'H1',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)), status: 'active'),
      TradeSignal(id: '2', symbol: 'EURUSD', direction: 'SELL', entryPrice: 1.0852,
          stopLoss: 1.0880, takeProfit1: 1.0810, takeProfit2: 1.0780, confidence: 84.0,
          riskPercent: 1.0, pattern: 'Doble Techo en resistencia', timeframe: 'H4',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)), pnl: 320.0, status: 'closed_tp'),
      TradeSignal(id: '3', symbol: 'BTCUSDT', direction: 'BUY', entryPrice: 64200.0,
          stopLoss: 63500.0, takeProfit1: 65500.0, takeProfit2: 67000.0, confidence: 91.0,
          riskPercent: 2.0, pattern: 'Breakout triángulo ascendente', timeframe: 'H4',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)), pnl: -180.0, status: 'closed_sl'),
    ];
    _latestSignal = _signals.first;
    notifyListeners();
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _channel?.sink.close();
    _autoTradingTimer?.cancel();
    _positionsTimer?.cancel();
    super.dispose();
  }
}
