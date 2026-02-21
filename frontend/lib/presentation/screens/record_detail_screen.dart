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
            // Imagen del registro
            _buildImageSection(isDark),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado en la parte superior
                  _buildStatusBadge(isValid),
                  
                  const SizedBox(height: 24),
                  
                  // Tarjeta de información del registro
                  _buildInfoCard(isDark, isValid),
                  
                  const SizedBox(height: 24),
                  
                  // Tarjeta de verificación
                  _buildVerificationCard(isDark),
                  
                  const SizedBox(height: 32),
                  
                  // Botones de acción
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

  Widget _buildImageWidget() {
    final imagePath = widget.record.imagen;
    
    if (imagePath.isEmpty) {
      return _buildNoImage();
    }

    // Lógica Robusta: Si empieza con /9j/ es Base64 (JPEG)
    if (imagePath.startsWith('/9j/') || imagePath.length > 500) {
      try {
        // Limpiar el string por si viene con prefijos data:image/jpeg;base64,
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
        print("❌ Error decodificando Base64: $e");
        return _buildNoImage();
      }
    } 

    // Si es una ruta de archivo local
    if (imagePath.startsWith('/') || imagePath.contains(':/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildNoImage(),
      );
    }

    return _buildNoImage();
  }

  // Widget auxiliar para cuando no hay imagen
  Widget _buildNoImage() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Center(child: Icon(Icons.image_not_supported, size: 80, color: Color(0xFF757575))),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Container(
      width: double.infinity,
      height: 300,
      color: isDark ? const Color(0xFF2A2A2A) : _white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen - detectar si es file path o base64
          _buildImageWidget(),
          
          // Overlay superior con estado
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.record.estado == 'VÁLIDO'
                          ? _successGreen
                          : _errorRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.record.estado == 'VÁLIDO'
                              ? Icons.check_circle
                              : Icons.warning,
                          color: _white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.record.estado,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.record.zona,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isValid) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Si es válido verde, si no rojo
          color: isValid ? _successGreen.withOpacity(0.15) : _errorRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isValid ? 'VERIFICACIÓN EXITOSA' : 'INFRACCIÓN DETECTADA',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isValid ? _successGreen : _errorRed, // Color de texto dinámico
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
        border: Border.all(
          color: _mediumGray,
          width: 1,
        ),
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
          // Número de patente
          Text(
            'Número de Patente',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _darkGray,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.record.placa,
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: _darkPurple,
              letterSpacing: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Separador
          Divider(color: _mediumGray, height: 1),
          
          const SizedBox(height: 24),
          
          // Fecha y Hora
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha y Hora',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _darkGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(widget.record.fecha),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? _white : Colors.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supervisor',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _darkGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.record.supervisor,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? _white : Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Ubicación
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicación',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _darkGray,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _darkPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: _darkPurple,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.record.ubicacion,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _darkPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _mediumGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado de Verificación',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? _white : Colors.black,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _successGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: _successGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permiso Vigente',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? _white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La patente tiene todos los permisos requeridos',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        // Botón Imprimir
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A3A3A) : _white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _mediumGray,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Función de impresión en desarrollo',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: _darkPurple,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.print, color: _darkPurple),
                    const SizedBox(width: 12),
                    Text(
                      'Imprimir',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _darkPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botón Editar
        Container(
          decoration: BoxDecoration(
            color: _darkPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Función de edición en desarrollo',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: _darkPurple,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit, color: _white),
                    const SizedBox(width: 12),
                    Text(
                      'Editar Registro',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayLabel;
    if (recordDate == today) {
      dayLabel = 'Hoy';
    } else if (recordDate == yesterday) {
      dayLabel = 'Ayer';
    } else {
      dayLabel = '${recordDate.day}/${recordDate.month}/${recordDate.year}';
    }

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dayLabel • $timeStr';
  }
}
