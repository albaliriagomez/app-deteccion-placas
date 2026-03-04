import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';
import 'record_detail_screen.dart';
import 'scanner_screen.dart'; 

class RecordsScreen extends StatefulWidget {
  final Function(PlateRecord)? onNewRecordAdded;
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
  // --- CONSTANTES DE DISEÑO ---
  static const Color _primaryDark = Color(0xFF2D2D5E);
  static const Color _accentBlue = Color(0xFF4DB6E1);
  static const Color _bgGray = Color(0xFFF8FAFF);

  // --- VARIABLES DE ESTADO ---
  final ApiRepository _apiRepository = ApiRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<PlateRecord> _allRecords = []; 
  List<PlateRecord> _filteredRecords = []; 
  bool _isLoading = true;
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

  // Carga con manejo de Timeout
  Future<void> _loadRecords() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Intentamos obtener los registros
      final records = await _apiRepository.getPlateRecords();
      
      if (mounted) {
        setState(() {
          _allRecords = records;
          _filteredRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBarError("No se pudo conectar con el servidor. Verifica tu conexión.");
      }
    }
  }

  void addNewRecord(PlateRecord newRecord) {
    setState(() {
      _allRecords.insert(0, newRecord);
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        final matchesSearch = record.placa.toLowerCase().contains(query);
        final now = DateTime.now();
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

  void _showSnackBarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _primaryDark))
        : RefreshIndicator(
            onRefresh: _loadRecords,
            color: _primaryDark,
            child: Column(
              children: [
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
                  child: _filteredRecords.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) => _buildRecordCard(_filteredRecords[index]),
                        ),
                ),
              ],
            ),
          ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
            backgroundColor: Colors.white,
            labelStyle: GoogleFonts.poppins(
              color: _selectedTimeFilter == filter ? Colors.white : _primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: _selectedTimeFilter == filter ? _primaryDark : Colors.transparent),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por patente...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _accentBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildRecordCard(PlateRecord record) {
    final isValid = record.estado == 'VÁLIDO';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecordDetailScreen(record: record)),
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isValid ? Icons.check_circle : Icons.warning_amber_rounded, 
            color: isValid ? Colors.green : Colors.red,
            size: 26,
          ),
        ),
        title: Text(
          record.placa, 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _primaryDark)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(record.ubicacion, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            Text(_formatDateTime(record.fecha), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: _accentBlue)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildFAB() {
  return FloatingActionButton(
    onPressed: () {
      if (widget.onNavigateToScanner != null) {
        widget.onNavigateToScanner!();
      }
    },
    backgroundColor: const Color(0xFF1B2430), // Tu color _primaryDark
    elevation: 5,
    shape: const CircleBorder(), 
    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 15),
          Text(
            'Sin registros encontrados', 
            style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2,'0')}/${dateTime.month.toString().padLeft(2,'0')} • ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} HS';
  }
}