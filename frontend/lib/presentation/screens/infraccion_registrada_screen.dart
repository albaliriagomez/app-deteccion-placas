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

class _InfraccionRegistradaScreenState
    extends State<InfraccionRegistradaScreen> {

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
      print("Error enviando notificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 50),

              const Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              Text(
                "Infracción registrada correctamente",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "La infracción ha sido procesada y enviada al sistema central de monitoreo.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14),
              ),

              const SizedBox(height: 40),

              _detailTile("Patente", registro["placa"]),
              _detailTile("Hora",
                  DateTime.now().toString().substring(11, 16) + " HS"),
              _detailTile("Fecha",
                  registro["fecha"].toString().substring(0, 10)),
              _detailTile("Ubicación", registro["ubicacion"]),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScannerScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2E8E),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Nueva verificación",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 14)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}