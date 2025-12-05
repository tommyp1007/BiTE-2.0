import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_layouts.dart';

class VocabularyLearningScreen extends StatefulWidget {
  final String word;
  final String imageName;
  final String audioFileName;
  final String englishMeaning;
  final String malayMeaning;

  const VocabularyLearningScreen({
    required this.word, 
    required this.imageName, 
    required this.audioFileName, 
    required this.englishMeaning, 
    required this.malayMeaning
  });

  @override
  _VocabularyLearningScreenState createState() => _VocabularyLearningScreenState();
}

class _VocabularyLearningScreenState extends State<VocabularyLearningScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _audioUrl;
  bool _isLoadingAudio = true;

  @override
  void initState() {
    super.initState();
    _fetchAudio();
    
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _fetchAudio() async {
    try {
      final ref = FirebaseStorage.instance.ref().child("vocabulary_audio/${widget.audioFileName}");
      final url = await ref.getDownloadURL();
      if (mounted) {
        setState(() {
          _audioUrl = url;
          _isLoadingAudio = false;
        });
      }
    } catch (e) {
      print("Audio fetch error: $e");
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  void _toggleAudio() async {
    if (_audioUrl == null) return;
    
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(_audioUrl!));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      bottomNavigationBar: BottomNavPanel(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- HEADER ---
            AppHeader(title: "BiTE Translator"),
            
            // --- SCROLLABLE CONTENT ---
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    physics: BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      // Ensure content is at least as tall as the view for centering
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40, 
                      ),
                      child: Center(
                        // Limit width on Tablets so it looks like a nice card
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 500),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Vocabulary Learning", 
                                style: TextStyle(
                                  color: AppColors.white, 
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              
                              SizedBox(height: 20),
                              
                              // --- WHITE CARD CONTAINER ---
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26, 
                                      blurRadius: 10, 
                                      offset: Offset(0, 5)
                                    )
                                  ]
                                ),
                                child: Column(
                                  children: [
                                    // Image Container
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: Colors.grey.shade200)
                                      ),
                                      child: Image.asset(
                                        'assets/images/${widget.imageName}.png', 
                                        width: 180, 
                                        height: 180, 
                                        fit: BoxFit.contain,
                                        errorBuilder: (_,__,___) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey)
                                      ),
                                    ),
                                    
                                    SizedBox(height: 24),
                                    
                                    // Main Word
                                    Text(
                                      widget.word, 
                                      style: TextStyle(
                                        fontSize: 34, 
                                        fontWeight: FontWeight.w900, 
                                        color: AppColors.primary,
                                        letterSpacing: 1.0
                                      )
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Meanings
                                    _buildMeaningRow("English", widget.englishMeaning),
                                    SizedBox(height: 10),
                                    _buildMeaningRow("Malay", widget.malayMeaning),
                                    
                                    SizedBox(height: 30),
                                    
                                    // Audio Controls
                                    GestureDetector(
                                      onTap: _isLoadingAudio || _audioUrl == null ? null : _toggleAudio,
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                                          ]
                                        ),
                                        child: Opacity(
                                          opacity: _isLoadingAudio ? 0.5 : 1.0,
                                          child: Image.asset(
                                            // Using orange icons because background is white
                                            _isPlaying ? 'assets/images/pause_orange.png' : 'assets/images/play_orange.png', 
                                            width: 80, 
                                            height: 80,
                                            errorBuilder: (c,e,s) => Icon(
                                              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                              size: 80,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    if (_isLoadingAudio)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeaningRow(String lang, String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10)
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 18, color: Colors.black87),
          children: [
            TextSpan(
              text: "$lang: ", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 16)
            ),
            TextSpan(
              text: text, 
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)
            ),
          ],
        ),
      ),
    );
  }
}