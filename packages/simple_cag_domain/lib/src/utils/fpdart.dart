import "package:fpdart/fpdart.dart";

typedef Failure<L, R> = Left<L, R>;
typedef Success<L, R> = Right<L, R>;

T repeatFold<T>(int count, T initial, T Function(T) step) =>
    Iterable<int>.generate(count).fold(initial, (state, _) => step(state));
