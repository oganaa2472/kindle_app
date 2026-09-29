// lib/features/reader/view/reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kindle_app/features/reader/data/e_pub_parser.dart';
import 'package:kindle_app/features/reader/data/dictionary_service.dart';

import '../cubit/reader_cubit.dart';
import '../cubit/reader_state.dart';

class ReaderScreen extends StatefulWidget {
  final ParsedBook book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getCurrentTimeString() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        final isDark = state.themeMode == ReaderThemeMode.dark;
        final isSepia = state.themeMode == ReaderThemeMode.sepia;

        final Color bgColor = isDark
            ? const Color(0xFF151515)
            : (isSepia ? const Color(0xFFF7F0E3) : const Color(0xFFFCFCFB));

        final Color textColor = isDark
            ? const Color(0xFFD6D6D6)
            : (isSepia ? const Color(0xFF332B23) : const Color(0xFF1A1A1A));

        final Color subtextColor = isDark
            ? Colors.grey.shade600
            : (isSepia ? const Color(0xFF8F8070) : Colors.grey.shade500);

        final totalPages = widget.book.pages.length;
        final progressPercent = totalPages > 0
            ? (((_currentPage + 1) / totalPages) * 100).toInt()
            : 0;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Stack(
              children: [
                // Үндсэн ном унших талбар
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  child: Column(
                    children: [
                      // Kindle Micro Status-Bar (Дээд хэсэг)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: subtextColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                Text(
                                  _getCurrentTimeString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subtextColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.battery_std_rounded,
                                  size: 14,
                                  color: subtextColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Бүлэг эргүүлэх PageView хэсэг
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: widget.book.pages.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26.0,
                                vertical: 12.0,
                              ),
                              child: _DictionaryText(
                                text: widget.book.pages[index],
                                style: TextStyle(
                                  fontSize: state.fontSize,
                                  height: 1.85,
                                  color: textColor,
                                  letterSpacing: 0.15,
                                  fontFamily: 'serif',
                                ),
                                onWordTap: (word) => _showDefinition(
                                  context,
                                  word,
                                  bgColor,
                                  textColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Kindle Micro Status-Bar (Доод хэсэг)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Хуудас ${_currentPage + 1} / $totalPages',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtextColor,
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Дэлгэц дээр 1 товшиход гарч ирэх дээд цэс
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: _showControls ? 0 : -80,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: bgColor.withOpacity(0.97),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: textColor,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.format_size_rounded,
                            color: textColor,
                          ),
                          onPressed: () =>
                              _showSettingsModal(context, bgColor, textColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDefinition(
    BuildContext context,
    String word,
    Color backgroundColor,
    Color textColor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final requestedWord = DictionaryService.normalizeWord(word);
        return FutureBuilder<WordLookup>(
          future: DictionaryService.lookupWord(word),
          builder: (context, snapshot) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? _DefinitionLoading(word: requestedWord)
                    : snapshot.hasError
                    ? _DefinitionError(
                        word: requestedWord,
                        message: snapshot.error.toString(),
                      )
                    : _DefinitionContent(
                        title: requestedWord,
                        translation: snapshot.data!.translation,
                        definitions: snapshot.data!.definitions,
                        textColor: textColor,
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // Фонтын хэмжээ болон Theme солих цонх
  void _showSettingsModal(
    BuildContext context,
    Color bgColor,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return BlocBuilder<ReaderCubit, ReaderState>(
          bloc: context.read<ReaderCubit>(),
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: state.fontSize,
                          min: 14.0,
                          max: 30.0,
                          divisions: 8,
                          activeColor: textColor,
                          inactiveColor: Colors.grey.shade400,
                          onChanged: (val) =>
                              context.read<ReaderCubit>().updateFontSize(val),
                        ),
                      ),
                      const Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildThemeCircle(
                        context,
                        mode: ReaderThemeMode.sepia,
                        color: const Color(0xFFF9F1E1),
                        isSelected: state.themeMode == ReaderThemeMode.sepia,
                        label: 'Sepia',
                      ),
                      const SizedBox(width: 12),
                      _buildThemeCircle(
                        context,
                        mode: ReaderThemeMode.light,
                        color: Colors.white,
                        isSelected: state.themeMode == ReaderThemeMode.light,
                        label: 'Light',
                      ),
                      const SizedBox(width: 12),
                      _buildThemeCircle(
                        context,
                        mode: ReaderThemeMode.dark,
                        color: const Color(0xFF141414),
                        isSelected: state.themeMode == ReaderThemeMode.dark,
                        label: 'Dark',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeCircle(
    BuildContext context, {
    required ReaderThemeMode mode,
    required Color color,
    required bool isSelected,
    required String label,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<ReaderCubit>().updateThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orange.shade800 : Colors.grey.shade400,
              width: isSelected ? 2.2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: mode == ReaderThemeMode.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _DictionaryText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final ValueChanged<String> onWordTap;

  const _DictionaryText({
    required this.text,
    required this.style,
    required this.onWordTap,
  });

  @override
  State<_DictionaryText> createState() => _DictionaryTextState();
}

class _DictionaryTextState extends State<_DictionaryText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final spans = <TextSpan>[];
    for (final match in RegExp(r'\S+|\s+').allMatches(widget.text)) {
      final token = match.group(0)!;
      if (token.trim().isEmpty) {
        spans.add(TextSpan(text: token, style: widget.style));
        continue;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onWordTap(token);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(text: token, style: widget.style, recognizer: recognizer),
      );
    }

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(children: spans),
    );
  }
}

class _DefinitionContent extends StatelessWidget {
  final String title;
  final String? translation;
  final List<WordDefinition> definitions;
  final Color textColor;

  const _DefinitionContent({
    required this.title,
    required this.translation,
    required this.definitions,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withOpacity(.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Хайсан үг',
          style: TextStyle(
            color: textColor.withOpacity(.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (translation != null) ...[
          const SizedBox(height: 8),
          Text(
            'Монгол утга: $translation',
            style: TextStyle(
              color: textColor.withOpacity(.8),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (translation == null && definitions.isEmpty)
          const Text(
            'Орчуулга болон тайлбар олдсонгүй.',
            style: TextStyle(color: Colors.grey),
          ),
        if (definitions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'English explanation',
            style: TextStyle(
              color: textColor.withOpacity(.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...definitions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.partOfSpeech.isNotEmpty)
                  Text(
                    item.partOfSpeech,
                    style: TextStyle(
                      color: textColor.withOpacity(.55),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  item.definition,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                if (item.example != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '“${item.example}”',
                    style: TextStyle(
                      color: textColor.withOpacity(.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (item.synonyms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Similar words: ${item.synonyms.join(', ')}',
                    style: TextStyle(
                      color: textColor.withOpacity(.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DefinitionError extends StatelessWidget {
  final String word;
  final String message;

  const _DefinitionError({required this.word, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Хайсан үг: $word',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Icon(Icons.cloud_off_rounded, size: 36, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wi-Fi эсвэл mobile data асаалттай эсэхийг шалгана уу.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _DefinitionLoading extends StatelessWidget {
  final String word;

  const _DefinitionLoading({required this.word});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Хайсан үг: $word',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
