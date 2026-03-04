import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notificacion_service.dart';
import 'scanner_screen.dart';

class InfraccionRegistradaScreen extends StatefulWidget {
  const InfraccionRegistradaScreen({super.key});

  @override
  State<InfraccionRegistradaScreen> createState() =>
      _InfraccionRegistradaScreenState();
}

class _InfraccionRegistradaScreenState extends State<InfraccionRegistradaScreen> {
  late Map<String, dynamic> registro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic> data =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    registro = data["registro"];

    _enviarNotificacion();
  }

  Future<void> _enviarNotificacion() async {
    try {
      await NotificacionService.enviarNotificacion(
        patente: registro["placa"],
        fecha: registro["fecha"].toString().substring(0, 10),
        hora: DateTime.now().toString().substring(11, 16),
        ubicacion: registro["ubicacion"],
      );
    } catch (e) {
      debugPrint("Error enviando notificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Botón de modo noche (decorativo como el mockup)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.dark_mode, color: Color(0xFF2D2D5E), size: 20),
                ),
              ),

              const SizedBox(height: 20),

              // Icono de Check con efecto de fondo
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
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
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                "La infracción ha sido procesada y enviada al\nsistema central de monitoreo.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              /// CARD DE DETALLES (Estilo exacto al mockup image_64d019.jpg)
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
                    _detailRow(Icons.directions_car_outlined, "Patente", registro["placa"], isBold: true),
                    const Divider(height: 30, color: Color(0xFFF1F4F8)),
                    _detailRow(Icons.access_time, "Hora", "${DateTime.now().toString().substring(11, 16)} HS"),
                    const Divider(height: 30, color: Color(0xFFF1F4F8)),
                    _detailRow(Icons.calendar_today_outlined, "Fecha", registro["fecha"].toString().substring(0, 10)),
                    const Divider(height: 30, color: Color(0xFFF1F4F8)),
                    _detailRow(Icons.location_on_outlined, "Ubicación", registro["ubicacion"]),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // BOTÓN VOLVER AL INICIO
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D5E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_filled, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Volver al inicio",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // BOTÓN IMPRIMIR COMPROBANTE
              OutlinedButton(
                onPressed: () {
                  // Lógica futura de impresión
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  side: const BorderSide(color: Colors.transparent),
                  backgroundColor: const Color(0xFFF0F4FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.print_outlined, color: Color(0xFF2D2D5E), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Imprimir Comprobante",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D2D5E),
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

  Widget _detailRow(IconData icon, String title, String value, {bool isBold = false}) {
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