import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  // ── Paleta oficial de marca ───────────────────────────────────
  static const Color _purple  = Color(0xFF462677);
  static const Color _cyan    = Color(0xFFB2DFEF);
  static const Color _green   = Color(0xFFA5C857);
  static const Color _red     = Color(0xFFE32344);
  static const Color _bgGray  = Color(0xFFF8FAFF);

  final ApiRepository _apiRepository = ApiRepository();
  final TextEditingController _searchController = TextEditingController();

  List<PlateRecord> _allRecords      = [];
  List<PlateRecord> _filteredRecords = [];

  bool    _isLoading          = true;
  String? _errorMessage;
  String  _selectedTimeFilter = 'Todos';

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
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final records = await _apiRepository.getPlateRecords();
      if (mounted) {
        setState(() {
          _allRecords      = records;
          _filteredRecords = records;
          _isLoading       = false;
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
      setState(() { _isLoading = false; _errorMessage = msg; });
      _showSnackBarError(msg);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final now   = DateTime.now();
    setState(() {
      _filteredRecords = _allRecords.where((r) {
        final matchesSearch = r.placa.toLowerCase().contains(query);
        bool matchesTime = true;
        if (_selectedTimeFilter == 'Hoy') {
          matchesTime = r.fecha.year  == now.year &&
                        r.fecha.month == now.month &&
                        r.fecha.day   == now.day;
        } else if (_selectedTimeFilter == 'Esta semana') {
          matchesTime = r.fecha.isAfter(now.subtract(const Duration(days: 7)));
        } else if (_selectedTimeFilter == 'Mes') {
          matchesTime = r.fecha.isAfter(now.subtract(const Duration(days: 30)));
        }
        return matchesSearch && matchesTime;
      }).toList();
    });
  }

  // ── Config por los 3 estados reales ──────────────────────────
  Map<String, dynamic> _getStatusConfig(String estado) {
    switch (estado.trim()) {
      case 'Pago Vigente':
        return {
          'bg':         _green.withOpacity(0.14),
          'iconColor':  _green,
          'icon':       Icons.check_circle_outline_rounded,
          'labelColor': const Color(0xFF3D5A0D),
          'badgeBg':    _green.withOpacity(0.14),
        };
      case 'Pago Vencido':
        return {
          'bg':         _red.withOpacity(0.10),
          'iconColor':  _red,
          'icon':       Icons.gavel_rounded,
          'labelColor': const Color(0xFF8B0E22),
          'badgeBg':    _red.withOpacity(0.10),
        };
      case 'No Registrado':
        return {
          'bg':         const Color(0xFFFFF0D6),
          'iconColor':  Colors.orange,
          'icon':       Icons.warning_amber_rounded,
          'labelColor': Colors.orange.shade900,
          'badgeBg':    const Color(0xFFFFF0D6),
        };
      default:
        return {
          'bg':         const Color(0xFFF0F0F0),
          'iconColor':  Colors.grey,
          'icon':       Icons.help_outline_rounded,
          'labelColor': Colors.grey.shade700,
          'badgeBg':    const Color(0xFFF0F0F0),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _purple))
          : RefreshIndicator(
              onRefresh: _loadRecords,
              color: _purple,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _errorMessage != null
                        ? _buildErrorState()
                        : _filteredRecords.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                    bottom: 100, top: 8),
                                itemCount: _filteredRecords.length,
                                itemBuilder: (context, index) =>
                                    _buildRecordCard(
                                        _filteredRecords[index]),
                              ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onNavigateToScanner,
        backgroundColor: _purple,
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner,
            color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Header con gradiente morado (igual al mapa y dashboard) ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, Color(0xFF6B3FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "HISTORIAL",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: _cyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Registros",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Contador total
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _cyan.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _cyan.withOpacity(0.35), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt_rounded,
                            color: _cyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_filteredRecords.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Barra de búsqueda
              _buildSearchBar(),
              const SizedBox(height: 12),
              // Chips de tiempo
              _buildTimeFilters(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Barra de búsqueda ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por patente...',
          hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.55), fontSize: 14),
          prefixIcon:
              Icon(Icons.search, color: _cyan, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Chips de tiempo ───────────────────────────────────────────
  Widget _buildTimeFilters() {
    final filters = ['Todos', 'Hoy', 'Esta semana', 'Mes'];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((filter) {
          final selected = _selectedTimeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTimeFilter = filter);
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? _purple : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Card de registro ──────────────────────────────────────────
  Widget _buildRecordCard(PlateRecord record) {
    final config  = _getStatusConfig(record.estado);
    final dateStr = DateFormat('dd/MM/yyyy').format(record.fecha);
    final hourStr = DateFormat('HH:mm').format(record.fecha);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RecordDetailScreen(record: record)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              // Ícono de estado
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: config['bg'] as Color,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: (config['iconColor'] as Color).withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  config['icon'] as IconData,
                  color: config['iconColor'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placa + fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          record.placa,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _purple,
                          ),
                        ),
                        Text(
                          "$dateStr • $hourStr",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Ubicación
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 13, color: _cyan.withOpacity(0.9)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.ubicacion,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: config['badgeBg'] as Color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.estado.trim(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: config['labelColor'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Flecha
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: _cyan.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Estados vacío / error ─────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: _cyan.withOpacity(0.5)),
          const SizedBox(height: 14),
          Text('Sin registros encontrados',
              style: GoogleFonts.poppins(
                  color: _purple.withOpacity(0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: _red),
          const SizedBox(height: 14),
          Text(_errorMessage ?? "Error",
              style: GoogleFonts.poppins(
                  color: _purple, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _loadRecords,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Reintentar",
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}