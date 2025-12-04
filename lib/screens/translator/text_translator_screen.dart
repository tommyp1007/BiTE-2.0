import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_layouts.dart';
import '../../services/translation_service.dart';

class TextTranslatorScreen extends StatefulWidget {
  @override
  _TextTranslatorScreenState createState() => _TextTranslatorScreenState();
}

class _TextTranslatorScreenState extends State<TextTranslatorScreen> {
  final TranslationService _translationService = TranslationService();
  final TextEditingController _sourceController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _translatedText = "Translated Text Here";
  String _fromLanguage = "English";
  String _toLanguage = "Malay";
  bool _isResultVisible = false;
  bool _isLoadingDictionaries = true;

  final Map<String, String> _bidayuhToEnglishDict = {};
  final Map<String, String> _bidayuhToMalayDict = {};
  final Map<String, String> _englishToBidayuhDict = {};
  final Map<String, String> _malayToBidayuhDict = {};

  @override
  void initState() {
    super.initState();
    _fetchTranslationsFromFirestore();
  }

  Future<void> _fetchTranslationsFromFirestore() async {
    try {
      final snapshot = await _db.collection("bidayuh_words").get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String? word = data['word'];
        String? english = data['english'];
        String? malay = data['malay'];
        List<dynamic>? bidayuhVars = data['bidayuhVariations'];
        List<dynamic>? englishVars = data['englishVariations'];
        List<dynamic>? malayVars = data['malayVariations'];

        if (word != null && english != null && malay != null) {
          String w = word.toLowerCase();
          String e = english.toLowerCase();
          String m = malay.toLowerCase();

          _bidayuhToEnglishDict[w] = e;
          _bidayuhToMalayDict[w] = m;
          _englishToBidayuhDict[e] = w;
          _malayToBidayuhDict[m] = w;

          if (bidayuhVars != null) {
            for (var v in bidayuhVars) {
              String vLower = v.toString().toLowerCase();
              _bidayuhToEnglishDict[vLower] = e;
              _bidayuhToMalayDict[vLower] = m;
            }
          }
          if (englishVars != null) {
            for (var v in englishVars) {
              String vLower = v.toString().toLowerCase();
              _englishToBidayuhDict[vLower] = w;
              _malayToBidayuhDict[vLower] = m;
            }
          }
          if (malayVars != null) {
            for (var v in malayVars) {
              String vLower = v.toString().toLowerCase();
              _malayToBidayuhDict[vLower] = w;
              _englishToBidayuhDict[vLower] = e;
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching translations: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDictionaries = false);
    }
  }

  void _handleTranslate() async {
    // Note: Removed Unfocus here so keyboard doesn't close every time you switch language
    // FocusScope.of(context).unfocus(); 

    String text = _sourceController.text.trim().toLowerCase();
    if (text.isEmpty) {
      setState(() {
        _translatedText = "Please enter text to translate.";
        _isResultVisible = true;
      });
      return;
    }

    if (_fromLanguage == _toLanguage) {
      setState(() {
        _translatedText = "Unsupported translation pair.";
        _isResultVisible = true;
      });
      return;
    }

    // Custom Bidayuh Logic
    if (_fromLanguage == "Bidayuh" || _toLanguage == "Bidayuh") {
      String result = _getBidayuhTranslation(
          text, _fromLanguage.toLowerCase(), _toLanguage.toLowerCase());
      setState(() {
        _translatedText = result;
        _isResultVisible = true;
      });
      return;
    }

    // External API Logic (Google/ML Kit)
    setState(() {
      _translatedText = "Translating...";
      _isResultVisible = true;
    });

    String result = await _translationService.translate(text, _fromLanguage, _toLanguage);

    if (mounted) {
      setState(() => _translatedText = result);
    }
  }

  String _getBidayuhTranslation(String text, String fromLang, String toLang) {
    // 1. Clean input
    String cleanedText = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    // Keep punctuation to append at the end
    String punctuation = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');

    if (cleanedText.isEmpty) return "Please enter valid text";

    // Split text into list of words to check if it is a sentence or single word
    List<String> originalWords = cleanedText.split(RegExp(r'\s+'));
    
    // CHECK: Is the input just one word?
    bool isSingleWordInput = originalWords.length == 1;

    List<String> words = List.from(originalWords); // Create a mutable copy for processing
    List<String> translatedParts = [];

    // 2. Loop through words
    while (words.isNotEmpty) {
      String? phrase;
      String singleWord = words[0];
      int wordsUsed = 0;

      // Try to find the longest matching phrase first
      for (int i = words.length; i > 0; i--) {
        String potentialPhrase = words.sublist(0, i).join(" ");

        if (fromLang == 'bidayuh' && toLang == 'english') {
          if (_bidayuhToEnglishDict.containsKey(potentialPhrase)) {
            phrase = _bidayuhToEnglishDict[potentialPhrase];
            wordsUsed = i;
            break;
          }
        } else if (fromLang == 'bidayuh' && toLang == 'malay') {
          if (_bidayuhToMalayDict.containsKey(potentialPhrase)) {
            phrase = _bidayuhToMalayDict[potentialPhrase];
            wordsUsed = i;
            break;
          }
        } else if (fromLang == 'english' && toLang == 'bidayuh') {
          if (_englishToBidayuhDict.containsKey(potentialPhrase)) {
            phrase = _englishToBidayuhDict[potentialPhrase];
            wordsUsed = i;
            break;
          }
        } else if (fromLang == 'malay' && toLang == 'bidayuh') {
          if (_malayToBidayuhDict.containsKey(potentialPhrase)) {
            phrase = _malayToBidayuhDict[potentialPhrase];
            wordsUsed = i;
            break;
          }
        }
      }

      // 3. Fallback to single word if phrase not found
      if (phrase == null) {
        if (fromLang == 'bidayuh' && toLang == 'english') {
          phrase = _bidayuhToEnglishDict[singleWord];
        } else if (fromLang == 'bidayuh' && toLang == 'malay') {
          phrase = _bidayuhToMalayDict[singleWord];
        } else if (fromLang == 'english' && toLang == 'bidayuh') {
          phrase = _englishToBidayuhDict[singleWord];
        } else if (fromLang == 'malay' && toLang == 'bidayuh') {
          phrase = _malayToBidayuhDict[singleWord];
        }
        wordsUsed = 1;
      }

      // 4. Combined Logic for Not Found
      if (phrase != null) {
        translatedParts.add(phrase);
      } else {
        // Word not found
        if (isSingleWordInput) {
          // If the user only typed ONE word, and it wasn't found, return specific error
          return "Translation is soon to add";
        } else {
          // If the user typed a SENTENCE, and this specific word wasn't found, use "_"
          translatedParts.add("_");
        }
      }

      // Remove the processed words from the list
      if (words.isNotEmpty) {
        words.removeRange(0, wordsUsed > 0 ? wordsUsed : 1);
      }
    }

    return translatedParts.join(" ") + punctuation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      // Fixed: moved bottom panel to property
      bottomNavigationBar: BottomNavPanel(),
      resizeToAvoidBottomInset: false,

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Header
            AppHeader(title: "BiTE Translator"),

            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Text Translator",
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),

                    // Language Spinners
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 40, 20, 0),
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildDropdown(
                                  (v) {
                                    setState(() => _fromLanguage = v!);
                                    // AUTO UPDATE: If text exists, translate immediately
                                    if(_sourceController.text.isNotEmpty) {
                                      _handleTranslate();
                                    }
                                  },
                                  _fromLanguage)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.compare_arrows,
                                color: Colors.black, size: 24),
                          ),
                          Expanded(
                              child: _buildDropdown(
                                  (v) {
                                    setState(() => _toLanguage = v!);
                                    // AUTO UPDATE: If text exists, translate immediately
                                    if(_sourceController.text.isNotEmpty) {
                                      _handleTranslate();
                                    }
                                  },
                                  _toLanguage)),
                        ],
                      ),
                    ),

                    // Input Field
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: TextField(
                        controller: _sourceController,
                        maxLines: 4,
                        // Add listener or onSubmitted if you want enter key to work, 
                        // but button is fine
                        style: TextStyle(fontSize: 20, color: AppColors.black),
                        decoration: InputDecoration(
                          hintText: "Enter your text",
                          filled: true,
                          fillColor: AppColors.white,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          hintStyle: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ),

                    // Translate Button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ElevatedButton(
                        onPressed:
                            _isLoadingDictionaries ? null : () {
                              FocusScope.of(context).unfocus(); // Close keyboard on manual press
                              _handleTranslate();
                            },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        child: _isLoadingDictionaries
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text("Translate",
                                style: TextStyle(
                                    fontSize: 20, color: AppColors.white)),
                      ),
                    ),

                    // Result Display
                    if (_isResultVisible)
                      Container(
                        margin: EdgeInsets.fromLTRB(20, 10, 20, 20),
                        padding: EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(15)),
                        child: Text(
                          _translatedText,
                          style: TextStyle(
                              fontSize: 17,
                              color: AppColors.primary,
                              letterSpacing: 0.03),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(ValueChanged<String?> onChanged, String val) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: val,
        isExpanded: true,
        items: ["English", "Malay", "Bidayuh"]
            .map((e) =>
                DropdownMenuItem(value: e, child: Center(child: Text(e))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}