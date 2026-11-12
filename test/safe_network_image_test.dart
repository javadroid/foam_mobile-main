import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/safe_network_image.dart';

void main() {
  group('resolveImageUrl Tests', () {
    test('handles null and empty string', () {
      expect(resolveImageUrl(null), '');
      expect(resolveImageUrl(''), '');
      expect(resolveImageUrl('   '), '');
    });

    test('prepends Constants.url for relative paths', () {
      final expectedBase = Constants.url.replaceAll(RegExp(r'/+$'), '');
      expect(
        resolveImageUrl('/uploads/test.jpg'),
        '$expectedBase/uploads/test.jpg',
      );
      expect(
        resolveImageUrl('uploads/test.jpg'),
        '$expectedBase/uploads/test.jpg',
      );
    });

    test('rewrites localhost:55618 and localhost:8545 to Constants.url host and port', () {
      final expectedBase = Constants.url.replaceAll(RegExp(r'/+$'), '');

      // From user reported crash: address = localhost, port = 55618
      final resolvedEphemeral = resolveImageUrl('http://localhost:55618/uploads/file-123.jpg');
      expect(resolvedEphemeral, '$expectedBase/uploads/file-123.jpg');

      // Standard localhost:8545
      final resolvedLocalhost = resolveImageUrl('http://localhost:8545/uploads/file-123.jpg');
      expect(resolvedLocalhost, '$expectedBase/uploads/file-123.jpg');

      // 127.0.0.1
      final resolvedLoopback = resolveImageUrl('http://127.0.0.1:8545/uploads/file-123.jpg');
      expect(resolvedLoopback, '$expectedBase/uploads/file-123.jpg');
    });

    test('leaves external URLs untouched', () {
      const cloudinaryUrl =
          'https://res.cloudinary.com/dtyfzid4c/image/upload/v1/foam_uploads/avatar.jpg';
      expect(resolveImageUrl(cloudinaryUrl), cloudinaryUrl);
    });
  });

  group('SafeNetworkImage Widget Tests', () {
    testWidgets('renders fallbackBuilder immediately on empty URL without network calls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: '',
              fallbackBuilder: (context) => const Text('Fallback Initial B'),
            ),
          ),
        ),
      );

      expect(find.text('Fallback Initial B'), findsOneWidget);
    });

    testWidgets('renders fallbackBuilder cleanly when URL is unreachable or connection refused',
        (WidgetTester tester) async {
      // Points to a dead port that will refuse connection immediately
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: 'http://127.0.0.1:59999/uploads/nonexistent.jpg',
              timeout: const Duration(milliseconds: 300),
              fallbackBuilder: (context) => const Text('Safe Offline Fallback'),
            ),
          ),
        ),
      );

      // Advance clock past timeout/failure
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Safe Offline Fallback'), findsOneWidget);
      // No unhandled exception should be caught by FlutterError
      expect(tester.takeException(), isNull);
    });
  });
}

