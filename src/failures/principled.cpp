#include "failures/principled.h"

using namespace failures::principled;

template<class T>
char const *calcified_failure<T>::what() const noexcept {
  return this->serializer_(this->failure_);
}

template<class R, class T, class U, class E>
tl::expected<R, failure<E>> map2(
  std::function<R(T, U)> const &fn,
  tl::expected<T, failure<E>> const &first,
  tl::expected<U, failure<E>> const &second) {
  if (first.has_value()) {
    if (second.has_value()) {
      return fn(first.value, second.value);
    } else {
      return tl::make_unexpected(second.error);
    }
  } else {
    return tl::make_unexpected(
      second.has_value() ? first.error : all({first.error, second.error}));
  }
}

template<class R, class T, class U, class E>
tl::expected<R, failure<E>> attempt_call_then(
  std::function<tl::expected<R, failure<E>>(T, U)> const &fn,
  tl::expected<T, failure<E>> const &first,
  tl::expected<U, failure<E>> const &second) {
  auto r = attempt_call(fn, first, second);
  if (r.has_value()) {
    return r.value;
  } else {
    return tl::make_unexpected(r.error);
  }
}

template<class T, class U, class E>
tl::expected<std::pair<T, U>, failure<E>>
  both(tl::expected<T, failure<E>> first, tl::expected<U, failure<E>> second) {
  return attempt_call(std::make_pair, first, second);
}

template<class T, class U, class E>
tl::expected<std::pair<T, U>, failure<E>>
  both(tl::expected<T, failure<E>> first, tl::expected<U, E> second) {
  return both(first, second.map_error([](E const &e) { return only(e); }));
}

template<class T, class U, class E>
tl::expected<std::pair<T, U>, failure<E>>
  both(tl::expected<T, E> first, tl::expected<U, E> second) {
  return both(first.map_error([](E const &e) { return only(e); }), second);
}

template<class T, class E>
result<T, E> first_success(
  tl::expected<T, failure<E>> const &first,
  std::function<tl::expected<T, failure<E>>()> const &second) {
  if (first.has_value()) {
    return first.value;
  } else {
    auto s = second();
    if (s.has_value()) {
      return std::make_pair(s.value, first.error);
    } else {
      return tl::make_unexpected(any({first.error, s.error}));
    }
  }
}

template<class T, class E>
result<T, E> first_success_warn(
  tl::expected<T, failure<E>> const &first,
  tl::expected<T, failure<E>> const &second) {
  if (first.has_value()) {
    return std::make_pair(
      first.value,
      second.has_value() ? std::nullopt : std::optional(second.error));
  } else if (second.has_value()) {
    return std::make_pair(second, first.error);
  } else {
    return tl::make_unexpected(any({first.error, second.error}));
  }
}

template<class T, class E>
std::pair<T, std::optional<failure<E>>> default_if_failure(
  tl::expected<T, failure<E>> const &first, T const &second) {
  if (first.has_value()) {
    return std::make_pair(first.value, std::nullopt);
  } else {
    return std::make_pair(second, first.error);
  }
}
