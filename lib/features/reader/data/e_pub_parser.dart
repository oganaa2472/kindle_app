// lib/features/reader/data/epub_parser.dart
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class ParsedBook {
  final String title;
  final String author;
  final String assetPath;
  final List<String> pages; // Бүлэг биш, жинхэнэ дэлгэцийн хуудсууд

  ParsedBook({
    required this.title,
    required this.author,
    required this.assetPath,
    required this.pages,
  });
}

class BookInfo {
  final String title;
  final String author;
  final String assetPath;

  BookInfo({
    required this.title,
    required this.author,
    required this.assetPath,
  });
}

class EpubService {
  // 1. Assets доторх бүх .epub номыг автоматаар илрүүлж тоолох
  static Future<List<BookInfo>> loadAllAssetBooks() async {
    final List<BookInfo> books = [];

    try {
      // Шинэ Flutter-ийн стандарт арга:
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      // Ямар asset-ууд танигдаж байгааг Terminal дээр хэвлэж шалгах
      print('Бүх илэрсэн assets: $allAssets');

      final epubPaths = allAssets.where((String key) {
        return key.toLowerCase().endsWith('.epub');
      }).toList();

      print('Олдсон EPUB файлууд: $epubPaths');

      for (final path in epubPaths) {
        try {
          final byteData = await rootBundle.load(path);
          final bytes = byteData.buffer.asUint8List();
          final epubBook = await EpubReader.readBook(bytes);

          books.add(
            BookInfo(
              title:
                  epubBook.Title ??
                  path.split('/').last.replaceAll('.epub', ''),
              author: epubBook.Author ?? 'Зохиогч тодорхойгүй',
              assetPath: path,
            ),
          );
        } catch (e) {
          // Хэрэв EPUB задлахад алдаа гарвал ядаж файлын нэрээр нь харуулна
          books.add(
            BookInfo(
              title: path.split('/').last.replaceAll('.epub', ''),
              author: 'Зохиогч тодорхойгүй',
              assetPath: path,
            ),
          );
        }
      }
    } catch (e) {
      print('Manifest уншихад алдаа: $e');
    }

    return books;
  }

  // 2. Сонгосон номын бүх бүлгийг бүрэн задалж унших дэлгэцэд бэлдэх
  static Future<ParsedBook> parseAssetEpub(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();

    final EpubBook epubBook = await EpubReader.readBook(bytes);
    final title =
        epubBook.Title ?? assetPath.split('/').last.replaceAll('.epub', '');
    final author = epubBook.Author ?? 'Зохиогч тодорхойгүй';

    final fullText = _collectBookText(epubBook);

    // 2. Бүх текстийг уншихад тохиромжтой хуудсуудад хуваах (ойролцоогоор 1000 тэмдэгтээр)
    final List<String> generatedPages = _splitTextIntoPages(fullText, 900);

    return ParsedBook(
      title: title,
      author: author,
      assetPath: assetPath,
      pages: generatedPages.isEmpty
          ? ['Номын агуулга хоосон байна.']
          : generatedPages,
    );
  }

  static String _collectBookText(EpubBook epubBook) {
    StringBuffer fullTextBuffer = StringBuffer();

    if (epubBook.Chapters != null && epubBook.Chapters!.isNotEmpty) {
      for (var chapter in epubBook.Chapters!) {
        fullTextBuffer.writeln(_extractTextFromChapter(chapter));
      }
    }

    if (epubBook.Content?.Html != null && epubBook.Content!.Html!.isNotEmpty) {
      StringBuffer htmlBuffer = StringBuffer();

      for (var entry in epubBook.Content!.Html!.entries) {
        final fileName = entry.key.toLowerCase();
        final isNavigation =
            fileName.contains('nav') ||
            fileName.contains('toc') ||
            fileName.contains('notice');
        if (isNavigation) continue;

        final htmlText = _extractTextFromHtml(entry.value.Content);
        if (htmlText.isNotEmpty) {
          htmlBuffer.writeln(htmlText);
        }
      }

      final htmlText = htmlBuffer.toString().trim();
      if (htmlText.isNotEmpty && htmlText.length > fullTextBuffer.length) {
        return htmlText;
      }
    }

    return fullTextBuffer.toString().trim();
  }

  static String _extractTextFromHtml(String? htmlContent) {
    if (htmlContent == null || htmlContent.isEmpty) return '';

    final doc = html_parser.parse(htmlContent);
    final text = doc.body == null ? '' : _renderNode(doc.body!);
    return _cleanText(text);
  }

  static String _renderNode(dom.Node node) {
    if (node is dom.Text) return node.text;
    if (node is dom.Element &&
        (node.localName == 'script' || node.localName == 'style')) {
      return '';
    }

    final content = node.nodes.map(_renderNode).join();
    if (node is dom.Element && _blockElements.contains(node.localName)) {
      return '\n$content\n';
    }
    return content;
  }

  static const Set<String> _blockElements = {
    'address',
    'article',
    'blockquote',
    'br',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'header',
    'li',
    'p',
    'section',
    'tr',
  };

  static String _cleanText(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .replaceAll('\r', '')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n')
        .trim();
  }

  // Текстийг үг таслахгүйгээр ухаалгаар хуудас болгох функц
  static List<String> _splitTextIntoPages(String text, int charsPerPage) {
    final List<String> pages = [];
    final normalizedText = _cleanText(text);
    if (normalizedText.isEmpty) return pages;

    int start = 0;
    while (start < normalizedText.length) {
      int end = start + charsPerPage;

      if (end >= normalizedText.length) {
        pages.add(normalizedText.substring(start).trim());
        break;
      }

      final paragraphBreak = normalizedText.lastIndexOf('\n\n', end);
      if (paragraphBreak > start + 120) {
        end = paragraphBreak;
      } else {
        final sentenceBreak = _lastSentenceBreak(normalizedText, start, end);
        if (sentenceBreak > start + 120) {
          end = sentenceBreak;
        } else {
          final lastSpace = normalizedText.lastIndexOf(' ', end);
          if (lastSpace > start) end = lastSpace;
        }
      }

      final pageContent = normalizedText.substring(start, end).trim();
      if (pageContent.isNotEmpty) {
        pages.add(pageContent);
      }
      start = end < normalizedText.length && normalizedText[end] == '\n'
          ? end + 1
          : end;
    }

    return pages;
  }

  static int _lastSentenceBreak(String text, int start, int end) {
    for (var index = end - 1; index > start; index--) {
      final character = text[index];
      if ((character == '.' || character == '?' || character == '!') &&
          index + 1 < text.length &&
          RegExp(r'\s').hasMatch(text[index + 1])) {
        return index + 1;
      }
    }
    return -1;
  }

  static String _extractTextFromChapter(EpubChapter chapter) {
    StringBuffer textBuffer = StringBuffer();

    if (chapter.HtmlContent != null) {
      textBuffer.writeln(_extractTextFromHtml(chapter.HtmlContent));
    }

    if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
      for (var sub in chapter.SubChapters!) {
        textBuffer.writeln(_extractTextFromChapter(sub));
      }
    }

    return textBuffer.toString();
  }
}
