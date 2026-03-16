import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_manager.dart';
import 'scanner_screen.dart';
import '../screens/app_shell.dart';

class InfraccionRegistradaScreen extends StatefulWidget {
  const InfraccionRegistradaScreen({super.key});

  @override
  State<InfraccionRegistradaScreen> createState() =>
      _InfraccionRegistradaScreenState();
}

class _InfraccionRegistradaScreenState
    extends State<InfraccionRegistradaScreen> {
  // ✅ Datos desde SessionManager — siempre disponibles
  String get _placa => SessionManager.ultimaPlaca;
  Map<String, dynamic> get _registro => SessionManager.ultimoRegistro;

  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final bg        = _darkMode ? const Color(0xFF1A1B2E) : const Color(0xFFF0F2F5);
    final cardBg    = _darkMode ? const Color(0xFF252640) : Colors.white;
    final textMain  = _darkMode ? Colors.white : const Color(0xFF1A1C2E);
    final textSub   = _darkMode ? Colors.white60 : const Color(0xFF8A8FA8);
    final textValue = _darkMode ? Colors.white : const Color(0xFF1A1C2E);
    final labelColor= _darkMode ? Colors.white38 : const Color(0xFF9CA3AF);
    final iconColor = _darkMode ? Colors.white38 : const Color(0xFFB0B8C9);
    final divColor  = _darkMode ? Colors.white10 : const Color(0xFFF0F1F5);

    // ── hora actual ──
    final now = TimeOfDay.now();
    final hora =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} HS";

    // ── fecha ──
    String fecha = "Sin datos";
    if (_registro["fecha"] != null &&
        _registro["fecha"].toString().isNotEmpty) {
      fecha = _formatFechaCorta(_registro["fecha"].toString());
    }

    // ── ubicación ──
    final ubicacion = _registro["ubicacion"]?.toString().isNotEmpty == true
        ? _registro["ubicacion"].toString()
        : "Sin datos";

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Dark mode toggle ──
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => setState(() => _darkMode = !_darkMode),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _darkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                    color: textSub,
                    size: 20,
                  ),
                ),
              ),
            ),

            // ── Contenido principal ──
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ── Ícono check verde ──
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Título ──
                  Text(
                    "Notificación enviada\ncorrectamente",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Subtítulo ──
                  Text(
                    "La infracción ha sido procesada y enviada al\nsistema central de monitoreo.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textSub,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Card detalles ──
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                          child: Text(
                            "DETALLES DEL REGISTRO",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: labelColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        // Patente
                        _detailRow(
                          icon: Icons.directions_car_outlined,
                          label: "Patente",
                          value: _placa.isNotEmpty ? _placa : "SIN DATOS",
                          iconColor: iconColor,
                          textColor: textMain,
                          valueColor: textValue,
                          dividerColor: divColor,
                          showDivider: true,
                          valueBold: true,
                        ),

                        // Hora
                        _detailRow(
                          icon: Icons.access_time_outlined,
                          label: "Hora",
                          value: hora,
                          iconColor: iconColor,
                          textColor: textMain,
                          valueColor: textValue,
                          dividerColor: divColor,
                          showDivider: true,
                        ),

                        // Fecha
                        _detailRow(
                          icon: Icons.calendar_today_outlined,
                          label: "Fecha",
                          value: fecha,
                          iconColor: iconColor,
                          textColor: textMain,
                          valueColor: textValue,
                          dividerColor: divColor,
                          showDivider: true,
                        ),

                        // Ubicación
                        _detailRow(
                          icon: Icons.location_on_outlined,
                          label: "Ubicación",
                          value: ubicacion,
                          iconColor: iconColor,
                          textColor: textMain,
                          valueColor: textValue,
                          dividerColor: divColor,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Botón Volver al inicio ──
                  SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Redirige al AppShell en el índice 0 (MenuScreen)
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
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.home_outlined, size: 22),
                    label: Text(
                      "Volver al inicio",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                  const SizedBox(height: 14),

                  // ── Botón Imprimir Comprobante ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () {
                        // Acción de imprimir — implementar según necesidad
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: textSub,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.print_outlined, size: 20, color: textSub),
                      label: Text(
                        "Imprimir Comprobante",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textSub,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget fila de detalle ──
  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color textColor,
    required Color valueColor,
    required Color dividerColor,
    required bool showDivider,
    bool valueBold = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight:
                        valueBold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }

  // ── Formateador de fecha corta: "24 Oct 2023" ──
  String _formatFechaCorta(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return "${dt.day} ${meses[dt.month]} ${dt.year}";
    } catch (_) {
      return fecha;
    }
  }
}