import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';
import 'record_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  final Function(dynamic)? onNewRecordAdded;
  final VoidCallback? onNavigateToScanner;

  const RecordsScreen({
    super.key,
    this.onNewRecordAdded,
    this.onNavigateToScanner,
  });

  @override
  State<RecordsScreen> createState() => RecordsScreenState();
}

class RecordsScreenState extends State<RecordsScreen> {
  static const Color _primaryDark = Color(0xFF2D2D5E);
  static const Color _accentBlue = Color(0xFF4DB6E1);
  static const Color _bgGray = Color(0xFFF8FAFF);

  final ApiRepository _apiRepository = ApiRepository();
  final TextEditingController _searchController = TextEditingController();
  
  // CAMBIO: Ahora usamos el tipo PlateRecord definido en tu repositorio
  List<PlateRecord> _allRecords = []; 
  List<PlateRecord> _filteredRecords = []; 
  
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTimeFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadRecords(); 
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void addNewRecord(PlateRecord newRecord) {
    setState(() {
      _allRecords.insert(0, newRecord);
      _applyFilters();
    });
  }

  Future<void> _loadRecords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Llamamos al repo que ya devuelve List<PlateRecord>
      final List<PlateRecord> records = await _apiRepository.getPlateRecords();

      if (mounted) {
        setState(() {
          _allRecords = records;
          _filteredRecords = records;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      _handleError("El servidor tardó demasiado en responder.");
    } catch (e) {
      print("Error detallado: $e");
      _handleError("No se pudo conectar con el servidor.");
    }
  }

  void _handleError(String msg) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
      _showSnackBarError(msg);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now(); 

    setState(() {
      _filteredRecords = _allRecords.where((record) {
        // CAMBIO: Acceso mediante punto (record.placa) porque es un objeto
        final matchesSearch = record.placa.toLowerCase().contains(query);
        final recordDate = record.fecha;
        
        bool matchesTime = true;
        if (_selectedTimeFilter == 'Hoy') {
          matchesTime = recordDate.year == now.year &&
              recordDate.month == now.month &&
              recordDate.day == now.day;
        } else if (_selectedTimeFilter == 'Esta semana') {
          final weekAgo = now.subtract(const Duration(days: 7));
          matchesTime = recordDate.isAfter(weekAgo);
        } else if (_selectedTimeFilter == 'Mes') {
          final monthAgo = now.subtract(const Duration(days: 30));
          matchesTime = recordDate.isAfter(monthAgo);
        }
        return matchesSearch && matchesTime;
      }).toList();
    });
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _primaryDark))
        : RefreshIndicator(
            onRefresh: _loadRecords,
            color: _primaryDark,
            child: Column(
              children: [
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 15),
                      _buildTimeFilters(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _errorMessage != null 
                      ? _buildErrorState()
                      : _filteredRecords.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100, top: 10),
                              itemCount: _filteredRecords.length,
                              itemBuilder: (context, index) => _buildRecordCard(_filteredRecords[index]),
                            ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onNavigateToScanner,
        backgroundColor: _primaryDark,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildRecordCard(PlateRecord record) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      onTap: () {
        // Al tocar, vamos al detalle. El detalle se encargará de pedir la foto.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecordDetailScreen(record: record)),
        );
      },
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFF8FAFF), 
        child: Icon(Icons.directions_car, color: Color(0xFF2D2D5E))
      ),
      title: Text(record.placa, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("${record.fecha.day}/${record.fecha.month}/${record.fecha.year}"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    ),
  );
}


  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar por patente...',
          prefixIcon: Icon(Icons.search, color: _accentBlue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTimeFilters() {
    final filters = ['Todos', 'Hoy', 'Esta semana', 'Mes'];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((filter) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(filter),
            selected: _selectedTimeFilter == filter,
            onSelected: (val) {
              if (val) {
                setState(() => _selectedTimeFilter = filter);
                _applyFilters();
              }
            },
            selectedColor: _primaryDark,
            labelStyle: TextStyle(color: _selectedTimeFilter == filter ? Colors.white : _primaryDark),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text('Sin registros', style: GoogleFonts.poppins(color: Colors.grey)));
  }

  Widget _buildErrorState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded, size: 80, color: Colors.red.withOpacity(0.3)),
              const SizedBox(height: 15),
              Text(
                _errorMessage ?? "Error de conexión",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadRecords,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryDark),
                child: const Text("Reintentar", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnackBarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}