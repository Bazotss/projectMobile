import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_text_styles.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<List<dynamic>> fetchNews() async {
  try {
    const apiKey = '18bc83d8a4f7f0ff986fd99eef0bc02b'; // pastikan ada
    final url =
        'https://newsapi.org/v2/top-headlines?country=id&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    return data['articles'] ?? [];
  } catch (e) {
    return [];
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HSNEWS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: fetchNews(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
           return const Center(child: Text('Berita tidak tersedia'));
          }


          final news = snapshot.data as List;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: news.length,
            itemBuilder: (context, i) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    news[i]['title'] ?? '',
                    style: AppTextStyles.title,
                  ),
                  subtitle: const Text('Indonesia • Baru'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          title: news[i]['title'] ?? '',
                          description:
                              news[i]['description'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
