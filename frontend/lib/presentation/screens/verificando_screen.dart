import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/parqueo_service.dart';
import '../../services/session_manager.dart';

class VerificandoScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const VerificandoScreen({super.key, required this.data});

  @override
  State<VerificandoScreen> createState() => _VerificandoScreenState();
}

class _VerificandoScreenState extends State<VerificandoScreen> {
  static const Color _darkPurple = Color(0xFF311B92);
  static const Color _lightGray  = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE0E0E0);
  static const Color _darkGray   = Color(0xFF757575);
  static const Color _white      = Color(0xFFFFFFFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);

  bool _isStep1Done   = false;
  bool _isStep2Active = false;

  @override
  void initState() {
    super.initState();
    _iniciarProceso();
  }

  Future<void> _iniciarProceso() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isStep1Done = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isStep2Active = true);

    _ejecutarLlamadaApi();
  }

  Future<void> _ejecutarLlamadaApi() async {
    try {
      final token = SessionManager.semToken;
      if (token == null) throw Exception("No hay sesión activa");

      final placa      = widget.data["placa"]?.toString()      ?? "";
      final base64Img  = widget.data["base64Image"]?.toString() ?? "";
      final ubicacion  = widget.data["ubicacion"]?.toString()  ?? "Sin ubicación";
      final latitude   = widget.data["latitude"]?.toString()   ?? "0.0";
      final longitude  = widget.data["longitude"]?.toString()  ?? "0.0";

      debugPrint("🚀 Enviando verificación — placa: $placa");

      final response = await ParqueoService.verificarParqueo(
        token:       token,
        placa:       placa,
        base64Image: base64Img,
        ubicacion:   ubicacion,
        latitude:    latitude,
        longitude:   longitude,
      );

      debugPrint("✅ RESPUESTA COMPLETA DEL BACKEND: $response");

      // ✅ GUARDAR en SessionManager antes de navegar
      SessionManager.guardarVerificacion(
        verificacion: response,
        placa:        placa,
        latitud:      latitude,
        longitud:     longitude,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/resultadoVerificacion',
        // ✅ Seguimos pasando arguments como respaldo
        arguments: response,
      );
    } catch (e) {
      debugPrint("❌ Error en verificación: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verificando',
            style: GoogleFonts.poppins(
                color: _darkPurple,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildProgressIndicator(),
          const Spacer(),
          _buildVisualLoader(),
          const SizedBox(height: 40),
          Text('Verificando pago...',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _darkPurple)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Consultando base de datos del vehículo en tiempo real.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _darkGray, fontSize: 14),
            ),
          ),
          const Spacer(),
          _buildStatusCard(
            icon: Icons.location_on,
            title: 'Obteniendo ubicación',
            subtitle:
                _isStep1Done ? 'Ubicación fijada' : 'Detectando GPS...',
            isDone: _isStep1Done,
          ),
          const SizedBox(height: 12),
          _buildStatusCard(
            icon: Icons.directions_car,
            title: 'Validando patente',
            subtitle: _isStep2Active
                ? 'Verificando placa ${widget.data["placa"]}...'
                : 'Esperando...',
            isDone: false,
            isLoading: _isStep2Active,
          ),
          const SizedBox(height: 30),
          _buildFooterLabel(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
            color: _mediumGray,
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepCircle('1', filled: true),
            _stepLine(filled: true),
            _stepCircle('2', filled: true),
            _stepLine(filled: true),
            _stepCircle('3', filled: true),
          ],
        ),
      ),
    );
  }

  Widget _stepCircle(String label, {required bool filled}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          color: filled ? _darkPurple : _white,
          shape: BoxShape.circle),
      child: Center(
        child: Text(label,
            style: GoogleFonts.poppins(
                color: filled ? _white : _darkGray,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Widget _stepLine({required bool filled}) {
    return Container(
        width: 30, height: 2, color: filled ? _darkPurple : _white);
  }

  Widget _buildVisualLoader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                _accentBlue.withOpacity(0.5)),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _accentBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.search, size: 50, color: _accentBlue),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDone    = false,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _accentBlue.withOpacity(0.1),
            child: Icon(
                isDone ? Icons.check : icon,
                color: _accentBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: _darkPurple)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDone ? Colors.green : _darkGray)),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildFooterLabel() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: _mediumGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        'PATENTE: ${widget.data["placa"]}',
        style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _darkPurple),
      ),
    );
  }
}