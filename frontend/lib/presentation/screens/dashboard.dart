import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';
import 'mapa_zonas_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // ── Paleta oficial de marca ───────────────────────────────────
  static const Color _cyan       = Color(0xFFB2DFEF); // Azul claro primario
  static const Color _purple     = Color(0xFF462677); // Morado primario
  static const Color _green      = Color(0xFFA5C857); // Verde secundario
  static const Color _red        = Color(0xFFE32344); // Rojo secundario
  static const Color _bgGray     = Color(0xFFF8FAFF);
  static const Color _white      = Colors.white;

  final ApiRepository _apiRepository = ApiRepository();

  bool _isLoading = true;
  String? _errorMessage;

  int _total        = 0;
  int _vigentes     = 0;
  int _vencidos     = 0;
  int _noRegistrado = 0;
  int _totalHoy     = 0;

  List<PlateRecord> _recientes = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final stats = await _apiRepository.getDashboardStats();
      final porEstado   = Map<String, dynamic>.from(stats['por_estado'] ?? {});
      final recientesRaw = List<Map<String, dynamic>>.from(stats['recientes'] ?? []);

      setState(() {
        _total        = stats['total']     ?? 0;
        _vigentes     = porEstado['Pago Vigente']  ?? 0;
        _vencidos     = porEstado['Pago Vencido']  ?? 0;
        _noRegistrado = porEstado['No Registrado'] ?? 0;
        _totalHoy     = stats['total_hoy'] ?? 0;
        _recientes    = recientesRaw.map((j) => PlateRecord.fromJson(j)).toList();
        _isLoading    = false;
      });
    } catch (e) {
      setState(() {
        _isLoading    = false;
        _errorMessage = 'No se pudo conectar con el servidor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _purple))
            : RefreshIndicator(
                onRefresh: _cargarDatos,
                color: _purple,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBanner(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null) _buildErrorBanner(),
                            _buildStatsGrid(),
                            const SizedBox(height: 16),
                            _buildDistribucion(),
                            const SizedBox(height: 16),
                            _buildQuickAction(),
                            const SizedBox(height: 16),
                            _buildActividadReciente(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Hero banner con gradiente morado → cyan ───────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple, Color(0xFF6B3FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "VISTA GENERAL",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: _cyan,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Dashboard\nde Control",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              // Mini stats inline
              Row(
                children: [
                  _heroBadge('$_total', 'registros', _cyan),
                  const SizedBox(width: 10),
                  _heroBadge('$_totalHoy', 'hoy', _green),
                ],
              ),
            ],
          ),
          // Botón refresh
          GestureDetector(
            onTap: _cargarDatos,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: color.withOpacity(0.85))),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _red.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: _red, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_errorMessage!,
                  style: GoogleFonts.poppins(fontSize: 12, color: _red))),
          TextButton(
              onPressed: _cargarDatos,
              child: Text('Reintentar',
                  style: GoogleFonts.poppins(fontSize: 12, color: _red))),
        ],
      ),
    );
  }

  // ── Grid 2×2 con paleta de marca ──────────────────────────────
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _StatCard(
          gradient: const LinearGradient(
            colors: [_purple, Color(0xFF6B3FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: "Total registros",
          value: _total.toString(),
          icon: Icons.remove_red_eye_outlined,
          textColor: Colors.white,
          iconColor: _cyan,
        ),
        _StatCard(
          gradient: LinearGradient(
            colors: [_cyan, _cyan.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: "Detectados hoy",
          value: _totalHoy.toString(),
          icon: Icons.today_rounded,
          textColor: _purple,
          iconColor: _purple,
        ),
        _StatCard(
          gradient: LinearGradient(
            colors: [_green, _green.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: "Pago Vigente",
          value: _vigentes.toString(),
          icon: Icons.check_circle_outline_rounded,
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
        _StatCard(
          gradient: LinearGradient(
            colors: [_red, _red.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: "Pago Vencido",
          value: _vencidos.toString(),
          icon: Icons.gavel_rounded,
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
      ],
    );
  }

  // ── Distribución de estados ───────────────────────────────────
  Widget _buildDistribucion() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _purple.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Distribución de Estados",
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _purple)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("$_total total",
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _purple)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEstadoRow('Pago Vigente',  _vigentes,     _green, Icons.check_circle_outline_rounded),
          const SizedBox(height: 12),
          _buildEstadoRow('Pago Vencido',  _vencidos,     _red,   Icons.gavel_rounded),
          const SizedBox(height: 12),
          _buildEstadoRow('No Registrado', _noRegistrado,
              const Color(0xFFFF9800), Icons.warning_amber_rounded),
        ],
      ),
    );
  }

  Widget _buildEstadoRow(
      String label, int count, Color color, IconData icon) {
    final pct    = _total > 0 ? count / _total : 0.0;
    final pctStr = _total > 0 ? '${(pct * 100).toStringAsFixed(1)}%' : '0%';
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _purple)),
            ),
            Text('$count',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(width: 8),
            Text(pctStr,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade400)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Botón Mapa ────────────────────────────────────────────────
  Widget _buildQuickAction() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapaZonasScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_purple, Color(0xFF6B3FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _purple.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mapa de Zonas",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
                  Text("$_total registros disponibles",
                      style: GoogleFonts.poppins(
                          color: _cyan.withOpacity(0.9),
                          fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actividad reciente ────────────────────────────────────────
  Widget _buildActividadReciente() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _purple.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Actividad Reciente",
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _purple)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Últimos 5",
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _purple)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_recientes.isEmpty)
            Center(
              child: Text("Sin registros recientes",
                  style: GoogleFonts.poppins(
                      color: Colors.grey, fontSize: 13)),
            )
          else
            ..._recientes.map((r) => _buildRecentItem(r)),
        ],
      ),
    );
  }

  Widget _buildRecentItem(PlateRecord r) {
    final Color color;
    final Color bg;
    final IconData icon;

    switch (r.estado.trim()) {
      case 'Pago Vigente':
        color = _green;
        bg    = _green.withOpacity(0.12);
        icon  = Icons.check_circle_outline_rounded;
        break;
      case 'Pago Vencido':
        color = _red;
        bg    = _red.withOpacity(0.10);
        icon  = Icons.gavel_rounded;
        break;
      default:
        color = const Color(0xFFFF9800);
        bg    = const Color(0xFFFF9800).withOpacity(0.10);
        icon  = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _bgGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.placa,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _purple)),
                Text(r.ubicacion,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${r.fecha.hour.toString().padLeft(2, '0')}:${r.fecha.minute.toString().padLeft(2, '0')}",
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  r.estado.trim(),
                  style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── StatCard con gradiente ────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final LinearGradient gradient;
  final String title, value;
  final IconData icon;
  final Color textColor, iconColor;

  const _StatCard({
    required this.gradient,
    required this.title,
    required this.value,
    required this.icon,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor)),
          const SizedBox(height: 2),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8))),
        ],
      ),
    );
  }
}