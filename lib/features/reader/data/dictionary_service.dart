import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class WordDefinition {
  final String word;
  final String partOfSpeech;
  final String definition;
  final String? example;
  final List<String> synonyms;

  const WordDefinition({
    required this.word,
    required this.partOfSpeech,
    required this.definition,
    this.example,
    this.synonyms = const [],
  });
}

class WordLookup {
  final String word;
  final String? translation;
  final List<WordDefinition> definitions;

  const WordLookup({
    required this.word,
    required this.translation,
    required this.definitions,
  });
}

class DictionaryException implements Exception {
  final String message;

  const DictionaryException(this.message);

  @override
  String toString() => message;
}

class DictionaryService {
  static String normalizeWord(String rawWord) {
    return rawWord.replaceAll(RegExp(r"^[^\w']+|[^\w']+$"), '').toLowerCase();
  }

  static Future<List<WordDefinition>> lookup(String rawWord) async {
    final word = normalizeWord(rawWord);

    if (word.isEmpty || !RegExp(r"^[a-z]+(?:['-][a-z]+)*$").hasMatch(word)) {
      throw const DictionaryException(
        'Энэ үгийг тайлбарлах боломжгүй байна. Англи үг дээр дахин оролдоно уу.',
      );
    }

    late final http.Response response;
    try {
      response = await http
          .get(Uri.https('api.dictionaryapi.dev', '/api/v2/entries/en/$word'))
          .timeout(const Duration(seconds: 10));
    } on http.ClientException {
      throw const DictionaryException(
        'Интернэт холболтоо шалгаад дахин оролдоно уу.',
      );
    } on TimeoutException {
      throw const DictionaryException(
        'Тайлбарын сервер хариу өгөхгүй байна. Хэсэг хүлээгээд дахин оролдоно уу.',
      );
    } on SocketException {
      throw const DictionaryException(
        'Интернэт холболтоо шалгаад дахин оролдоно уу.',
      );
    }

    if (response.statusCode == 404) {
      throw const DictionaryException('Энэ үг dictionary-д олдсонгүй.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const DictionaryException(
        'Тайлбарын серверт холбогдож чадсангүй. Дахин оролдоно уу.',
      );
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const DictionaryException('Үгийн тайлбарын хариу буруу байна.');
    }
    if (decoded is! List) {
      throw const DictionaryException('Үгийн тайлбарын формат буруу байна.');
    }

    final definitions = <WordDefinition>[];
    for (final entry in decoded) {
      if (entry is! Map || entry['meanings'] is! List) continue;
      for (final meaning in entry['meanings']) {
        if (meaning is! Map || meaning['definitions'] is! List) continue;
        for (final item in meaning['definitions']) {
          if (item is! Map || item['definition'] is! String) continue;
          definitions.add(
            WordDefinition(
              word: entry['word'] as String? ?? word,
              partOfSpeech: meaning['partOfSpeech'] as String? ?? '',
              definition: item['definition'] as String,
              example: item['example'] as String?,
              synonyms: [
                ...((item['synonyms'] as List?) ?? const []),
                ...((meaning['synonyms'] as List?) ?? const []),
              ].whereType<String>().take(5).toList(),
            ),
          );
          if (definitions.length == 5) return definitions;
        }
      }
    }

    if (definitions.isEmpty) {
      throw const DictionaryException('Энэ үгийн тайлбар олдсонгүй.');
    }
    return definitions;
  }

  static Future<WordLookup> lookupWord(String rawWord) async {
    final word = normalizeWord(rawWord);
    final results = await Future.wait<Object?>([
      _lookupDefinitionsSafely(word),
      _translate(word),
    ], eagerError: false);

    return WordLookup(
      word: word,
      translation: results[1] as String?,
      definitions: results[0] as List<WordDefinition>,
    );
  }

  static Future<List<WordDefinition>> _lookupDefinitionsSafely(
    String word,
  ) async {
    try {
      return await lookup(word);
    } on DictionaryException {
      return const <WordDefinition>[];
    } on TimeoutException {
      return const <WordDefinition>[];
    } on SocketException {
      return const <WordDefinition>[];
    } on http.ClientException {
      return const <WordDefinition>[];
    }
  }

  static Future<String?> _translate(String word) async {
    try {
      final response = await http
          .get(
            Uri.https('api.mymemory.translated.net', '/get', {
              'q': word,
              'langpair': 'en|mn',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      final translated = decoded is Map ? decoded['responseData'] : null;
      final value = translated is Map ? translated['translatedText'] : null;
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
