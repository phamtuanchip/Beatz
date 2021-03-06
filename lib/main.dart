import 'package:beatz/blocs/bloc_provider.dart';
import 'package:beatz/blocs/home_page_bloc.dart';
import 'package:beatz/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beatz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.pinkAccent,
        primaryColorDark: Colors.pink,
        primaryColorLight: Colors.deepOrangeAccent,
        accentColor: Colors.purpleAccent,
      ),
      home: BlocProvider<HomePageBloc>(
        bloc: HomePageBloc(),
        child: HomePage(title: 'Beatz'),
      ),
    );
  }
}
