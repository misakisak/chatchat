import 'dart:convert'; // JSONデータを解析するために必要
import 'package:flutter/material.dart';
import 'package:chat/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;


class Utils {
  static Future<Map<String, String>> fetchEmojiMeaningsFromFirestore() async {
    // Initialize Firestore
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch emoji meanings from Firestore collection
    QuerySnapshot snapshot = await firestore.collection('emojis').get();
    
    // Convert snapshot to a Map of emoji -> meaning
    Map<String, String> emojiMeanings = {};
    snapshot.docs.forEach((doc) {
      String emoji = doc.get('id'); // Emoji character itself
      String meaning = doc.get('meanEn') ?? "Unknown"; // English meaning
      emojiMeanings[emoji] = meaning;
    });

    return emojiMeanings;
  }
  
  static Future<String> replaceEmojisWithMeanings(String text, RegExp regex) async {
    // Implementation...
    // Future<String> replaceEmojisWithMeanings(String text, RegExp regex) async {
      // Initialize Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Fetch emoji meanings from Firestore
      Map<String, String> emojiMeanings = await fetchEmojiMeaningsFromFirestore();

      // Replace emojis with their names and meanings
      String textWithNamesAndMeanings = text.replaceAllMapped(regex, (match) {
        String emoji = match.group(0)!;
        String meaning = emojiMeanings[emoji] ?? "Unknown";
        return "$emoji ($meaning)";
      });

      return textWithNamesAndMeanings;
    // }
  }

  static Future<String> translateText(String text, String targetLang) async {
    // Implementation...
    // Future<String> translateText(String text, String targetLang) async {
      // DeepL APIのエンドポイント
      final apiUrl = 'https://api-free.deepl.com/v2/translate';

      // DeepL APIキー
      final apiKey = 'a3e6e60c-2fca-4dbb-a60f-ffd776d09293:fx';

      // HTTP POSTリクエストのヘッダーとボディを設定
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'DeepL-Auth-Key $apiKey',
        },
        body: {
          'text': text,
          'target_lang': targetLang,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['translations'] != null && responseData['translations'].isNotEmpty) {
          return responseData['translations'][0]['text'];
        } else {
          throw Exception('Translation not found in response data');
        }
      } else {
        throw Exception('Failed to translate text: ${response.statusCode}');
      }
    }
  // }
}