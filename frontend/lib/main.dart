import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/resultado_verificacion.dart';
import 'presentation/screens/infraccion_registrada_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEM Fotomultas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: const Color(0xFF2D2D5E),
      ),
      initialRoute: '/login',
      // Usamos onGenerateRoute para poder pasar el initialIndex dinámicamente
      onGenerateRoute: (settings) {
        if (settings.name == '/app') {
          // Extraemos el índice si se envía por argumentos, sino por defecto es 0
          final int index = settings.arguments as int? ?? 0;
          return MaterialPageRoute(
            builder: (context) => AppShell(initialIndex: index),
          );
        }

        // Rutas normales
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