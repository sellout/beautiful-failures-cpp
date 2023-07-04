#ifndef FAILURES_VARIANT_H
#define FAILURES_VARIANT_H

#include <variant>

// Stolen from https://stackoverflow.com/a/47204507/5090651
/// Casts from a variant to another variant containing a superset of the types.
template<class... FromArgs>
struct variant_cast {
    std::variant<FromArgs...> v;

    template<class... ToArgs>
    operator std::variant<ToArgs...>() const {
      return std::visit(
        [](auto &&arg) -> std::variant<ToArgs...> { return arg; }, v);
    }
};

/// explicit deduction guide for `struct variant_cast` (not needed as of C++20)
template<class... Args>
auto variant_cast(std::variant<Args...> const &v) -> variant_cast<Args...> {
  return {v};
}

#endif // FAILURES_VARIANT_H
