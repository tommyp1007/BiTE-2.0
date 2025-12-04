import 'dart:async';
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

  Timer? _debounce;

  String _translatedText = "";
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
          String w = word.toLowerCase().trim();
          String e = english.toLowerCase().trim();
          String m = malay.toLowerCase().trim();

          _bidayuhToEnglishDict[w] = e;
          _bidayuhToMalayDict[w] = m;
          _englishToBidayuhDict[e] = w;
          _malayToBidayuhDict[m] = w;

          if (bidayuhVars != null) {
            for (var v in bidayuhVars) {
              String vLower = v.toString().toLowerCase().trim();
              _bidayuhToEnglishDict[vLower] = e;
              _bidayuhToMalayDict[vLower] = m;
            }
          }
          if (englishVars != null) {
            for (var v in englishVars) {
              String vLower = v.toString().toLowerCase().trim();
              _englishToBidayuhDict[vLower] = w;
              _malayToBidayuhDict[vLower] = m;
            }
          }
          if (malayVars != null) {
            for (var v in malayVars) {
              String vLower = v.toString().toLowerCase().trim();
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.isNotEmpty) {
        _handleTranslate();
      } else {
        if(mounted) setState(() {
          _isResultVisible = false;
          _translatedText = "";
        });
      }
    });
  }

  void _handleTranslate() async {
    String text = _sourceController.text.trim().toLowerCase();
    
    if (text.isEmpty) {
      if (mounted) setState(() { _translatedText = ""; _isResultVisible = false; });
      return;
    }

    if (_fromLanguage == _toLanguage) {
      if (mounted) setState(() { _translatedText = "Unsupported translation pair."; _isResultVisible = true; });
      return;
    }

    String result = "";

    // ==========================================
    // STRATEGY: SMART PIVOT TRANSLATION
    // ==========================================

    // 1. BIDAYUH -> ENGLISH (Use Malay Pivot)
    // Convert Bidayuh to Malay (Local DB) -> Send Malay to API -> English
    if (_fromLanguage == "Bidayuh" && _toLanguage == "English") {
      // Step A: Get Rough Malay from DB
      String roughMalay = _getBidayuhTranslation(text, "bidayuh", "malay");
      
      // If DB doesn't have the words, fail early
      if (roughMalay == "Translation is soon to add") {
        result = roughMalay;
      } else {
        // Step B: Send Rough Malay to Google Translate API to get proper English grammar
        result = await _translationService.translate(roughMalay, "Malay", "English");
      }
    }
    
    // 2. ENGLISH -> BIDAYUH (Use Malay Pivot)
    // Send English to API -> Malay -> Convert Malay to Bidayuh (Local DB)
    else if (_fromLanguage == "English" && _toLanguage == "Bidayuh") {
      // Step A: Translate English to Malay online
      String properMalay = await _translationService.translate(text, "English", "Malay");
      
      if (properMalay == "Translation is soon to add") {
        result = properMalay;
      } else {
        // Step B: Map Malay words to Bidayuh locally
        result = _getBidayuhTranslation(properMalay, "malay", "bidayuh");
      }
    }

    // 3. BIDAYUH -> MALAY (Direct Local)
    // Bidayuh structure is close enough to Malay to use direct DB mapping
    else if (_fromLanguage == "Bidayuh" && _toLanguage == "Malay") {
      result = _getBidayuhTranslation(text, "bidayuh", "malay");
    }

    // 4. MALAY -> BIDAYUH (Direct Local)
    else if (_fromLanguage == "Malay" && _toLanguage == "Bidayuh") {
      result = _getBidayuhTranslation(text, "malay", "bidayuh");
    }

    // 5. STANDARD ONLINE (English <-> Malay)
    else {
      result = await _translationService.translate(text, _fromLanguage, _toLanguage);
    }

    if (mounted) {
      setState(() {
        _translatedText = result;
        _isResultVisible = true;
      });
    }
  }

  // Helper to query the Local HashMaps
  String _getBidayuhTranslation(String text, String fromLang, String toLang) {
    String cleanedText = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    if (cleanedText.isEmpty) return "";

    List<String> originalWords = cleanedText.split(RegExp(r'\s+'));
    List<String> words = List.from(originalWords);
    List<String> translatedParts = [];
    bool hasMissingTranslation = false;

    while (words.isNotEmpty) {
      String? phrase;
      String singleWord = words[0];
      int wordsUsed = 0;

      // Greedy Search for Phrases
      for (int i = words.length; i > 0; i--) {
        String potentialPhrase = words.sublist(0, i).join(" ");

        if (fromLang == 'bidayuh' && toLang == 'english') {
          if (_bidayuhToEnglishDict.containsKey(potentialPhrase)) {
            phrase = _bidayuhToEnglishDict[potentialPhrase]; wordsUsed = i; break;
          }
        } else if (fromLang == 'bidayuh' && toLang == 'malay') {
          if (_bidayuhToMalayDict.containsKey(potentialPhrase)) {
            phrase = _bidayuhToMalayDict[potentialPhrase]; wordsUsed = i; break;
          }
        } else if (fromLang == 'english' && toLang == 'bidayuh') {
          if (_englishToBidayuhDict.containsKey(potentialPhrase)) {
            phrase = _englishToBidayuhDict[potentialPhrase]; wordsUsed = i; break;
          }
        } else if (fromLang == 'malay' && toLang == 'bidayuh') {
          if (_malayToBidayuhDict.containsKey(potentialPhrase)) {
            phrase = _malayToBidayuhDict[potentialPhrase]; wordsUsed = i; break;
          }
        }
      }

      // Single word fallback
      if (phrase == null) {
        if (fromLang == 'bidayuh' && toLang == 'english') phrase = _bidayuhToEnglishDict[singleWord];
        else if (fromLang == 'bidayuh' && toLang == 'malay') phrase = _bidayuhToMalayDict[singleWord];
        else if (fromLang == 'english' && toLang == 'bidayuh') phrase = _englishToBidayuhDict[singleWord];
        else if (fromLang == 'malay' && toLang == 'bidayuh') phrase = _malayToBidayuhDict[singleWord];
        wordsUsed = 1;
      }

      if (phrase != null) {
        translatedParts.add(phrase);
      } else {
        // Missing word logic
        hasMissingTranslation = true;
        break; 
      }

      if (words.isNotEmpty) {
        words.removeRange(0, wordsUsed > 0 ? wordsUsed : 1);
      }
    }

    if (hasMissingTranslation) {
      return "Translation is soon to add";
    }

    return translatedParts.join(" ");
  }

  void _swapLanguages() {
    setState(() {
      String temp = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = temp;
      if (_sourceController.text.isNotEmpty) _handleTranslate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.primary,
      bottomNavigationBar: BottomNavPanel(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              AppHeader(title: "BiTE Translator"),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      padding: EdgeInsets.only(bottom: 70),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: TextField(
                                controller: _sourceController,
                                maxLines: null,
                                expands: true,
                                style: TextStyle(fontSize: 28, color: Colors.black87, height: 1.3),
                                decoration: InputDecoration(
                                  hintText: "Enter text",
                                  hintStyle: TextStyle(fontSize: 28, color: Colors.grey.shade400),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                          ),
                          if (_isResultVisible && _translatedText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(color: Colors.grey.shade300, thickness: 1),
                            ),
                          if (_isResultVisible && _translatedText.isNotEmpty)
                            Expanded(
                              flex: 1,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                child: SingleChildScrollView(
                                  physics: BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _toLanguage.toUpperCase(),
                                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _translatedText,
                                        style: TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.w500, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: keyboardHeight, 
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.3))
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLanguageButton(_fromLanguage, (val) {
                                setState(() => _fromLanguage = val);
                                if (_sourceController.text.isNotEmpty) _handleTranslate();
                              }),
                              IconButton(
                                icon: Icon(Icons.swap_horiz, color: AppColors.primary, size: 28),
                                onPressed: _swapLanguages,
                              ),
                              _buildLanguageButton(_toLanguage, (val) {
                                setState(() => _toLanguage = val);
                                if (_sourceController.text.isNotEmpty) _handleTranslate();
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String currentLang, Function(String) onSelect) {
    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        _showLanguagePicker(context, (val) => onSelect(val));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          currentLang,
          style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 250,
          child: Column(
            children: ["English", "Malay", "Bidayuh"].map((lang) {
              return ListTile(
                title: Text(lang, textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                onTap: () {
                  onSelect(lang);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      }
    );
  }
}