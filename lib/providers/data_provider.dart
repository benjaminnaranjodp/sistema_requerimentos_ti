import 'package:flutter/material.dart';
import '../models/section.dart';
import '../models/module.dart';

class DataProvider with ChangeNotifier {
  final List<Section> _sections = [
    Section(
      id: 'p1',
      name: 'Piso 1',
      modules: [
        Module(id: 'm101', name: 'Sala 101', programs: ['VS Code', 'Git', 'Node.js', 'Postman']),
        Module(id: 'm102', name: 'Sala 102', programs: ['IntelliJ', 'Docker', 'Python', 'Jupyter']),
      ],
    ),
    Section(
      id: 'p2',
      name: 'Piso 2',
      modules: [
        Module(id: 'm201', name: 'Sala 201', programs: ['Eclipse', 'Maven', 'Java', 'Android Studio']),
        Module(id: 'm202', name: 'Sala 202', programs: ['Sublime Text', 'Chrome DevTools', 'SQL Server']),
      ],
    ),
  ];

  List<Section> get sections => _sections;
}
