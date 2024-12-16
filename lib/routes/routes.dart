import 'package:flutter/material.dart';
import 'package:project/pages/home_page.dart';
import 'package:project/main.dart';


class AppRoutes {
  static const String paginaInicial = '/homeScreen';

  static Map<String, WidgetBuilder> routes = {
    paginaInicial: (context) => TaskApp(),
  };
}
