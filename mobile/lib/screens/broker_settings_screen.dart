import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/synapse_theme.dart';
import '../widgets/glass_card.dart';

/// Broker configuration model
class BrokerConfig {
  final String id;
  final String name;
  final String logoText;
  final Color logoColor;
  String status; // 'connected', 'disconnected'
  String apiKey;
  String accountId;

  BrokerConfig({
    required this.id,
    required this.name,
    required this.logoText,
    required this.logoColor,
    this.status = 'disconnected',
    this.apiKey = '',
    this.accountId = '',
  });
}

/// Configuración screen — pixel-perfect to the Stitch reference design.
/// Sections: Broker Connections, Risk Management, Alerts, System Status.
/// NO Telegram. Full multi-broker support with API key management.
class BrokerSettingsScreen extends StatefulWidget {
  const BrokerSettingsScreen({super.key});

  @override
  State<BrokerSettingsScreen> createState() => _BrokerSettingsScreenState();
}

class _BrokerSettingsScreenState extends State<BrokerSettingsScreen> {
  // ── Broker list (expandable) ──────────────────────────────────────────────
  final List<BrokerConfig> _brokers = [
    BrokerConfig(
      id: 'mt5',
      name: 'MetaTrader 5',
      logoText: 'MT5',
      logoColor: const Color(0xFF0066FF),
      status: 'connected',
    ),
    BrokerConfig(
      id: 'exness',
      name: 'Exness Global',
      logoText: 'EX',
      logoColor: const Color(0xFF00A651),
    ),
  ];

  // ── Risk settings ─────────────────────────────────────────────────────────
  double _riskPercent = 1.5;
  double _stopLossPips = 25;
  double _targetPips = 75;
  bool _disciplineMode = true;

  // ── Alerts ────────────────────────────────────────────────────────────────
  bool _pushNotifications = false;
  bool _priceAlerts = true;
  bool _weeklyReport = true;

  // ── Sync ──────────────────────────────────────────────────────────────────
  bool _syncGlobal = true;
  final String _syncLatency = '12ms';

