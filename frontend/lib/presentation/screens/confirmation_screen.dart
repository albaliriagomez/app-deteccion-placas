import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';
import 'dart:convert';
import '../../services/parqueo_service.dart';
import '../../services/session_manager.dart';
import 'verificando_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final String plate;
  final String base64Image; // ← ahora recibe base64, no path
  final String location;
  final String latitude;
  final String longitude;
  final String hora;

  const ConfirmationScreen({
    super.key,
    required this.plate,
    required this.base64Image,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.hora,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  late TextEditingController _plateController;
  final ApiRepository _apiRepository = ApiRepository();
  bool _isSaving = false;

  // Colores
  static const Color _darkPurple = Color(0xFF311B92);
  static const Color _successGreen = Color(0xFF8BC34A);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE0E0E0);
  static const Color _darkGray = Color(0xFF757575);
  static const Color _white = Color(0xFFFFFFFF);

  bool _isEditing = false;

  // Bytes de la imagen decodificados una sola vez
  late final Uint8List _imageBytes;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(text: widget.plate);
    _imageBytes = base64Decode(widget.base64Image);
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: _lightGray,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildProgressIndicator(),
                const SizedBox(height: 24),
                _buildCapturedImage(),
                const SizedBox(height: 24),
                _buildPlateEditField(),
                const SizedBox(height: 12),
                _buildHelpText(),
                const SizedBox(height: 24),
                _buildLocationChip(),
                const SizedBox(height: 32),
                _buildActionButtons(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _darkPurple),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Confirmar Patente',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkPurple,
        ),
      ),
      centerTitle: false,
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildProgressIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _mediumGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepCircle('1', filled: true),
            _stepLine(filled: true),
            _stepCircle('2', filled: true),
            _stepLine(filled: false),
            _stepCircle('3', filled: false),
          ],
        ),
      ),
    );
  }

  Widget _stepCircle(String label, {required bool filled}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: filled ? _darkPurple : _mediumGray,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: filled ? _white : _darkGray,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _stepLine({required bool filled}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
          width: 40, height: 2, color: filled ? _darkPurple : _mediumGray),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Imagen desde bytes en memoria — no necesita File en disco
  // ─────────────────────────────────────────────────────────────
  Widget _buildCapturedImage() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ← Image.memory en lugar de Image.file
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                _imageBytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
            Center(
              child: Container(
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: _white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildPlateEditField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Número de patente',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500, color: _darkGray),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: _successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LECTURA EXITOSA',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _successGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _isEditing ? _darkPurple : _mediumGray, width: 2),
              boxShadow: _isEditing
                  ? [
                      BoxShadow(
                          color: _darkPurple.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _plateController,
                    onTap: () => setState(() => _isEditing = true),
                    onSubmitted: (_) => setState(() => _isEditing = false),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _darkPurple,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Patente',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: _mediumGray),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isEditing = !_isEditing),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _darkPurple.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: _darkPurple, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildHelpText() {
    return Text(
      'Revise el texto. Puede editarlo si hubo un error en el escaneo.',
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _darkGray,
          height: 1.5),
    );
  }

  Widget _buildLocationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mediumGray, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _darkPurple.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: _darkPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ubicación detectada',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _darkGray)),
                const SizedBox(height: 4),
                Text(widget.location,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _darkPurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        AbsorbPointer(
          absorbing: _isSaving,
          child: Opacity(
            opacity: _isSaving ? 0.6 : 1.0,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkPurple,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    _isSaving ? 'Guardando...' : 'Confirmar Patente',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!_isSaving)
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _darkPurple, width: 2),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              'Volver a Escanear',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _darkPurple),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Guardar: usa base64Image ya en memoria, sin leer File
  // ─────────────────────────────────────────────────────────────

  Future<void> _onConfirm() async {
    Navigator.push(
      context,
      MaterialPageRoute(
      builder: (_) => VerificandoScreen(
        data: {
          "placa": _plateController.text.trim().toUpperCase(),
          "base64Image": widget.base64Image,
          "ubicacion": widget.location,
          "latitude": widget.latitude,
          "longitude": widget.longitude,
        },
      ),
    ),
    );

    try {
      print("OBTENIENDO TOKEN...");
      final token = SessionManager.semToken;

      if (token == null) {
        print("TOKEN ES NULL ❌");
        Navigator.pop(context);
        return;
      }

      print("TOKEN OK ✅");

      final result = await ParqueoService.verificarParqueo(
        token: token,
        placa: _plateController.text.trim().toUpperCase(),
        base64Image: widget.base64Image,
        ubicacion: widget.location,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );
      print("RESULTADO COMPLETO: $result");

      print("RESULTADO: $result");

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/resultadoVerificacion',
        arguments: result,
      );
    } catch (e) {
      print("ERROR EN VERIFICACION ❌: $e");
      if (mounted) Navigator.pop(context);
    }
  }
}
