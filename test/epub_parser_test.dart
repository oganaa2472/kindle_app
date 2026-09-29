import 'package:flutter_test/flutter_test.dart';
import 'package:kindle_app/features/reader/data/e_pub_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('epub parser reads more than a two-page placeholder from the imported book', () async {
    final parsedBook = await EpubService.parseAssetEpub('assets/books/Atomic_Habits.epub');

    expect(parsedBook.title, startsWith('Atomic Habits'));
    expect(parsedBook.pages.length, greaterThan(2));
    expect(parsedBook.pages.first, isNotEmpty);
  });
}
