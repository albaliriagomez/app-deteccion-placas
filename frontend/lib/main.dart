import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/session_manager.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/resultado_verificacion.dart';
import 'presentation/screens/infraccion_registrada_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 'ok' | 'expired' | 'none'
  final estadoSesion = await SessionManager.recuperarSesionConEstado();

  runApp(MyApp(estadoSesion: estadoSesion));
}

class MyApp extends StatelessWidget {
  final String estadoSesion;
  const MyApp({super.key, required this.estadoSesion});

  @override
  Widget build(BuildContext context) {
    // Decidir pantalla inicial
    String rutaInicial;
    bool sessionExpired = false;

    if (estadoSesion == 'ok') {
      rutaInicial = '/app';
    } else if (estadoSesion == 'expired') {
      rutaInicial    = '/login';
      sessionExpired = true;       // ← activar el diálogo
    } else {
      rutaInicial = '/login';
    }

    return MaterialApp(
      title: 'SEM Fotomultas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: const Color(0xFF2D2D5E),
      ),
      // Pasamos sessionExpired como argumento inicial si aplica
      initialRoute: rutaInicial,
      onGenerateRoute: (settings) {
        switch (settings.name) {

          case '/login': {
            // Leer argumento si viene de una redirección interna
            // O usar el valor inicial si es la primera pantalla
            bool expired = false;
            if (settings.arguments is Map) {
              expired = (settings.arguments as Map)['sessionExpired'] == true;
            } else {
              // Primera carga: usar el valor calculado en main()
              expired = sessionExpired;
              sessionExpired = false; // limpiar para no repetir en navegaciones futuras
            }
            return MaterialPageRoute(
              builder: (_) => LoginScreen(sessionExpired: expired),
            );
          }

          case '/app': {
            final int index = settings.arguments as int? ?? 0;
            return MaterialPageRoute(
              builder: (_) => AppShell(initialIndex: index),
            );
          }

          case '/resultadoVerificacion':
            return MaterialPageRoute(
                builder: (_) => const ResultadoVerificacionScreen());

          case '/infraccionRegistrada':
            return MaterialPageRoute(
                builder: (_) => const InfraccionRegistradaScreen());

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}