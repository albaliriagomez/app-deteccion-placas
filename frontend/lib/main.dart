import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/resultado_verificacion.dart'; // ✅ NUEVA IMPORTACIÓN
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
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/app': (context) => const AppShell(),

        // ✅ NUEVA RUTA AGREGADA
        '/resultadoVerificacion': (context) =>
            const ResultadoVerificacionScreen(),

        '/infraccionRegistrada': (context) =>
            const InfraccionRegistradaScreen(),
      },
    );
  }
}