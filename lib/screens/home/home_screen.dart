import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../detail/detail_screen.dart';
import '../video/video_screen.dart';
import '../more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// ================= IMAGE FIX =================
String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://')) {
    return url.replaceFirst('http://', 'https://');
  }
  return url;
}

class _HomeScreenState extends State<HomeScreen> {
  final List _articles = [];
  int _page = 1;
  bool _loading = false;
  String _query = '';
  int _currentIndex = 0;

  final ScrollController _scrollController = ScrollController();

  static const String apiKey = '18bc83d8a4f7f0ff986fd99eef0bc02b';

  @override
  void initState() {
    super.initState();
    fetchNews();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_loading) {
        _page++;
        fetchNews();
      }
    });
  }

  Future<void> fetchNews({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _articles.clear();
    }

    setState(() => _loading = true);

    final url = Uri.parse(
      'https://gnews.io/api/v4/search?q=${_query.isEmpty ? "indonesia" : _query}'
      '&lang=id&country=id&max=10&page=$_page&token=$apiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        _articles.addAll(data['articles']);
        _loading = false;
      });
    }
  }

  /// ================= PAGE SWITCH =================
  Widget _buildBody() {
    if (_currentIndex == 1) return const VideoScreen();
    if (_currentIndex == 2) return const MoreScreen();
    return _buildHome();
  }

  /// ================= HOME UI =================
  Widget _buildHome() {
    return Column(
      children: [
        /// SEARCH
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari berita...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              _query = value;
              fetchNews(refresh: true);
            },
          ),
        ),

        /// LIST BERITA
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _articles.length + 1,
            itemBuilder: (context, index) {
              if (index == _articles.length) {
                return _loading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox();
              }

              final article = _articles[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(article: article),
                    ),
                  );
                },
                child: NewsCard(article: article, big: index == 0),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APPBAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'HSNEWS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),

      body: _buildBody(),

      /// BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}

/// ================= NEWS CARD =================
class NewsCard extends StatelessWidget {
  final Map article;
  final bool big;

  const NewsCard({super.key, required this.article, this.big = false});

  @override
  Widget build(BuildContext context) {
    final imageUrl = fixImageUrl(article['image']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: big ? 200 : 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _imageFallback(big);
                    },
                  )
                : _imageFallback(big),
          ),

          const SizedBox(height: 8),

          /// TITLE
          Text(
            article['title'] ?? '',
            maxLines: big ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: big ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          /// SOURCE
          Text(
            article['source']['name'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(bool big) {
    return Container(
      height: big ? 200 : 120,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image_not_supported, size: 40),
    );
  }
}
