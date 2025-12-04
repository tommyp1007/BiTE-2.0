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
    
    // Listen to player state changes to update the icon
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Reset icon when audio finishes
    _player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  // Replaces Java's DownloadAudioTask
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(title: "BiTE Translator"),
            
            // Title
            SizedBox(height: 10),
            Text("Vocabulary Learning", style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Word Image
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Image.asset(
                        'assets/images/${widget.imageName}.png', 
                        width: 180, 
                        height: 180, 
                        fit: BoxFit.contain,
                        errorBuilder: (_,__,___) => Icon(Icons.image, size: 100, color: AppColors.white)
                      ),
                    ),
                    
                    // Word Text
                    SizedBox(height: 20),
                    Text(
                      widget.word, 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white)
                    ),
                    
                    // English Meaning
                    SizedBox(height: 10),
                    Text(
                      "English: ${widget.englishMeaning}", 
                      style: TextStyle(fontSize: 18, color: AppColors.white)
                    ),
                    
                    // Malay Meaning
                    SizedBox(height: 5),
                    Text(
                      "Malay: ${widget.malayMeaning}", 
                      style: TextStyle(fontSize: 18, color: AppColors.white)
                    ),
                    
                    // Play/Pause Button
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isLoadingAudio || _audioUrl == null ? null : _toggleAudio,
                      child: Opacity(
                        opacity: _isLoadingAudio ? 0.5 : 1.0,
                        child: Image.asset(
                          // Switching icons based on state like Java code
                          _isPlaying ? 'assets/images/pause.png' : 'assets/images/play.png', 
                          width: 110, 
                          height: 100
                        ),
                      ),
                    ),
                    
                    // Result TextView (Placeholder from XML)
                    SizedBox(height: 30),
                    Text(
                      "", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green) // holo_green_dark
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Panel
            BottomNavPanel(),
          ],
        ),
      ),
    );
  }
}