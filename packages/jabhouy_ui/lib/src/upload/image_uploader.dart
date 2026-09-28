import 'dart:io';

/// Sends one image somewhere and answers with its URL.
///
/// `UploadBloc` is shared presentation — shop and profile both drive it —
/// so it lives here, and here cannot reach `jabhouy_net`: that package
/// already imports this one for its snack bars, and Dart forbids the
/// cycle. So the transport is a port, and `UploadService` satisfies it.
// A named port, not a callback: the app satisfies it with UploadService,
// and a typedef would not say so.
// ignore: one_member_abstracts
abstract interface class ImageUploader {
  /// The uploaded image's URL, or null if the server did not return one.
  ///
  /// Throws on failure; the bloc turns that into `UploadFailure`.
  Future<String?> upload({required File file, required String fileName});
}
