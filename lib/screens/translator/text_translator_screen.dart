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
    // --- UPDATED: THIS LINE DISMISSES THE KEYBOARD ---
    FocusScope.of(context).unfocus(); 

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

    if (_fromLanguage == "Bidayuh" || _toLanguage == "Bidayuh") {
      String result = _getBidayuhTranslation(text, _fromLanguage.toLowerCase(), _toLanguage.toLowerCase());
      setState(() {
        _translatedText = result.isNotEmpty ? result : "Translation not found.";
        _isResultVisible = true;
      });
      return;
    }

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
    String cleanedText = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    String punctuation = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');

    List<String> words = cleanedText.split(RegExp(r'\s+'));
    List<String> translatedParts = [];

    while (words.isNotEmpty) {
      String? phrase;
      String singleWord = words[0];

      for (int i = words.length; i > 0; i--) {
        String potentialPhrase = words.sublist(0, i).join(" ");
        
        if (fromLang == 'bidayuh' && toLang == 'english') {
          if (_bidayuhToEnglishDict.containsKey(potentialPhrase)) {
            phrase = _bidayuhToEnglishDict[potentialPhrase];
            words = words.sublist(i);
            break; 
          }
        } else if (fromLang == 'bidayuh' && toLang == 'malay') {
          if (_bidayuhToMalayDict.containsKey(potentialPhrase)) {
            phrase = _bidayuhToMalayDict[potentialPhrase];
            words = words.sublist(i);
            break;
          }
        } else if (fromLang == 'english' && toLang == 'bidayuh') {
          if (_englishToBidayuhDict.containsKey(potentialPhrase)) {
            phrase = _englishToBidayuhDict[potentialPhrase];
            words = words.sublist(i);
            break;
          }
        } else if (fromLang == 'malay' && toLang == 'bidayuh') {
          if (_malayToBidayuhDict.containsKey(potentialPhrase)) {
            phrase = _malayToBidayuhDict[potentialPhrase];
            words = words.sublist(i);
            break;
          }
        }
      }

      if (phrase == null) {
        if (fromLang == 'bidayuh' && toLang == 'english') {
           phrase = _bidayuhToEnglishDict[singleWord] ?? singleWord;
        } else if (fromLang == 'bidayuh' && toLang == 'malay') {
           phrase = _bidayuhToMalayDict[singleWord] ?? singleWord;
        } else if (fromLang == 'english' && toLang == 'bidayuh') {
           phrase = _englishToBidayuhDict[singleWord] ?? singleWord;
        } else if (fromLang == 'malay' && toLang == 'bidayuh') {
           phrase = _malayToBidayuhDict[singleWord] ?? singleWord;
        }
        if (words.isNotEmpty) words.removeAt(0);
      }
      
      if (phrase != null) translatedParts.add(phrase);
    }

    return translatedParts.join(" ") + punctuation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      
      // Setting this to false stops the keyboard from pushing widgets up.
      // The keyboard will instead overlay on top of the bottom widgets.
      resizeToAvoidBottomInset: false, 
      
      body: SafeArea(
        child: Column(
          children: [
            // App Header
            AppHeader(title: "BiTE Translator"),
            
            // Expanded allows the SingleChildScrollView to take all available space
            // between the Header and the BottomNavPanel
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Text Translator", 
                      style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    
                    // Language Spinners
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 40, 20, 0),
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)), 
                      child: Row(
                        children: [
                          Expanded(child: _buildDropdown((v) => setState(() => _fromLanguage = v!), _fromLanguage)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.compare_arrows, color: Colors.black, size: 24), 
                          ),
                          Expanded(child: _buildDropdown((v) => setState(() => _toLanguage = v!), _toLanguage)),
                        ],
                      ),
                    ),
                    
                    // Input Field
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: TextField(
                        controller: _sourceController,
                        maxLines: 4,
                        style: TextStyle(fontSize: 20, color: AppColors.black),
                        decoration: InputDecoration(
                          hintText: "Enter your text",
                          filled: true,
                          fillColor: AppColors.white,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          hintStyle: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ),
                    
                    // Translate Button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ElevatedButton(
                        onPressed: _isLoadingDictionaries ? null : _handleTranslate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary, 
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: _isLoadingDictionaries 
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Translate", style: TextStyle(fontSize: 20, color: AppColors.white)),
                      ),
                    ),
                    
                    // Result Display
                    if (_isResultVisible)
                      Container(
                        margin: EdgeInsets.fromLTRB(20, 10, 20, 20),
                        padding: EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)),
                        child: Text(
                          _translatedText, 
                          style: TextStyle(fontSize: 17, color: AppColors.primary, letterSpacing: 0.03), 
                          textAlign: TextAlign.center
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom Panel remains fixed at the bottom.
            // Since resizeToAvoidBottomInset is false, the keyboard will cover this 
            // instead of pushing it up.
            BottomNavPanel(),
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
        items: ["English", "Malay", "Bidayuh"].map((e) => DropdownMenuItem(value: e, child: Center(child: Text(e)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}