import 'package:flutter/material.dart';
import '../../services/parqueo_service.dart';

class VerificandoScreen extends StatefulWidget {
  const VerificandoScreen({super.key});

  @override
  State<VerificandoScreen> createState() => _VerificandoScreenState();
}

class _VerificandoScreenState extends State<VerificandoScreen> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verificar();
  }

  Future<void> _verificar() async {

    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    try {

      final response = await ParqueoService.verificarParqueo(
        token: args["token"],
        placa: args["placa"],
        base64Image: args["base64Image"],
        ubicacion: args["ubicacion"],
        latitude: args["latitude"],
        longitude: args["longitude"],
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/resultado',
        arguments: response,
      );

    } catch (e) {

      print("ERROR EN VERIFICACIÓN: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al verificar pago")),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}