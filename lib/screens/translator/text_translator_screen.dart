import 'dart:async'; // Required for Timer (Debouncing)
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

  // Debounce Timer for auto-translation
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
    _debounce?.cancel(); // Cancel timer to prevent memory leaks
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

  // Real-time translation trigger
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.isNotEmpty) {
        _handleTranslate();
      } else {
        setState(() {
          _isResultVisible = false;
          _translatedText = "";
        });
      }
    });
  }

  void _handleTranslate() async {
    String text = _sourceController.text.trim().toLowerCase();
    if (text.isEmpty) {
      if (mounted) {
        setState(() {
          _translatedText = "";
          _isResultVisible = false;
        });
      }
      return;
    }

    if (_fromLanguage == _toLanguage) {
      if (mounted) {
        setState(() {
          _translatedText = "Unsupported translation pair.";
          _isResultVisible = true;
        });
      }
      return;
    }

    // Custom Bidayuh Logic
    if (_fromLanguage == "Bidayuh" || _toLanguage == "Bidayuh") {
      String result = _getBidayuhTranslation(
          text, _fromLanguage.toLowerCase(), _toLanguage.toLowerCase());
      if (mounted) {
        setState(() {
          _translatedText = result;
          _isResultVisible = true;
        });
      }
      return;
    }

    // External API Logic
    String result = await _translationService.translate(text, _fromLanguage, _toLanguage);

    if (mounted) {
      setState(() {
        _translatedText = result;
        _isResultVisible = true;
      });
    }
  }

  String _getBidayuhTranslation(String text, String fromLang, String toLang) {
    String cleanedText = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    String punctuation = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');

    if (cleanedText.isEmpty) return "";

    List<String> originalWords = cleanedText.split(RegExp(r'\s+'));
    bool isSingleWordInput = originalWords.length == 1;

    List<String> words = List.from(originalWords);
    List<String> translatedParts = [];

    while (words.isNotEmpty) {
      String? phrase;
      String singleWord = words[0];
      int wordsUsed = 0;

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

      if (phrase != null) {
        translatedParts.add(phrase);
      } else {
        if (isSingleWordInput) {
          return "Translation is soon to add";
        } else {
          translatedParts.add("_");
        }
      }

      if (words.isNotEmpty) {
        words.removeRange(0, wordsUsed > 0 ? wordsUsed : 1);
      }
    }

    return translatedParts.join(" ") + punctuation;
  }

  void _swapLanguages() {
    setState(() {
      String temp = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = temp;
      
      if (_sourceController.text.isNotEmpty) {
        _handleTranslate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This value tells us how high the keyboard is
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.primary,
      // We keep the BottomNavPanel here. Standard behavior is it gets covered by keyboard.
      // If no keyboard, it shows at bottom.
      bottomNavigationBar: BottomNavPanel(),
      
      // IMPORTANT: Set to false so we can manage the layout manually with Stack
      resizeToAvoidBottomInset: false, 

      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          // HitTestBehavior.translucent ensures taps on blank areas are caught
          onTap: () {
            FocusScope.of(context).unfocus(); // Close keyboard when tapping outside
          },
          child: Column(
            children: [
              // App Header
              AppHeader(title: "BiTE Translator"),

              // We use Expanded + Stack to handle the Floating Language Bar
              Expanded(
                child: Stack(
                  children: [
                    // 1. The Main Content (White Card)
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      // Add bottom margin to ensure content isn't hidden behind the language bar
                      // 70 is approx height of language bar
                      padding: EdgeInsets.only(bottom: 70), 
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // Input Text Field
                          Expanded(
                            flex: 1, 
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: TextField(
                                controller: _sourceController,
                                maxLines: null, 
                                expands: true, 
                                style: TextStyle(
                                  fontSize: 28, 
                                  color: Colors.black87,
                                  height: 1.3
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter text",
                                  hintStyle: TextStyle(
                                    fontSize: 28, 
                                    color: Colors.grey.shade400
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                // AUTO-TRANSLATE LOGIC HERE
                                onChanged: _onSearchChanged, 
                              ),
                            ),
                          ),

                          // Divider
                          if (_isResultVisible && _translatedText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(color: Colors.grey.shade300, thickness: 1),
                            ),

                          // Result Display
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
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _translatedText,
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 2. The Floating Language Control Bar
                    // Positioned dynamically based on keyboard height
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: keyboardHeight, // Moves up when keyboard opens
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
                              _buildLanguageButton(
                                _fromLanguage, 
                                (val) {
                                  setState(() => _fromLanguage = val);
                                  if(_sourceController.text.isNotEmpty) _handleTranslate();
                                }
                              ),

                              IconButton(
                                icon: Icon(Icons.swap_horiz, color: AppColors.primary, size: 28),
                                onPressed: _swapLanguages,
                              ),

                              _buildLanguageButton(
                                _toLanguage, 
                                (val) {
                                  setState(() => _toLanguage = val);
                                  if(_sourceController.text.isNotEmpty) _handleTranslate();
                                }
                              ),
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
        // Dismiss keyboard before showing modal to avoid UI glitches
        FocusScope.of(context).unfocus();
        _showLanguagePicker(context, (val) {
          onSelect(val);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          currentLang,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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