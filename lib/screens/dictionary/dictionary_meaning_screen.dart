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
            // Custom Header
            AppHeader(title: "BiTE Translator"),
            
            SizedBox(height: 20),
            Text(
              "Dictionary Meaning", 
              style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(0), // Standard rectangular shape
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                    ]
                  ),
                  width: double.infinity,
                  child: Column(
                    // FIX: Align children (Text) to the start (left)
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      // FIX: Wrap Image in Center so it stays centered
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
                      
                      // FIX: Wrap Play Button in Center so it stays centered
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
                      
                      SizedBox(height: 10),
                      
                      // Word Text (Left Aligned)
                      Text(
                        widget.word, 
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary)
                      ),
                      
                      // Type & Category (Left Aligned)
                      Text("Type: Verb", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black)),
                      Text("Category: Activities", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black)),
                      
                      SizedBox(height: 10),
                      
                      // English Meaning (Left Aligned)
                      Text("English meaning", style: TextStyle(fontSize: 20, color: AppColors.black)),
                      Text("English: ${widget.english ?? 'N/A'}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black)),
                      
                      SizedBox(height: 10),
                      
                      // Malay Meaning (Left Aligned)
                      Text("Malay meaning", style: TextStyle(fontSize: 20, color: AppColors.black)),
                      Text("Malay: ${widget.malay ?? 'N/A'}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black)),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}