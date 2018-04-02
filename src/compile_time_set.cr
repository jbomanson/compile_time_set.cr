require "./compile_time_set/version"

# A dummy type used for all values in the tuple type `T`.
private struct In
end

# :nodoc:
private IN = In.new

# A `CompileTimeSet` is a set of identifiers that are known at compile time.
# It is like a `NamedTuple` but with only keys and no values.
# It has operations similar to those of `Set`.
# Internally, a compile time set is implemented as a struct with no fields and a
# type parameter `T` that is a named tuple type.
#
# With this library, you can write assertions that are checked at compile time.
# Moreover, it is an example how the crystal type system can be used to express
# the result of compile time computations.
#
# See [`spec/compile_time_set_spec.cr`](https://github.com/jbomanson/compile_time_set.cr/blob/master/spec/compile_time_set_spec.cr)
#
# ### Examples
#
# This is a compile time assertion that verifies that the set `({a, b} | {d, e})
# & {b, c}` is a subset of `{b, e}`.
# ```crystal
# require "compile_time_set"
#
# ((CompileTimeSet.create(a, b) | CompileTimeSet.create(d, e)) &
#   CompileTimeSet.create(b, c)).subset! CompileTimeSet.create(b, e)
# ```
#
# A compile time set such as `{a, b}` can be created from literal identifiers or
# from named tuples.
# ```
# CompileTimeSet.create(a, b)   # => {a, b}
# CompileTimeSet.create(:a, :b) # => {a, b}
# named_tuple = {a: 100, b: "abc"}
# CompileTimeSet.from_named_tuple_type(typeof(named_tuple)) # => {a, b}
# CompileTimeSet.from_option_keys(a: 100, b: "abc")         # => {a, b}
# ```
#
# Set operations such as union `|`, intersection `&`, difference `-` and
# symmetric difference `^` are available.
# The result is computed at compile time and it is encoded in the type of the
# resulting set.
# ```
# a = CompileTimeSet.create(:a)
# b = CompileTimeSet.create(:b)
# ab = CompileTimeSet.create(:a, :b)
#
# a | b == ab                 # true
# typeof(a | b) == typeof(ab) # true
# ```
#
# *Assertions* can be made on sets at compile time with methods `disjoint!`,
# `empty!`, `subset!`, `superset!`.
# In the following, it is first asserted that the singleton sets {a} and {b}
# are *disjoint*. This means that they have no elements in common.
# In this example the assertion succeeds.
# Then it is asserted that the sets {a} and {a, b} have no elements in common,
# but this assertion fails at compile time.
# ```
# a = CompileTimeSet.create(:a)
# b = CompileTimeSet.create(:b)
# ab = CompileTimeSet.create(:a, :b)
#
# a.disjoint! b  # Nil
# a.disjoint! ab # Expected {a} and {a, b} to be disjoint
# ```
#
# A `CompileTimeSet` always has a size of zero. It contains no runtime
# information.
# ```
# sizeof(typeof(CompileTimeSet.create(:a, :b))) # 0 : Int32
# ```
#
# Values that can equal different sets are represented with *union types*.
# ```
# a = CompileTimeSet.create(:a)
# b = CompileTimeSet.create(:b)
# ab = CompileTimeSet.create(:a, :b)
#
# x = true ? a : b
# typeof(x) == typeof(a) | typeof(b) # true
# ```
#
# An assertion involving *ambiguous* sets succeed if the assertion holds for
# *all* possible combinations of values for the set.
# Below, the set `x`, which is either `{a}` and `{b}`, is successfully asserted
# to be a subset of `{a, b}`, because both of the possible values for `x` are
# subsets of `{a, b}`.
# However, `x` is then falsely asserted to be a subset of `{a}`, which fails
# because the possible value `{b}` for `x` is not a subset of `{a, b}`.
# ```
# a = CompileTimeSet.create(:a)
# b = CompileTimeSet.create(:b)
# ab = CompileTimeSet.create(:a, :b)
#
# x = true ? a : b
# x.subset! ab # : Nil
# x.subset! a  # Expected {b} to be a subset of {a}
# ```
#
# A method can restrict an *argument* to a specific set.
# Presently, Crystal does not allow using `create` here in place of
# `from_option_keys`.
# ```
# def myfun(x : typeof(CompileTimeSet.from_option_keys(a: 1))) : Nil
# end
#
# myfun(CompileTimeSet.create(:a)) # Nil
# myfun(CompileTimeSet.create(:b)) # no overload matches ...
# ```
struct CompileTimeSet(T)
  # Creates a compile time set containing the given identifiers as elements.
  #
  # ### Examples
  # ```
  # named_tuple = {a: 100, b: "abc"}
  # CompileTimeSet.create(a, b)
  # # {a, b} : CompileTimeSet(NamedTuple(a: In, b: In))
  # ```
  # ```
  # named_tuple = {a: 100, b: "abc"}
  # CompileTimeSet.create(:a, :b)
  # # {a, b} : CompileTimeSet(NamedTuple(a: In, b: In))
  # ```
  macro create(*args)
    {% begin %}
      ::CompileTimeSet.from_option_keys(
        {% for key in args %}
          {{key.id}}: nil,
        {% end %}
      )
    {% end %}
  end

  # Creates a compile time set containing the keys of the given *options* as
  # elements.
  #
  # ### Example
  # ```
  # named_tuple = {a: 100, b: "abc"}
  # CompileTimeSet.from_option_keys(a: 100, b: "abc")
  # # {a, b} : CompileTimeSet(NamedTuple(a: In, b: In))
  # ```
  def self.from_option_keys(**options) : CompileTimeSet
    from_named_tuple_type(typeof(options))
  end

  # Creates a compile time set containing the keys of the given
  # *named_tuple_type* as elements.
  #
  # ### Example
  # ```
  # named_tuple = {a: 100, b: "abc"}
  # CompileTimeSet.from_named_tuple_type(typeof(named_tuple))
  # # {a, b} : CompileTimeSet(NamedTuple(a: In, b: In))
  # ```
  def self.from_named_tuple_type(named_tuple_type : U.class) : CompileTimeSet forall U
    {% begin %}
      CompileTimeSet.new(
        nil,
        {% for key in U.keys %}
          {{key}}: IN,
        {% end %}
      )
    {% end %}
  end

  # :nodoc:
  protected def initialize(overload : Nil, **named_tuple : **T)
    {% for key in T.keys %}
      {% unless T[key] == In %}
        {{ raise "Expected all values to be of type In, got #{T[key]}" }}
      {% end %}
    {% end %}
  end

  # Union: returns a new set containing all unique elements from both sets.
  def |(other : CompileTimeSet(U)) : CompileTimeSet forall U
    {% begin %}
      CompileTimeSet.from_option_keys(
        {% for key in (T.keys + U.keys).uniq.sort %}
          {{key}}: IN,
        {% end %}
      )
    {% end %}
  end

  # Intersection: returns a new set containing elements common to both sets.
  def &(other : CompileTimeSet(U)) : CompileTimeSet forall U
    {% begin %}
      CompileTimeSet.from_option_keys(
        {% for key in (T.keys.select { |key| U[key] }).uniq.sort %}
          {{key}}: IN,
        {% end %}
      )
    {% end %}
  end

  # Difference: returns a new set containing elements in this set that are not
  # present in the other.
  def -(other : CompileTimeSet(U)) : CompileTimeSet forall U
    {% begin %}
      CompileTimeSet.from_option_keys(
        {% for key in (T.keys.reject { |key| U[key] }).uniq.sort %}
          {{key}}: IN,
        {% end %}
      )
    {% end %}
  end

  # Symmetric Difference: returns a new set (self - other) | (other - self).
  def ^(other : CompileTimeSet) : CompileTimeSet
    (self - other) | (other - self)
  end

  # Checks at compile time that this and the *other* set have no common
  # elements.
  def disjoint!(other : CompileTimeSet(U)) : Nil forall U
    (self & other).try_nonempty do
      {{
        raise "Expected #{T.keys} and #{U.keys} to be disjoint".tr("[]", "{}")
      }}
    end
  end

  # Checks at compile time that this set is empty.
  def empty! : Nil
    self.try_nonempty do
      {{
        raise "Expected #{T.keys} to be empty".tr("[]", "{}")
      }}
    end
  end

  # Calls `to_s(io)`.
  def inspect(io)
    to_s(io)
  end

  # Returns the number of elements in the set.
  def size : Int32
    {{ T.size }}
  end

  # Checks at compile time that this set is a superset of the *other* set.
  def superset!(other : CompileTimeSet(U)) : Nil forall U
    (other - self).try_nonempty do
      {{
        raise "Expected #{T.keys} to be a superset of #{U.keys}".tr("[]", "{}")
      }}
    end
  end

  # Checks at compile time that this set is a subset of the *other* set.
  def subset!(other : CompileTimeSet(U)) : Nil forall U
    (self - other).try_nonempty do
      {{
        raise "Expected #{T.keys} to be a subset of #{U.keys}".tr("[]", "{}")
      }}
    end
  end

  # Evaluates a block if this set contains any elements.
  def try_nonempty(&block)
    {% unless T.keys.empty? %}
      yield self
    {% end %}
  end

  # Returns a named tuple that maps each element of this set to *value*.
  def to_named_tuple(value = 1)
    {% begin %}
      NamedTuple.new(
        {% for key in T.keys %}
          {{key}}: value,
        {% end %}
      )
    {% end %}
  end

  # Writes a string representation of the set to *io*.
  def to_s(io)
    io << '{'
    {% for key, index in T.keys.sort %}
      {% unless index == 0 %}
        io << ", "
      {% end %}
      io << {{key.stringify}}
    {% end %}
    io << '}'
  end
end
