import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';

class RecordDetailScreen extends StatefulWidget {
  final PlateRecord record;

  const RecordDetailScreen({
    super.key,
    required this.record,
  });

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  // Colores
  static const Color _darkPurple = Color(0xFF311B92);
  static const Color _successGreen = Color(0xFF8BC34A);
  static const Color _errorRed = Color(0xFFE57373);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE0E0E0);
  static const Color _darkGray = Color(0xFF757575);
  static const Color _white = Color(0xFFFFFFFF);

  // NUEVAS VARIABLES PARA CARGA DINÁMICA
  final ApiRepository _apiRepository = ApiRepository();
  String? _loadedImageData;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    // Si el objeto record viene sin imagen (porque optimizamos la lista), la pedimos
    if (widget.record.imagen.isEmpty) {
      _fetchFullImage();
    } else {
      _loadedImageData = widget.record.imagen;
    }
  }

  Future<void> _fetchFullImage() async {
    setState(() => _isLoadingImage = true);
    try {
      final fullImage = await _apiRepository.getFullImage(widget.record.id);
      if (mounted) {
        setState(() {
          _loadedImageData = fullImage;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isValid = widget.record.estado == 'VÁLIDO';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : _lightGray,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageSection(isDark),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(isValid),
                  const SizedBox(height: 24),
                  _buildInfoCard(isDark, isValid),
                  const SizedBox(height: 24),
                  _buildVerificationCard(isDark),
                  const SizedBox(height: 32),
                  _buildActionButtons(isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE UI ACTUALIZADOS ---

  Widget _buildImageWidget() {
    // 1. Si está cargando desde el API
    if (_isLoadingImage) {
      return const Center(
        child: CircularProgressIndicator(color: _darkPurple),
      );
    }

    final imagePath = _loadedImageData ?? "";
    
    // 2. Si no hay imagen disponible después de la carga
    if (imagePath.isEmpty) {
      return _buildNoImage();
    }

    // 3. Lógica Base64
    if (imagePath.startsWith('/9j/') || imagePath.length > 500) {
      try {
        String base64String = imagePath;
        if (imagePath.contains(',')) {
          base64String = imagePath.split(',').last;
        }
        return Image.memory(
          base64Decode(base64String.trim()),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildNoImage(),
        );
      } catch (e) {
        return _buildNoImage();
      }
    } 

    // 4. Si es una ruta de archivo local (para capturas recién hechas)
    if (imagePath.startsWith('/') || imagePath.contains(':/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildNoImage(),
      );
    }

    return _buildNoImage();
  }

  // El resto de tus métodos permanecen igual o con ajustes mínimos
  Widget _buildImageSection(bool isDark) {
    return Container(
      width: double.infinity,
      height: 300,
      color: isDark ? const Color(0xFF2A2A2A) : _white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImageWidget(),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniBadge(widget.record.estado),
                  _buildZoneChip(widget.record.zona),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers pequeños para limpiar el código
  Widget _buildMiniBadge(String estado) {
    final isValido = estado == 'VÁLIDO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isValido ? _successGreen : _errorRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isValido ? Icons.check_circle : Icons.warning, color: _white, size: 18),
          const SizedBox(width: 8),
          Text(estado, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _white)),
        ],
      ),
    );
  }

  Widget _buildZoneChip(String zona) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(zona, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _white)),
    );
  }

  // ... (Aquí van tus métodos _buildAppBar, _buildNoImage, _buildStatusBadge, 
  // _buildInfoCard, _buildVerificationCard, _buildActionButtons y _formatDateTime 
  // que ya tenías, no necesitan cambios mayores)
  
  // Nota: Asegúrate de mantener _buildNoImage() tal como lo tenías.
  Widget _buildNoImage() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Center(child: Icon(Icons.image_not_supported, size: 80, color: Color(0xFF757575))),
    );
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : _white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _darkPurple),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Detalles del Registro',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _darkPurple,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildStatusBadge(bool isValid) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isValid ? _successGreen.withOpacity(0.15) : _errorRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isValid ? 'VERIFICACIÓN EXITOSA' : 'INFRACCIÓN DETECTADA',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isValid ? _successGreen : _errorRed,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, bool isValid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mediumGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Número de Patente', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _darkGray)),
          const SizedBox(height: 8),
          Text(widget.record.placa, style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: _darkPurple, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          const Divider(color: _mediumGray, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Fecha y Hora', _formatDateTime(widget.record.fecha), isDark),
              _buildInfoItem('Supervisor', widget.record.supervisor, isDark),
            ],
          ),
          const SizedBox(height: 24),
          Text('Ubicación', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: _darkGray)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _darkPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: _darkPurple, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.record.ubicacion, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _darkPurple))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: _darkGray)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? _white : Colors.black)),
      ],
    );
  }

  Widget _buildVerificationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mediumGray, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: _successGreen.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: _successGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permiso Vigente', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? _white : Colors.black)),
                Text('La patente tiene todos los permisos requeridos', style: GoogleFonts.poppins(fontSize: 11, color: _darkGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        _buildButton(Icons.print, 'Imprimir', _darkPurple, isDark ? const Color(0xFF3A3A3A) : _white, _darkPurple),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildButton(IconData icon, String label, Color textColor, Color bgColor, Color iconColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: bgColor == _white || bgColor == const Color(0xFF3A3A3A) ? Border.all(color: _mediumGray) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    String dayLabel = recordDate == today ? 'Hoy' : '${recordDate.day}/${recordDate.month}/${recordDate.year}';
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dayLabel • $timeStr';
  }
}