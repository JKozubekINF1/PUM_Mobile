import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'api_connection.dart';
import 'local_storage.dart';

class UploadQueue {
  static final UploadQueue instance = UploadQueue._();

  UploadQueue._();

  Database? _db;
  bool _isProcessing = false;
  StreamSubscription? _connectivitySub;
  final ApiService _api = ApiService();
  final LocalStorage _storage = LocalStorage();

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'upload_queue.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE upload_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
    processQueue();
  }

  Future<bool> addActivity(Activity activity) async {
    await _db!.insert(
      "upload_queue",
      {
        "data": jsonEncode(activity.toJson()),
        "createdAt": DateTime.now().millisecondsSinceEpoch,
      },
    );
    return processQueue();
  }

  Future<int?> getQueueSize() async {
    try {
      final rows = await _db!.query(
        "upload_queue",
        orderBy: "createdAt ASC",
      );
      return rows.length;
    } catch (e) {
      debugPrint("$e");
      return null;
    }
  }

  Future<bool> processQueue() async {
    if (_isProcessing) return false;
    _isProcessing = true;
    try {
      while (true) {
        final rows = await _db!.query(
          "upload_queue",
          orderBy: "createdAt ASC",
        );
        if (rows.isEmpty) return true;

        debugPrint("[QUEUE] REQUESTS PENDING: ${rows.length}, TRYING TO UPLOAD");

        final id = rows.first["id"] as int;
        final data = rows.first["data"] as String;

        final activity = Activity.fromJson(jsonDecode(data));

        final success = await _upload(activity);

        if (success) {
          await _db!.delete(
            "upload_queue",
            where: "id = ?",
            whereArgs: [id],
          );
        } else {
          break;
        }
      }
      return false;
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _upload(Activity activity) async {
    try {
      await _api.saveActivity(
        durationSeconds: activity.duration,
        distanceMeters: activity.distance,
        averageSpeedMs: activity.avgSpeed,
        routeCoordinates: activity.routelist.map((p) => [p.latitude, p.longitude]).toList(),
        title: activity.title,
        description: activity.description,
        activityType: activity.activityType,
      );

      debugPrint("[QUEUE] UPLOAD SUCCESSFUL");
      return true;

    } catch (e) {
      debugPrint("[QUEUE] UPLOAD FAILED: $e");
      return false;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _db?.close();
  }

  Future<void> cancelQueue() async {
    try {
      while (true) {
        final rows = await _db!.query(
          "upload_queue",
          orderBy: "createdAt ASC",
          limit: 1,
        );
        if (rows.isEmpty) break;
        final id = rows.first["id"] as int;
        final data = rows.first["data"] as String;
        await _storage.saveToStorage(jsonDecode(data));
        await _db!.delete(
          "upload_queue",
          where: "id = ?",
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint("$e");
    }
  }
}