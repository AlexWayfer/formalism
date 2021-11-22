# Changelog

## Unreleased

## 0.4.0 (2021-02-11)

*   Support Ruby 3.
*   Update development dependencies.
*   Resolve new RuboCop offenses.

## 0.3.1 (2020-10-02)

*   Fix `Float` coercion to `BigDecimal`.

## 0.3.0 (2020-09-28)

*   Add `BigDecimal` coercion.
*   Support `BigDecimal` for `Float` coercion.

## 0.2.1 (2020-09-25)

*   Make `Form::Outcome` constant public.
    Useful for re-defining `#run` method in modules.

## 0.2.0 (2020-09-23)

*   Fix `included` in child forms.
    Call `super`, and use `module_methods` at all.
*   Update bundle.

## 0.1.0 (2020-07-09)

*   Initial version
