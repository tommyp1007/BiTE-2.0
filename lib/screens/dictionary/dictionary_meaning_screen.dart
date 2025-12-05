import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_layouts.dart';

class DictionaryMeaningScreen extends StatefulWidget {
  final String word;
  final String? english;
  final String? malay;

  const DictionaryMeaningScreen({required this.word, this.english, this.malay});

  @override
  _DictionaryMeaningScreenState createState() => _DictionaryMeaningScreenState();
}

class _DictionaryMeaningScreenState extends State<DictionaryMeaningScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _fetchAudioUrl();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  // Fetch audio URL from Firebase Storage
  Future<void> _fetchAudioUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref().child("vocabulary_audio/${widget.word.toLowerCase()}.mp3");
      final url = await ref.getDownloadURL();
      if (mounted) setState(() => _audioUrl = url);
    } catch (e) {
      print("Audio not found for ${widget.word}: $e");
    }
  }

  // Toggle Audio
  void _toggleAudio() async {
    if (_audioUrl == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(_audioUrl!));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logic to format filename: "Jam Sindung" -> "jam_sindung"
    String imageFilename = widget.word.toLowerCase().replaceAll(' ', '_');

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header (Fixed at top)
            AppHeader(title: "BiTE Translator"),
            
            // Expanded area that contains the scrollable content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: ConstrainedBox(
                      // Ensures content is at least the height of the view, 
                      // allowing alignment logic to work
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        // Limits the width on Tablet/Desktop for a nice card look
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 600),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
                            children: [
                              Text(
                                "Dictionary Meaning", 
                                style: TextStyle(
                                  color: AppColors.white, 
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              
                              SizedBox(height: 20),
                              
                              // The White Card Container
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16), // Rounded corners look better
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26, 
                                      blurRadius: 8, 
                                      offset: Offset(0, 4)
                                    )
                                  ]
                                ),
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    // Image
                                    Center(
                                      child: Image.asset(
                                        'assets/images/$imageFilename.png', 
                                        width: 150, 
                                        height: 150,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/default_image.png', 
                                            width: 150, 
                                            height: 150,
                                            fit: BoxFit.contain
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Audio Play Button
                                    Center(
                                      child: GestureDetector(
                                        onTap: _audioUrl == null ? null : _toggleAudio,
                                        child: Image.asset(
                                          _isPlaying ? 'assets/images/pause_orange.png' : 'assets/images/play_orange.png', 
                                          width: 60, 
                                          height: 60,
                                          errorBuilder: (c,e,s) => Icon(Icons.play_circle_fill, size: 60, color: AppColors.secondary),
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Word Text
                                    Text(
                                      widget.word, 
                                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)
                                    ),
                                    
                                    // Type & Category
                                    SizedBox(height: 8),
                                    Text("Type: Verb", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                    Text("Category: Activities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                    
                                    Divider(height: 30, thickness: 1),
                                    
                                    // English Meaning
                                    Text("English meaning", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Text(
                                      widget.english ?? 'N/A', 
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black)
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Malay Meaning
                                    Text("Malay meaning", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Text(
                                      widget.malay ?? 'N/A', 
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black)
                                    ),
                                  ],
                                ),
                              ),
                              // Spacer at bottom so card doesn't touch navigation bar
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}