#ifndef FAILURES_PRINCIPLED_H
#define FAILURES_PRINCIPLED_H

#include <tl/expected.hpp>

#include <exception>
#include <functional>
#include <optional>
#include <string>
#include <variant>

namespace failures {
  namespace principled {
    template<class T>
    class only {
      public:
        T the_one;
    };

    template<class T>
    class all {
      public:
        std::vector<T> them;
    };

    template<class T>
    class any {
      public:
        std::vector<T> them;
    };

    // template<class T>
    // class implies {
    // public:
    //   std::vector<T> implicators
    // }

    /// A `failure` is like an exception, but doesn’t have a `what` method.
    /// Failures should be explicitly serialized close to the program
    /// boundary. If it needs to be thrown instead of reported directly, see
    /// `calcify`.
    template<class T>
    class failure {
      public:
        std::variant<only<T>, all<failure<T>>, any<failure<T>>> causes;
    };

    template<class T, class E>
    class warnable {
      public:
        T value_;
        std::optional<failure<E>> warnings_;

        warnable(T value) : value_(value), warnings_(std::nullopt) {}

        warnable(T value, failure<E> warnings)
          : value_(value), warnings_(warnings) {}
    };

    template<class T, class E>
    class result {
      private:
        tl::expected<warnable<T, E>, failure<E>> res_;

        result(warnable<T, E> with_notes) : res_(with_notes) {}

        result(failure<E> failure) : res_(tl::make_unexpected(failure)) {}

      public:
        result(T success) : res_(warnable(success)) {}

        result(E failure) : res_(tl::make_unexpected(only(failure))) {}
    };

    /// A `calcified_failure` is a wrapper for failures that conforms to the
    /// `std::exception` interface.
    ///
    /// This should only be used when necessary, as its `what` method is fixed
    /// at the point of `throw`, not the top of the call stack.
    template<class T>
    class calcified_failure : public std::exception {
      public:
        T failure_;
        std::function<std::string(T)> serializer_;

        /// Turns a `failure` into a `std::exception`. This preserves the
        /// structure in case the failure is caught and needs to be
        /// analyzed,, but provides a `what` method (as required)
        calcified_failure<T>(
          T failure, std::function<std::string(T)> serializer)
          : failure_(failure), serializer_(serializer) {}

        char const *what() const noexcept;
    };

    /// If both `tl::expected` arguments have values, then call the function
    /// with them. Otherwise, return the product of the failures.
    template<class R, class T, class U, class E>
    tl::expected<R, failure<E>> attempt_call(
      std::function<R(T, U)> const &fn,
      tl::expected<T, failure<E>> const &first,
      tl::expected<U, failure<E>> const &second);

    /// Like `attempt_call`, but if the call can fail, then this handles the
    /// sequencing step of either returning the errors from the arguments or (if
    /// both arguments have values), the failure from the result of the function
    /// call.
    template<class R, class T, class U, class E>
    tl::expected<R, failure<E>> attempt_call_then(
      std::function<tl::expected<R, failure<E>>(T, U)> const &fn,
      tl::expected<T, failure<E>> const &first,
      tl::expected<U, failure<E>> const &second);

    /// Combines both values – returning either a `std::pair` of values or the
    /// product of the failures.
    template<class T, class U, class E>
    tl::expected<std::pair<T, U>, failure<E>> both(
      tl::expected<T, failure<E>> const &first,
      tl::expected<U, failure<E>> const &second);

    template<class T, class U, class E>
    tl::expected<std::pair<T, U>, failure<E>> both(
      tl::expected<T, failure<E>> const &first,
      tl::expected<U, E> const &second);

    template<class T, class U, class E>
    tl::expected<std::pair<T, U>, failure<E>>
      both(tl::expected<T, E> const &first, tl::expected<U, E> const &second);

    /// This is the “preferred” variant, where we only try one at a time. The
    /// second value is only calculated if needed.
    template<class T, class E>
    result<T, E> first_success(
      tl::expected<T, failure<E>> const &first,
      std::function<tl::expected<T, failure<E>>()> const &second);

    /// This is the “we’d like them all to succeed”, strict variant.
    template<class T, class E>
    result<T, E> first_success_warn(
      tl::expected<T, failure<E>> const &first,
      tl::expected<T, failure<E>> const &second);

    /// Lixe `first_success`, but the second argument can’t fail, so we always
    /// have a successful return, just perhaps with some warnings.
    template<class T, class E>
    std::pair<T, std::optional<failure<E>>> default_if_failure(
      tl::expected<T, failure<E>> const &first, T const &second);
  }
}

#endif // FAILURES_PRINCIPLED_H
