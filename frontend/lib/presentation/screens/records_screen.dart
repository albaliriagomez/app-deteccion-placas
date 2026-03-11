import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
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

  Map<String, dynamic> _getStatusConfig(String estado) {
    switch (estado.toUpperCase()) {
      case 'INFRACCIÓN':
      case 'INFRACCION':
        return {
          'color': const Color(0xFFFFE9E9),
          'iconColor': Colors.redAccent,
          'icon': Icons.gavel_rounded,
          'labelColor': Colors.red.shade800,
        };
      case 'NO REGISTRADO':
        return {
          'color': const Color(0xFFFFF4E5),
          'iconColor': Colors.orangeAccent,
          'icon': Icons.warning_amber_rounded,
          'labelColor': Colors.orange.shade900,
        };
      case 'VÁLIDO':
      case 'VALIDO':
      default:
        return {
          'color': const Color(0xFFE8F5E9),
          'iconColor': Colors.green,
          'icon': Icons.check_circle_outline_rounded,
          'labelColor': Colors.green.shade800,
        };
    }
  }

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
                // Ajuste de espacio superior para que pegue más arriba
                const SizedBox(height: 50), 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildTimeFilters(),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: _errorMessage != null 
                      ? _buildErrorState()
                      : _filteredRecords.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100, top: 5),
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
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildRecordCard(PlateRecord record) {
    final config = _getStatusConfig(record.estado);
    // Formateo de fecha y hora
    final String dateStr = DateFormat('dd/MM/yyyy').format(record.fecha);
    final String hourStr = DateFormat('HH:mm').format(record.fecha);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecordDetailScreen(record: record)),
          );
        },
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: config['color'],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(config['icon'], color: config['iconColor'], size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              record.placa,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryDark),
            ),
            Text(
              "$dateStr • $hourStr",
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: _accentBlue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.ubicacion, // Muestra la calle/avenida real
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (config['color'] as Color),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.estado.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 9, 
                    fontWeight: FontWeight.bold, 
                    color: config['labelColor']
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por patente...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _accentBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(filter),
            selected: _selectedTimeFilter == filter,
            onSelected: (val) {
              if (val) {
                setState(() => _selectedTimeFilter = filter);
                _applyFilters();
              }
            },
            elevation: 0,
            backgroundColor: Colors.white,
            selectedColor: _primaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: _selectedTimeFilter == filter ? Colors.white : _primaryDark,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('Sin registros encontrados', style: GoogleFonts.poppins(color: Colors.grey)),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 15),
          Text(_errorMessage ?? "Error", style: GoogleFonts.poppins()),
          TextButton(onPressed: _loadRecords, child: const Text("Reintentar"))
        ],
      ),
    );
  }

  void _showSnackBarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }
}