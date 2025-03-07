import 'package:logger/logger.dart';

// Factory class to create reusable Logger instances with configurable settings
class LoggerFactory {
  // Default configuration values
  static const bool _defaultPrintTime = true;
  static const bool _defaultPrintEmojis = true;
  static const int _defaultMethodCount = 2;
  static const int _defaultLineLength = 120;
  static const int _defaultErrorMethodCount = 8;

  // Create a Logger instance with the specified configurations
  static Logger createLogger({
    bool printTime = _defaultPrintTime,
    bool printEmojis = _defaultPrintEmojis,
    int methodCount = _defaultMethodCount,
    int lineLength = _defaultLineLength,
    int errorMethodCount = _defaultErrorMethodCount,
  }) {
    return Logger(
      printer: PrettyPrinter(
        printTime: printTime,
        printEmojis: printEmojis,
        methodCount: methodCount,
        lineLength: lineLength,
        errorMethodCount: errorMethodCount,
      ),
    );
  }
}

// Default Logger instance with the default configuration
final logger = LoggerFactory.createLogger();
