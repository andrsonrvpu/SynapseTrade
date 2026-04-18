import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/synapse_theme.dart';

/// Premium animated login screen with Google + Email/Password auth.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _passVisible = false;
  bool _isRegister = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _googleLogin() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    final auth = context.read<AuthService>();
    final result = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      widget.onLogin();
    } else if (!result.cancelled) {
      setState(() => _errorMsg = result.error);
    }
  }

  // ── Email Auth ─────────────────────────────────────────────────────────────
  Future<void> _emailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final auth = context.read<AuthService>();
    final result = _isRegister
        ? await auth.registerWithEmail(
            email: _emailCtrl.text,
            password: _passCtrl.text,
            displayName: _nameCtrl.text.isEmpty ? 'Trader' : _nameCtrl.text,
          )
        : await auth.signInWithEmail(
            email: _emailCtrl.text,
            password: _passCtrl.text,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      widget.onLogin();
    } else {
      setState(() => _errorMsg = result.error);
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Ingresa tu correo primero.');
      return;
    }
    final auth = context.read<AuthService>();
    final result = await auth.sendPasswordReset(_emailCtrl.text);
    setState(() => _errorMsg = result.message ?? result.error);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: SynapseTheme.surface,
      body: Stack(
        children: [
          // ── Background gradient orbs ──────────────────────────────────────
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SynapseTheme.primaryContainer.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 100, right: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SynapseTheme.secondary.withOpacity(0.08),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: size.height * 0.07),

                      // ── Logo + Title ────────────────────────────────────
                      Center(
                        child: Column(children: [
                          // Icon
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  SynapseTheme.primaryContainer.withOpacity(0.3),
                                  SynapseTheme.primaryContainer.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: SynapseTheme.primaryContainer.withOpacity(0.35),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: SynapseTheme.primaryContainer.withOpacity(0.25),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text('⚡', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'SynapseTrade',
                            style: SynapseTheme.headline(fontSize: 30, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRegister ? 'Crea tu cuenta de trading' : 'Bienvenido de nuevo',
                            style: SynapseTheme.label(fontSize: 15, color: SynapseTheme.onSurfaceVariant),
                          ),
                        ]),
                      ),

                      SizedBox(height: size.height * 0.05),

                      // ── Google Button ───────────────────────────────────
                      _googleButton(),
                      const SizedBox(height: 20),

                      // ── Divider ─────────────────────────────────────────
                      Row(children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('o continúa con correo',
                              style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.onSurfaceVariant)),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                      ]),
                      const SizedBox(height: 20),

                      // ── Name field (register only) ───────────────────────
                      if (_isRegister) ...[
                        _inputField(
                          controller: _nameCtrl,
                          hint: 'Nombre completo',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Email ────────────────────────────────────────────
                      _inputField(
                        controller: _emailCtrl,
                        hint: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Password ─────────────────────────────────────────
                      _inputField(
                        controller: _passCtrl,
                        hint: 'Contraseña',
                        icon: Icons.lock_outline,
                        obscure: !_passVisible,
                        suffix: GestureDetector(
                          onTap: () => setState(() => _passVisible = !_passVisible),
                          child: Icon(
                            _passVisible ? Icons.visibility_off : Icons.visibility,
                            size: 20, color: SynapseTheme.onSurfaceVariant,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (_isRegister && v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),

                      // ── Forgot password ──────────────────────────────────
                      if (!_isRegister) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _forgotPassword,
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: SynapseTheme.label(fontSize: 12, color: SynapseTheme.primaryContainer),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Error message ─────────────────────────────────────
                      if (_errorMsg != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _errorMsg!.contains('enviado')
                                ? SynapseTheme.primaryContainer.withOpacity(0.1)
                                : SynapseTheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _errorMsg!.contains('enviado')
                                  ? SynapseTheme.primaryContainer.withOpacity(0.3)
                                  : SynapseTheme.secondary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(children: [
                            Icon(
                              _errorMsg!.contains('enviado') ? Icons.check_circle_outline : Icons.error_outline,
                              size: 18,
                              color: _errorMsg!.contains('enviado') ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              _errorMsg!,
                              style: SynapseTheme.label(
                                fontSize: 13,
                                color: _errorMsg!.contains('enviado') ? SynapseTheme.primaryContainer : SynapseTheme.secondary,
                              ),
                            )),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Main action button ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SynapseTheme.primaryContainer,
                            foregroundColor: SynapseTheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: SynapseTheme.primaryContainer.withOpacity(0.3),
                          ),
                          onPressed: _isLoading ? null : _emailAuth,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRegister ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                                  style: SynapseTheme.headline(fontSize: 15, color: SynapseTheme.onPrimary, letterSpacing: 0.5),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Toggle register / login ────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isRegister = !_isRegister;
                            _errorMsg = null;
                          }),
                          child: RichText(
                            text: TextSpan(
                              text: _isRegister
                                  ? '¿Ya tienes cuenta? '
                                  : '¿No tienes cuenta? ',
                              style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.onSurfaceVariant),
                              children: [
                                TextSpan(
                                  text: _isRegister ? 'Iniciar sesión' : 'Registrarse',
                                  style: SynapseTheme.label(fontSize: 14, color: SynapseTheme.primaryContainer),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Legal ─────────────────────────────────────────────
                      Center(
                        child: Text(
                          'Al continuar aceptas los Términos de Uso\ny la Política de Privacidad de SynapseTrade.',
                          textAlign: TextAlign.center,
                          style: SynapseTheme.label(
                            fontSize: 11,
                            color: SynapseTheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Full-screen loading ───────────────────────────────────────────
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: SynapseTheme.surface.withOpacity(0.4),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: SynapseTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(
                          color: SynapseTheme.primaryContainer, strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Autenticando...',
                          style: SynapseTheme.label(fontSize: 14),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Google button ───────────────────────────────────────────────────────────
  Widget _googleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _googleLogin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Google logo in SVG colors
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text('G',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4285F4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Continuar con Google',
            style: SynapseTheme.headline(fontSize: 15, color: Colors.white),
          ),
        ]),
      ),
    );
  }

  // ── Input field ─────────────────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: SynapseTheme.label(fontSize: 15, color: SynapseTheme.onSurface),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SynapseTheme.label(fontSize: 15, color: SynapseTheme.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 20, color: SynapseTheme.onSurfaceVariant),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 40),
        filled: true,
        fillColor: SynapseTheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SynapseTheme.primaryContainer.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SynapseTheme.secondary.withOpacity(0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
