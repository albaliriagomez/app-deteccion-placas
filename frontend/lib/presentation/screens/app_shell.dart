import 'package:flutter/material.dart';

import 'menu_screen.dart';
import 'scanner_screen.dart';
import 'records_screen.dart';

class AppShell extends StatefulWidget {

  final int initialIndex;

  const AppShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {

  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  // ============================
  // CAMBIO DE PANTALLA
  // ============================

  void _goTo(int index) {
    Navigator.pop(context);

    setState(() {
      _index = index;
    });
  }

  void _logout() {

    Navigator.pop(context);

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  // ============================
  // PANTALLAS
  // ============================

  Widget _pageForIndex(int i) {

    switch (i) {

      case 0:
        return const MenuScreen();

      case 1:
        return const ScannerScreen();

      case 2:
        return RecordsScreen(
          onNavigateToScanner: () {
            setState(() => _index = 1);
          },
        );

      case 3:
        return const MapPlaceholderScreen();

      default:
        return const MenuScreen();
    }
  }

  String _titleForIndex(int i) {

    switch (i) {

      case 0:
        return "Menú";

      case 1:
        return "Escanear Placa";

      case 2:
        return "Historial";

      case 3:
        return "Mapa de Zonas";

      default:
        return "Menú";
    }
  }

  @override
  Widget build(BuildContext context) {

    const bg = Color(0xFFF6F8FC);

    return Scaffold(

      backgroundColor: bg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: const Color(0xFF1B2430),
        title: Text(
          _titleForIndex(_index),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      drawer: SideMenuDrawer(
        onItemSelected: _goTo,
        onLogout: _logout,
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pageForIndex(_index),
      ),
    );
  }
}






// ===================================================
// DRAWER
// ===================================================

class SideMenuDrawer extends StatelessWidget {

  final void Function(int) onItemSelected;
  final VoidCallback onLogout;

  const SideMenuDrawer({
    super.key,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {

    const bg = Color(0xFFF6F8FC);
    const lime = Color(0xFFBFD23A);
    const lime2 = Color(0xFFCFE36B);

    return Drawer(
      backgroundColor: bg,

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),

          child: Column(
            children: [

              const SizedBox(height: 10),

              Row(
                children: [

                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE6ECF6),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person_outline_rounded),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Supervisor",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B8AA5),
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          "Carlos Rodríguez",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B2430),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _MenuItem(
                icon: Icons.home_rounded,
                title: "Ir al Menú",
                subtitle: "Pantalla principal",
                onTap: () => onItemSelected(0),
              ),

              const SizedBox(height: 14),

              _MenuBigAction(
                title: "Escanear Placa",
                subtitle: "Verificación inmediata",
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [lime, lime2],
                ),
                leftIcon: Icons.qr_code_scanner_rounded,
                onTap: () => onItemSelected(1),
              ),

              const SizedBox(height: 14),

              _MenuItem(
                icon: Icons.history_rounded,
                title: "Historial de verificaciones",
                subtitle: "Consultar registros anteriores",
                onTap: () => onItemSelected(2),
              ),

              const SizedBox(height: 12),

              _MenuItem(
                icon: Icons.map_outlined,
                title: "Mapa de Zonas",
                subtitle: "Estado de ocupación en tiempo real",
                onTap: () => onItemSelected(3),
              ),

              const Spacer(),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE6ECF6),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("Cerrar sesión"),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "SEM SUPERVISOR • V.2.0.12",
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB0BDCF),
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






// ===================================================
// COMPONENTES
// ===================================================

class _MenuBigAction extends StatelessWidget {

  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData leftIcon;
  final VoidCallback onTap;

  const _MenuBigAction({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.leftIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(

      borderRadius: BorderRadius.circular(22),
      onTap: onTap,

      child: Container(

        width: double.infinity,

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
        ),

        child: Row(

          children: [

            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
              ),

              child: Icon(
                leftIcon,
                size: 26,
                color: const Color(0xFF233046),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2430),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2430),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}



class _MenuItem extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(

      borderRadius: BorderRadius.circular(18),
      onTap: onTap,

      child: Container(

        width: double.infinity,

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6ECF6)),
        ),

        child: Row(

          children: [

            Container(
              width: 46,
              height: 46,

              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(16),
              ),

              child: Icon(
                icon,
                color: const Color(0xFF5FA8FF),
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2430),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A9AB1),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}



class MapPlaceholderScreen extends StatelessWidget {

  const MapPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return const Center(
      child: Text(
        "Mapa de Zonas (próximamente)",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF5A6B85),
        ),
      ),
    );
  }
}