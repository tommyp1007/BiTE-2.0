import 'dart:convert';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  // Note: Secure your API Key for production
  static const String _apiKey = "AIzaSyBJEZs_TIsG1SzlJcuk48qiblqJYNAuvrY";
  static const String _baseUrl = "https://translation.googleapis.com/language/translate/v2";

  // ML Kit Translators
  final OnDeviceTranslator _englishToMalay;
  final OnDeviceTranslator _malayToEnglish;

  TranslationService()
      : _englishToMalay = OnDeviceTranslator(
            sourceLanguage: TranslateLanguage.english,
            targetLanguage: TranslateLanguage.malay),
        _malayToEnglish = OnDeviceTranslator(
            sourceLanguage: TranslateLanguage.malay,
            targetLanguage: TranslateLanguage.english);

  Future<String> translate(String text, String fromLang, String toLang) async {
    if (text.isEmpty) return "Text cannot be empty";
    if (fromLang.toLowerCase() == toLang.toLowerCase()) return "Unsupported Translation Pair.";

    bool hasInternet = await _isNetworkAvailable();

    if (hasInternet) {
      String targetCode = _getLanguageCode(toLang);
      String sourceCode = _getLanguageCode(fromLang);
      return await _translateOnline(text, sourceCode, targetCode);
    } else {
      return await _translateOffline(text, fromLang, toLang);
    }
  }

  String _getLanguageCode(String language) {
    if (language.toLowerCase() == 'english') return 'en';
    if (language.toLowerCase() == 'malay') return 'ms';
    return 'en';
  }

  Future<bool> _isNetworkAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<String> _translateOnline(String text, String sourceLang, String targetLang) async {
    try {
      final Uri url = Uri.parse(
          "$_baseUrl?key=$_apiKey&q=${Uri.encodeComponent(text)}&target=$targetLang&source=$sourceLang&format=text");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('data') &&
            data['data']['translations'] != null &&
            data['data']['translations'].isNotEmpty) {
          return data['data']['translations'][0]['translatedText'];
        }
      } 
      return "Error: ${response.statusCode}";
    } catch (e) {
      return "Network error: $e";
    }
  }

  Future<String> _translateOffline(String text, String fromLang, String toLang) async {
    fromLang = fromLang.toLowerCase();
    toLang = toLang.toLowerCase();

    try {
      if (fromLang == 'english' && toLang == 'malay') {
        return await _englishToMalay.translateText(text);
      } else if (fromLang == 'malay' && toLang == 'english') {
        return await _malayToEnglish.translateText(text);
      }
      return "Offline model not found for this pair.";
    } catch (e) {
      return "Translation failed: $e";
    }
  }

  void dispose() {
    _englishToMalay.close();
    _malayToEnglish.close();
  }
}