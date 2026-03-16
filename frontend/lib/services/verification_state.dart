// lib/services/verification_state.dart

class VerificationState {
  VerificationState._();
  static final VerificationState instance = VerificationState._();

  // ── Datos del escaneo ──
  String placa        = '';
  String base64Image  = '';
  String ubicacion    = '';
  String latitude     = '0.0';
  String longitude    = '0.0';

  // ── Resultado del backend ──
  Map<String, dynamic> resultado  = {};
  Map<String, dynamic> registro   = {};
  String               estado     = '';

  void setEscaneo({
    required String placa,
    required String base64Image,
    required String ubicacion,
    required String latitude,
    required String longitude,
  }) {
    this.placa       = placa;
    this.base64Image = base64Image;
    this.ubicacion   = ubicacion;
    this.latitude    = latitude;
    this.longitude   = longitude;
  }

  void setResultado(Map<String, dynamic> response) {
    resultado = Map<String, dynamic>.from(response);
    estado    = (response['estado'] ?? 'No Registrado').toString().trim();

    final raw = response['registro'];
    if (raw != null && raw is Map) {
      registro = Map<String, dynamic>.from(raw);
    } else {
      registro = {};
    }

    // Garantizar placa en registro
    if ((registro['placa']?.toString().isEmpty ?? true) && placa.isNotEmpty) {
      registro['placa'] = placa;
    }
    // Garantizar coords en registro
    registro['latitude']  ??= latitude;
    registro['longitude'] ??= longitude;
    registro['ubicacion'] ??= ubicacion;
  }

  void clear() {
    placa = ''; base64Image = ''; ubicacion = '';
    latitude = '0.0'; longitude = '0.0';
    resultado = {}; registro = {}; estado = '';
  }
}