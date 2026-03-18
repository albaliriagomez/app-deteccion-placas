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

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  final AIScannerService _aiService = AIScannerService();
  bool _isCameraReady  = false;
  bool _isProcessing   = false;
  bool _isFlashOn      = false;

  final GlobalKey<RecordsScreenState> _recordsKey =
      GlobalKey<RecordsScreenState>();

  // ── Paleta oficial de marca ───────────────────────────────────
  static const Color _purple      = Color(0xFF462677); // morado primario
  static const Color _purpleMid   = Color(0xFF6C559F); // morado medio
  static const Color _cyan        = Color(0xFFB2DFEF); // cyan claro
  static const Color _cyanMid     = Color(0xFF4ABFDD); // cyan medio
  static const Color _cyanDark    = Color(0xFF00ABD6); // cyan oscuro
  static const Color _green       = Color(0xFFA5C857); // verde
  static const Color _red         = Color(0xFFE32344); // rojo
  static const Color _darkBg      = Color(0xFF1A0F2E); // fondo oscuro morado
  static const Color _darkSurface = Color(0xFF2A1A4A); // superficie morada
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back);
      if (_controller != null) await _controller!.dispose();
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      print("Error inicializando cámara: $e");
    }
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
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return "Ubicación no disponible";
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
                position.latitude, position.longitude)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        return "Buscando nombre de calle...";
      }
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String street = place.thoroughfare ?? "";
        String number = place.subThoroughfare ?? "";
        String locality = place.locality ?? "";
        if (street.isEmpty || street.toLowerCase().contains("unnamed")) {
          street = place.name ?? "Calle desconocida";
        }
        final String fullAddress =
            [street, number, locality].where((s) => s.isNotEmpty).join(' ');
        return fullAddress.isNotEmpty ? fullAddress : "Dirección no identificada";
      }
      return "Área sin nombre registrado";
    } catch (e) {
      return "Error al obtener dirección";
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraReady) return;
    _isFlashOn = !_isFlashOn;
    await _controller!
        .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _quickCapture() async {
    if (!_isCameraReady || _isProcessing) return;
    setState(() => _isProcessing = true);
    final List<String> photoPaths = [];
    try {
      for (int i = 0; i < 3; i++) {
        final XFile photo = await _controller!.takePicture();
        photoPaths.add(photo.path);
      }
      final results = await Future.wait([
        _aiService.processBestOfThree(photoPaths),
        _getPositionSafe(),
      ]);
      final PlateDetection? detection = results[0] as PlateDetection?;
      final Position position          = results[1] as Position;
      for (final path in photoPaths) {
        try {
          if (await File(path).exists()) await File(path).delete();
        } catch (_) {}
      }
      if (detection == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ NO SE DETECTÓ PLACA. REINTENTE',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              backgroundColor: _red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      final String currentAddress = await _resolveAddress(position);
      if (!mounted) return;
      final resultData = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            plate:       detection.plate,
            base64Image: detection.base64Image,
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

  Future<Position> _getPositionSafe() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        await Geolocator.requestPermission();
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

  Future<String> _resolveAddress(Position pos) async {
    if (pos.latitude == 0 && pos.longitude == 0)
      return 'Ubicación no disponible';
    try {
      final marks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude)
              .timeout(const Duration(seconds: 4));
      if (marks.isEmpty) return 'Área sin nombre registrado';
      final p = marks.first;
      String street = p.thoroughfare ?? '';
      if (street.isEmpty || street.toLowerCase().contains('unnamed')) {
        street = p.name ?? 'Calle desconocida';
      }
      final parts =
          [street, p.subThoroughfare ?? '', p.locality ?? '']
              .where((s) => s.isNotEmpty);
      return parts.join(' ').isNotEmpty
          ? parts.join(' ')
          : 'Dirección no identificada';
    } catch (_) {
      return 'Ubicación no disponible';
    }
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: _darkBg,
        body: Center(
          child: CircularProgressIndicator(color: _cyanMid),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _darkBg,
      body: _buildScannerTab(),
    );
  }

  Widget _buildScannerTab() {
    return Stack(
      children: [
        // ── Cámara ────────────────────────────────────────────
        Positioned.fill(child: CameraPreview(_controller!)),

        // ── Overlay oscuro con tinte morado ───────────────────
        Positioned.fill(
          child: Container(
            color: _purple.withOpacity(0.18),
          ),
        ),

        // ── Status bar ────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusChip(
                icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                label: _isFlashOn ? 'FLASH ON' : 'FLASH OFF',
                color: _isFlashOn ? Colors.amber : Colors.white60,
              ),
              _statusChip(
                label: _isProcessing ? 'PROCESANDO...' : 'LISTO',
                color: _isProcessing ? _green : _cyanMid,
              ),
            ],
          ),
        ),

        // ── Marco de escaneo con paleta oficial ───────────────
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: _cyanMid, width: 2.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _cyanMid.withOpacity(0.45),
                        blurRadius: 22,
                        spreadRadius: 2),
                    BoxShadow(
                        color: _purple.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 8),
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
                          Icon(Icons.crop_free,
                              color: _cyanMid.withOpacity(0.7), size: 38),
                          const SizedBox(height: 10),
                          Text(
                            'POSITION PLATE HERE',
                            style: GoogleFonts.poppins(
                              color: _cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Hint bajo el marco
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _darkBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _cyanMid.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  'Centra la patente dentro del marco',
                  style: GoogleFonts.poppins(
                    color: _cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Panel inferior ────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              // Gradiente morado oscuro → superficie
              gradient: LinearGradient(
                colors: [_darkBg, _darkSurface],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: _cyanMid.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Botones de control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.flash_on,
                        label: 'Flash',
                        onTap: _toggleFlash,
                        isActive: _isFlashOn,
                      ),
                      _buildControlButton(
                        icon: Icons.refresh_rounded,
                        label: 'Reset',
                        onTap: _initializeCamera,
                        isActive: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Botón principal de captura
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _isProcessing
                            ? null
                            : LinearGradient(
                                colors: [_cyanDark, _cyanMid],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isProcessing
                            ? []
                            : [
                                BoxShadow(
                                  color: _cyanMid.withOpacity(0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                        color: _isProcessing ? Colors.grey.shade700 : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _quickCapture,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded, size: 24),
                        label: Text(
                          _isProcessing ? 'CAPTURANDO...' : 'Capturar Patente',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Entrada manual
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.keyboard_alt_outlined,
                        color: _cyan.withOpacity(0.7), size: 16),
                    label: Text(
                      'Entrada manual',
                      style: GoogleFonts.poppins(
                        color: _cyan.withOpacity(0.7),
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

  // ── Chip de estado ────────────────────────────────────────────
  Widget _statusChip(
      {IconData? icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _darkBg.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }

  // ── Esquinas del marco ────────────────────────────────────────
  Positioned _corner({
    double? top, double? bottom, double? left, double? right,
    bool borderTop    = false,
    bool borderBottom = false,
    bool borderLeft   = false,
    bool borderRight  = false,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          border: Border(
            top:    borderTop    ? BorderSide(color: _cyanMid, width: 3) : BorderSide.none,
            bottom: borderBottom ? BorderSide(color: _cyanMid, width: 3) : BorderSide.none,
            left:   borderLeft   ? BorderSide(color: _cyanMid, width: 3) : BorderSide.none,
            right:  borderRight  ? BorderSide(color: _cyanMid, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Botón de control (flash / reset) ─────────────────────────
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isActive
                  ? _cyanMid
                  : _darkSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? _cyanMid
                    : _cyanMid.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? _cyanMid.withOpacity(0.45)
                      : _purple.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive ? _darkBg : _cyan,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isActive ? _cyanMid : _cyan.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}