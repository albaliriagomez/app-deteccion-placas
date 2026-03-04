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
      backgroundColor: const Color(0xFFF8FAFF), // Fondo más claro y moderno
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 26),
            onPressed: () {}, // Lógica de historial si fuera necesaria
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: Color(0xFF2D2D5E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TARJETA PRINCIPAL (PATENTE Y ESTADO)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                  Text(
                    registro["placa"],
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1C24),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          pagoVigente ? Icons.check_circle : Icons.error_outline,
                          color: pagoVigente ? Colors.green : Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          pagoVigente ? "Pago vigente" : "Sin pago activo",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: pagoVigente ? Colors.green : Colors.red,
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
              registro["fecha"].toString().substring(0, 10),
            ),

            _detailTile(
              Icons.access_time_rounded,
              "HORA DE CONSULTA",
              parking != null ? parking["hour_end"] : "Sin registro",
            ),

            _detailTile(
              Icons.location_on_outlined,
              "UBICACIÓN",
              registro["ubicacion"],
            ),

            const SizedBox(height: 40),

            /// BOTONES DE ACCIÓN
            ElevatedButton(
              onPressed: () {
                if (pagoVigente) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                    (route) => false,
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InfraccionRegistradaScreen(),
                      settings: RouteSettings(
                        arguments: {"registro": registro},
                      ),
                    ),
                  );
                }
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
                  Icon(pagoVigente ? Icons.search : Icons.report_problem_outlined, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    pagoVigente ? "Nueva verificación" : "Notificar infracción",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            if (!pagoVigente) ...[
               const SizedBox(height: 15),
               TextButton(
                 onPressed: () => Navigator.pop(context),
                 style: TextButton.styleFrom(
                   minimumSize: const Size(double.infinity, 50),
                 ),
                 child: Text(
                   "Volver",
                   style: GoogleFonts.poppins(
                     color: Colors.grey,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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
            child: Icon(icon, color: const Color(0xFF4DB6E1), size: 22),
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
          )
        ],
      ),
    );
  }
}