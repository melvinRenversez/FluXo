import 'package:flutter/material.dart';
import 'package:FluXo/screens/movie.dart';
import 'screens/search.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SearchScreen(),
      // home: const MovieScreen(
      //   movieId: 4242,
      //   movieUrl: "https://sharecloudy.com/iframe/2jPOr5kfXm",
      // ),
    );
  }
}