  @override
  Widget build(BuildContext context) {
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
              _buildBrokerSection(),
              const SizedBox(height: 24),
              _buildSyncBar(),
              const SizedBox(height: 24),
              _buildRiskSection(),
              const SizedBox(height: 24),
              _buildAlertsSection(),
              const SizedBox(height: 20),
              _buildSystemStatus(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
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
        Text(
          'Optimiza tu entorno de trading neuronal y gestión de riesgos.',
          style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // ── Broker Connections ────────────────────────────────────────────────────
  Widget _buildBrokerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.electric_bolt, size: 18, color: Color(0xFFF5A623)),
            const SizedBox(width: 8),
            Text('Conexiones de Broker', style: SynapseTheme.headline(fontSize: 15)),
          ]),
          GestureDetector(
            onTap: () => _showAddBrokerDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SynapseTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SynapseTheme.primaryContainer.withOpacity(0.3)),
              ),
              child: Text('VINCULAR NUEVO', style: SynapseTheme.headline(fontSize: 10, color: SynapseTheme.primaryContainer, letterSpacing: 1)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Column(
            children: [
              ..._brokers.map((b) => _buildBrokerCard(b)),
              // ADD API button
              GestureDetector(
                onTap: _showAddBrokerDialog,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_circle_outline, color: SynapseTheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 10),
                    Text('AÑADIR API', style: SynapseTheme.headline(fontSize: 13, color: SynapseTheme.onSurfaceVariant, letterSpacing: 1)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrokerCard(BrokerConfig broker) {
    final isConnected = broker.status == 'connected';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: broker.logoColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: broker.logoColor.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(broker.logoText, style: SynapseTheme.headline(fontSize: 15, color: broker.logoColor)),
            ),
          ),
          const SizedBox(width: 16),
          // Name + status
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(broker.name, style: SynapseTheme.headline(fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'CONECTADO' : 'NO VINCULADO',
                  style: SynapseTheme.label(
                    fontSize: 11,
                    color: isConnected ? SynapseTheme.primaryContainer : SynapseTheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ]),
            ]),
          ),
          // Actions
          Row(children: [
            if (isConnected)
              GestureDetector(
                onTap: () => _showBrokerDetail(broker),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SynapseTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings, size: 16, color: Colors.white70),
                ),
              )
            else
              GestureDetector(
                onTap: () => _showBrokerDetail(broker),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: SynapseTheme.primaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SynapseTheme.primaryContainer.withOpacity(0.3)),
                  ),
                  child: Text('VINCULAR', style: SynapseTheme.headline(fontSize: 10, color: SynapseTheme.primaryContainer, letterSpacing: 0.5)),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  // ── Sync Global Bar ───────────────────────────────────────────────────────
  Widget _buildSyncBar() {
    return GlassCard(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('SYNC GLOBAL', style: SynapseTheme.headline(fontSize: 11, color: SynapseTheme.onSurfaceVariant, letterSpacing: 1.5)),
              Row(children: [
                Text(_syncLatency,
                    style: SynapseTheme.headline(fontSize: 12, color: SynapseTheme.primaryContainer)),
                const SizedBox(width: 12),
                _buildSmallToggle(_syncGlobal, (v) => setState(() => _syncGlobal = v)),
              ]),
            ]),
            const SizedBox(height: 8),
            Text(
              'Latencia optimizada mediante red neuronal propia en todos los instrumentos.',
              style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Risk Management ───────────────────────────────────────────────────────
  Widget _buildRiskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFF5A623)),
          const SizedBox(width: 8),
          Text('Gestión de Riesgo', style: SynapseTheme.headline(fontSize: 15)),
        ]),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Risk % slider
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('RIESGO MÁXIMO POR OPERACIÓN', style: SynapseTheme.label(fontSize: 11, letterSpacing: 0.5)),
                Text('${_riskPercent.toStringAsFixed(1)}%',
                    style: SynapseTheme.headline(fontSize: 16, color: SynapseTheme.primaryContainer)),
              ]),
              _buildSlider(_riskPercent, 0.5, 5, 9, (v) => setState(() => _riskPercent = v)),
              const SizedBox(height: 16),
              // SL Pips
              _buildPipRow('STOP / PIPS AUTOMÁTICO', '${_stopLossPips.toInt()} Pips', () => _editPips(false)),
              const SizedBox(height: 12),
              // Target Pips
              _buildPipRow('TAKE PROFIT OBJETIVO', '${_targetPips.toInt()} Pips', () => _editPips(true)),
              const SizedBox(height: 16),
              // Discipline Mode
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
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Modo Disciplina', style: SynapseTheme.headline(fontSize: 14)),
                      Text('El sistema frena el trading tras 3 pérdidas consecutivas.',
                          style: SynapseTheme.label(fontSize: 11, color: SynapseTheme.onSurfaceVariant)),
                    ]),
                  ),
                  _buildSmallToggle(_disciplineMode, (v) => setState(() => _disciplineMode = v),
                      activeColor: const Color(0xFFF5A623)),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPipRow(String label, String value, VoidCallback onEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: SynapseTheme.surfaceContainerHigh.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: SynapseTheme.label(fontSize: 11, color: SynapseTheme.onSurfaceVariant, letterSpacing: 0.3)),
        Row(children: [
          Text(value, style: SynapseTheme.headline(fontSize: 14)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined, size: 16, color: SynapseTheme.onSurfaceVariant),
          ),
        ]),
      ]),
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
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              _buildAlertRow('Notificaciones Push', _pushNotifications,
                  (v) => setState(() => _pushNotifications = v)),
              _buildAlertDivider(),
              _buildAlertRow('Alertas de Precio', _priceAlerts,
                  (v) => setState(() => _priceAlerts = v), activeColor: SynapseTheme.primaryContainer),
              _buildAlertDivider(),
              _buildAlertRow('Reporte Semanal', _weeklyReport,
                  (v) => setState(() => _weeklyReport = v), activeColor: SynapseTheme.primaryContainer),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertRow(String label, bool value, ValueChanged<bool> onChanged, {Color? activeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurface)),
        _buildSmallToggle(value, onChanged, activeColor: activeColor),
      ]),
    );
  }

  Widget _buildAlertDivider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: Colors.white.withOpacity(0.05),
  );

  // ── System Status ─────────────────────────────────────────────────────────
  Widget _buildSystemStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: SynapseTheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: SynapseTheme.primaryContainer.withOpacity(0.6), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Text('Estado del Sistema · Sincronizado',
            style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.onSurfaceVariant)),
      ]),
    );
  }

  // ── Reusable toggle  ──────────────────────────────────────────────────────
  Widget _buildSmallToggle(bool value, ValueChanged<bool> onChanged, {Color? activeColor}) {
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

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showAddBrokerDialog() {
    final nameCtrl = TextEditingController();
    final apiCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    String selectedType = 'MT5';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: SynapseTheme.surfaceContainerHigh.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: SynapseTheme.onSurfaceVariant, borderRadius: BorderRadius.circular(9))),
                  ),
                  const SizedBox(height: 20),
                  Text('Añadir Nuevo Broker', style: SynapseTheme.headline(fontSize: 20)),
                  const SizedBox(height: 20),
                  // Broker type selector
                  Text('TIPO DE BROKER', style: SynapseTheme.label(fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: ['MT5', 'MT4', 'cTrader', 'API Propia', 'OANDA', 'Exness', 'Deriv', 'IC Markets']
                      .map((t) => ChoiceChip(
                            label: Text(t, style: SynapseTheme.label(fontSize: 12, color: selectedType == t ? SynapseTheme.onPrimary : SynapseTheme.onSurfaceVariant)),
                            selected: selectedType == t,
                            selectedColor: SynapseTheme.primaryContainer,
                            backgroundColor: SynapseTheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onSelected: (_) => setModal(() => selectedType = t),
                          ))
                      .toList()),
                  const SizedBox(height: 16),
                  _inputField(nameCtrl, 'Nombre de la cuenta', Icons.label_outline),
                  const SizedBox(height: 12),
                  _inputField(apiCtrl, 'MetaApi Token / API Key', Icons.key, obscure: true),
                  const SizedBox(height: 12),
                  _inputField(accountCtrl, 'Account ID / Login', Icons.account_balance),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SynapseTheme.primaryContainer,
                        foregroundColor: SynapseTheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty) {
                          setState(() {
                            _brokers.add(BrokerConfig(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameCtrl.text,
                              logoText: selectedType.substring(0, 2).toUpperCase(),
                              logoColor: SynapseTheme.primaryContainer,
                              apiKey: apiCtrl.text,
                              accountId: accountCtrl.text,
                            ));
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text('VINCULAR BROKER', style: SynapseTheme.headline(fontSize: 15, color: SynapseTheme.onPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBrokerDetail(BrokerConfig broker) {
    final apiCtrl = TextEditingController(text: broker.apiKey);
    final accountCtrl = TextEditingController(text: broker.accountId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: SynapseTheme.surfaceContainerHigh.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: SynapseTheme.onSurfaceVariant, borderRadius: BorderRadius.circular(9))),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: broker.logoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(broker.logoText, style: SynapseTheme.headline(fontSize: 13, color: broker.logoColor))),
                  ),
                  const SizedBox(width: 12),
                  Text(broker.name, style: SynapseTheme.headline(fontSize: 20)),
                ]),
                const SizedBox(height: 20),
                _inputField(apiCtrl, 'MetaApi Token / API Key', Icons.key, obscure: true),
                const SizedBox(height: 12),
                _inputField(accountCtrl, 'Account ID / Login', Icons.account_balance),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SynapseTheme.secondary,
                        side: BorderSide(color: SynapseTheme.secondary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          broker.status = 'disconnected';
                          broker.apiKey = '';
                          broker.accountId = '';
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text('DESCONECTAR', style: SynapseTheme.headline(fontSize: 13, color: SynapseTheme.secondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SynapseTheme.primaryContainer,
                        foregroundColor: SynapseTheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          broker.apiKey = apiCtrl.text;
                          broker.accountId = accountCtrl.text;
                          if (apiCtrl.text.isNotEmpty) broker.status = 'connected';
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text('GUARDAR', style: SynapseTheme.headline(fontSize: 13, color: SynapseTheme.onPrimary)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editPips(bool isTarget) {
    final ctrl = TextEditingController(text: isTarget ? _targetPips.toInt().toString() : _stopLossPips.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SynapseTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isTarget ? 'Take Profit Pips' : 'Stop Loss Pips', style: SynapseTheme.headline(fontSize: 18)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: SynapseTheme.headline(fontSize: 18),
          decoration: InputDecoration(
            suffix: Text('pips', style: SynapseTheme.label()),
            filled: true, fillColor: SynapseTheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SynapseTheme.primaryContainer),
            onPressed: () {
              final v = double.tryParse(ctrl.text) ?? (isTarget ? _targetPips : _stopLossPips);
              setState(() => isTarget ? _targetPips = v : _stopLossPips = v);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: SynapseTheme.label(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 18, color: SynapseTheme.onSurfaceVariant),
        filled: true,
        fillColor: SynapseTheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
