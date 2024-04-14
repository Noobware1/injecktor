abstract interface class InjectKtorInterface {
  S addSingleton<S>(
    S singleInstance, {
    bool? permanent,
    String? name,
  });

  void addLazySingleton<S>(
    InstanceBuilderCallback<S> builder, {
    bool? permanent,
    String? name,
  });

  void addFactory<S>(
    InstanceBuilderCallback<S> builder, {
    bool? permanent,
    String? name,
  });

  S get<S>({
    String? name,
  });

  S getOrElse<S>(
    S Function() orElse, {
    String? name,
  });

  S? getOrNull<S>({
    String? name,
  });

  /// Replace a parent instance of a class in dependency management
  /// with a [child] instance
  /// - [name] optional, if you use a [name] to register the Instance.
  void replaceSingleton<P>(P child, {String? name});

  /// Replaces a parent instance with a new Instance<P> lazily from the
  /// `<P>builder()` callback.
  /// - [name] optional, if you use a [name] to register the Instance.
  /// - [fenix] optional
  ///
  ///  Note: if fenix is not provided it will be set to true if
  /// the parent instance was permanent
  void lazyReplaceSingleton<P>(InstanceBuilderCallback<P> builder,
      {String? name, bool? permanent});

  void markAsDirty<S>({String? name, String? key});

  /// Delete registered Class Instance [S] (or [name]) and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// /// Deletes the Instance<[S]>, cleaning the memory.
  //  ///
  //  /// - [name] Optional "name" used to register the Instance
  //  /// - [key] For internal usage, is the processed key used to register
  //  ///   the Instance. **don't use** it unless you know what you are doing.

  /// Deletes the Instance<[S]>, cleaning the memory and closes any open
  /// controllers (`DisposableInterface`).
  ///
  /// - [name] Optional "name" used to register the Instance
  /// - [key] For internal usage, is the processed key used to register
  ///   the Instance. **don't use** it unless you know what you are doing.
  /// - [force] Will remove an Instance even if marked as `permanent`.
  bool remove<S>({String? name, String? key, bool force = false});

  /// Removes all registered Class Instances
  /// - [force] Will delete the Instances even if marked as `permanent`.
  void removeAll({bool force = false});

  void reloadAll({bool force = false});

  void reload<S>({
    String? name,
    String? key,
    bool force = false,
  });

  InstanceInfo getInstanceInfo<S>({String? name});

  /// Check if a Class Instance<[S]> (or [name]) is registered in memory.
  /// - [name] is optional, if you used a [name] to register the Instance.
  bool isRegistered<S>({String? name});

  /// Checks if a lazy factory callback `Get.lazyPut()` that returns an
  /// Instance<[S]> is registered in memory.
  /// - [name] is optional, if you used a [name] to register the lazy Instance.
  bool isPrepared<S>({String? name});

  void resetInstance();
}

class InstanceInfo {
  final bool isPermanent;
  final bool? isSingleton;
  bool get isCreate => !isSingleton!;
  final bool isRegistered;
  final bool isPrepared;
  final bool? isInit;
  const InstanceInfo({
    required this.isPermanent,
    required this.isSingleton,
    required this.isRegistered,
    required this.isPrepared,
    required this.isInit,
  });

  @override
  String toString() {
    return 'InstanceInfo(isPermanent: $isPermanent, isSingleton: $isSingleton, isRegistered: $isRegistered, isPrepared: $isPrepared, isInit: $isInit)';
  }
}

typedef InstanceBuilderCallback<S> = S Function();
