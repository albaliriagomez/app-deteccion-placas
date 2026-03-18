import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/session_manager.dart';           // ← ajusta la ruta

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/resultado_verificacion.dart';
import 'presentation/screens/infraccion_registrada_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();       // ← necesario para async en main
  final sesionActiva = await SessionManager.recuperarSesion();
  runApp(MyApp(sesionActiva: sesionActiva));
}

class MyApp extends StatelessWidget {
  final bool sesionActiva;
  const MyApp({super.key, required this.sesionActiva});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEM Fotomultas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: const Color(0xFF2D2D5E),
      ),
      initialRoute: sesionActiva ? '/app' : '/login',  // ← va directo al app si hay sesión
      onGenerateRoute: (settings) {
        if (settings.name == '/app') {
          final int index = settings.arguments as int? ?? 0;
          return MaterialPageRoute(
            builder: (context) => AppShell(initialIndex: index),
          );
        }
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/resultadoVerificacion':
            return MaterialPageRoute(builder: (_) => const ResultadoVerificacionScreen());
          case '/infraccionRegistrada':
            return MaterialPageRoute(builder: (_) => const InfraccionRegistradaScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}