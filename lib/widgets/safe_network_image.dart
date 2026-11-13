import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:http/http.dart' as http;

/// In-memory cache for loaded image bytes to prevent repeated network calls
final Map<String, Uint8List> _safeImageCache = {};

/// Normalizes and resolves image URLs safely.
/// Handles:
/// - null or empty string -> returns ''
/// - relative paths (e.g. '/uploads/xyz.jpg' or 'uploads/xyz.jpg') -> prepends [Constants.url]
/// - localhost or 127.0.0.1 with any port (e.g. 55618, 8545, 3000):
///   rewrites host and port to match [Constants.url]'s scheme, host, and port.
/// - Android emulator loopback (10.0.2.2) if running on Android and Constants.url targets localhost.
String resolveImageUrl(String? rawUrl) {
  if (rawUrl == null) return '';
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return '';

  // Clean surrounding quotes if any
  var url = trimmed;
  if ((url.startsWith('"') && url.endsWith('"')) ||
      (url.startsWith("'") && url.endsWith("'"))) {
    url = url.substring(1, url.length - 1).trim();
  }

  // If path is relative like "/uploads/..." or "uploads/..."
  if (url.startsWith('/uploads/') || url.startsWith('uploads/')) {
    final base = Constants.url.replaceAll(RegExp(r'/+$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  // Parse as URI
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    if (url.contains('/uploads/')) {
      final base = Constants.url.replaceAll(RegExp(r'/+$'), '');
      final uploadIndex = url.indexOf('/uploads/');
      return '$base${url.substring(uploadIndex)}';
    }
    return '';
  }

  final host = uri.host.toLowerCase();
  // Check if host is a local loopback address
  if (host == 'localhost' || host == '127.0.0.1') {
    final baseUri = Uri.tryParse(Constants.url);
    if (baseUri != null &&
        baseUri.host.isNotEmpty &&
        baseUri.host.toLowerCase() != 'localhost' &&
        baseUri.host != '127.0.0.1') {
      // Rewrite scheme, host, and port to match active Constants.url
      final newUri = Uri(
        scheme: baseUri.scheme,
        userInfo: uri.userInfo.isNotEmpty ? uri.userInfo : null,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: uri.path,
        query: uri.hasQuery ? uri.query : null,
        fragment: uri.hasFragment ? uri.fragment : null,
      );
      return newUri.toString();
    } else {
      // If Constants.url is also localhost: on Android device/emulator map to 10.0.2.2
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final port = uri.hasPort ? uri.port : 8545;
        return uri.replace(host: '10.0.2.2', port: port).toString();
      }
    }
  }

  return url;
}

/// A resilient network image widget that:
/// 1. Automatically resolves localhost / relative paths to [Constants.url].
/// 2. Fetches image bytes with try/catch to completely prevent unhandled
///    [SocketException] / Connection Refused errors in Flutter's ImageResourceService.
/// 3. Falls back smoothly to [fallbackBuilder] on failure or offline without console crash dumps.
/// 4. Provides in-memory caching for zero-flicker re-rendering.
class SafeNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context)? fallbackBuilder;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Duration timeout;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackBuilder,
    this.placeholder,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.timeout = const Duration(seconds: 8),
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  Uint8List? _bytes;
  bool _isLoading = false;
  bool _hasError = false;
  String _resolvedUrl = '';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final resolved = resolveImageUrl(widget.imageUrl);
    _resolvedUrl = resolved;

    if (resolved.isEmpty) {
      if (mounted) {
        setState(() {
          _bytes = null;
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    // Check memory cache
    if (_safeImageCache.containsKey(resolved)) {
      if (mounted) {
        setState(() {
          _bytes = _safeImageCache[resolved];
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final response = await http
          .get(Uri.parse(resolved))
          .timeout(widget.timeout);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _safeImageCache[resolved] = response.bodyBytes;
        if (mounted) {
          setState(() {
            _bytes = response.bodyBytes;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (_) {
      // Gracefully catch SocketException, TimeoutException, etc.
      // Prevent exception propagation to ImageResourceService.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_hasError || _resolvedUrl.isEmpty) {
      content = widget.fallbackBuilder?.call(context) ??
          Container(
            width: widget.width,
            height: widget.height,
            color: const Color(0xFFF1F5F9),
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey,
            ),
          );
    } else if (_isLoading && _bytes == null) {
      content = widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
    } else if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) =>
            widget.fallbackBuilder?.call(context) ??
            const SizedBox.shrink(),
      );
    } else {
      content = widget.fallbackBuilder?.call(context) ?? const SizedBox.shrink();
    }

    if (widget.shape == BoxShape.circle) {
      return ClipOval(child: content);
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
