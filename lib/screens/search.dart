import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:FluXo/screens/movie.dart';

import 'package:cached_network_image/cached_network_image.dart';

class AppColors {
  static const bg = Color(0xFF08070C);
  static const surface = Color(0xFF0D0B17);
  static const surface2 = Color(0xFF110F20);

  static const border = Color(0x1FB400FF); // #B400FF1F
  static const borderBright = Color(0x66B400FF); // #B400FF66

  static const accent = Color(0xFFB400FF);
  static const accentDim = Color(0x26B400FF); // #B400FF26
  static const accentGlow = Color(0x0FB400FF); // #B400FF0F
  static const accentTrans = Color.fromARGB(118, 179, 0, 255);

  static const text = Color(0xFFD6CDE0);
  static const textDim = Color(0xFF604A70);
  static const textBright = Color(0xFFF3E8FF);
}

class MovieItem {
  final int id;
  final String title;
  final String image;
  final String url;
  final String type; // IMPORTANT: string pour matcher API
  final int date;
  final DateTime createdAt;

  MovieItem({
    required this.id,
    required this.title,
    required this.image,
    required this.url,
    required this.type,
    required this.date,
    required this.createdAt,
  });

  bool get isNew {
    return DateTime.now().difference(createdAt).inDays < 1;
  }

