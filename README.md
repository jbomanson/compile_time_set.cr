# compile_time_set.cr

This library provides a generic `CompileTimeSet` type that is like a
`NamedTuple` but with only keys and no values.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  compile_time_set:
    github: jbomanson/compile_time_set.cr
```

## Usage

A `CompileTimeSet` is a set of identifiers that are known at compile time.
It is like a `NamedTuple` but with only keys and no values.
It has operations similar to those of `Set`.
Internally, a compile time set is implemented as a struct with no fields and a
type parameter `T` that is a named tuple type.

With this library, you can write assertions that are checked at compile time.
Moreover, it is an example how the crystal type system can be used to express
the result of compile time computations.

See [`spec/compile_time_set_spec.cr`](https://github.com/jbomanson/compile_time_set.cr/blob/master/spec/compile_time_set_spec.cr)

### Examples

This is a compile time assertion that verifies that the set `({a, b} | {d, e})
& {b, c}` is a subset of `{b, e}`.
```crystal
require "compile_time_set"

((CompileTimeSet.create(a, b) | CompileTimeSet.create(d, e)) &
  CompileTimeSet.create(b, c)).subset! CompileTimeSet.create(b, e)
```

A compile time set such as `{a, b}` can be created from literal identifiers or
from named tuples.
```crystal
CompileTimeSet.create(a, b)   # => {a, b}
CompileTimeSet.create(:a, :b) # => {a, b}
named_tuple = {a: 100, b: "abc"}
CompileTimeSet.from_named_tuple_type(typeof(named_tuple)) # => {a, b}
CompileTimeSet.from_option_keys(a: 100, b: "abc")         # => {a, b}
```

Set operations such as union `|`, intersection `&`, difference `-` and
symmetric difference `^` are available.
The result is computed at compile time and it is encoded in the type of the
resulting set.
```crystal
a = CompileTimeSet.create(:a)
b = CompileTimeSet.create(:b)
ab = CompileTimeSet.create(:a, :b)

a | b == ab                 # true
typeof(a | b) == typeof(ab) # true
```

*Assertions* can be made on sets at compile time with methods `disjoint!`,
`empty!`, `subset!`, `superset!`.
In the following, it is first asserted that the singleton sets {a} and {b}
are *disjoint*. This means that they have no elements in common.
In this example the assertion succeeds.
Then it is asserted that the sets {a} and {a, b} have no elements in common,
but this assertion fails at compile time.
```crystal
a = CompileTimeSet.create(:a)
b = CompileTimeSet.create(:b)
ab = CompileTimeSet.create(:a, :b)

a.disjoint! b  # Nil
a.disjoint! ab # Expected {a} and {a, b} to be disjoint
```

A `CompileTimeSet` always has a size of zero. It contains no runtime
information.
```crystal
sizeof(typeof(CompileTimeSet.create(:a, :b))) # 0 : Int32
```

Values that can equal different sets are represented with *union types*.
```crystal
a = CompileTimeSet.create(:a)
b = CompileTimeSet.create(:b)
ab = CompileTimeSet.create(:a, :b)

x = true ? a : b
typeof(x) == typeof(a) | typeof(b) # true
```

An assertion involving *ambiguous* sets succeed if the assertion holds for
*all* possible combinations of values for the set.
Below, the set `x`, which is either `{a}` and `{b}`, is successfully asserted
to be a subset of `{a, b}`, because both of the possible values for `x` are
subsets of `{a, b}`.
However, `x` is then falsely asserted to be a subset of `{a}`, which fails
because the possible value `{b}` for `x` is not a subset of `{a, b}`.
```crystal
a = CompileTimeSet.create(:a)
b = CompileTimeSet.create(:b)
ab = CompileTimeSet.create(:a, :b)

x = true ? a : b
x.subset! ab # : Nil
x.subset! a  # Expected {b} to be a subset of {a}
```

A method can restrict an *argument* to a specific set.
Presently, Crystal does not allow using `create` here in place of
`from_option_keys`.
```crystal
def myfun(x : typeof(CompileTimeSet.from_option_keys(a: 1))) : Nil
end

myfun(CompileTimeSet.create(:a)) # Nil
myfun(CompileTimeSet.create(:b)) # no overload matches ...
```

## Development

Run `crystal spec` in the top level directory to run specs.
Some of the tests start new processes to run `crystal eval` on dynamically
constructed strings.
The purpose is to verify that certain compile time errors come up as
expected.
For this to work, a `crystal` binary must be found on PATH.

## Contributing

1. Fork it ( https://github.com/jbomanson/compile_time_set.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [jbomanson](https://github.com/jbomanson) Jori Bomanson - creator, maintainer
