import 'package:countdown/core/errors.dart';

/// Typed success/failure container. Layers return `Result` (or
/// `Stream<Result>`) instead of throwing.
sealed class Result<T> {
  const Result();
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppError error) = Err<T>;

  R when<R>({
    required R Function(T value) ok,
    required R Function(AppError error) err,
  }) {
    return switch (this) {
      Ok<T>(:final value) => ok(value),
      Err<T>(:final error) => err(error),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;
}
