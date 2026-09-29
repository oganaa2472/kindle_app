import 'package:flutter/material.dart';
import 'package:kindle_app/features/reader/data/e_pub_parser.dart';
import 'package:kindle_app/features/reader/view/reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<BookInfo>> _booksFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadBooks() {
    _booksFuture = EpubService.loadAllAssetBooks();
  }

  Future<void> _openBook(BuildContext context, String assetPath) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Номыг ачаалж байна...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final parsedBook = await EpubService.parseAssetEpub(assetPath);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ReaderScreen(key: const ValueKey('Ном уншигч'), book: parsedBook),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ном нээхэд алдаа гарлаа: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8F5EF);
    const ink = Color(0xFF27231F);
    const accent = Color(0xFFC8783D);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: FutureBuilder<List<BookInfo>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: accent),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Алдаа гарлаа: ${snapshot.error}'));
            }

            final books = (snapshot.data ?? [])
                .where(
                  (book) =>
                      _query.isEmpty ||
                      book.title.toLowerCase().contains(_query) ||
                      book.author.toLowerCase().contains(_query),
                )
                .toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Тавтай морил',
                                style: TextStyle(
                                  color: ink.withOpacity(.55),
                                  fontSize: 13,
                                  letterSpacing: .4,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Таны номын сан',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(_loadBooks),
                          icon: const Icon(Icons.refresh_rounded, color: ink),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Ном эсвэл зохиогч хайх',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${books.length} ном',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: accent, size: 16),
                            SizedBox(width: 5),
                            Text('Бүгд бэлэн', style: TextStyle(color: accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (books.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyLibrary(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _BookCard(
                          book: books[index],
                          index: index,
                          onTap: () =>
                              _openBook(context, books[index].assetPath),
                        ),
                        childCount: books.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            childAspectRatio: .67,
                          ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookInfo book;
  final int index;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF4C5A50),
      const Color(0xFFB56D48),
      const Color(0xFF756A83),
      const Color(0xFF52758A),
    ];
    final coverColor = colors[index % colors.length];

    return Semantics(
      button: true,
      label: 'Нээх: ${book.title}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.055),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: coverColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -18,
                        bottom: -18,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 105,
                          color: Colors.white.withOpacity(.09),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const Spacer(),
                            Text(
                              book.title,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF27231F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black.withOpacity(.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.black.withOpacity(.25),
            ),
            const SizedBox(height: 16),
            const Text(
              'Одоогоор ном алга',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'assets/books/ хавтсанд .epub файл нэмээд refresh хийнэ үү.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(.5)),
            ),
          ],
        ),
      ),
    );
  }
}
