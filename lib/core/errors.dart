/// Typed application errors. Convert exceptions at layer boundaries into
/// one of these — never throw across layers.
sealed class AppError implements Exception {
  const AppError(this.message);
  final String message;
}

final class NetworkError extends AppError {
  const NetworkError([super.message = 'Lost signal.']);
}

final class AuthError extends AppError {
  const AuthError([super.message = 'Missing or invalid OpenAI API key.']);
}

final class RateLimitError extends AppError {
  const RateLimitError({this.retryAfter, String message = 'Easy, tiger.'})
      : super(message);
  final Duration? retryAfter;
}

final class MalformedResponseError extends AppError {
  const MalformedResponseError([super.message = 'GPT gave us gibberish.']);
}

final class RefusedError extends AppError {
  const RefusedError([super.message = 'GPT declined to answer.']);
}

final class TimeoutError extends AppError {
  const TimeoutError([super.message = 'Request timed out.']);
}

final class UnknownError extends AppError {
  const UnknownError([super.message = 'Something went wrong.']);
}
