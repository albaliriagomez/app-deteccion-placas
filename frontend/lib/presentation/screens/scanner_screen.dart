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

    final List<String> photoPaths = [];

    try {
      // ── PASO 1: 3 fotos rápidas ───────────────────────────────
      for (int i = 0; i < 3; i++) {
        final XFile photo = await _controller!.takePicture();
        photoPaths.add(photo.path);
      }

      // ── PASO 2: OCR + GPS en paralelo ────────────────────────
      final results = await Future.wait([
        _aiService.processBestOfThree(photoPaths),
        _getPositionSafe(),
      ]);

      final PlateDetection? detection = results[0] as PlateDetection?;
      final Position position          = results[1] as Position;

      // ── PASO 3: Limpiar archivos ──────────────────────────────
      for (final path in photoPaths) {
        try { if (await File(path).exists()) await File(path).delete(); } catch (_) {}
      }

      // ── Sin detección ─────────────────────────────────────────
      if (detection == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ NO SE DETECTÓ PLACA. REINTENTE',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // ── PASO 4: Dirección legible ─────────────────────────────
      final String currentAddress = await _resolveAddress(position);

      // ── PASO 5: Navegar ───────────────────────────────────────
      if (!mounted) return;
      final resultData = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            plate:       detection.plate,
            base64Image: detection.base64Image, // ← ya no necesita imagePath
            location:    currentAddress,
            latitude:    position.latitude.toString(),
            longitude:   position.longitude.toString(),
            hora:        DateTime.now().toIso8601String(),
          ),
        ),
      );

      if (resultData != null && mounted) {
        final plateText    = resultData['plate']    ?? detection.plate;
        final locationText = resultData['location'] ?? currentAddress;

        final PlateRecord newRecord = PlateRecord(
          id:         int.tryParse(resultData['id'] ?? '') ?? 0,
          placa:      plateText,
          fecha:      DateTime.now(),
          imagen:     detection.base64Image,
          estado:     'VÁLIDO',
          zona:       'Zona A',
          supervisor: 'SUPERVISOR 01',
          ubicacion:  locationText,
        );

        _recordsKey.currentState?.addNewRecord(newRecord);
        _tabController.animateTo(1);
      }
    } catch (e) {
      print('Error en captura: $e');
      for (final path in photoPaths) {
        try { await File(path).delete(); } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// GPS con fallback rápido
  Future<Position> _getPositionSafe() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) await Geolocator.requestPermission();
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition() ??
          Position(
            latitude: 0, longitude: 0,
            timestamp: DateTime.now(),
            accuracy: 0, altitude: 0, heading: 0,
            speed: 0, speedAccuracy: 0,
            altitudeAccuracy: 0, headingAccuracy: 0,
          );
    }
  }

  /// Convierte coordenadas a dirección legible
  Future<String> _resolveAddress(Position pos) async {
    if (pos.latitude == 0 && pos.longitude == 0) return 'Ubicación no disponible';
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude)
          .timeout(const Duration(seconds: 4));
      if (marks.isEmpty) return 'Área sin nombre registrado';
      final p = marks.first;
      String street = p.thoroughfare ?? '';
      if (street.isEmpty || street.toLowerCase().contains('unnamed')) {
        street = p.name ?? 'Calle desconocida';
      }
      final parts = [street, p.subThoroughfare ?? '', p.locality ?? '']
          .where((s) => s.isNotEmpty);
      return parts.join(' ').isNotEmpty ? parts.join(' ') : 'Dirección no identificada';
    } catch (_) {
      return 'Ubicación no disponible';
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
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
              Text('Inicializando cámara...',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  )),
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
        Positioned.fill(child: CameraPreview(_controller!)),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.15))),

        // Status bar
        Positioned(
          top: 16, left: 16, right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusChip(
                icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                label: _isFlashOn ? 'FLASH ON' : 'FLASH OFF',
                color: _isFlashOn ? Colors.amber : Colors.white30,
              ),
              _statusChip(
                label: _isProcessing ? 'PROCESANDO...' : 'LISTO',
                color: _isProcessing ? Colors.yellowAccent : _neonCyan,
              ),
            ],
          ),
        ),

        // Marco de escaneo
        Center(
          child: Container(
            width: 320, height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: _neonCyan, width: 3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: _neonCyan.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                BoxShadow(color: _neonCyan.withOpacity(0.2), blurRadius: 40, spreadRadius: 8),
              ],
            ),
            child: Stack(
              children: [
                _corner(top: 8,    left: 8,  borderTop: true,    borderLeft: true),
                _corner(top: 8,    right: 8, borderTop: true,    borderRight: true),
                _corner(bottom: 8, left: 8,  borderBottom: true, borderLeft: true),
                _corner(bottom: 8, right: 8, borderBottom: true, borderRight: true),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.crop_free, color: _neonCyan.withOpacity(0.6), size: 40),
                      const SizedBox(height: 12),
                      Text('POSITION PLATE HERE',
                          style: GoogleFonts.poppins(
                            color: _neonCyan, fontSize: 13,
                            fontWeight: FontWeight.bold, letterSpacing: 1,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Panel inferior
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? _darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20, spreadRadius: 2, offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(icon: Icons.flash_on, onTap: _toggleFlash, isActive: _isFlashOn, isDark: isDark),
                      _buildControlButton(icon: Icons.refresh,   onTap: _initializeCamera, isActive: false, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 62,
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _quickCapture,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.camera_alt, size: 24),
                      label: Text(
                        _isProcessing ? 'CAPTURANDO...' : 'Capture',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _brightBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: Text('Manual Entry',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontSize: 13, fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip({IconData? icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: color, size: 16), const SizedBox(width: 6)],
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Positioned _corner({
    double? top, double? bottom, double? left, double? right,
    bool borderTop = false, bool borderBottom = false,
    bool borderLeft = false, bool borderRight = false,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          border: Border(
            top:    borderTop    ? BorderSide(color: _neonCyan, width: 3) : BorderSide.none,
            bottom: borderBottom ? BorderSide(color: _neonCyan, width: 3) : BorderSide.none,
            left:   borderLeft   ? BorderSide(color: _neonCyan, width: 3) : BorderSide.none,
            right:  borderRight  ? BorderSide(color: _neonCyan, width: 3) : BorderSide.none,
          ),
        ),
      ),
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
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: isActive ? _neonCyan : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isActive ? _neonCyan.withOpacity(0.4) : Colors.black.withOpacity(0.12),
              blurRadius: 12, spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: isActive ? _darkBg : Colors.grey[800], size: 32),
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