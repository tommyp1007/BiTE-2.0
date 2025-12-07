import 'dart:io'; // Needed for File type
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // Import cache manager
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
  bool _isAudioReady = false; // Tracks if audio is cached and ready to play

  @override
  void initState() {
    super.initState();
    _fetchAndCacheAudio(); 
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // When audio finishes, just stop (don't release resource) so we can replay instantly
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  // 1. Get URL from Firebase
  // 2. Download and Save to Local Storage (Cache)
  // 3. Set Player source to the LOCAL file
  Future<void> _fetchAndCacheAudio() async {
    try {
      // Step A: Construct the Firebase reference
      final ref = FirebaseStorage.instance.ref().child("vocabulary_audio/${widget.word.toLowerCase()}.mp3");
      
      // Step B: Get the download URL (Requires internet the very first time to find the file)
      final onlineUrl = await ref.getDownloadURL();

      // Step C: Use CacheManager to download and save the file locally.
      // If the file was downloaded previously, this returns the local file instantly (Offline support).
      File localFile = await DefaultCacheManager().getSingleFile(onlineUrl);

      if (mounted) {
        // Step D: Configure the player to play from the LOCAL DEVICE file, not the internet
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.setSource(DeviceFileSource(localFile.path));
        
        setState(() => _isAudioReady = true);
        print("Audio cached at: ${localFile.path}"); // Debugging: See where it saves
      }
    } catch (e) {
      print("Audio loading failed for ${widget.word}: $e");
    }
  }

  // Toggle Audio
  void _toggleAudio() async {
    if (!_isAudioReady) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // resume() plays the buffered/loaded local file instantly
      await _audioPlayer.resume();
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
            
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 600),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                              
                              // White Card
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
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
                                        onTap: _isAudioReady ? _toggleAudio : null,
                                        child: AnimatedOpacity(
                                          duration: Duration(milliseconds: 300),
                                          // If audio isn't cached/ready yet, dim the button
                                          opacity: _isAudioReady ? 1.0 : 0.3,
                                          child: Image.asset(
                                            _isPlaying ? 'assets/images/pause_orange.png' : 'assets/images/play_orange.png', 
                                            width: 60, 
                                            height: 60,
                                            errorBuilder: (c,e,s) => Icon(Icons.play_circle_fill, size: 60, color: AppColors.secondary),
                                          ),
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