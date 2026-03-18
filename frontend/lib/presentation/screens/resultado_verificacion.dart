import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/notificacion_service.dart';
import '../../services/session_manager.dart';
import 'infraccion_registrada_screen.dart';
import 'scanner_screen.dart';
import '../screens/app_shell.dart';

class ResultadoVerificacionScreen extends StatefulWidget {
  const ResultadoVerificacionScreen({super.key});

  @override
  State<ResultadoVerificacionScreen> createState() =>
      _ResultadoVerificacionScreenState();
}

class _ResultadoVerificacionScreenState
    extends State<ResultadoVerificacionScreen> {
  // ── Paleta oficial ────────────────────────────────────────────
  static const Color _purple    = Color(0xFF462677);
  static const Color _purpleMid = Color(0xFF6C559F);
  static const Color _cyan      = Color(0xFFB2DFEF);
  static const Color _cyanMid   = Color(0xFF4ABFDD);
  static const Color _cyanDark  = Color(0xFF00ABD6);
  static const Color _green     = Color(0xFFA5C857);
  static const Color _red       = Color(0xFFE32344);
  static const Color _bgGray    = Color(0xFFF8FAFF);

  bool _notificando = false;

  Map<String, dynamic> get _data     => SessionManager.ultimaVerificacion;
  Map<String, dynamic> get _registro => SessionManager.ultimoRegistro;
  String               get _estado   => SessionManager.ultimoEstado;
  String               get _placa    => SessionManager.ultimaPlaca;
  String               get _lat      => SessionManager.ultimaLatitud;
  String               get _lon      => SessionManager.ultimaLongitud;

  @override
  Widget build(BuildContext context) {
    final parking = _data["parking"];

    final bool pagoVigente  = _estado == "Pago Vigente";
    final bool pagoVencido  = _estado == "Pago Vencido";
    final bool noRegistrado = _estado == "No Registrado";
    final bool esInfraccion = pagoVencido || noRegistrado;

    // ── Config visual por estado ──────────────────────────────
    Color    estadoColor;
    Color    estadoBg;
    Color    estadoBorder;
    IconData estadoIcon;

    if (pagoVigente) {
      estadoColor  = _green;
      estadoBg     = _green.withOpacity(0.12);
      estadoBorder = _green.withOpacity(0.3);
      estadoIcon   = Icons.check_circle_rounded;
    } else if (pagoVencido) {
      estadoColor  = _red;
      estadoBg     = _red.withOpacity(0.10);
      estadoBorder = _red.withOpacity(0.3);
      estadoIcon   = Icons.gavel_rounded;
    } else {
      estadoColor  = Colors.orange;
      estadoBg     = Colors.orange.withOpacity(0.10);
      estadoBorder = Colors.orange.withOpacity(0.3);
      estadoIcon   = Icons.warning_amber_rounded;
    }

    final horaConsulta =
        "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:"
        "${TimeOfDay.now().minute.toString().padLeft(2, '0')} HS";

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
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: Colors.white),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const ScannerScreen()),
                (route) => false,
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: _cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  "VERIFICACIÓN",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Card patente + estado ─────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_purple, Color(0xFF6B3FA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Stack(
                children: [
                  // Círculos decorativos
                  Positioned(
                    top: -20, right: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _cyanMid.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -15, left: -15,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _cyan.withOpacity(0.08),
                      ),
                    ),
                  ),

                  // Contenido
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    child: Column(
                      children: [
                        // Label PATENTE
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _cyan.withOpacity(0.3), width: 1),
                          ),
                          child: Text(
                            "PATENTE",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _cyan,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Número de placa
                        Text(
                          _placa.isNotEmpty ? _placa : "SIN DATOS",
                          style: GoogleFonts.poppins(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Badge estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: estadoBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: estadoBorder, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(estadoIcon,
                                  color: estadoColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _estado.isEmpty
                                    ? "No Registrado"
                                    : _estado,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: estadoColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Sección label ─────────────────────────────────
            Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_purple, _cyanMid],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "DETALLES DEL REGISTRO",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _purple.withOpacity(0.6),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Tiles de detalle ──────────────────────────────
            _detailTile(
              Icons.calendar_today_outlined,
              "FECHA",
              _registro["fecha"] != null &&
                      _registro["fecha"].toString().isNotEmpty
                  ? _formatFecha(_registro["fecha"].toString())
                  : "Sin datos",
            ),

            _detailTile(
              Icons.access_time_rounded,
              "HORA DE CONSULTA",
              horaConsulta,
            ),

            _detailTile(
              Icons.location_on_outlined,
              "UBICACIÓN",
              _registro["ubicacion"]?.toString().isNotEmpty == true
                  ? _registro["ubicacion"].toString()
                  : "Sin datos",
            ),

            if (parking != null && parking["hour_end"] != null)
              _detailTile(
                Icons.timer_outlined,
                "HORA FIN PARQUEO",
                parking["hour_end"].toString(),
              ),

            const SizedBox(height: 24),

            // ── Botón volver al inicio ────────────────────────
            SizedBox(
              width: double.infinity,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_purple, _purpleMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AppShell(initialIndex: 0)),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor:     Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Volver al inicio",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Botón notificar infracción ────────────────────
            if (esInfraccion)
              _notificando
                  ? Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                            color: _red),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton.icon(
                        onPressed: _notificando
                            ? null
                            : () => _notificarInfraccion(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _red,
                          side: BorderSide(color: _red, width: 2),
                          backgroundColor: _red.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: Icon(Icons.warning_amber_rounded,
                            color: _red, size: 22),
                        label: Text(
                          "Notificar infracción",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _red,
                          ),
                        ),
                      ),
                    ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Lógica intacta ────────────────────────────────────────────
  Future<void> _notificarInfraccion(BuildContext context) async {
    if (_notificando) return;
    debugPrint(
        "🔔 NOTIFICANDO — placa: $_placa | lat: $_lat | lon: $_lon");
    if (_placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Error: no se encontró la placa del vehículo",
              style: GoogleFonts.poppins()),
          backgroundColor: _red,
        ),
      );
      return;
    }
    setState(() => _notificando = true);
    try {
      final token = SessionManager.semToken;
      if (token == null) throw Exception("No hay sesión activa");
      await NotificacionService.enviarNotificacion(
        token:     token,
        placa:     _placa,
        latitude:  _lat,
        longitude: _lon,
      );
      debugPrint("✅ Notificación enviada");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const InfraccionRegistradaScreen(),
          settings: RouteSettings(
            arguments: {
              "registro": {
                ..._registro,
                "placa": _placa,
              }
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ ERROR AL NOTIFICAR: $e");
      if (!mounted) return;
      setState(() => _notificando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al notificar: $e",
              style: GoogleFonts.poppins()),
          backgroundColor: _red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre',
        'Diciembre'
      ];
      return "${dt.day} de ${meses[dt.month]}, ${dt.year}";
    } catch (_) {
      return fecha;
    }
  }

  // ── Tile de detalle con paleta oficial ────────────────────────
  Widget _detailTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cyan.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Ícono con fondo cyan
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _purple, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _purpleMid.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}