import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/parqueo_service.dart';
import '../../services/session_manager.dart';

class VerificandoScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const VerificandoScreen({super.key, required this.data});

  @override
  State<VerificandoScreen> createState() => _VerificandoScreenState();
}

class _VerificandoScreenState extends State<VerificandoScreen> {
  // ── Paleta oficial ────────────────────────────────────────────
  static const Color _purple    = Color(0xFF462677);
  static const Color _purpleMid = Color(0xFF6C559F);
  static const Color _cyan      = Color(0xFFB2DFEF);
  static const Color _cyanMid   = Color(0xFF4ABFDD);
  static const Color _cyanDark  = Color(0xFF00ABD6);
  static const Color _green     = Color(0xFFA5C857);
  static const Color _red       = Color(0xFFE32344);
  static const Color _bgGray    = Color(0xFFF8FAFF);
  static const Color _white     = Colors.white;

  // ── Lógica intacta ────────────────────────────────────────────
  bool _isStep1Done   = false;
  bool _isStep2Active = false;

  @override
  void initState() {
    super.initState();
    _iniciarProceso();
  }

  Future<void> _iniciarProceso() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isStep1Done = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isStep2Active = true);

    _ejecutarLlamadaApi();
  }

  Future<void> _ejecutarLlamadaApi() async {
    try {
      final token = SessionManager.semToken;
      if (token == null) throw Exception("No hay sesión activa");

      final placa     = widget.data["placa"]?.toString()       ?? "";
      final base64Img = widget.data["base64Image"]?.toString() ?? "";
      final ubicacion = widget.data["ubicacion"]?.toString()   ?? "Sin ubicación";
      final latitude  = widget.data["latitude"]?.toString()    ?? "0.0";
      final longitude = widget.data["longitude"]?.toString()   ?? "0.0";

      debugPrint("🚀 Enviando verificación — placa: $placa");

      final response = await ParqueoService.verificarParqueo(
        token:       token,
        placa:       placa,
        base64Image: base64Img,
        ubicacion:   ubicacion,
        latitude:    latitude,
        longitude:   longitude,
      );

      debugPrint("✅ RESPUESTA COMPLETA DEL BACKEND: $response");

      SessionManager.guardarVerificacion(
        verificacion: response,
        placa:        placa,
        latitud:      latitude,
        longitud:     longitude,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/resultadoVerificacion',
        arguments: response,
      );
    } catch (e) {
      debugPrint("❌ Error en verificación: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e",
              style: GoogleFonts.poppins()),
          backgroundColor: _red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,

      // ── AppBar con gradiente morado ───────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_purple, Color(0xFF6B3FA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Icon(Icons.manage_search_rounded,
                    color: _cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Verificando',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 16),

          // ── Indicador de pasos ────────────────────────────────
          _buildProgressIndicator(),

          const Spacer(),

          // ── Loader visual ─────────────────────────────────────
          _buildVisualLoader(),

          const SizedBox(height: 28),

          Text(
            'Verificando pago...',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _purple,
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Consultando base de datos del vehículo en tiempo real.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _purpleMid.withOpacity(0.6),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

          const Spacer(),

          // ── Cards de estado ───────────────────────────────────
          _buildStatusCard(
            icon:      Icons.location_on_rounded,
            title:     'Obteniendo ubicación',
            subtitle:  _isStep1Done
                ? 'Ubicación fijada'
                : 'Detectando GPS...',
            isDone:    _isStep1Done,
          ),

          const SizedBox(height: 10),

          _buildStatusCard(
            icon:      Icons.directions_car_rounded,
            title:     'Validando patente',
            subtitle:  _isStep2Active
                ? 'Verificando placa ${widget.data["placa"]}...'
                : 'Esperando...',
            isDone:    false,
            isLoading: _isStep2Active,
          ),

          const SizedBox(height: 24),

          // ── Footer patente ────────────────────────────────────
          _buildFooterLabel(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Indicador de pasos ────────────────────────────────────────
  Widget _buildProgressIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cyan.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepCircle('1', filled: true),
            _stepLine(filled: true),
            _stepCircle('2', filled: true),
            _stepLine(filled: true),
            _stepCircle('3', filled: true),
          ],
        ),
      ),
    );
  }

  Widget _stepCircle(String label, {required bool filled}) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        gradient: filled
            ? const LinearGradient(
                colors: [_purple, _purpleMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: filled ? null : _cyan.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: filled
              ? Colors.transparent
              : _cyan.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: filled ? _white : _purpleMid,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _stepLine({required bool filled}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 32, height: 3,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [_purple, _cyanMid],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: filled ? null : _cyan.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Loader visual animado ─────────────────────────────────────
  Widget _buildVisualLoader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anillo exterior cyan
        SizedBox(
          width: 150, height: 150,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
                _cyanMid.withOpacity(0.4)),
          ),
        ),
        // Anillo medio morado
        SizedBox(
          width: 120, height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
                _purpleMid.withOpacity(0.3)),
          ),
        ),
        // Círculo central con gradiente
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _purple.withOpacity(0.15),
                _cyanMid.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
                color: _cyanMid.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(
            Icons.search_rounded,
            size: 44,
            color: _purple,
          ),
        ),
      ],
    );
  }

  // ── Card de estado ────────────────────────────────────────────
  Widget _buildStatusCard({
    required IconData icon,
    required String   title,
    required String   subtitle,
    bool isDone    = false,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? _green.withOpacity(0.3)
              : isLoading
                  ? _cyanMid.withOpacity(0.3)
                  : _cyan.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Ícono con fondo dinámico
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDone
                  ? _green.withOpacity(0.12)
                  : isLoading
                      ? _cyanMid.withOpacity(0.12)
                      : _cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : icon,
              color: isDone
                  ? _green
                  : isLoading
                      ? _cyanDark
                      : _purpleMid,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _purple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDone
                        ? _green
                        : isLoading
                            ? _cyanDark
                            : _purpleMid.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Spinner de carga
          if (isLoading)
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_cyanMid),
              ),
            ),
        ],
      ),
    );
  }

  // ── Footer con número de patente ──────────────────────────────
  Widget _buildFooterLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withOpacity(0.08),
            _cyanMid.withOpacity(0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _cyan.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_rounded,
              color: _purple, size: 15),
          const SizedBox(width: 7),
          Text(
            'PATENTE: ${widget.data["placa"]}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _purple,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}