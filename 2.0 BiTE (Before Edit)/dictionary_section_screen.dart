import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_layouts.dart';
import 'dictionary_meaning_screen.dart';

class DictionarySectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: "BiTE Translator"),
            SizedBox(height: 20),
            Text(
              "Dictionary", 
              style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 5, 16, 16),
                padding: EdgeInsets.all(8),
                // Implements rounded_background_dictionary.xml (Secondary Color, 16dp Radius)
                decoration: BoxDecoration(
                  color: AppColors.secondary, 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bidayuh_dictionary').orderBy('word').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppColors.white));
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No words found", style: TextStyle(fontSize: 18, color: Colors.white)));
                    }

                    final docs = snapshot.data!.docs;
                    
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (c, i) => Divider(color: AppColors.white, height: 10),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        String word = data['word'] ?? '';
                        String english = data['english'] ?? '';
                        String malay = data['malay'] ?? '';

                        return ListTile(
                          title: Text(
                            word, 
                            // UPDATED: Added fontWeight: FontWeight.bold here
                            style: TextStyle(
                              fontSize: 18, 
                              color: AppColors.white, 
                              fontWeight: FontWeight.bold
                            ) 
                          ),
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => DictionaryMeaningScreen(
                                word: word, 
                                english: english, 
                                malay: malay
                              ))
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}