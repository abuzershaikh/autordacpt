import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';
import 'telemetry_service.dart';

class TutorialItem {
  final int id;
  final String title;
  final String description;
  final String category;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String thumbnailUrl;
  final String duration;
  final int sortOrder;

  const TutorialItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.thumbnailUrl,
    required this.duration,
    this.sortOrder = 0,
  });

  factory TutorialItem.fromJson(Map<String, dynamic> json) {
    final videoId = (json['youtube_video_id'] ?? json['youtubeVideoId'] ?? '').toString();
    final thumb = (json['thumbnail_url'] ?? json['thumbnailUrl'] ?? '').toString();

    return TutorialItem(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'AutoRide Tutorial',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      youtubeUrl: json['youtube_url'] ?? json['youtubeUrl'] ?? 'https://www.youtube.com',
      youtubeVideoId: videoId,
      thumbnailUrl: thumb.isNotEmpty 
          ? thumb 
          : (videoId.isNotEmpty ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg' : ''),
      duration: json['duration'] ?? '3:45',
      sortOrder: json['sort_order'] ?? json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'youtube_url': youtubeUrl,
      'youtube_video_id': youtubeVideoId,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'sort_order': sortOrder,
    };
  }
}

/// Service to fetch and cache YouTube video tutorials managed via the VPS Dashboard
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  static const String keyTutorialsCache = 'cached_tutorials_list_json';
  final TelemetryService _telemetryService = TelemetryService();

  /// Curated default tutorials available out of the box even before first sync
  static final List<TutorialItem> fallbackTutorials = [
    const TutorialItem(
      id: 1,
      title: 'AutoRide Complete Setup & Onboarding Guide',
      description: 'Step-by-step complete guide on setting up Accessibility service, battery optimization bypass, and overlay permissions.',
      category: 'general',
      youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      youtubeVideoId: 'dQw4w9WgXcQ',
      thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      duration: '4:20',
      sortOrder: 1,
    ),
    const TutorialItem(
      id: 2,
      title: 'Rapido Captain: Instant Auto-Accept Config',
      description: 'How to accept high-paying Rapido Bike & Auto orders under 50 milliseconds with minimum fare filters.',
      category: 'rapido',
      youtubeUrl: 'https://www.youtube.com/watch?v=kXYiU_JCYtU',
      youtubeVideoId: 'kXYiU_JCYtU',
      thumbnailUrl: 'https://img.youtube.com/vi/kXYiU_JCYtU/hqdefault.jpg',
      duration: '3:15',
      sortOrder: 2,
    ),
    const TutorialItem(
      id: 3,
      title: 'Porter Partner: Truck & 2-Wheeler Auto-Acceptance',
      description: 'Configure maximum pickup distance and trip distance limits so you never get distant unlucrative Porter trips.',
      category: 'porter',
      youtubeUrl: 'https://www.youtube.com/watch?v=fJ9rUzIMcZQ',
      youtubeVideoId: 'fJ9rUzIMcZQ',
      thumbnailUrl: 'https://img.youtube.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
      duration: '5:10',
      sortOrder: 3,
    ),
    const TutorialItem(
      id: 4,
      title: 'Ola Driver: Motivator Card Real-Touch Clicking',
      description: 'Auto-accepting Ola city taxi & bike rides from floating cards and system notification overlays reliably.',
      category: 'ola',
      youtubeUrl: 'https://www.youtube.com/watch?v=9bZkp7q19f0',
      youtubeVideoId: '9bZkp7q19f0',
      thumbnailUrl: 'https://img.youtube.com/vi/9bZkp7q19f0/hqdefault.jpg',
      duration: '3:50',
      sortOrder: 4,
    ),
    const TutorialItem(
      id: 5,
      title: 'Uber Driver: Instant Trip Radar & Request Sniping',
      description: 'Sniping Trip Radar requests and standard dispatched rides at peak surge hours without delay.',
      category: 'uber',
      youtubeUrl: 'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
      youtubeVideoId: 'kJQP7kiw5Fk',
      thumbnailUrl: 'https://img.youtube.com/vi/kJQP7kiw5Fk/hqdefault.jpg',
      duration: '4:45',
      sortOrder: 5,
    ),
    const TutorialItem(
      id: 6,
      title: 'Troubleshooting: Why Accessibility Service Disables',
      description: 'How to lock the app in RAM and disable MIUI / Samsung / Vivo battery killer daemon to keep auto-accept alive 24/7.',
      category: 'troubleshooting',
      youtubeUrl: 'https://www.youtube.com/watch?v=L_LUpnjgPso',
      youtubeVideoId: 'L_LUpnjgPso',
      thumbnailUrl: 'https://img.youtube.com/vi/L_LUpnjgPso/hqdefault.jpg',
      duration: '6:30',
      sortOrder: 6,
    ),
  ];

  /// Fetch tutorials from VPS with local cache fallback
  Future<List<TutorialItem>> getTutorials({String category = 'all'}) async {
    // 1. Try fetching from live VPS Control Engine
    try {
      final baseUrl = await _telemetryService.getBaseUrl();
      final catParam = category == 'all' ? '' : '?category=$category';
      final uri = Uri.parse('$baseUrl/api/tutorials$catParam');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final raw = await response.transform(utf8.decoder).join();
        final json = jsonDecode(raw);

        if (json is Map<String, dynamic> && json['success'] == true) {
          final list = (json['tutorials'] as List? ?? [])
              .map((item) => TutorialItem.fromJson(item as Map<String, dynamic>))
              .toList();

          if (list.isNotEmpty) {
            // Save to local cache
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(keyTutorialsCache, raw);
            Logger.log('🎬 Fetched ${list.length} tutorials live from VPS');
            return list;
          }
        }
      }
    } catch (e) {
      Logger.error('Failed to load tutorials from VPS, checking local cache: $e');
    }

    // 2. Fallback to cached tutorials in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(keyTutorialsCache);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final json = jsonDecode(cachedJson);
        final list = (json['tutorials'] as List? ?? [])
            .map((item) => TutorialItem.fromJson(item as Map<String, dynamic>))
            .where((t) => category == 'all' || t.category.toLowerCase() == category.toLowerCase())
            .toList();

        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {}

    // 3. Built-in defaults
    if (category == 'all') {
      return fallbackTutorials;
    }
    return fallbackTutorials
        .where((t) => t.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}
