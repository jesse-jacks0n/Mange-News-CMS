import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'news_detail.dart';

class NewsList extends StatelessWidget {
  Future<void> _deleteNews(BuildContext context, String newsId, String imageUrl) async {
    try {
      await FirebaseDatabase.instance.ref().child('news').child(newsId).remove();

      if (imageUrl.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('News item deleted successfully')));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete news item: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref().child('news').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(child: CircularProgressIndicator());
        } else {
          Map<dynamic, dynamic> newsMap = (snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
          List<NewsItem> newsList = newsMap.entries.map<NewsItem>((entry) {
            final key = entry.key as String;
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

          return LayoutBuilder(
            builder: (context, constraints) {
              double maxWidth;
              if (constraints.maxWidth < 600) {
                maxWidth = constraints.maxWidth * 0.9; // Small screens
              } else if (constraints.maxWidth < 1200) {
                maxWidth = constraints.maxWidth * 0.75; // Medium screens
              } else {
                maxWidth = constraints.maxWidth * 0.6; // Large screens
              }

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final newsItem = newsList[index];

                      return Card(
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewsDetail(newsItem: newsItem),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                newsItem.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    newsItem.imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : Icon(Icons.image, size: 100),
                                SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        newsItem.title,
                                        style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        newsItem.description,
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        'By ${newsItem.author} • ${newsItem.date.toLocal().toIso8601String().split('T').first}',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteNews(context, newsItem.id, newsItem.imageUrl),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class NewsItem {
  final String id;
  final String title;
  final String description;
  final String content;
  final String author;
  final DateTime date;
  final String category;
  final String imageUrl;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.author,
    required this.date,
    required this.category,
    required this.imageUrl,
  });
}
