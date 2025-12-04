import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_layouts.dart';
import 'vocabulary_learning_screen.dart';

class VocabularyTestingScreen extends StatefulWidget {
  @override
  _VocabularyTestingScreenState createState() => _VocabularyTestingScreenState();
}

class _VocabularyTestingScreenState extends State<VocabularyTestingScreen> {
  // Comprehensive list merging 'gridItems' and 'wordTranslations' from Java
  final List<Map<String, String>> vocabList = [
    {"word": "Gaon", "img": "gaon", "audio": "gaon.mp3", "eng": "Gown", "mal": "Gaun"},
    {"word": "Jura", "img": "jura", "audio": "jura.mp3", "eng": "Tongue", "mal": "Lidah"},
    {"word": "Jipuh", "img": "jipuh", "audio": "jipuh.mp3", "eng": "Teeth", "mal": "Gigi"},
    {"word": "Ndung", "img": "ndung", "audio": "ndung.mp3", "eng": "Nose", "mal": "Hidung"},
    {"word": "Bebak", "img": "bebak", "audio": "bebak.mp3", "eng": "Mouth", "mal": "Mulut"},
    {"word": "Tengan", "img": "tengan", "audio": "tengan.mp3", "eng": "Hand", "mal": "Tangan"},
    {"word": "Abok", "img": "abok", "audio": "abok.mp3", "eng": "Hair", "mal": "Rambut"},
    {"word": "Kejak", "img": "kejak", "audio": "kejak.mp3", "eng": "Foot", "mal": "Kaki"},
    {"word": "Siruh", "img": "siruh", "audio": "siruh.mp3", "eng": "Nail", "mal": "Kuku"},
    {"word": "Beteh", "img": "beteh", "audio": "beteh.mp3", "eng": "Eye", "mal": "Mata"},
    {"word": "Kejit", "img": "kejit", "audio": "kejit.mp3", "eng": "Ear", "mal": "Telinga"},
    {"word": "Babu", "img": "babu", "audio": "babu.mp3", "eng": "Mouse", "mal": "Tikus"},
    {"word": "Rabit", "img": "rabit", "audio": "rabit.mp3", "eng": "Rabbit", "mal": "Arnab"},
    {"word": "Kuda", "img": "kuda", "audio": "kuda.mp3", "eng": "Horse", "mal": "Kuda"},
    {"word": "Kembing", "img": "kembing", "audio": "kembing.mp3", "eng": "Goat", "mal": "Kambing"},
    {"word": "Atik", "img": "atik", "audio": "atik.mp3", "eng": "Duck", "mal": "Itik"},
    {"word": "Kesong", "img": "kesong", "audio": "kesong.mp3", "eng": "Dog", "mal": "Anjing"},
    {"word": "Biron", "img": "biron", "audio": "biron.mp3", "eng": "Aeroplane", "mal": "Kapal Terbang"},
    {"word": "Siyok", "img": "siyok", "audio": "siyok.mp3", "eng": "Chicken", "mal": "Ayam"},
    {"word": "Busing", "img": "busing", "audio": "busing.mp3", "eng": "Cat", "mal": "Kucing"},
    {"word": "Manuk", "img": "manuk", "audio": "manuk.mp3", "eng": "Bird", "mal": "Burung"},
    {"word": "Ragu", "img": "ragu", "audio": "ragu.mp3", "eng": "Singing", "mal": "Nyanyi"},
    {"word": "Jam Sindung", "img": "jam_sindung", "audio": "jam_sindung.mp3", "eng": "Wall Clock", "mal": "Jam Dinding"},
    {"word": "Man", "img": "man", "audio": "man.mp3", "eng": "Eat", "mal": "Makan"},
    {"word": "Nok", "img": "nok", "audio": "nok.mp3", "eng": "Drink", "mal": "Minum"},
    {"word": "Gogo", "img": "gogo", "audio": "gogo.mp3", "eng": "Dancing", "mal": "Menari"},
    {"word": "Jopo", "img": "jopo", "audio": "jopo.mp3", "eng": "Shirt", "mal": "Baju"},
    {"word": "Sinjang", "img": "sinjang", "audio": "sinjang.mp3", "eng": "Trousers", "mal": "Seluar"},
    {"word": "Tukin", "img": "tukin", "audio": "tukin.mp3", "eng": "Stocking", "mal": "Stokin"},
    {"word": "Jeket", "img": "jeket", "audio": "jeket.mp3", "eng": "Jacket", "mal": "Jaket"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(title: "BiTE Translator"),
            
            // Title Text
            SizedBox(height: 10),
            Text(
              "Vocabulary Learning", 
              style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            
            // GridView
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 16, 
                  mainAxisSpacing: 16, 
                  childAspectRatio: 0.85
                ),
                itemCount: vocabList.length,
                itemBuilder: (context, index) {
                  final item = vocabList[index];
                  return Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => VocabularyLearningScreen(
                            word: item['word']!, 
                            imageName: item['img']!, 
                            audioFileName: item['audio']!, 
                            englishMeaning: item['eng']!, 
                            malayMeaning: item['mal']!
                          ))
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/images/${item['img']}.png', 
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Icon(Icons.image, size: 50, color: Colors.grey)
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text(
                                item['word']!, 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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