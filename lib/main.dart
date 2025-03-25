import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

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
  Movie? _selectedMovie;

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
            _selectedMovie = _movies.isNotEmpty ? _movies[0] : null; // Select the first movie initially
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

  void _selectMovie(Movie movie) {
    setState(() {
      _selectedMovie = movie;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing Movies'),
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    // Big Movie Display
                    Expanded(
                      flex: 3,
                      child: _selectedMovie != null
                          ? _buildBigMovieCard(_selectedMovie!)
                          : const Center(child: Text('No movie selected')),
                    ),
                    // Miniature Movie List
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 10000,
                          itemBuilder: (context, index) {
                            final movie = _movies[index % _movies.length];
                            return GestureDetector(
                              onTap: () => _selectMovie(movie),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Hero(
                                  tag: 'movie-${movie.id}',
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    scale: _selectedMovie == movie ? 1.1 : 1.0,
                                    child: Container(
                                      width: 92, // Width of the thumbnail (w92)
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 500),
                                          opacity: _isLoading ? 0.5 : 1.0,
                                          child: movie.posterPath != null
                                              ? Image.network(
                                                  'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Center(child: Icon(Icons.error)),
                                                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Center(child: Icon(Icons.movie, size: 40)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildBigMovieCard(Movie movie) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'movie-${movie.id}',
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _isLoading ? 0.5 : 1.0,
                  child: movie.posterPath != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w342${movie.posterPath}', // Larger image for big display
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : const Icon(Icons.movie, size: 100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title ?? 'No Title',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Release: ${movie.releaseDate ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8.0),
              color: Colors.grey,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 92,
                    height: 150,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
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
