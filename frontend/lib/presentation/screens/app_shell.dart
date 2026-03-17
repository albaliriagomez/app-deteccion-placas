import 'package:flutter/material.dart';
import '../../services/session_manager.dart';
import 'menu_screen.dart';
import 'scanner_screen.dart';
import 'records_screen.dart';
import 'mapa_zonas_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;
  static const Color cochaPurple = Color(0xFF6C559F);
  static const Color cochaLightBg = Color(0xFFF6F8FC);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _goTo(int index) {
    Navigator.pop(context);
    setState(() => _index = index);
  }

  void _logout() {
    SessionManager.semToken = null;
    SessionManager.username = null;
    SessionManager.role = null;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _pageForIndex(int i) {
    switch (i) {
      case 0: return const MenuScreen();
      case 1: return const ScannerScreen();
      case 2: return RecordsScreen(onNavigateToScanner: () => setState(() => _index = 1));
      case 3: return const MapaZonasScreen();
      default: return const MenuScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cochaLightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cochaLightBg,
        foregroundColor: const Color(0xFF1B2430),
        title: Text(
          _index == 0 ? "Dashboard" : _index == 1 ? "Escanear" : _index == 2 ? "Historial" : "Mapa",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      drawer: SideMenuDrawer(
        onItemSelected: _goTo,
        onLogout: _logout,
        activeColor: cochaPurple,
      ),
      body: _pageForIndex(_index),
    );
  }
}

class SideMenuDrawer extends StatelessWidget {
  final void Function(int) onItemSelected;
  final VoidCallback onLogout;
  final Color activeColor;

  const SideMenuDrawer({
    super.key,
    required this.onItemSelected,
    required this.onLogout,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFBFD23A);
    const lime2 = Color(0xFFCFE36B);

    return Drawer(
      backgroundColor: const Color(0xFFF6F8FC),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // PERFIL SUPERIOR
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: activeColor.withOpacity(0.2), width: 2),
                    ),
                    child: Icon(Icons.person_rounded, color: activeColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SessionManager.role ?? "TICKEADOR",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: activeColor),
                        ),
                        Text(
                          SessionManager.username ?? "Usuario SEM",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2430)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // ITEMS DEL MENÚ
              _MenuItem(
                icon: Icons.dashboard_customize_rounded,
                title: "Dashboard",
                subtitle: "Panel principal",
                iconColor: activeColor,
                onTap: () => onItemSelected(0),
              ),
              const SizedBox(height: 12),
              _MenuBigAction(
                title: "Escanear Placa",
                subtitle: "IA Detecion",
                gradient: const LinearGradient(colors: [lime, lime2]),
                leftIcon: Icons.qr_code_scanner_rounded,
                onTap: () => onItemSelected(1),
              ),
              const SizedBox(height: 12),
              _MenuItem(
                icon: Icons.history_rounded,
                title: "Historial",
                subtitle: "Mis registros",
                iconColor: activeColor,
                onTap: () => onItemSelected(2),
              ),
              const SizedBox(height: 12),
              _MenuItem(
                icon: Icons.map_rounded,
                title: "Mapa de Zonas",
                subtitle: "Geolocalización",
                iconColor: activeColor,
                onTap: () => onItemSelected(3),
              ),

              const Spacer(), 

              Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: 70, // Tamaño ajustado
                width: double.infinity,
                child: Image.asset(
                  'assets/Logo Yo Amo Cocha Oficial 1.png', 
                  fit: BoxFit.contain,
                ),
              ),

              // BOTÓN CERRAR SESIÓN
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6ECF6)),
                ),
                child: TextButton.icon(
                  onPressed: onLogout,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.power_settings_new_rounded),
                  label: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// Los componentes _MenuItem y _MenuBigAction se mantienen iguales
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6ECF6)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1B2430))),
                  Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8A9AB1))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFB0BDCF)),
          ],
        ),
      ),
    );
  }
}

class _MenuBigAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData leftIcon;
  final VoidCallback onTap;
  const _MenuBigAction({required this.title, required this.subtitle, required this.gradient, required this.leftIcon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(14)),
              child: Icon(leftIcon, size: 24, color: const Color(0xFF1B2430)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2430))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1B2430))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF1B2430)),
          ],
        ),
      ),
    );
  }
}

class MapPlaceholderScreen extends StatelessWidget {
  const MapPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Mapa próximamente"));
}