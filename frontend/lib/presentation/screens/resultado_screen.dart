import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultadoScreen extends StatelessWidget {

  const ResultadoScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final Map<String, dynamic> data =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final estado = data["estado"];
    final registro = data["registro"];
    final parking = data["parking"];

    final bool esValido = estado == "VÁLIDO";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Resultado Verificación"),
        backgroundColor: const Color(0xFF311B92),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            Icon(
              esValido ? Icons.check_circle : Icons.warning,
              color: esValido ? Colors.green : Colors.red,
              size: 100,
            ),

            const SizedBox(height: 20),

            Text(
              esValido ? "PARQUEO VÁLIDO" : "INFRACCIÓN DETECTADA",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: esValido ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 30),

            _infoTile("Placa", registro["placa"]),
            _infoTile("Estado", registro["estado"]),
            _infoTile("Fecha", registro["fecha"]),

            if (parking != null) ...[
              const SizedBox(height: 20),
              _infoTile("Hora Inicio", parking["hour_start"]),
              _infoTile("Hora Fin", parking["hour_end"]),
              _infoTile("Tiempo Pagado", parking["tarifario"]["time"]),
            ],

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF311B92),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text("Volver al inicio"),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value ?? "-"),
    );
  }
}