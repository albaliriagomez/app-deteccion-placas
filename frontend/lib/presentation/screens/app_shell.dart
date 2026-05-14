import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/session_manager.dart';
import 'dashboard.dart';
import 'scanner_screen.dart';
import 'records_screen.dart';
import 'mapa_zonas_screen.dart';
import 'dictado_placa_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;

  // ── Paleta oficial ────────────────────────────────────────────
  static const Color _purple     = Color(0xFF462677);
  static const Color _purpleMid  = Color(0xFF6C559F);
  static const Color _cyan       = Color(0xFFB2DFEF);
  static const Color _cyanMid    = Color(0xFF4ABFDD);
  static const Color _cyanDark   = Color(0xFF00ABD6);
  static const Color _green      = Color(0xFFA5C857);
  static const Color _red        = Color(0xFFE32344);
  static const Color _bgLight    = Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _verificarSesion(); // 🔥 Del Git
  }

  void _goTo(int index) {
    Navigator.pop(context);
    setState(() => _index = index);
  }

  // 🔥 Logout mejorado (del Git): limpia memoria + disco
  void _logout() async {
    SessionManager.semToken = null;
    SessionManager.username = null;
    SessionManager.role     = null;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

    await SessionManager.limpiarSesion();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // 🔥 Verificar sesión vigente (del Git)
  Future<void> _verificarSesion() async {
    final vigente = await SessionManager.sesionVigente();
    if (!vigente && mounted) {
      await SessionManager.limpiarSesion();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false,
          arguments: {'sessionExpired': true});
    }
  }

  Widget _pageForIndex(int i) {
    switch (i) {
      case 0:  return const MenuScreen();
      case 1:  return const ScannerScreen();
      case 2:  return const DictadoPlacaScreen(); // 🔥 Del tuyo
      case 3:  return RecordsScreen(
                  onNavigateToScanner: () => setState(() => _index = 1));
      case 4:  return const MapaZonasScreen();
      default: return const MenuScreen();
    }
  }

  // Títulos e íconos de cada tab (con dictado)
  static const _titles = [
    'Dashboard',
    'Escanear',
    'Dictado de Placa',
    'Historial',
    'Mapa',
  ];

  static const _icons = [
    Icons.dashboard_customize_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.mic_rounded,
    Icons.history_rounded,
    Icons.map_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    // 🔥 Fondo oscuro para dictado, claro para el resto (del tuyo)
    final bool isDark = _index == 2;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1630) : _bgLight,
      // ── AppBar con gradiente morado ───────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_purple, Color(0xFF6B3FA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Row(
              children: [
                Icon(_icons[_index], color: _cyan, size: 20),
                const SizedBox(width: 10),
                Text(
                  _titles[_index],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _AppDrawer(
        onItemSelected: _goTo,
        onLogout:       _logout,
        activeIndex:    _index,
      ),
      body: _pageForIndex(_index),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final void Function(int) onItemSelected;
  final VoidCallback onLogout;
  final int activeIndex;

  static const Color _purple    = Color(0xFF462677);
  static const Color _purpleMid = Color(0xFF6C559F);
  static const Color _cyan      = Color(0xFFB2DFEF);
  static const Color _cyanMid   = Color(0xFF4ABFDD);
  static const Color _cyanDark  = Color(0xFF00ABD6);
  static const Color _green     = Color(0xFFA5C857);
  static const Color _red       = Color(0xFFE32344);

  const _AppDrawer({
    required this.onItemSelected,
    required this.onLogout,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header con gradiente ──────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_purple, Color(0xFF6B3FA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _cyan.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 12),
                // Rol
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _cyan.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    SessionManager.role ?? "TICKEADOR",
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: _cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Nombre
                Text(
                  SessionManager.username ?? "Usuario SEM",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Badge conectado
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                          color: _green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Conectado',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _green,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Items de navegación ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  // Sección label
                  _sectionLabel('NAVEGACIÓN'),
                  const SizedBox(height: 10),

                  _DrawerItem(
                    icon:      Icons.dashboard_customize_rounded,
                    title:     'Dashboard',
                    subtitle:  'Panel principal',
                    index:     0,
                    active:    activeIndex == 0,
                    activeColor: _purple,
                    onTap:     () => onItemSelected(0),
                  ),
                  const SizedBox(height: 8),

                  // Botón escanear destacado con gradiente verde
                  _DrawerScanAction(
                    onTap: () => onItemSelected(1),
                    isActive: activeIndex == 1,
                  ),
                  const SizedBox(height: 8),

                  // 🔥 Dictado de Placa (del tuyo)
                  _DrawerItem(
                    icon:      Icons.mic_rounded,
                    title:     'Dictado de Placa',
                    subtitle:  'Ingreso por voz',
                    index:     2,
                    active:    activeIndex == 2,
                    activeColor: _purple,
                    onTap:     () => onItemSelected(2),
                  ),
                  const SizedBox(height: 8),

                  _DrawerItem(
                    icon:      Icons.history_rounded,
                    title:     'Historial',
                    subtitle:  'Mis registros',
                    index:     3,
                    active:    activeIndex == 3,
                    activeColor: _purple,
                    onTap:     () => onItemSelected(3),
                  ),
                  const SizedBox(height: 8),

                  _DrawerItem(
                    icon:      Icons.map_rounded,
                    title:     'Mapa de Zonas',
                    subtitle:  'Geolocalización',
                    index:     4,
                    active:    activeIndex == 4,
                    activeColor: _purple,
                    onTap:     () => onItemSelected(4),
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('SISTEMA'),
                  const SizedBox(height: 10),

                  // Info versión
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _cyan.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.info_outline_rounded,
                              color: _purpleMid, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SEM Cochabamba',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _purple)),
                            Text('v2.0 · 2025',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Logo + Cerrar sesión ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                // Logo
                Container(
                  height: 60,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Image.asset(
                    'assets/Logo Yo Amo Cocha Oficial 1.png',
                    fit: BoxFit.contain,
                  ),
                ),

                // Botón cerrar sesión
                GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: _red.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.power_settings_new_rounded,
                            color: _red, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Cerrar Sesión',
                          style: GoogleFonts.poppins(
                            color: _red,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ── Item normal del drawer ────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final int      index;
  final bool     active;
  final Color    activeColor;
  final VoidCallback onTap;

  static const Color _cyan = Color(0xFFB2DFEF);

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? activeColor.withOpacity(0.3)
                : const Color(0xFFEEF1F8),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: active
                    ? activeColor.withOpacity(0.12)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon,
                  color: active ? activeColor : Colors.grey.shade500,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? activeColor
                              : const Color(0xFF1B2430))),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: active ? activeColor : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón escanear destacado ──────────────────────────────────────
class _DrawerScanAction extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;

  static const Color _green     = Color(0xFFA5C857);
  static const Color _greenDark = Color(0xFF7A9E2E);
  static const Color _purple    = Color(0xFF462677);

  const _DrawerScanAction({
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [_greenDark, _green]
                : [_green, Color(0xFFBFD23A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  size: 26, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Escanear Placa',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  Text('IA Detection',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPlaceholderScreen extends StatelessWidget {
  const MapPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text("Mapa próximamente"));
}