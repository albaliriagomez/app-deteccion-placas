class Constants {
  // Backend API
  static const String apiBase = 'http://192.168.31.11:8000'; // emulador Android -> host machine
  static const String verificarMultaEndpoint = '/verificar-multa';

  // Plate regex: allow 4-8 alphanumeric uppercase (adjust según país)
  static final RegExp plateRegex = RegExp(r'^[A-Z0-9]{4,8}$');
}
