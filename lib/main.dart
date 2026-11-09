import 'package:beatz/blocs/bloc_provider.dart';
import 'package:beatz/blocs/home_page_bloc.dart';
import 'package:beatz/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  /// Overrides the home screen (used by tests).
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beatz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          primary: Colors.pinkAccent,
          secondary: Colors.purpleAccent,
        ),
      ),
      home: home ??
          BlocProvider<HomePageBloc>(
            bloc: HomePageBloc(),
            child: const HomePage(title: 'Beatz'),
          ),
    );
  }
}
