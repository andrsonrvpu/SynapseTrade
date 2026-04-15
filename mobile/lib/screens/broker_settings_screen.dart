import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';
import '../providers/app_provider.dart';

/// Configuración de Broker — conecta a MetaAPI para trading real.
class BrokerSettingsScreen extends StatefulWidget {
  const BrokerSettingsScreen({super.key});

  @override
  State<BrokerSettingsScreen> createState() => _BrokerSettingsScreenState();
}

class _BrokerSettingsScreenState extends State<BrokerSettingsScreen> {
  final _tokenCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  bool _isConnecting = false;
  String? _connectionMessage;
  bool _tokenVisible = false;

  // Risk & auto-trading UI state managed here, saved to provider
  double _riskPercent = 1.5;
  bool _disciplineMode = true;
  bool _pushNotifications = false;
  bool _priceAlerts = true;
  double _minConfidence = 82.0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _tokenCtrl.text = provider.metaApiToken;
    _accountCtrl.text = provider.metaApiAccountId;
    _riskPercent = provider.riskPercent;
    _minConfidence = provider.minConfidenceForAuto;
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: SynapseTheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildConnectionCard(provider),
                  const SizedBox(height: 24),
                  if (provider.brokerConnected) ...[
                    _buildAccountInfoCard(provider),
                    const SizedBox(height: 24),
                    _buildOpenPositionsCard(provider),
                    const SizedBox(height: 24),
                  ],
                  _buildRiskSection(provider),
                  const SizedBox(height: 24),
                  _buildAutoTradingSection(provider),
                  const SizedBox(height: 24),
                  _buildAlertsSection(),
                  const SizedBox(height: 20),
                  _buildSystemStatus(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: SynapseTheme.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: SynapseTheme.primaryContainer.withOpacity(0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 10),
          Text('SYNAPSE TRADE', style: SynapseTheme.headline(fontSize: 11, color: SynapseTheme.primaryContainer, letterSpacing: 2.5)),
        ]),
        const SizedBox(height: 12),
        Text('Configuración', style: SynapseTheme.headline(fontSize: 32, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('Conecta tu broker MT5/Exness para trading real con IA.',
            style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant)),
      ],
    );
  }

  // ── Broker Connection Card ────────────────────────────────────────────────
  Widget _buildConnectionCard(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.electric_bolt, size: 18, color: Color(0xFFF5A623)),
          const SizedBox(width: 8),
          Text('Conexión MetaAPI / Broker', style: SynapseTheme.headline(fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: provider.brokerConnected
                        ? SynapseTheme.primaryContainer.withOpacity(0.1)
                        : SynapseTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: provider.brokerConnected
                          ? SynapseTheme.primaryContainer.withOpacity(0.4)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: provider.brokerConnected
                            ? SynapseTheme.primaryContainer
                            : SynapseTheme.onSurfaceVariant,
                        boxShadow: provider.brokerConnected
                            ? [BoxShadow(color: SynapseTheme.primaryContainer.withOpacity(0.6), blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      provider.brokerConnected
                          ? '${provider.brokerName} — CONECTADO (${provider.accountInfo['mode'] == 'live' ? 'REAL' : 'DEMO'})'
                          : 'Sin conexión — modo Demo',
                      style: SynapseTheme.label(
                        fontSize: 12,
                        color: provider.brokerConnected ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                // How to get credentials
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF5A623).withOpacity(0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFF5A623)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Obtén tu MetaAPI Token gratis en metaapi.cloud — conecta tu cuenta MT5/Exness en menos de 5 min.',
                      style: SynapseTheme.label(fontSize: 11, color: const Color(0xFFF5A623)),
                    )),
                  ]),
                ),
                const SizedBox(height: 16),
                // Broker type chips
                Text('PLATAFORMA', style: SynapseTheme.label(fontSize: 10, letterSpacing: 1.5, color: SynapseTheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6,
                  children: ['MT5 / Exness', 'MT5 / IC Markets', 'MT5 / Pepperstone', 'MT4', 'Deriv'].map((b) {
                    final selected = provider.brokerName == b;
                    return GestureDetector(
                      onTap: () => setState(() {}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? SynapseTheme.primaryContainer.withOpacity(0.15) : SynapseTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? SynapseTheme.primaryContainer.withOpacity(0.5) : Colors.white.withOpacity(0.07),
                          ),
                        ),
                        child: Text(b, style: SynapseTheme.label(
                          fontSize: 11,
                          color: selected ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant,
                        )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Token field
                _inputField(_tokenCtrl, 'MetaAPI Token', Icons.key, obscure: !_tokenVisible,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _tokenVisible = !_tokenVisible),
                    child: Icon(_tokenVisible ? Icons.visibility_off : Icons.visibility,
                        size: 18, color: SynapseTheme.onSurfaceVariant),
                  )),
                const SizedBox(height: 10),
                _inputField(_accountCtrl, 'Account ID', Icons.account_balance),
                // Error/success message
                if (_connectionMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _connectionMessage!.contains('✅')
                          ? SynapseTheme.primaryContainer.withOpacity(0.1)
                          : SynapseTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_connectionMessage!, style: SynapseTheme.label(fontSize: 12,
                      color: _connectionMessage!.contains('✅') ? SynapseTheme.primaryContainer : SynapseTheme.secondary)),
                  ),
                ],
                const SizedBox(height: 16),
                // Buttons row
                Row(children: [
                  if (provider.brokerConnected) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SynapseTheme.secondary,
                          side: BorderSide(color: SynapseTheme.secondary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          provider.disconnectBroker();
                          _tokenCtrl.clear();
                          _accountCtrl.clear();
                          setState(() => _connectionMessage = null);
                        },
                        child: Text('DESCONECTAR', style: SynapseTheme.headline(fontSize: 12, color: SynapseTheme.secondary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SynapseTheme.primaryContainer,
                        foregroundColor: SynapseTheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isConnecting ? null : () => _connect(provider),
                      child: _isConnecting
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('VINCULAR BROKER', style: SynapseTheme.headline(fontSize: 13, color: SynapseTheme.onPrimary)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _connect(AppProvider provider) async {
    if (_tokenCtrl.text.isEmpty || _accountCtrl.text.isEmpty) {
      setState(() => _connectionMessage = '⚠️ Ingresa Token y Account ID');
      return;
    }
    setState(() { _isConnecting = true; _connectionMessage = null; });

    final connected = await provider.configureBroker(
      token: _tokenCtrl.text.trim(),
      accountId: _accountCtrl.text.trim(),
      brokerName: 'MetaAPI',
    );

    setState(() {
      _isConnecting = false;
      if (connected) {
        _connectionMessage = '✅ Conectado — ${provider.accountInfo['mode'] == 'live' ? 'Cuenta Real' : 'Cuenta Demo'}';
      } else {
        _connectionMessage = '⚠️ Modo demo activo. Verifica credenciales en metaapi.cloud';
      }
    });
  }

  // ── Account Info Card ─────────────────────────────────────────────────────
  Widget _buildAccountInfoCard(AppProvider provider) {
    final info = provider.accountInfo;
    final balance = (info['balance'] ?? 0.0) as num;
    final equity = (info['equity'] ?? 0.0) as num;
    final profit = (info['profit'] ?? info['free_margin'] ?? 0.0) as num;
    final isReal = info['mode'] == 'live';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF00E5B4)),
          const SizedBox(width: 8),
          Text('Cuenta del Broker', style: SynapseTheme.headline(fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isReal ? const Color(0xFFFF4C6E).withOpacity(0.15) : SynapseTheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isReal ? 'REAL' : 'DEMO',
              style: SynapseTheme.headline(fontSize: 10, letterSpacing: 1.5,
                  color: isReal ? const Color(0xFFFF4C6E) : SynapseTheme.primaryContainer),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              _accountStat('BALANCE', '\$${balance.toStringAsFixed(2)}'),
              _divider(),
              _accountStat('EQUITY', '\$${equity.toStringAsFixed(2)}'),
              _divider(),
              _accountStat('P&L', '\$${profit.toStringAsFixed(2)}',
                  color: profit >= 0 ? SynapseTheme.primaryContainer : SynapseTheme.secondary),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _accountStat(String label, String value, {Color? color}) {
    return Expanded(child: Column(children: [
      Text(label, style: SynapseTheme.label(fontSize: 10, letterSpacing: 1, color: SynapseTheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Text(value, style: SynapseTheme.headline(fontSize: 15, color: color ?? SynapseTheme.onSurface)),
    ]));
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08));

  // ── Open Positions ────────────────────────────────────────────────────────
  Widget _buildOpenPositionsCard(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.show_chart, size: 18, color: Color(0xFF00E5B4)),
          const SizedBox(width: 8),
          Text('Posiciones Abiertas', style: SynapseTheme.headline(fontSize: 15)),
          const Spacer(),
          if (provider.openPositions.isNotEmpty)
            Text('${provider.openPositions.length} activa${provider.openPositions.length > 1 ? 's' : ''}',
                style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.primaryContainer)),
        ]),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 20,
          child: provider.openPositions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('Sin posiciones abiertas',
                      style: SynapseTheme.label(color: SynapseTheme.onSurfaceVariant))),
                )
              : Column(
                  children: provider.openPositions.map((pos) => _buildPositionRow(pos, provider)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildPositionRow(OpenPosition pos, AppProvider provider) {
    final isProfit = pos.profit >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: pos.isBuy ? SynapseTheme.primaryContainer.withOpacity(0.1) : SynapseTheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(
            pos.isBuy ? '↑' : '↓',
            style: TextStyle(fontSize: 18, color: pos.isBuy ? SynapseTheme.primaryContainer : SynapseTheme.secondary),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pos.symbol, style: SynapseTheme.headline(fontSize: 14)),
          Text('${pos.volume} lot · ${pos.direction}',
              style: SynapseTheme.label(fontSize: 11, color: SynapseTheme.onSurfaceVariant)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${isProfit ? '+' : ''}\$${pos.profit.toStringAsFixed(2)}',
            style: SynapseTheme.headline(fontSize: 15,
                color: isProfit ? SynapseTheme.primaryContainer : SynapseTheme.secondary),
          ),
          Text('@ ${pos.openPrice}', style: SynapseTheme.label(fontSize: 10, color: SynapseTheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }

  // ── Risk Management ───────────────────────────────────────────────────────
  Widget _buildRiskSection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFF5A623)),
          const SizedBox(width: 8),
          Text('Gestión de Riesgo', style: SynapseTheme.headline(fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('RIESGO POR OPERACIÓN', style: SynapseTheme.label(fontSize: 11, letterSpacing: 0.5)),
                Text('${_riskPercent.toStringAsFixed(1)}%',
                    style: SynapseTheme.headline(fontSize: 18, color: SynapseTheme.primaryContainer)),
              ]),
              _buildSlider(_riskPercent, 0.5, 5, 9, (v) {
                setState(() => _riskPercent = v);
                provider.setRiskPercent(v);
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SynapseTheme.surfaceContainerHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.block, size: 18, color: Color(0xFFF5A623)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Modo Disciplina', style: SynapseTheme.headline(fontSize: 14)),
                    Text('Pausa auto-trading tras 3 pérdidas consecutivas.',
                        style: SynapseTheme.label(fontSize: 11, color: SynapseTheme.onSurfaceVariant)),
                  ])),
                  _buildToggle(_disciplineMode, (v) => setState(() => _disciplineMode = v),
                      activeColor: const Color(0xFFF5A623)),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Auto-Trading Section ──────────────────────────────────────────────────
  Widget _buildAutoTradingSection(AppProvider provider) {
    final autoOn = provider.autoTradingEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.smart_toy_outlined, size: 18, color: autoOn ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('Trading Automático IA', style: SynapseTheme.headline(fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Main toggle
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('EJECUCIÓN AUTOMÁTICA', style: SynapseTheme.headline(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    autoOn ? '${provider.autoTradingStatus.toUpperCase()} · ${provider.autoTradesExecuted} trades ejecutados'
                           : 'La IA ejecuta órdenes con SL y TP automáticamente.',
                    style: SynapseTheme.label(fontSize: 11,
                        color: autoOn ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant),
                  ),
                ])),
                _buildToggle(autoOn, (v) => provider.toggleAutoTrading(v),
                    activeColor: SynapseTheme.primaryContainer),
              ]),
              if (autoOn) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SynapseTheme.primaryContainer.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SynapseTheme.primaryContainer.withOpacity(0.2)),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Confianza mínima', style: SynapseTheme.label(fontSize: 12)),
                      Text('${_minConfidence.toInt()}%',
                          style: SynapseTheme.headline(fontSize: 14, color: SynapseTheme.primaryContainer)),
                    ]),
                    _buildSlider(_minConfidence, 70, 96, 13, (v) {
                      setState(() => _minConfidence = v);
                      provider.setMinConfidence(v);
                    }),
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4C6E).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF4C6E).withOpacity(0.15)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFFF4C6E)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'El trading automático ejecuta órdenes reales en tu broker. Configura bien tu gestión de riesgo antes de activarlo.',
                    style: SynapseTheme.label(fontSize: 11, color: const Color(0xFFFF4C6E)),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Alerts ────────────────────────────────────────────────────────────────
  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🔔', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('Alertas', style: SynapseTheme.headline(fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              _alertRow('Notificaciones Push', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
              _alertDivider(),
              _alertRow('Alertas de Precio', _priceAlerts, (v) => setState(() => _priceAlerts = v)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _alertRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurface)),
        _buildToggle(value, onChanged),
      ]),
    );
  }

  Widget _alertDivider() => Container(
    height: 1, margin: const EdgeInsets.symmetric(horizontal: 20),
    color: Colors.white.withOpacity(0.05),
  );

  // ── System Status ─────────────────────────────────────────────────────────
  Widget _buildSystemStatus(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: provider.isConnected ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant,
            shape: BoxShape.circle,
            boxShadow: provider.isConnected
                ? [BoxShadow(color: SynapseTheme.primaryContainer.withOpacity(0.6), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Sistema ${provider.isConnected ? 'Conectado' : 'Offline'} · '
          '${provider.brokerConnected ? 'Broker Activo' : 'Sin Broker'}',
          style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.onSurfaceVariant),
        ),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildToggle(bool value, ValueChanged<bool> onChanged, {Color? activeColor}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 24,
        decoration: BoxDecoration(
          color: value ? (activeColor ?? SynapseTheme.primaryContainer) : SynapseTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20, height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(double value, double min, double max, int div, ValueChanged<double> onChanged) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: SynapseTheme.primaryContainer,
        inactiveTrackColor: SynapseTheme.surfaceContainerHighest,
        thumbColor: Colors.white,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayColor: SynapseTheme.primaryContainer.withOpacity(0.15),
      ),
      child: Slider(value: value, min: min, max: max, divisions: div, onChanged: onChanged),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: SynapseTheme.label(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 18, color: SynapseTheme.onSurfaceVariant),
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix) : null,
        filled: true,
        fillColor: SynapseTheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
