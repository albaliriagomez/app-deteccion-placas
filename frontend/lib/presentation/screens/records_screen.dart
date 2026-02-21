import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';
import 'record_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  final Function(PlateRecord)? onNewRecordAdded;

  const RecordsScreen({
    super.key,
    this.onNewRecordAdded,
  });

  @override
  State<RecordsScreen> createState() => RecordsScreenState();
}

class RecordsScreenState extends State<RecordsScreen> {
  // --- CONSTANTES DE COLOR ---
  static const Color _darkPurple = Color(0xFF311B92);
  static const Color _successGreen = Color(0xFF8BC34A);
  static const Color _errorRed = Color(0xFFE57373);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE0E0E0);
  static const Color _darkGray = Color(0xFF757575);
  static const Color _white = Color(0xFFFFFFFF);

  // --- VARIABLES DE ESTADO ---
  late Future<List<PlateRecord>> _recordsFuture;
  final ApiRepository _apiRepository = ApiRepository();
  final TextEditingController _searchController = TextEditingController();
  
  final List<PlateRecord> _injectedRecords = [];
  String _selectedTimeFilter = 'Hoy';
  List<PlateRecord> _filteredRecords = [];
  List<PlateRecord> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecords() {
    setState(() {
      _recordsFuture = _apiRepository.getPlateRecords();
    });
  }

  void addNewRecord(PlateRecord record) {
    setState(() {
      _injectedRecords.insert(0, record);
      _allRecords.insert(0, record);
      _filterRecords();
    });
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecords = _allRecords
          .where((record) => record.placa.toLowerCase().contains(query))
          .toList();
    });
  }

  void _applyTimeFilter(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
      _filteredRecords = _allRecords.where((record) {
        final now = DateTime.now();
        final recordDate = record.fecha;
        
        switch (filter) {
          case 'Hoy':
            return recordDate.year == now.year &&
                recordDate.month == now.month &&
                recordDate.day == now.day;
          case 'Esta semana':
            final weekAgo = now.subtract(const Duration(days: 7));
            return recordDate.isAfter(weekAgo) && recordDate.isBefore(now.add(const Duration(days: 1)));
          case 'Mes':
            final monthAgo = now.subtract(const Duration(days: 30));
            return recordDate.isAfter(monthAgo) && recordDate.isBefore(now.add(const Duration(days: 1)));
          default:
            return true;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : _lightGray,
      appBar: _buildAppBar(isDark),
      body: FutureBuilder<List<PlateRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _darkPurple));
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else if (!snapshot.hasData || (snapshot.data!.isEmpty && _injectedRecords.isEmpty)) {
            return _buildEmptyState();
          } else {
            _allRecords = [..._injectedRecords, ...snapshot.data!];
            if (_filteredRecords.isEmpty && _searchController.text.isEmpty) {
              _filteredRecords = _allRecords;
            }
            
            return RefreshIndicator(
              color: _darkPurple,
              onRefresh: () async => _loadRecords(),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeFilters(isDark),
                        const SizedBox(height: 16),
                        _buildSearchBar(isDark),
                      ],
                    ),
                  ),
                  _filteredRecords.isEmpty
                      ? _buildNoResultsFound()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            return _buildRecordCard(_filteredRecords[index], isDark);
                          },
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- COMPONENTES DE INTERFAZ ---

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : _white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _darkPurple),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'HISTORIAL DE VERIFICACIÓN',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _darkPurple,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, color: _darkPurple),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTimeFilters(bool isDark) {
    final filters = ['Hoy', 'Esta semana', 'Mes'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) => Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: () => _applyTimeFilter(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedTimeFilter == filter ? _darkPurple : (isDark ? const Color(0xFF3A3A3A) : _mediumGray),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _selectedTimeFilter == filter ? _white : _darkGray,
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3A) : _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mediumGray, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14, color: isDark ? _white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Buscar patente...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: _darkGray),
          prefixIcon: const Icon(Icons.search, color: _darkGray),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRecordCard(PlateRecord record, bool isDark) {
    final isValid = record.estado == 'VÁLIDO';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecordDetailScreen(record: record)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: isValid ? _successGreen : _errorRed, shape: BoxShape.circle),
                child: Icon(isValid ? Icons.check : Icons.gavel, color: _white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.placa, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? _white : Colors.black)),
                    Text(_formatDateTime(record.fecha), style: GoogleFonts.poppins(fontSize: 12, color: _darkGray)),
                    Text('${record.zona} • ${record.ubicacion}', style: GoogleFonts.poppins(fontSize: 11, color: _darkGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isValid ? _successGreen : _errorRed).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(record.estado, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: isValid ? _successGreen : _errorRed)),
                  ),
                  const SizedBox(height: 8),
                  Text(record.supervisor, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _darkGray)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.pop(context),
      backgroundColor: _darkPurple,
      child: const Icon(Icons.qr_code_scanner, color: _white, size: 28),
    );
  }

  // --- HELPERS ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: _mediumGray),
          Text('Sin registros disponibles', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _darkGray)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: _errorRed),
          Text('Error al cargar registros', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _darkGray)),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(child: Text('No se encontraron resultados', style: GoogleFonts.poppins(fontSize: 14, color: _darkGray))),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    
    String dayLabel = (recordDate == today) ? 'Hoy' : '${recordDate.day}/${recordDate.month}/${recordDate.year}';
    return '$dayLabel • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}