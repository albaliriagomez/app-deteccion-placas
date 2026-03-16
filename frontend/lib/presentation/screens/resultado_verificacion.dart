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
  bool _notificando = false;

  // ✅ Leemos directamente desde SessionManager — siempre disponibles
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

    Color    estadoColor;
    Color    estadoBg;
    IconData estadoIcon;

    if (pagoVigente) {
      estadoColor = Colors.green;
      estadoBg    = const Color(0xFFE8F5E9);
      estadoIcon  = Icons.check_circle;
    } else if (pagoVencido) {
      estadoColor = Colors.red;
      estadoBg    = const Color(0xFFFFEBEE);
      estadoIcon  = Icons.error_outline;
    } else {
      estadoColor = Colors.orange;
      estadoBg    = const Color(0xFFFFF3E0);
      estadoIcon  = Icons.info_outline;
    }

    final horaConsulta =
        "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:"
        "${TimeOfDay.now().minute.toString().padLeft(2, '0')} HS";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
            (route) => false,
          ),
        ),
        title: Text(
          "VERIFICACIÓN",
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2D5E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D2D5E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Card patente + estado ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    color: const Color(0xFF4A2E8E).withOpacity(0.05),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "PATENTE",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.withOpacity(0.8),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ✅ Usa SessionManager directamente
                  Text(
                    _placa.isNotEmpty ? _placa : "SIN DATOS",
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1C24),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: estadoBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, color: estadoColor, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _estado.isEmpty ? "No Registrado" : _estado,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
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

            const SizedBox(height: 35),

            Text(
              "DETALLES DEL REGISTRO",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 15),

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

            const SizedBox(height: 30),

           // ── Botón Nueva verificación ──
          ElevatedButton(
            onPressed: () {
              // Esto reinicia la app en el AppShell apuntando al Dashboard (Case 0)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AppShell(initialIndex: 0)),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D5E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 12),
                Text(
                  "Volver al inicio", // Cambiado para que sea coherente con el Dashboard
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

            const SizedBox(height: 16),

            // ── Botón Notificar infracción ──
            if (esInfraccion)
              _notificando
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                            color: Colors.red),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _notificarInfraccion(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                              color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                        label: Text(
                          "Notificar infracción",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
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

  Future<void> _notificarInfraccion(BuildContext context) async {
    // ✅ Datos vienen de SessionManager — nunca vacíos
    debugPrint("🔔 NOTIFICANDO — placa: $_placa | lat: $_lat | lon: $_lon");

    if (_placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: no se encontró la placa del vehículo"),
          backgroundColor: Colors.red,
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
          // ✅ Pasamos los datos como arguments Y están en SessionManager
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
          content: Text("Error al notificar: $e"),
          backgroundColor: Colors.red,
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

  Widget _detailTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: const Color(0xFF4DB6E1), size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D5E),
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