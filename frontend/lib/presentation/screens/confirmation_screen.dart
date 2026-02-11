import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmationScreen extends StatefulWidget {
  final String plate;
  final String imagePath;

  const ConfirmationScreen({
    super.key,
    required this.plate,
    required this.imagePath,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  // Colores
  static const Color _darkPurple = Color(0xFF311B92);
  static const Color _successGreen = Color(0xFF8BC34A);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE0E0E0);
  static const Color _darkGray = Color(0xFF757575);
  static const Color _white = Color(0xFFFFFFFF);

  late TextEditingController _plateController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(text: widget.plate);
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _darkPurple,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '1',
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 2,
              color: _darkPurple,
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _darkPurple,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '2',
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 2,
              color: _mediumGray,
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _mediumGray,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '3',
                  style: GoogleFonts.poppins(
                    color: _darkGray,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            // Imagen capturada
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Overlay gris semi-transparente
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black.withOpacity(0.15),
              ),
            ),
            // Marco guía en el centro
            Center(
              child: Container(
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateEditField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta y estado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Número de patente',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _darkGray,
              ),
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
        // TextField estilizado
        Material(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isEditing ? _darkPurple : _mediumGray,
                width: 2,
              ),
              boxShadow: _isEditing
                  ? [
                      BoxShadow(
                        color: _darkPurple.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
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
                        color: _mediumGray,
                      ),
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
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: _darkPurple,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpText() {
    return Text(
      'Revise el texto. Puede editarlo si hubo un error en el escaneo.',
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _darkGray,
        height: 1.5,
      ),
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
              color: _darkPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: _darkPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación aproximada',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calle 12 e/ 51 y 53, La Plata',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _darkPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Botón primario (Confirmar)
        Material(
          child: GestureDetector(
            onTap: () {
              // Aquí va la lógica de confirmación
              Navigator.pop(context, _plateController.text);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _darkPurple,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _darkPurple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: _white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Confirmar Patente',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botón secundario (Volver a escanear)
        Material(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _darkPurple,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    color: _darkPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Volver a Escanear',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _darkPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
