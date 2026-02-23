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
  final ApiRepository _apiRepository = ApiRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<PlateRecord> _allRecords = []; // Base de datos local (memoria)
  List<PlateRecord> _filteredRecords = []; // Lo que se muestra
  bool _isLoading = true;
  String _selectedTimeFilter = 'Todos'; // Cambiado a 'Todos' por defecto

  @override
  void initState() {
    super.initState();
    _loadRecords(); // Se llama SOLO una vez
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void addNewRecord(PlateRecord newRecord) {
    setState(() {
      // Insertamos al principio de la lista local
      _allRecords.insert(0, newRecord);
      // Re-aplicamos filtros para que aparezca en pantalla inmediatamente
      _applyFilters();
    });
  }

  // Carga inicial desde el servidor
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await _apiRepository.getPlateRecords();
      setState(() {
        _allRecords = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBarError("Error al conectar con el servidor");
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  // Función única de filtrado (Velocidad instantánea)
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
      SnackBar(content: Text(msg), backgroundColor: _errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : _lightGray,
      appBar: _buildAppBar(isDark),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _darkPurple))
        : RefreshIndicator(
            onRefresh: _loadRecords,
            color: _darkPurple,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
                _filteredRecords.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildRecordCard(_filteredRecords[index], isDark),
                          childCount: _filteredRecords.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- COMPONENTES ---

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : _white,
      elevation: 2,
      automaticallyImplyLeading: false,
      title: Text('HISTORIAL', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _darkPurple)),
    );
  }

  Widget _buildTimeFilters(bool isDark) {
    final filters = ['Todos', 'Hoy', 'Esta semana', 'Mes'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
            selectedColor: _darkPurple,
            labelStyle: GoogleFonts.poppins(
              color: _selectedTimeFilter == filter ? Colors.white : Colors.black,
              fontSize: 12,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar patente...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: isDark ? const Color(0xFF3A3A3A) : _white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildRecordCard(PlateRecord record, bool isDark) {
    final isValid = record.estado == 'VÁLIDO';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecordDetailScreen(record: record)),
        ),
        leading: CircleAvatar(
          backgroundColor: isValid ? _successGreen : _errorRed,
          child: Icon(isValid ? Icons.check : Icons.warning, color: Colors.white),
        ),
        title: Text(record.placa, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${record.ubicacion}\n${_formatDateTime(record.fecha)}'),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildFAB() {
    // Si esta pantalla es una pestaña, el botón debería cerrar o cambiar de tab
    return FloatingActionButton.extended(
      onPressed: () {
        // Esto asume que quieres volver al escáner si está en un Navigator
        // Si quieres que cambie de pestaña, podrías pasarle un callback
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      backgroundColor: _darkPurple,
      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
      label: const Text("ESCANEAR", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No se encontraron registros', style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}