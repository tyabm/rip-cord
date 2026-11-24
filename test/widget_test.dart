import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/router.dart';

void main() {
  test('locationFromUri parses ripcord deep links', () {
    expect(
      locationFromUri(Uri.parse('ripcord://activate?source=tile')),
      '/activate?source=tile',
    );
    expect(
      locationFromUri(Uri.parse('ripcord://activate?source=widget')),
      '/activate?source=widget',
    );
    expect(locationFromUri(null), isNull);
    expect(locationFromUri(Uri.parse('ripcord://rate')), '/');
  });
}
