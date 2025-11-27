/// Utility class for handling image URLs
class ImageUrlHelper {
  /// Base URL for the backend server (without /api)
  static const String baseUrl = 'http://localhost:3000';

  /// Converts a relative image URL to an absolute URL
  /// 
  /// If the URL is already absolute (starts with http:// or https://), returns it as is.
  /// If the URL is relative (starts with /), prepends the base URL.
  /// If the URL is null, returns null.
  static String? toAbsoluteUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return null;
    }

    // If already absolute, return as is
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }

    // If relative, prepend base URL
    if (relativeUrl.startsWith('/')) {
      return '$baseUrl$relativeUrl';
    }

    // If no leading slash, add it
    return '$baseUrl/$relativeUrl';
  }
}

