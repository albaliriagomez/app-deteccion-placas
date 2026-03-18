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
  // ── Paleta oficial ────────────────────────────────────────────
  static const Color _purple    = Color(0xFF462677);
  static const Color _purpleMid = Color(0xFF6C559F);
  static const Color _cyan      = Color(0xFFB2DFEF);
  static const Color _cyanMid   = Color(0xFF4ABFDD);
  static const Color _cyanDark  = Color(0xFF00ABD6);
  static const Color _green     = Color(0xFFA5C857);
  static const Color _red       = Color(0xFFE32344);

  // ── Lógica intacta ────────────────────────────────────────────
  String get _placa    => SessionManager.ultimaPlaca;
  Map<String, dynamic> get _registro => SessionManager.ultimoRegistro;

  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    // ── Colores dinámicos dark/light con paleta oficial ────────
    final bg         = _darkMode ? const Color(0xFF1A0F2E) : const Color(0xFFF8FAFF);
    final cardBg     = _darkMode ? const Color(0xFF2A1A4A) : Colors.white;
    final textMain   = _darkMode ? Colors.white           : _purple;
    final textSub    = _darkMode ? Colors.white60         : _purpleMid.withOpacity(0.6);
    final textValue  = _darkMode ? Colors.white           : _purple;
    final labelColor = _darkMode ? Colors.white38         : _purpleMid.withOpacity(0.5);
    final iconColor  = _darkMode ? _cyanMid.withOpacity(0.6) : _purpleMid;
    final divColor   = _darkMode ? Colors.white10         : _cyan.withOpacity(0.3);

    // ── Hora actual ───────────────────────────────────────────
    final now  = TimeOfDay.now();
    final hora =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} HS";

    // ── Fecha ─────────────────────────────────────────────────
    String fecha = "Sin datos";
    if (_registro["fecha"] != null &&
        _registro["fecha"].toString().isNotEmpty) {
      fecha = _formatFechaCorta(_registro["fecha"].toString());
    }

    // ── Ubicación ─────────────────────────────────────────────
    final ubicacion =
        _registro["ubicacion"]?.toString().isNotEmpty == true
            ? _registro["ubicacion"].toString()
            : "Sin datos";

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [

            // ── Toggle dark mode ──────────────────────────────
            Positioned(
              top: 12, right: 16,
              child: GestureDetector(
                onTap: () => setState(() => _darkMode = !_darkMode),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _cyan.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _darkMode
                        ? Icons.wb_sunny_outlined
                        : Icons.dark_mode_outlined,
                    color: _darkMode ? _cyanMid : _purpleMid,
                    size: 20,
                  ),
                ),
              ),
            ),

            // ── Contenido principal ───────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 64),

                  // ── Ícono check con paleta verde oficial ─────
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _green.withOpacity(0.3), width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_green, Color(0xFF7A9E2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _green.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Título ────────────────────────────────────
                  Text(
                    "Notificación enviada\ncorrectamente",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Subtítulo ─────────────────────────────────
                  Text(
                    "La infracción ha sido procesada y enviada al\nsistema central de monitoreo.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: textSub,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Card detalles ─────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: _cyan.withOpacity(
                              _darkMode ? 0.15 : 0.3),
                          width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(
                              _darkMode ? 0.3 : 0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header card
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4, height: 16,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: labelColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Patente
                        _detailRow(
                          icon:         Icons.directions_car_outlined,
                          label:        "Patente",
                          value:        _placa.isNotEmpty ? _placa : "SIN DATOS",
                          iconColor:    iconColor,
                          textColor:    textMain,
                          valueColor:   textValue,
                          dividerColor: divColor,
                          showDivider:  true,
                          valueBold:    true,
                        ),

                        // Hora
                        _detailRow(
                          icon:         Icons.access_time_outlined,
                          label:        "Hora",
                          value:        hora,
                          iconColor:    iconColor,
                          textColor:    textMain,
                          valueColor:   textValue,
                          dividerColor: divColor,
                          showDivider:  true,
                        ),

                        // Fecha
                        _detailRow(
                          icon:         Icons.calendar_today_outlined,
                          label:        "Fecha",
                          value:        fecha,
                          iconColor:    iconColor,
                          textColor:    textMain,
                          valueColor:   textValue,
                          dividerColor: divColor,
                          showDivider:  true,
                        ),

                        // Ubicación
                        _detailRow(
                          icon:         Icons.location_on_outlined,
                          label:        "Ubicación",
                          value:        ubicacion,
                          iconColor:    iconColor,
                          textColor:    textMain,
                          valueColor:   textValue,
                          dividerColor: divColor,
                          showDivider:  false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Botón volver al inicio ────────────────────
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
                      child: ElevatedButton.icon(
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
                          backgroundColor:         Colors.transparent,
                          shadowColor:             Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.home_rounded,
                            color: Colors.white, size: 22),
                        label: Text(
                          "Volver al inicio",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Botón imprimir comprobante ────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Acción de imprimir — implementar según necesidad
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _darkMode ? _cyanMid : _purpleMid,
                        side: BorderSide(
                          color: _darkMode
                              ? _cyanMid.withOpacity(0.4)
                              : _cyan.withOpacity(0.6),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: Icon(
                        Icons.print_outlined,
                        size: 20,
                        color: _darkMode ? _cyanMid : _purpleMid,
                      ),
                      label: Text(
                        "Imprimir Comprobante",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _darkMode ? _cyanMid : _purpleMid,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fila de detalle — lógica intacta, colores actualizados ────
  Widget _detailRow({
    required IconData icon,
    required String   label,
    required String   value,
    required Color    iconColor,
    required Color    textColor,
    required Color    valueColor,
    required Color    dividerColor,
    required bool     showDivider,
    bool valueBold = false,
  }) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(
                      _darkMode ? 0.15 : 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight:
                        valueBold ? FontWeight.w800 : FontWeight.w600,
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

  // ── Formateador intacto ───────────────────────────────────────
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