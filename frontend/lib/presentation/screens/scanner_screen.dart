import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/services/ai_scanner_service.dart';
import '../../data/api_repository.dart';
// Asegúrate de que esta ruta sea la correcta para tu pantalla de registros
import 'records_screen.dart'; 

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

// Agregamos SingleTickerProviderStateMixin para el TabController
class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  final AIScannerService _aiService = AIScannerService();
  final ApiRepository _apiRepository = ApiRepository();
  bool _isCameraReady = false;
  bool _isProcessing = false;
  
  // Controlador de pestañas manual
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // Inicializamos el controlador de 2 pestañas
    _tabController = TabController(length: 2, vsync: this);
    
    // Escuchamos cuando cambias de pestaña para refrescar la lista
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        setState(() {}); // Refresca para recargar RecordsScreen
      }
    });

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    await _controller!.setFocusMode(FocusMode.locked); 
    if (mounted) setState(() => _isCameraReady = true);
  }

  Future<void> _quickCapture() async {
    if (!_isCameraReady || _isProcessing) return;
    setState(() => _isProcessing = true);

    PlateDetection? bestResult;

    try {
      // RÁFAGA FLASH: 3 fotos seguidas (Tu lógica intacta)
      for (int i = 0; i < 3; i++) {
        final XFile photo = await _controller!.takePicture();
        final result = await _aiService.processStaticImage(photo.path);
        
        if (result != null) {
          bestResult = result;
          await File(photo.path).delete();
          break; 
        }
        await File(photo.path).delete();
      }

      if (bestResult != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ DETECTADO: ${bestResult.plate}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          )
        );
        // Guardado en Postgres real
        await _apiRepository.savePlateRecord(bestResult.plate, bestResult.base64Image);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ NO LEÍDO. ACÉRQUESE MÁS")));
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("SISTEMA LPR BOLIVIA"),
        bottom: TabBar(
          controller: _tabController, // Usamos tu controlador manual
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: "ESCANER"),
            Tab(icon: Icon(Icons.list_alt), text: "REGISTROS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Usamos tu controlador manual
        physics: const NeverScrollableScrollPhysics(), 
        children: [
          // PESTAÑA 1: TU CÁMARA ORIGINAL (MANTENIDA)
          Stack(
            children: [
              Positioned.fill(child: CameraPreview(_controller!)),
              Center(
                child: Container(
                  width: 320, height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: _isProcessing ? Colors.red : Colors.blueAccent, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _quickCapture,
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: _isProcessing ? Colors.grey : Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: _isProcessing 
                        ? const Padding(padding: EdgeInsets.all(25), child: CircularProgressIndicator(color: Colors.white)) 
                        : const Icon(Icons.flash_on, size: 45, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // PESTAÑA 2: LA PANTALLA DE REGISTROS (Con recarga forzada)
          RecordsScreen(key: UniqueKey()), 
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _aiService.dispose();
    _tabController.dispose(); // Limpiamos el controlador
    super.dispose();
  }
}