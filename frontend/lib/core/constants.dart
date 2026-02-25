class Constants {
  // Backend API
  static const String apiBase = 'http://10.1.50.165:8000'; // emulador Android -> host machine
  static const String verificarMultaEndpoint = '/verificar-multa';

  // Plate regex: allow 4-8 alphanumeric uppercase (adjust según país)
  static final RegExp plateRegex = RegExp(r'^[A-Z0-9]{4,8}$');
}
