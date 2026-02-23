import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  late TabController _tabController;
  // Key para acceder al estado de RecordsScreen y agregar registros en caliente
  final GlobalKey<RecordsScreenState> _recordsKey = GlobalKey<RecordsScreenState>();

  // Color palette
  static const Color _neonCyan = Color(0xFF00E5FF);
  static const Color _brightBlue = Color(0xFF4ABFDD);
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
  
  Future<String> _getDetailedAddress() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "GPS Desactivado";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "Permiso denegado";
    }

    Position? position;
    try {
      // Intentamos obtener la posición con un poco más de margen
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // Aumentado a 5s para mayor precisión
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) return "Ubicación no disponible";

    // --- AQUÍ ESTÁ EL CAMBIO CLAVE ---
    List<Placemark> placemarks = [];
    try {
      // Aumentamos el timeout a 5 segundos. La geocodificación a veces es lenta.
      placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print("Error en Geocoding: $e");
      // Si falla la conversión, NO retornamos coordenadas, retornamos un texto descriptivo
      return "Buscando nombre de calle..."; 
    }

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      
      // Prioridad de campos para obtener la dirección más exacta
      String street = place.thoroughfare ?? ""; // Calle
      String number = place.subThoroughfare ?? ""; // Número de casa
      String locality = place.locality ?? ""; // Ciudad/Zona
      
      // Si la calle es "Unnamed road" o está vacía, usamos el nombre del lugar
      if (street.isEmpty || street.toLowerCase().contains("unnamed")) {
        street = place.name ?? "Calle desconocida";
      }

      // Construimos una dirección legible: "Calle Falsa 123, Cochabamba"
      final String fullAddress = [
        street,
        number,
        locality
      ].where((s) => s.isNotEmpty).join(' ');

      return fullAddress.isNotEmpty ? fullAddress : "Dirección no identificada";
    }

    // NUNCA retornar coordenadas puras si lo que quieres son calles
    return "Área sin nombre registrado";
    
  } catch (e) {
    return "Error al obtener dirección";
  }
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
    // DISPARAMOS AMBAS TAREAS AL MISMO TIEMPO
    // La ubicación se busca mientras la cámara toma las fotos
    final results = await Future.wait([
      _getDetailedAddress(), // Tarea 0
      _runDetectionLoop(),    // Tarea 1 (Nueva función abajo)
    ]);

    String currentAddress = results[0] as String;
    Map<String, dynamic>? detectionResult = results[1] as Map<String, dynamic>?;

    if (detectionResult != null) {
      final PlateDetection bestResult = detectionResult['bestResult'];
      final String finalImagePath = detectionResult['path'];

      final resultData = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
            plate: bestResult.plate,
            imagePath: finalImagePath,
            location: currentAddress,
          ),
        ),
      );

      if (resultData != null) {
        // Si ConfirmationScreen ya guardó el registro (saved == true), no volver a guardarlo
        final alreadySaved = resultData['saved'] == true || resultData['saved'] == 'true';
        final plateText = resultData['plate'] ?? '';
        final locationText = resultData['location'] ?? currentAddress;
        
        print("📋 ConfirmationScreen returned: alreadySaved=$alreadySaved, plate=$plateText, location=$locationText");

        // Crear un registro con los datos correctos
        // Usar base64Image en lugar de finalImagePath porque el archivo será borrado
        final PlateRecord newRecord = PlateRecord(
          id: (resultData['id'] != null) ? int.tryParse(resultData['id'].toString()) ?? 0 : 0,
          placa: plateText,
          fecha: DateTime.now(),
          imagen: bestResult.base64Image, // Usar base64 que se preserva en DB
          estado: 'VÁLIDO',
          zona: 'Zona A',
          supervisor: 'SUPERVISOR 01',
          ubicacion: locationText,
        );
        
        // Añadir al RecordsScreen mediante la key
        try {
          _recordsKey.currentState?.addNewRecord(newRecord);
          print("✅ Record injected: ${plateText} @ ${locationText}, image: ${bestResult.base64Image.length} bytes");
        } catch (e) {
          print("❌ Error injecting record: $e");
        }
        
        // Saltar a pestaña de historial
        _tabController.animateTo(1);
      }

      // Limpieza
      if (await File(finalImagePath).exists()) {
        await File(finalImagePath).delete();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se detectó ninguna placa clara")),
      );
    }
  } catch (e) {
    print("Error en captura: $e");
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}

// Función auxiliar para separar la lógica de la cámara
Future<Map<String, dynamic>?> _runDetectionLoop() async {
  for (int i = 0; i < 3; i++) {
    final XFile photo = await _controller!.takePicture();
    final result = await _aiService.processStaticImage(photo.path);
    if (result != null) {
      return {'bestResult': result, 'path': photo.path};
    }
    await File(photo.path).delete();
  }
  return null;
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
      
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildScannerTab(),
          RecordsScreen(key: _recordsKey),
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