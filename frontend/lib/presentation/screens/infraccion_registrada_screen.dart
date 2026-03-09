import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/notificacion_service.dart';
import '../../services/session_manager.dart';
import 'app_shell.dart';
import 'scanner_screen.dart';


class InfraccionRegistradaScreen extends StatefulWidget {
  const InfraccionRegistradaScreen({super.key});

  @override
  State<InfraccionRegistradaScreen> createState() =>
      _InfraccionRegistradaScreenState();
}

class _InfraccionRegistradaScreenState extends State<InfraccionRegistradaScreen> {

  Map<String, dynamic> registro = {};
  bool notificacionEnviada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (notificacionEnviada) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null) {
      final mapaArgs = Map<String, dynamic>.from(args as Map);
      final mapaRegistro = mapaArgs["registro"];
      if (mapaRegistro != null) {
        registro = Map<String, dynamic>.from(mapaRegistro as Map);
      }
    }

    _enviarNotificacion();
    notificacionEnviada = true;
  }

  Future<void> _enviarNotificacion() async {

    try {

      final token = SessionManager.semToken;

      if (token == null) {
        debugPrint("Token no disponible");
        return;
      }

      await NotificacionService.enviarNotificacion(
        token: token,
        placa: registro["placa"] ?? "",
        latitude: registro["latitude"] ?? "",
        longitude: registro["longitude"] ?? "",
      );

      debugPrint("Notificación enviada correctamente");

    } catch (e) {

      debugPrint("Error enviando notificación: $e");

    }
  }

  @override
  Widget build(BuildContext context) {

    final placa = registro["placa"] ?? "N/A";
    final fecha = registro["fecha"] ?? "";
    final ubicacion = registro["ubicacion"] ?? "N/A";

    String fechaMostrar = "N/A";

    if (fecha.toString().length >= 10) {
      fechaMostrar = fecha.toString().substring(0, 10);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            children: [

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(8),

                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.dark_mode,
                    color: Color(0xFF2D2D5E),
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Stack(
                alignment: Alignment.center,
                children: [

                  Container(
                    width: 120,
                    height: 120,

                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                  ),

                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Color(0xFF4CAF50),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Text(
                "Infracción registrada\ncorrectamente",
                textAlign: TextAlign.center,

                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C24),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                "La infracción fue enviada automáticamente\nal sistema central.",
                textAlign: TextAlign.center,

                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(
                      "DETALLES DEL REGISTRO",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey.withOpacity(0.4),
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _detailRow(
                      Icons.directions_car_outlined,
                      "Patente",
                      placa,
                      isBold: true,
                    ),

                    const Divider(height: 30),

                    _detailRow(
                      Icons.access_time,
                      "Hora",
                      "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} HS",
                    ),

                    const Divider(height: 30),

                    _detailRow(
                      Icons.calendar_today_outlined,
                      "Fecha",
                      fechaMostrar,
                    ),

                    const Divider(height: 30),

                    _detailRow(
                      Icons.location_on_outlined,
                      "Ubicación",
                      ubicacion,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/app',
                    (route) => false,
                    arguments: 0,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D5E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_rounded),
                    const SizedBox(width: 10),
                    Text(
                      "Volver al Menú",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value,
      {bool isBold = false}) {

    return Row(
      children: [

        Icon(icon, color: Colors.blueGrey.shade300, size: 20),

        const SizedBox(width: 12),

        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.blueGrey.shade400,
          ),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF1A1C24),
            ),
          ),
        ),
      ],
    );
  }
}