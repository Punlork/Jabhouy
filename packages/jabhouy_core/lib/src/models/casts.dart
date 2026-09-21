/// Two helpers every `fromJson` in the app leans on.
///
/// They were in `lib/app/models/pagination_model.dart`, which meant a
/// model could not be read without importing the app package, which
/// carries Flutter. Moving them here is what lets `logic/` and the
/// repository interfaces stay Flutter-free.
library;

T? tryCast<T>(dynamic x, {T? fallback}) {
  if (x is T) return x;

  return fallback;
}

extension ObjectExtension<T> on T {
  R? let<R>(R Function(T) transform) => this != null ? transform(this!) : null;
}
