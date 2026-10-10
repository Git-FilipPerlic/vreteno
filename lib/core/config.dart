/// Adresa Vreteno servera (collector/server.py).
///
/// Menja se pri buildu bez izmene koda:
///   flutter build apk --release --dart-define=API_URL=http://192.168.0.16:8080
/// Ako server nije dostupan, aplikacija čita RSS direktno.
const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://192.168.0.16:8080',
);
