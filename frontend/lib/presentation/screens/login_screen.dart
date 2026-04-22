import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/session_manager.dart';
import '../../core/config/env_config.dart';

class LoginScreen extends StatefulWidget {
  /// Si viene con [sessionExpired] = true, muestra aviso automático
  final bool sessionExpired;
  const LoginScreen({super.key, this.sessionExpired = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // ── Paleta oficial ────────────────────────────────────────────
  static const Color _purple     = Color(0xFF462677);
  static const Color _purpleMid  = Color(0xFF6C559F);
  static const Color _cyan       = Color(0xFFB2DFEF);
  static const Color _cyanMid    = Color(0xFF4ABFDD);
  static const Color _cyanDark   = Color(0xFF00ABD6);
  static const Color _green      = Color(0xFFA5C857);
  static const Color _red        = Color(0xFFE32344);
  static const Color _orange     = Color(0xFFFF8C00);

  bool _obscure   = true;
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _shakeController;
  late Animation<double>    _shakeAnim;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Mostrar aviso de sesión expirada si corresponde
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSessionExpiredDialog();
      });
    }
  }

  // ── Diálogo sesión expirada ───────────────────────────────────
  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono de reloj
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_off_rounded,
                    color: _orange, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                'Sesión terminada',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _purple),
              ),
              const SizedBox(height: 10),
              Text(
                'Tu turno de 8 horas ha finalizado.\nPor seguridad, debes volver a ingresar tus credenciales.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Entendido, ingresar',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<void> _login() async {
    if (_userController.text.trim().isEmpty || _passController.text.isEmpty) {
      _showError("Por favor llene todos los campos");
      _shakeController.forward(from: 0);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${EnvConfig.baseUrl}/api/login');
      print("🌐 URL: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userController.text.trim(),
          'password': _passController.text,
        }),
      ).timeout(const Duration(minutes: 1));

      print("📡 STATUS: ${response.statusCode}");
      print("📡 BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        await SessionManager.guardarSesion(
          token:    data['sem_token'],
          user:     data['username'],
          userRole: data['role'],
          email:    _userController.text.trim().toLowerCase(),
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/app');
      } else {
        print("❌ LOGIN FALLÓ — status: ${response.statusCode}");
        _showError("Usuario o contraseña incorrectos");
        _shakeController.forward(from: 0);
      }
    } catch (e) {
      print("🔥 EXCEPCIÓN: $e");
      _showError("Error de conexión con el servidor");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          // ── Fondo decorativo superior ──────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.42,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purple, Color(0xFF6B3FA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40)),
              ),
            ),
          ),

          // ── Círculos decorativos ───────────────────────────
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyanMid.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: 60, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withOpacity(0.08),
              ),
            ),
          ),

          // ── Contenido principal ────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Banner de sesión expirada (visible antes del diálogo)
                  if (widget.sessionExpired)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _orange.withOpacity(0.4), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_off_rounded,
                                color: _orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Sesión de 8 horas finalizada.\nVuelve a ingresar para continuar.',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _orange,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Escudo + títulos ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: _purple.withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: _cyanMid.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                            border: Border.all(
                                color: _cyan.withOpacity(0.4), width: 2.5),
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/Escudo-GAMC-vertical_CMYK.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SEM',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _cyan.withOpacity(0.4), width: 1),
                          ),
                          child: Text(
                            'SUPERVISIÓN & ADMINISTRACIÓN',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: _cyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Alcaldía de Cochabamba',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Card de login con efecto shake ─────────
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) {
                      final offset = _shakeController.isAnimating
                          ? _shakeAnim.value *
                              ((_shakeController.value * 10).toInt() % 2 == 0
                                  ? 1
                                  : -1)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withOpacity(0.10),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4, height: 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_purple, _cyanMid],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bienvenido',
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: _purple)),
                                  Text('Ingresa tus credenciales SEM',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey.shade500)),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _buildInput(
                            controller: _userController,
                            hint:  "correo@sem.gob.bo",
                            label: "Email SEM",
                            icon:  Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),

                          _buildInput(
                            controller: _passController,
                            hint:   "••••••••",
                            label:  "Contraseña",
                            icon:   Icons.lock_outline_rounded,
                            isPass: true,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero),
                              child: Text(
                                "¿Olvidó su contraseña?",
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: _cyanDark,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? null
                                    : const LinearGradient(
                                        colors: [_purple, _purpleMid],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                color: _isLoading
                                    ? Colors.grey.shade300
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: _purple.withOpacity(0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        )
                                      ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login_rounded,
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Ingresar al Sistema',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'O ACCEDER CON',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _biometricBtn(Icons.fingerprint_rounded, 'Huella'),
                      const SizedBox(width: 16),
                      _biometricBtn(Icons.face_rounded, 'Facial'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'SEM Cochabamba · v2.0 · 2025',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    bool isPass = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _purple),
        ),
        const SizedBox(height: 7),
        TextField(
          controller:  controller,
          obscureText: isPass ? _obscure : false,
          style: GoogleFonts.poppins(fontSize: 14, color: _purple),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: _purpleMid, size: 20),
            suffixIcon: isPass
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _purpleMid,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF4F6FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: _cyanMid, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 15, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _biometricBtn(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _cyan.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Icon(icon, color: _purpleMid, size: 28),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}