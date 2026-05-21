import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  group('RankItem.fromJson', () {
    test('parses a place item', () {
      final item = RankItem.fromJson({
        'kind': 'place',
        'rank': 1,
        'title': 'Ichiran Shibuya',
        'whyItRanks': 'Iconic tonkotsu, late-night vibe',
        'details': 'Solo-booth ramen experience with customizable broth.',
        'score': 9.4,
        'imageUrl': null,
        'address': 'Shibuya, Tokyo',
        'lat': 35.6595,
        'lng': 139.7005,
        'author': null,
        'year': null,
        'tagline': null,
      });

      expect(item, isA<PlaceItem>());
      final place = item as PlaceItem;
      expect(place.rank, 1);
      expect(place.lat, closeTo(35.6595, 0.0001));
      expect(place.address, 'Shibuya, Tokyo');
    });

    test('parses a book item', () {
      final item = RankItem.fromJson({
        'kind': 'book',
        'rank': 3,
        'title': 'The Lean Startup',
        'whyItRanks': 'Defined a generation of product thinking',
        'details': 'Eric Ries codified iterative experimentation as a discipline.',
        'score': 8.6,
        'imageUrl': null,
        'address': null,
        'lat': null,
        'lng': null,
        'author': 'Eric Ries',
        'year': 2011,
        'tagline': null,
      });

      expect(item, isA<BookItem>());
      expect((item as BookItem).author, 'Eric Ries');
      expect(item.year, 2011);
    });

    test('throws on missing discriminator', () {
      expect(
        () => RankItem.fromJson(<String, dynamic>{
          'rank': 1,
          'title': 'x',
          'whyItRanks': 'y',
          'score': 1.0,
        }),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('throws on unknown kind', () {
      expect(
        () => RankItem.fromJson({
          'kind': 'movie',
          'rank': 1,
          'title': 'x',
          'whyItRanks': 'y',
          'score': 1.0,
        }),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
