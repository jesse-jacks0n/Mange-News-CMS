import 'package:flutter/material.dart';
import 'news_list.dart';

class NewsDetail extends StatelessWidget {
  final NewsItem newsItem;

  NewsDetail({required this.newsItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(newsItem.title),
      ),
      body: LayoutBuilder(
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsItem.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      newsItem.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'By ${newsItem.author} on ${newsItem.date.toIso8601String().split('T').first}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 16.0),
                    newsItem.imageUrl.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(newsItem.imageUrl),
                    )
                        : SizedBox.shrink(),
                    SizedBox(height: 16.0),
                    Text(
                      newsItem.content,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