  factory MovieItem.fromJson(Map<String, dynamic> json) {
    return MovieItem(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      url: json['video'],
      type: json['type'].toString(),
      date: json['date'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TypesItem {
  final int id;
  final String title;

  TypesItem({required this.id, required this.title});

  factory TypesItem.fromJson(Map<String, dynamic> json) {
    return TypesItem(id: json['id'], title: json['libelle']);
  }
}

class ApiService {
  static const _baseUrl = 'http://88.189.251.90:21555';

  static Future<List<MovieItem>> getMovies() async {
    final res = await http.get(Uri.parse('$_baseUrl/getMovies'));

    if (res.statusCode != 200) {
      throw Exception('GetMovies failed');
    }

    final List<dynamic> data = jsonDecode(res.body)['movies'];

    return data.map((e) => MovieItem.fromJson(e)).toList();
  }

  static Future<List<TypesItem>> getTypes() async {
    final res = await http.get(Uri.parse('$_baseUrl/getTypes'));

    if (res.statusCode != 200) throw Exception('GetTypes failed');
    final data = jsonDecode(res.body)['types'] as List;
    return data.map((e) => TypesItem.fromJson(e)).toList();
  }

  static Future<List<MovieItem>> search(String query, List<int> types) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'search': query, 'types': types}),
    );

    if (res.statusCode != 200) throw Exception('Search failed');

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final titles = data['titles'] as List<dynamic>;

    return titles
        .map((e) => MovieItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> getMeta() async {
    final res = await http.get(Uri.parse('$_baseUrl/getMeta'));

    if (res.statusCode != 200) throw Exception('GetMeta failed');

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchState();
}

class _SearchState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<MovieItem> _homeMovies = [];
  List<MovieItem> _searchedMovies = [];
  List<TypesItem> _types = [];
  List<int> _activeFilters = [];

  bool _isSearching = false;
  int _metaTotal = 0;
  int _metaNew = 0;
  Map<int, int> _metaNewByType = {};

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _fetchMovies();
    _fetchTypes();
    _fetchMeta();

    // search et totla tt les 5s en arriere
    Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchMovies();
      _fetchMeta();
    });
  }

  Future<void> _fetchMovies() async {
    try {
      final res = await ApiService.getMovies();

      if (mounted) setState(() => _homeMovies = res);
    } catch (_) {}
  }

  Future<void> _fetchTypes() async {
    try {
      final res = await ApiService.getTypes();
      if (mounted) setState(() => _types = res);
    } catch (_) {}
  }

  void _resetSearch() {
    setState(() {
      _searchController.text = '';
      _activeFilters = [];
      _isSearching = false;
    });
  }

  void _fetchMeta() async {
    try {
      final res = await ApiService.getMeta();
      print(res);
      if (mounted) {
        setState(() {
          _metaTotal = res['total'];
          _metaNew = res['new'];
          _metaNewByType = Map<int, int>.from(
            (res['newByType'] as Map).map(
              (key, value) => MapEntry(
                key is int ? key : int.parse(key.toString()),
                value as int,
              ),
            ),
          );

          print(_metaNewByType);
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final hasText = value.isNotEmpty || _activeFilters.isNotEmpty;

      setState(() {
        _isSearching = hasText;
      });

      if (hasText) {
        _fetchSearch(value);
      }
    });
  }

  void _fetchSearch(String query) async {
    try {
      final results = await ApiService.search(query, _activeFilters);
      if (mounted) setState(() => _searchedMovies = results);
    } catch (_) {}
  }

  void _toggleFilter(int id) {
    setState(() {
      if (_activeFilters.contains(id)) {
        _activeFilters.remove(id);
      } else {
        _activeFilters.add(id);
      }

      if (_activeFilters.length > 0) {
        _fetchSearch(_searchController.text);
        setState(() => _isSearching = true);
      } else {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            const _GridBackground(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(height: 22),
                  _SearchBar(
                    controller: _searchController,
                    onchanged: _onSearchChanged,
                    reset: _resetSearch,
                  ),
                  SizedBox(height: 10),
                  _Filters(
                    types: _types,
                    activeFilters: _activeFilters,
                    toggleFilter: _toggleFilter,
                  ),
                  SizedBox(height: 5),
                  _MetaBar(
                    total: _isSearching
                        ? _searchedMovies.length
                        : _homeMovies.length,
                    diff: _metaNew,
                  ),
                  !_isSearching
                      ? Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (var i = 0; i < _types.length; i++)
                                  _CatList(
                                    catName: _types[i].title,
                                    films: _homeMovies,
                                    newMovies:
                                        _metaNewByType[_types[i].id] ?? 0,
                                  ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: _FiltredMovieList(
                            films: _searchedMovies,
                            scrollController: _scrollController,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _GridPainter()));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(10, 179, 0, 255)
      ..strokeWidth = 1;

    const step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatList extends StatelessWidget {
  final String catName;
  final List<MovieItem> films;
  final int newMovies;

  const _CatList({
    required this.catName,
    required this.films,
    required this.newMovies,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = films.where((e) => e.type == catName).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            children: [
              Text(
                catName,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    "$newMovies",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    "New",
                    style: const TextStyle(
                      color: AppColors.textBright,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [for (final movie in filtered) _MovieCard(movie: movie)],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  final MovieItem movie;

  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieScreen(movieId: movie.id, movieUrl: movie.url),
          ),
        );

        print('movie: ${movie.id} ');
      },
      child: Row(
        children: [
          Container(
            width: 100,
            height: 150,
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: movie.image,
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                ),
                _DateTag(date: movie.date, top: 5, left: 5),
                if (movie.isNew) _NewTag(bottom: 5, right: 5),
                ..._Corners(),
              ],
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _DateTag extends StatelessWidget {
  final int date;
  final double top;
  final double left;

  const _DateTag({required this.date, this.top = 0, this.left = 0});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        decoration: BoxDecoration(
          color: AppColors.accentTrans,
          border: Border.all(width: 1, color: AppColors.accent),
        ),
        child: Text(
          date.toString(),
          style: const TextStyle(
            color: AppColors.bg,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onchanged;
  final void Function() reset;

  const _SearchBar({
    required this.controller,
    required this.onchanged,
    required this.reset,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(width: 1, color: AppColors.border),
      ),
      child: Stack(
        children: [
          ..._Corners(),
          Row(
            children: [
              SizedBox(width: 20),
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onChanged: (value) {
                    print("value: $value");
                    widget.onchanged(value);
                  },
                  style: TextStyle(
                    color: AppColors.textBright,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Search titles...',
                    hintStyle: TextStyle(
                      color: AppColors.textBright,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => widget.reset());
                },
                icon: Icon(Icons.clear),
              ),
              SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

List<Widget> _Corners({double adder = 0.0}) {
  final size = 8.0 + adder;
  const thick = 1.5;
  const c = AppColors.accent;
  final bp = BorderSide(color: c, width: thick);
  final tn = BorderSide.none;

  return [
    // top left
    Positioned(
      top: 0,
      left: 0,
      width: size,
      height: size,
      child: _CornerWidget(
        border: Border(top: bp, left: bp, right: tn, bottom: tn),
      ),
    ),

    // top right
    Positioned(
      top: 0,
      right: 0,
      width: size,
      height: size,
      child: _CornerWidget(
        border: Border(top: bp, left: tn, right: bp, bottom: tn),
      ),
    ),

    // bottom left
    Positioned(
      bottom: 0,
      left: 0,
      width: size,
      height: size,
      child: _CornerWidget(
        border: Border(top: tn, left: bp, right: tn, bottom: bp),
      ),
    ),

    // bottom right
    Positioned(
      bottom: 0,
      right: 0,
      width: size,
      height: size,
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

class _NewTag extends StatefulWidget {
  final double bottom;
  final double right;

  _NewTag({this.bottom = 0, this.right = 0});

  @override
  State<_NewTag> createState() => _NewTagState();
}

class _NewTagState extends State<_NewTag> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _dot;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _dot = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.bottom,
      right: widget.right,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: AppColors.accent),
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(_dot.value),
                  ),
                ),
                SizedBox(width: 3),
                Text(
                  ' New',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FiltredMovieList extends StatelessWidget {
  final List<MovieItem> films;
  final ScrollController scrollController;

  const _FiltredMovieList({
    required this.films,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      itemCount: films.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, i) {
        return _FiltredMovieCard(movie: films[i]);
      },
    );
  }
}

class _FiltredMovieCard extends StatefulWidget {
  final MovieItem movie;

  const _FiltredMovieCard({required this.movie});

  @override
  State<_FiltredMovieCard> createState() => _FiltredMovieCardState();
}

class _FiltredMovieCardState extends State<_FiltredMovieCard> {
  @override
  Widget build(BuildContext context) {
    final isNew = widget.movie.isNew;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieScreen(
              movieId: widget.movie.id,
              movieUrl: widget.movie.url,
            ),
          ),
        );
        print("Film id ${widget.movie.id}");
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(width: 1, color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRect(
              child: CachedNetworkImage(
                imageUrl: widget.movie.image,
                height: 70,
                width: 40,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.movie.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '  (${widget.movie.date})',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      if (isNew) _NewTag(),
                    ],
                  ),
                  Text(
                    widget.movie.type,
                    style: TextStyle(color: AppColors.accent, fontSize: 10),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatefulWidget {
  final List<TypesItem> types;
  final List<int> activeFilters;
  final Function(int) toggleFilter;

  const _Filters({
    required this.types,
    required this.activeFilters,
    required this.toggleFilter,
  });

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        alignment: WrapAlignment.start,
        spacing: 8,
        runSpacing: 8,
        children: [
          ...widget.types.map(
            (e) => _FilterElements(
              id: e.id,
              title: e.title,
              active: widget.activeFilters.contains(e.id),
              toggleFilter: widget.toggleFilter,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterElements extends StatefulWidget {
  final int id;
  final String title;
  final bool active;
  final Function(int) toggleFilter;

  const _FilterElements({
    required this.id,
    required this.title,
    required this.active,
    required this.toggleFilter,
  });

  @override
  State<_FilterElements> createState() => _FilterElementsState();
}

class _FilterElementsState extends State<_FilterElements> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.toggleFilter(widget.id),
      child: widget.active == true
          ? Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: AppColors.border),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    child: Text(
                      widget.title,
                      style: TextStyle(color: AppColors.accent, fontSize: 10),
                    ),
                  ),
                ),
                ..._Corners(adder: -3.0),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: AppColors.border),
              ),

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                child: Text(
                  widget.title,
                  style: TextStyle(color: AppColors.accent, fontSize: 10),
                ),
              ),
            ),
    );
  }
}

class _MetaBar extends StatelessWidget {
  final int total;
  final int diff;

  const _MetaBar({required this.total, required this.diff});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              child: Row(
                children: [
                  Text(
                    '$total ',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    "Found",
                    style: TextStyle(
                      color: AppColors.textBright,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            Container(
              child: Row(
                children: [
                  Text(
                    '$diff ',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    "New",
                    style: TextStyle(
                      color: AppColors.textBright,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
