abstract class BaseObjectStorage<T> {
  Future<void> init();
  Future<void> clear();
  Future<void> write(String key, T value);
  Future<T?> read(String key);

  void listen(void Function(T) callback, String key);
}
