import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= HEADER =================

              const SizedBox(height: 10),

              const Text(
                "VISTA GENERAL",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.teal,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Dashboard de Control",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2430),
                ),
              ),

              const SizedBox(height: 25),

              // ================= STATS GRID =================

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: const [

                  _StatCard(
                    color: Color(0xFFF4C20D),
                    title: "Total detecciones",
                    value: "12,678",
                    icon: Icons.remove_red_eye_outlined,
                  ),

                  _StatCard(
                    color: Color(0xFFAED581),
                    title: "Alertas activas",
                    value: "10",
                    icon: Icons.warning_amber_rounded,
                  ),

                  _StatCard(
                    color: Color(0xFF7CB342),
                    title: "Infracciones",
                    value: "2",
                    icon: Icons.block,
                  ),

                  _StatCard(
                    color: Color(0xFF26A69A),
                    title: "Cámaras activas",
                    value: "8",
                    icon: Icons.videocam,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ================= ACTIVIDAD =================

              const _ActivityCard(),

              const SizedBox(height: 20),

              // ================= CLASIFICACIÓN =================

              const _ClassificationCard(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.color,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 8),
            color: Color(0x22000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Color(0x11000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Actividad Reciente (7 días)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Icon(
              Icons.bar_chart_rounded,
              size: 100,
              color: Colors.teal,
            ),
          )
        ],
      ),
    );
  }
}

class _ClassificationCard extends StatelessWidget {
  const _ClassificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Color(0x11000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Clasificación",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20),
          _Item("No identificado", 12668),
          _Item("Automóvil", 4),
          _Item("Motocicleta", 2),
          _Item("Camioneta", 2),
          _Item("Camión", 1),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final int value;

  const _Item(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}