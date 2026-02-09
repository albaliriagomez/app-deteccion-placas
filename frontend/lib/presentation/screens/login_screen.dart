import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _showError("Por favor llene todos los campos");
      return;
    }

    setState() => _isLoading = true;

    try {
      // RECUERDA: Cambia la IP por la de tu PC 192.168.220.128
      final response = await http.post(
        Uri.parse('http://192.168.220.128:8000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userController.text,
          'password': _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String role = data['role'];
        
        // Redirección según rol
        if (role == 'SUPERVISOR') {
          Navigator.pushReplacementNamed(context, '/scanner'); // O a una pantalla de gestión
        } else {
          Navigator.pushReplacementNamed(context, '/scanner');
        }
      } else {
        _showError("Usuario o contraseña incorrectos");
      }
    } catch (e) {
      _showError("Error de conexión con el servidor");
    } finally {
      if (mounted) setState() => _isLoading = false;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins()), backgroundColor: Colors.red)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // LOGO ESTILO IMAGEN CARGADA
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(colors: [Color(0xFF3F37C9), Color(0xFF4CC9F0)]),
                  ),
                  child: Center(child: Text('P', style: GoogleFonts.poppins(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 20),
                Text('SEM', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF2B2D42))),
                Text('SUPERVISIÓN & ADMIN', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 40),

                // INPUT USUARIO
                _buildInput(controller: _userController, hint: "ej. supervisor_01", label: "Usuario", icon: Icons.person_outline),
                const SizedBox(height: 20),

                // INPUT CONTRASEÑA
                _buildInput(
                  controller: _passController, 
                  hint: "••••••••", 
                  label: "Contraseña", 
                  icon: Icons.lock_outline, 
                  isPass: true
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: Text("¿Olvidó su contraseña?", style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF4CC9F0)))),
                ),
                const SizedBox(height: 20),

                // BOTÓN INGRESAR
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B1B52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Ingresar", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("O ACCEDER CON", style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _biometricIcon(Icons.fingerprint),
                    const SizedBox(width: 20),
                    _biometricIcon(Icons.face),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required String label, required IconData icon, bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2B2D42))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass ? _obscure : false,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPass ? IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)) : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _biometricIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: Colors.grey),
    );
  }
}