import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class AppColors {
  static const bg = Color(0xFF08070C);
  static const surface = Color(0xFF0D0B17);
  static const surface2 = Color(0xFF110F20);

  static const border = Color(0x1FB400FF); // #B400FF1F
  static const borderBright = Color(0x66B400FF); // #B400FF66

  static const accent = Color(0xFFB400FF);
  static const accentDim = Color(0x26B400FF); // #B400FF26
  static const accentGlow = Color(0x0FB400FF); // #B400FF0F

  static const text = Color(0xFFD6CDE0);
  static const textDim = Color(0xFF604A70);
  static const textBright = Color(0xFFF3E8FF);
}

class Movie {
  final String video;
  final String image;
  final String type;
  final String title;
  final int date;
  final String description;

  Movie({
    required this.title,
    required this.image,
    required this.type,
    required this.date,
    required this.video,
    required this.description,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'],
      image: json['image'],
      type: json['type'],
      date: json['date'],
      video: json['video'],
      description: json['description'],
    );
  }
}

class ApiService {
  static const _baseUrl = 'http://88.189.251.90:21555';

  static Future<Movie> getMovie(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/getFilm/$id'));

    if (res.statusCode != 200) throw Exception('GetMovie failed');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final movieJson = data['film'] as Map<String, dynamic>;

    // print(const JsonEncoder.withIndent('  ').convert(movieJson));

    return Movie.fromJson(movieJson);
  }
}

class MovieScreen extends StatefulWidget {
  final int movieId;
  final String movieUrl;

  const MovieScreen({required this.movieId, required this.movieUrl});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  Movie? _movie;

  late WebViewController previewController;

  @override
  void initState() {
    super.initState();

    previewController = WebViewController();

    previewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.movieUrl));

    _fetchMovie();
  }

  void _fetchMovie() async {
    try {
      final results = await ApiService.getMovie(widget.movieId);
      if (mounted) setState(() => _movie = results);
      print(" movie: ${_movie} ");
    } catch (_) {}
  }


  // BUILD -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _movie == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _TopBar(movieId: widget.movieId),
                    const SizedBox(height: 16),
                    _Preview(controller: previewController),
                    const SizedBox(height: 16),
                    _MetaBar(movie: _movie!),
                    const SizedBox(height: 16),
                    _Description(description: _movie!.description),
                  ],
                ),
        ),
      ),  
    );
  }
}

class _Preview extends StatefulWidget {
  final WebViewController controller;

  const _Preview({required this.controller});

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          WebViewWidget(controller: widget.controller),
          ..._Corners(),
        ],
      ),
    );
  }
}

List<Widget> _Corners() {
  const size = 8.0;
  const thick = 1.5;
  const c = AppColors.accent;
  final bp = BorderSide(color: c, width: thick);
  final tn = BorderSide.none;

  return [
    // top left
    Positioned(
      top: 0,
      left: 0,
      child: _CornerWidget(
        border: Border(top: bp, left: bp, right: tn, bottom: tn),
      ),
    ),

    // top right
    Positioned(
      top: 0,
      right: 0,
      child: _CornerWidget(
        border: Border(top: bp, left: tn, right: bp, bottom: tn),
      ),
    ),

    // bottom left
    Positioned(
      bottom: 0,
      left: 0,
      child: _CornerWidget(
        border: Border(top: tn, left: bp, right: tn, bottom: bp),
      ),
    ),

    // bottom right
    Positioned(
      bottom: 0,
      right: 0,
      child: _CornerWidget(
        border: Border(top: tn, left: tn, right: bp, bottom: bp),
      ),
    ),
  ];
}

class _CornerWidget extends StatelessWidget {
  final Border border;
  const _CornerWidget({required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(border: border),
    );
  }
}

class _MetaBar extends StatelessWidget {
  final Movie _movie;

  _MetaBar({required Movie movie}) : _movie = movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Stack(
            children: [
              Image.network(_movie.image, height: 150, fit: BoxFit.cover),
              ..._Corners(),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _movie.title,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _movie.date.toString(),
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      _movie.type,
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int movieId;

  const _TopBar({required this.movieId});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Return',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: AppColors.accent),
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'ID $movieId',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  final String _description;

  _Description({required String description}) : _description = description;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 10,
      child: SingleChildScrollView(
        child: Text(
          _description,
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

// class _AskButton extends StatelessWidget {
//   final int movieId;
//   final int asked;
//   final void Function(int) askMovie;

//   const _AskButton({
//     required this.movieId,
//     required this.asked,
//     required this.askMovie,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return asked == 1
//         ? Stack(
//             children: [
//               Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   border: Border.all(width: 1, color: AppColors.borderBright),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     "Already Asked",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: AppColors.accent,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                       fontFamily: 'monospace',
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           )
//         : GestureDetector(
//             onTap: () {
//               askMovie(movieId);
//             },
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 border: Border.all(width: 1, color: AppColors.borderBright),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   "Ask",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: AppColors.accent,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     fontFamily: 'monospace',
//                   ),
//                 ),
//               ),
//             ),
//           );
//   }
// }
