// lib/presentation/screens/records_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/api_repository.dart'; // Importa el ApiRepository

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late Future<List<PlateRecord>> _recordsFuture;
  final ApiRepository _apiRepository = ApiRepository();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    setState(() {
      _recordsFuture = _apiRepository.getPlateRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadRecords(), // Permite refrescar arrastrando
      child: FutureBuilder<List<PlateRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}. ¿El servidor está corriendo?'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Aún no hay registros. ¡Empieza a escanear!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          } else {
            // Mostrar la lista de registros
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final record = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.placa,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fecha: ${record.fecha.toLocal().toString().split('.')[0]}', // Formato legible
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        // Mostrar la imagen
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              base64Decode(record.imagen),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200, // Altura fija para las imágenes
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 100, color: Colors.red);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}