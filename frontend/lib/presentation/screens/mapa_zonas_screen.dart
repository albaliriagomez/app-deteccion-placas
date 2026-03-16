/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/api_repository.dart';

class MapaZonasScreen extends StatefulWidget {
  const MapaZonasScreen({Key? key}) : super(key: key);

  @override
  State<MapaZonasScreen> createState() => _MapaZonasScreenState();
}

class _MapaZonasScreenState extends State<MapaZonasScreen> {
  final ApiRepository _apiRepository = ApiRepository();
  List<PlateRecord> _registros = [];
  bool _isLoading = true;

  // Centro por defecto (Santa Cruz de la Sierra, ajústalo a tu ciudad si necesitas)
  final LatLng _center = const LatLng(-17.7833, -63.1821); 

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final data = await _apiRepository.getPlateRecords();
      setState(() {
        // Filtramos solo los que tienen coordenadas válidas
        _registros = data.where((r) => r.latitude != null && r.longitude != null).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mapa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Zonas'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? const Center(child: Text('No hay registros con ubicación GPS.'))
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: _registros.isNotEmpty 
                        ? LatLng(_registros.first.latitude!, _registros.first.longitude!)
                        : _center,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tuapp.deteccion',
                    ),
                    MarkerLayer(
                      markers: _registros.map((registro) {
                        final esInfraccion = registro.estado == 'INFRACCIÓN';
                        return Marker(
                          point: LatLng(registro.latitude!, registro.longitude!),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              _mostrarDetalle(context, registro);
                            },
                            child: Icon(
                              Icons.location_on,
                              size: 40,
                              color: esInfraccion ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
    );
  }

  void _mostrarDetalle(BuildContext context, PlateRecord registro) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${registro.placa}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Estado: ${registro.estado}', 
                  style: TextStyle(fontSize: 18, color: registro.estado == 'INFRACCIÓN' ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Ubicación: ${registro.ubicacion}'),
              Text('Fecha: ${registro.fecha.toLocal().toString().split('.')[0]}'),
            ],
          ),
        );
      },
    );
  }
}*/