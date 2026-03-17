import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../data/api_repository.dart';

class MapaZonasScreen extends StatefulWidget {
  const MapaZonasScreen({Key? key}) : super(key: key);

  @override
  State<MapaZonasScreen> createState() => _MapaZonasScreenState();
}

class _MapaZonasScreenState extends State<MapaZonasScreen> {
  // ── Paleta oficial de marca ───────────────────────────────────
  static const Color _purple  = Color(0xFF462677);
  static const Color _cyan    = Color(0xFFB2DFEF);
  static const Color _green   = Color(0xFFA5C857);
  static const Color _red     = Color(0xFFE32344);
  static const Color _bgGray  = Color(0xFFF8FAFF);

  final ApiRepository _apiRepository = ApiRepository();
  List<PlateRecord> _registros = [];
  bool _isLoading = true;
  String _filtroEstado = 'Todos';
  final LatLng _center = const LatLng(-17.3935, -66.1570);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiRepository.getPlateRecords();
      setState(() {
        _registros = data
            .where((r) => r.latitude != null && r.longitude != null)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar mapa: $e',
                style: GoogleFonts.poppins()),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<PlateRecord> get _registrosFiltrados {
    if (_filtroEstado == 'Todos') return _registros;
    return _registros
        .where((r) => r.estado.trim() == _filtroEstado)
        .toList();
  }

  Map<String, dynamic> _getStatusConfig(String estado) {
    switch (estado.trim()) {
      case 'Pago Vigente':
        return {
          'bg':          _green.withOpacity(0.15),
          'iconColor':   _green,
          'labelColor':  const Color(0xFF3D5A0D),
          'markerColor': _green,
          'icon':        Icons.check_circle_outline_rounded,
        };
      case 'Pago Vencido':
        return {
          'bg':          _red.withOpacity(0.12),
          'iconColor':   _red,
          'labelColor':  const Color(0xFF8B0E22),
          'markerColor': _red,
          'icon':        Icons.gavel_rounded,
        };
      case 'No Registrado':
        return {
          'bg':          const Color(0xFFFFF4E5),
          'iconColor':   Colors.orange,
          'labelColor':  Colors.orange.shade900,
          'markerColor': Colors.orange,
          'icon':        Icons.warning_amber_rounded,
        };
      default:
        return {
          'bg':          const Color(0xFFF0F0F0),
          'iconColor':   Colors.grey,
          'labelColor':  Colors.grey.shade700,
          'markerColor': Colors.grey,
          'icon':        Icons.help_outline_rounded,
        };
    }
  }

  // ── Botón flotante ────────────────────────────────────────────
  Widget _floatingBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? bg,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg ?? _purple,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bgGray,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _purple))
          : Stack(
              children: [
                // ── Contenido principal ───────────────────────
                Column(
                  children: [
                    // Espacio para la barra flotante
                    SizedBox(height: topPad + 62),
                    _buildFiltros(),
                    _buildContador(),
                    Expanded(child: _buildMapa()),
                  ],
                ),

                // ── Header flotante con gradiente ─────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_purple, Color(0xFF6B3FA0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(0)),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón atrás
                        if (Navigator.of(context).canPop())
                          _floatingBtn(
                            icon: Icons.arrow_back_ios_new_rounded,
                            bg: Colors.white.withOpacity(0.2),
                            onTap: () => Navigator.of(context).pop(),
                          )
                        else
                          const SizedBox(width: 42),

                        // Título
                        Row(
                          children: [
                            Icon(Icons.map_rounded, color: _cyan, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Mapa de Zonas',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // Botón refresh
                        _floatingBtn(
                          icon: Icons.refresh_rounded,
                          bg: Colors.white.withOpacity(0.2),
                          onTap: _cargarDatos,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Chips de filtro ───────────────────────────────────────────
  Widget _buildFiltros() {
    final opciones = [
      {'label': 'Todos',         'color': _purple},
      {'label': 'Pago Vigente',  'color': _green},
      {'label': 'Pago Vencido',  'color': _red},
      {'label': 'No Registrado', 'color': Colors.orange},
    ];

    return Container(
      color: _bgGray,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: opciones.map((opcion) {
            final label    = opcion['label'] as String;
            final color    = opcion['color'] as Color;
            final selected = _filtroEstado == label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (val) {
                  if (val) setState(() => _filtroEstado = label);
                },
                elevation: 0,
                backgroundColor: Colors.white,
                selectedColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide.none,
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _purple,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Contador de estados ───────────────────────────────────────
  Widget _buildContador() {
    final lista        = _registrosFiltrados;
    final vigentes     = lista.where((r) => r.estado.trim() == 'Pago Vigente').length;
    final vencidos     = lista.where((r) => r.estado.trim() == 'Pago Vencido').length;
    final noRegistrado = lista.where((r) => r.estado.trim() == 'No Registrado').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: _purple.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(Icons.map_rounded,
              '${lista.length}', 'Total', _purple),
          _buildDivider(),
          _buildStatChip(Icons.check_circle_outline_rounded,
              '$vigentes', 'Vigentes', _green),
          _buildDivider(),
          _buildStatChip(Icons.gavel_rounded,
              '$vencidos', 'Vencidos', _red),
          _buildDivider(),
          _buildStatChip(Icons.warning_amber_rounded,
              '$noRegistrado', 'Sin reg.', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(value,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: _purple)),
          ],
        ),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(height: 28, width: 1, color: _cyan.withOpacity(0.5));

  // ── Mapa ──────────────────────────────────────────────────────
  Widget _buildMapa() {
    final lista = _registrosFiltrados;

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded,
                size: 60, color: _cyan.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Sin registros con ubicación',
                style: GoogleFonts.poppins(color: _purple.withOpacity(0.5))),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: FlutterMap(
        options: MapOptions(
          initialCenter:
              LatLng(lista.first.latitude!, lista.first.longitude!),
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.tuapp.deteccion',
            backgroundColor: const Color(0xFFE0E0E0),
          ),
          MarkerLayer(
            markers: lista.map((registro) {
              final config = _getStatusConfig(registro.estado);
              return Marker(
                point: LatLng(registro.latitude!, registro.longitude!),
                width: 46,
                height: 46,
                child: GestureDetector(
                  onTap: () => _mostrarDetalle(context, registro),
                  child: Container(
                    decoration: BoxDecoration(
                      color: config['bg'] as Color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (config['markerColor'] as Color).withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (config['markerColor'] as Color)
                              .withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Icon(
                      config['icon'] as IconData,
                      size: 22,
                      color: config['iconColor'] as Color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet detalle ──────────────────────────────────────
  void _mostrarDetalle(BuildContext context, PlateRecord registro) {
    final config = _getStatusConfig(registro.estado);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Placa + estado
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: config['bg'] as Color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (config['markerColor'] as Color).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(config['icon'] as IconData,
                        color: config['iconColor'] as Color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registro.placa,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _purple,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: config['bg'] as Color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            registro.estado.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: config['labelColor'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Separador
              Divider(color: _cyan.withOpacity(0.3), height: 1),
              const SizedBox(height: 16),

              // Ubicación y fecha
              _buildDetalleRow(
                  Icons.location_on_rounded, _purple, registro.ubicacion),
              const SizedBox(height: 10),
              _buildDetalleRow(
                  Icons.calendar_today_rounded,
                  _purple,
                  registro.fecha.toLocal().toString().split('.').first),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalleRow(IconData icon, Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _cyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}