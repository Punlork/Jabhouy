extension StateExtension<T> on T {
  S? asType<S>() => this is S ? this as S : null;
}
