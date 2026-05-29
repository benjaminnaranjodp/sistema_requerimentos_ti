import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/section.dart';
import '../models/module.dart';

class DataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Section> _sections = [];
  StreamSubscription? _subscription;

  List<Section> get sections => _sections;

  DataProvider() {
    _listenToModules();
  }

  void _listenToModules() {
    _subscription = _firestore.collection('modules').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        seedDefaultData();
        return;
      }

      
      final Map<String, List<Module>> grouped = {};
      
      for (var doc in snapshot.docs) {
        final module = Module.fromMap(doc.id, doc.data());
        if (!grouped.containsKey(module.sectionName)) {
          grouped[module.sectionName] = [];
        }
        grouped[module.sectionName]!.add(module);
      }

      _sections = grouped.entries.map((entry) {
        return Section(
          id: entry.key.toLowerCase().replaceAll(' ', '_'),
          name: entry.key,
          modules: entry.value,
        );
      }).toList();
      
      
      _sections.sort((a, b) => a.name.compareTo(b.name));
      for (var section in _sections) {
        section.modules.sort((a, b) => a.name.compareTo(b.name));
      }

      notifyListeners();
    });
  }

  Future<void> seedDefaultData() async {
    final batch = _firestore.batch();
    final defaults = [
      Module(id: '', name: 'Sala 101', sectionName: 'Piso 1', programs: ['VS Code', 'Git', 'Node.js', 'Postman']),
      Module(id: '', name: 'Sala 102', sectionName: 'Piso 1', programs: ['IntelliJ', 'Docker', 'Python', 'Jupyter']),
      Module(id: '', name: 'Sala 201', sectionName: 'Piso 2', programs: ['Eclipse', 'Maven', 'Java', 'Android Studio']),
      Module(id: '', name: 'Sala 202', sectionName: 'Piso 2', programs: ['Sublime Text', 'Chrome DevTools', 'SQL Server']),
    ];

    for (var mod in defaults) {
      final docRef = _firestore.collection('modules').doc();
      batch.set(docRef, mod.toMap());
    }
    
    await batch.commit();
  }

  Future<void> addModule(String name, String sectionName) async {
    final module = Module(id: '', name: name, sectionName: sectionName, programs: []);
    await _firestore.collection('modules').add(module.toMap());
  }

  Future<void> addProgramToModule(String moduleId, String programName) async {
    await _firestore.collection('modules').doc(moduleId).update({
      'programs': FieldValue.arrayUnion([programName])
    });
  }

  Future<void> removeProgramFromModule(String moduleId, String programName) async {
    await _firestore.collection('modules').doc(moduleId).update({
      'programs': FieldValue.arrayRemove([programName])
    });
  }

  Future<void> updateProgramInModule(String moduleId, String oldProgramName, String newProgramName) async {
    final docRef = _firestore.collection('modules').doc(moduleId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      List<dynamic> programs = snapshot.data()?['programs'] ?? [];
      final index = programs.indexOf(oldProgramName);
      if (index != -1) {
        programs[index] = newProgramName;
        transaction.update(docRef, {'programs': programs});
      }
    });
  }

  Future<void> updateModule(String id, String name, String sectionName) async {
    await _firestore.collection('modules').doc(id).update({
      'name': name,
      'sectionName': sectionName,
    });
  }

  Future<void> toggleModuleStatus(String id, bool currentStatus) async {
    await _firestore.collection('modules').doc(id).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> deleteModule(String id) async {
    await _firestore.collection('modules').doc(id).delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
