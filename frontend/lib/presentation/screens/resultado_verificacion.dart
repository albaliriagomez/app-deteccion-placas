import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'infraccion_registrada_screen.dart';
import 'scanner_screen.dart';

class ResultadoVerificacionScreen extends StatelessWidget {
  const ResultadoVerificacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final registro = data["registro"];
    final parking = data["parking"];
    final estado = data["estado"];

    final bool pagoVigente = estado == "VÁLIDO";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "VERIFICACIÓN",
          style: GoogleFonts.poppins(
            color: const Color(0xFF4A2E8E),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF4A2E8E)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// TARJETA PRINCIPAL
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.05),
                  )
                ],
              ),
              child: Column(
                children: [

                  Text(
                    "PATENTE",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    registro["placa"],
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C2F3A),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: pagoVigente
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pagoVigente
                              ? Icons.check_circle
                              : Icons.warning,
                          color: pagoVigente
                              ? Colors.green
                              : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pagoVigente
                              ? "Pago vigente"
                              : "Infracción detectada",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: pagoVigente
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _detailTile(Icons.calendar_today,
                "Fecha", registro["fecha"].toString().substring(0, 10)),

            _detailTile(Icons.access_time,
                "Hora de consulta",
                parking != null
                    ? parking["hour_end"]
                    : "Sin registro"),

            _detailTile(Icons.location_on,
                "Ubicación", registro["ubicacion"]),

            const Spacer(),

            ElevatedButton(
              onPressed: () {

                if (pagoVigente) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScannerScreen(),
                    ),
                    (route) => false,
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InfraccionRegistradaScreen(),
                      settings: RouteSettings(
                        arguments: {
                          "registro": registro,
                        },
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A2E8E),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                pagoVigente
                    ? "Nueva verificación"
                    : "Registrar infracción",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A2E8E)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ],
            )
          ],
        ),
      ),
    );
  }
}