import 'dart:convert';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _apiKey = "AIzaSyBJEZs_TIsG1SzlJcuk48qiblqJYNAuvrY";
  static const String _baseUrl = "https://translation.googleapis.com/language/translate/v2";

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
    if (text.isEmpty) return "";
    
    // Normalize logic
    String cleanFrom = fromLang.toLowerCase();
    String cleanTo = toLang.toLowerCase();

    if (cleanFrom == cleanTo) return "Unsupported Translation Pair.";

    bool hasInternet = await _isNetworkAvailable();
    String result;

    if (hasInternet) {
      String targetCode = _getLanguageCode(toLang);
      String sourceCode = _getLanguageCode(fromLang);
      result = await _translateOnline(text, sourceCode, targetCode);
    } else {
      result = await _translateOffline(text, cleanFrom, cleanTo);
    }

    // --- FALLBACK LOGIC ---
    // If API returns identical string (ignoring case), it likely failed.
    // However, if the text contains symbols that don't change (e.g., "?", "!"), we shouldn't error.
    // We check if at least one alphanumeric character changed, or if the input was meaningless.
    
    String rawInput = text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    String rawOutput = result.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

    // If input had words but output is identical, assume failure
    if (rawInput.isNotEmpty && rawInput == rawOutput) {
      return "Translation is soon to add";
    }

    return result;
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
          
          // Google API handles punctuation well, but sometimes returns encoded HTML like &#39;
          String raw = data['data']['translations'][0]['translatedText'];
          return _unescapeHtml(raw);
        }
      }
      return text; // Return original on failure
    } catch (e) {
      return text;
    }
  }

  // Simple unescape for common HTML entities returned by Google
  String _unescapeHtml(String input) {
    return input
      .replaceAll("&quot;", "\"")
      .replaceAll("&#39;", "'")
      .replaceAll("&amp;", "&")
      .replaceAll("&lt;", "<")
      .replaceAll("&gt;", ">");
  }

  Future<String> _translateOffline(String text, String fromLang, String toLang) async {
    try {
      if (fromLang == 'english' && toLang == 'malay') {
        return await _englishToMalay.translateText(text);
      } else if (fromLang == 'malay' && toLang == 'english') {
        return await _malayToEnglish.translateText(text);
      }
      return text; 
    } catch (e) {
      return text;
    }
  }

  void dispose() {
    _englishToMalay.close();
    _malayToEnglish.close();
  }
}