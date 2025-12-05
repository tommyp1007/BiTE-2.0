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
            // Header stays at the top full width
            AppHeader(title: "BiTE Translator"),
            
            // The rest of the content takes up the remaining space
            Expanded(
              child: Center(
                // Limit width for tablets/desktop so it looks like a nice list in the middle
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  width: double.infinity,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        "Dictionary", 
                        style: TextStyle(
                          color: AppColors.white, 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      
                      // The Orange Box fills the rest of the vertical space inside the constraints
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(16, 15, 16, 16),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary, 
                            borderRadius: BorderRadius.circular(16),
                            // Added shadow for better separation
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2)
                              )
                            ]
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bidayuh_dictionary')
                                .orderBy('word')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator(color: AppColors.white));
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No words found", 
                                    style: TextStyle(fontSize: 18, color: Colors.white)
                                  )
                                );
                              }

                              final docs = snapshot.data!.docs;
                              
                              return ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (c, i) => Divider(color: AppColors.white.withOpacity(0.5), height: 1),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  String word = data['word'] ?? '';
                                  String english = data['english'] ?? '';
                                  String malay = data['malay'] ?? '';

                                  return ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      word, 
                                      style: TextStyle(
                                        fontSize: 18, 
                                        color: AppColors.white, 
                                        fontWeight: FontWeight.bold
                                      ) 
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 16),
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
                      ),
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