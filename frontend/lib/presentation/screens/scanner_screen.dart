import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/ai_scanner_service.dart';
import 'confirmation_screen.dart';
import '../../data/api_repository.dart';
import 'records_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  final AIScannerService _aiService = AIScannerService();
  final ApiRepository _apiRepository = ApiRepository();
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  late TabController _tabController;

  // Color palette
  static const Color _neonCyan = Color(0xFF00E5FF);
  static const Color _brightBlue = Color(0xFF1E88E5);
  static const Color _darkBg = Color(0xFF0D1B2A);
  static const Color _lightBg = Color(0xFFF5F5F5);
  static const Color _darkSurface = Color(0xFF1A2332);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) setState(() {});
    });
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() => _isCameraReady = true);
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraReady) return;
    _isFlashOn = !_isFlashOn;
    await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _quickCapture() async {
    if (!_isCameraReady || _isProcessing) return;
  setState(() => _isProcessing = true);

  try {
    String? finalImagePath;
    PlateDetection? bestResult;

    for (int i = 0; i < 3; i++) {
      final XFile photo = await _controller!.takePicture();
      final result = await _aiService.processStaticImage(photo.path);
      
      if (result != null) {
        bestResult = result;
        finalImagePath = photo.path; // Guardamos la ruta de la imagen que funcionó
        break; 
      }
      await File(photo.path).delete();
    }

    if (bestResult != null && finalImagePath != null) {
      // --- PASO CLAVE: Navegar a la pantalla de confirmación ---
      final confirmedPlate = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
            plate: bestResult!.plate,
            imagePath: finalImagePath!,
          ),
        ),
      );

      // Si el usuario presionó "Confirmar", recibiremos la patente (editada o no)
      if (confirmedPlate != null) {
        await _apiRepository.savePlateRecord(confirmedPlate, bestResult.base64Image);
        
        // Opcional: Mostrar un pequeño aviso de éxito o ir a la pestaña de registros
        _tabController.animateTo(1); 
      }
      
      // Limpiar archivo temporal después de usarlo
      if (await File(finalImagePath).exists()) {
        await File(finalImagePath).delete();
      }

    } else {
      // ... (Tu SnackBar de error de detección)
    }
  } catch (e) {
    print("Error en captura: $e");
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
 }


  void _showResultDialog(String plate, String imageBase) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? _darkSurface : _lightSurface,
        title: Text(
          "✓ Placa Detectada",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : _darkBg,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _neonCyan.withOpacity(0.1),
                border: Border.all(color: _neonCyan, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                plate,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  color: _neonCyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "El registro ha sido guardado exitosamente.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _brightBlue,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (!_isCameraReady) {
      return Scaffold(
        backgroundColor: isDark ? _darkBg : _lightBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_neonCyan),
              ),
              const SizedBox(height: 20),
              Text(
                "Inicializando cámara...",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? _darkBg : _lightBg,
      appBar: AppBar(
        title: Text(
          "License Plate Scanner",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: isDark ? _darkSurface : Colors.white,
        elevation: 8,
        shadowColor: _neonCyan.withOpacity(0.3),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _neonCyan,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          labelColor: _neonCyan,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: "ESCANER"),
            Tab(icon: Icon(Icons.list_alt), text: "REGISTROS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildScannerTab(),
          RecordsScreen(key: UniqueKey()),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Camera preview background
        Positioned.fill(child: CameraPreview(_controller!)),

        // Dark overlay for better contrast
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.15),
          ),
        ),

        // Top status indicators
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (_isFlashOn)
                      const Icon(Icons.flash_on, color: Colors.amber, size: 16)
                    else
                      const Icon(Icons.flash_off, color: Colors.white30, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _isFlashOn ? "FLASH ON" : "FLASH OFF",
                      style: GoogleFonts.poppins(
                        color: _isFlashOn ? Colors.amber : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isProcessing ? "PROCESANDO..." : "LISTO",
                  style: GoogleFonts.poppins(
                    color: _isProcessing ? Colors.yellowAccent : _neonCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Central scanning frame with neon effect
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: _neonCyan, width: 3),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _neonCyan.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _neonCyan.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: _neonCyan, width: 3),
                            left: BorderSide(color: _neonCyan, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: _neonCyan, width: 3),
                            right: BorderSide(color: _neonCyan, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: _neonCyan, width: 3),
                            left: BorderSide(color: _neonCyan, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: _neonCyan, width: 3),
                            right: BorderSide(color: _neonCyan, width: 3),
                          ),
                        ),
                      ),
                    ),
                    // Center guide text
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.crop_free,
                            color: _neonCyan.withOpacity(0.6),
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "POSITION PLATE HERE",
                            style: GoogleFonts.poppins(
                              color: _neonCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom control panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? _darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Control buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.flash_on,
                        onTap: _toggleFlash,
                        isActive: _isFlashOn,
                        isDark: isDark,
                      ),
                      _buildControlButton(
                        icon: Icons.refresh,
                        onTap: () => _initializeCamera(),
                        isActive: false,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Capture button
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _quickCapture,
                      icon: _isProcessing
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.white : Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.camera_alt, size: 24),
                      label: Text(
                        _isProcessing ? "CAPTURING..." : "Capture",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _brightBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Manual entry option
                  TextButton(
                    onPressed: () {}, // TODO: Implement manual entry
                    child: Text(
                      "Manual Entry",
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isActive ? _neonCyan : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isActive ? _neonCyan.withOpacity(0.4) : Colors.black.withOpacity(0.12),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? _darkBg : Colors.grey[800],
          size: 32,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController.dispose();
    super.dispose();
  }
}