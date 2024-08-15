import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'news_list.dart';

class NewsProvider extends ChangeNotifier {
  List<NewsItem> _newsList = [];

  List<NewsItem> get newsList => _newsList;

  NewsProvider() {
    FirebaseDatabase.instance.ref().child('news').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        _newsList = data.entries.map((entry) {
          final key = entry.key as String; // Extract the unique ID
          final value = entry.value as Map<dynamic, dynamic>;
          return NewsItem(
            id: key,
            title: value['title'],
            description: value['description'],
            content: value['content'],
            author: value['author'],
            date: DateTime.parse(value['date']),
            category: value['category'],
            imageUrl: value['imageUrl'] ?? '',
          );
        }).toList();
      } else {
        _newsList = [];
      }
      notifyListeners();
    });
  }
}
