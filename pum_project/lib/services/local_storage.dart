import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:intl/intl.dart';

class LocalStorage {
  static Directory? localStorage;

  static Future<void> init() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(baseDir.path,'pum_project'));
    if (!await dir.exists()) {
      await dir.create();
    }
    localStorage = dir;
  }

  Future<String> saveToStorage(Map values) async {
    try {
      final String filename = generateFileName();
      final File newFile = File(p.join(localStorage!.path,filename));
      values.putIfAbsent("filename", () => filename);
      await newFile.writeAsString(jsonEncode(values));
      return filename;
    } catch (e) {
      debugPrint('$e');
    }
    throw Exception('Something went wrong while saving file');
  }

  Future<List<String>?> getStorageList() async {
    try {
      final List<String> files = localStorage!
          .listSync()
          .where((e) => e is File && e.path.endsWith('.json'))
          .map((e) => p.basename(e.path))
          .toList();
      return files;
    } catch (e) {
      debugPrint('$e');
    }
    throw Exception('Unable to get storage');
  }

  Future<Map?> readFromStorage(String filename) async {
    try {
      final File file = File(p.join(localStorage!.path, filename));
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('$e');
    }
    throw Exception('File not found');
  }

  Future<void> overwriteFile(String filename, Map<String,dynamic> data) async {
    try {
      final File file = File(p.join(localStorage!.path, filename));
      final fileContent = await file.readAsString();
      final mappedContent = jsonDecode(fileContent);
      if (data.containsKey("title")) {
        mappedContent["title"] = data["title"].toString();
      }
      if (data.containsKey("description")) {
        mappedContent["description"] = data["description"].toString();
      }
      if (data.containsKey("type")) {
        mappedContent["type"] = data["type"].toString();
      }
      await file.writeAsString(jsonEncode(mappedContent));
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> deleteFile(String filename) async {
    try {
      final File file = File(p.join(localStorage!.path, filename));
      file.deleteSync();
    } catch (e) {
      debugPrint('$e');
    }
  }

  String generateFileName() {
    return "activity_${DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now())}.json";
  }
}