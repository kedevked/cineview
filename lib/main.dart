import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Movie DB App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MovieListScreen(),
    );
  }
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List<Movie> _movies = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Replace with your actual API key.
      const apiKey = 'a61feb04a7d5a6ac523affbfa94bd6b4'; // Replace with your API key
      final response = await http.get(
        Uri.parse(
            'https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final List<dynamic> movieList = data['results'];
          setState(() {
            _movies =
                movieList.map((movieJson) => Movie.fromJson(movieJson)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid API response format.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load movies. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing Movies'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Number of columns in the grid
                    childAspectRatio: 0.7, // Adjust aspect ratio as needed
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _movies[index];
                    return Card(
                      child: InkWell(
                        onTap: () {
                          // Handle movie tap (e.g., navigate to details)
                          print('Tapped on ${movie.title}');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: movie.posterPath != null
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w185${movie.posterPath}', // Use a larger image size
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.error),
                                    )
                                  : const Icon(Icons.movie, size: 60),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title ?? 'No Title',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Release: ${movie.releaseDate ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class Movie {
  final int? id;
  final String? title;
  final String? posterPath;
  final String? releaseDate;

  Movie({
    this.id,
    this.title,
    this.posterPath,
    this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      releaseDate: json['release_date'],
    );
  }
}
