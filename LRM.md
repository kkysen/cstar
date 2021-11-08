# C* - Language Reference Manual

Github link: https://github.com/kkysen/cstar/blob/main/LRM.md

## Table of Contents
- [Overview](#overview)
- [A C* Program](#a-c-program)
  - [Modules](#modules)
  - [Identifiers](#identifiers)
  - [Keywords](#keywords)
  - [Comments](#comments)
    - [`//` Single-Line](#-single-line-comments)
      - [`///` Doc](#-doc-comments)
    - [`/* */` Nested, Multi-Line(#--nested-multi-line-comments)
    - [`/-` Structural](#--structural-comments)
  - [Publicity](#pub-publicity)
  - [Annotations](#annotations)
  - [`use` Declarations](#use-declarations)
  - [`let`s](#let-declarations)
  - [`fn` Function Declarations](#fn-function-declarations)
  - [`struct` Declarations](#struct-declarations)
  - [`enum` Declarations](#enum-declarations)
  - [`union` Declarations](#union-declarations)
  - [`impl` Blocks](#impl-blocks)
- [Type System](#type-system)
  - [Primitive Types](#primitive-types)
    - [`()` Unit Type](#-unit-type)
    - [`bool` Type](#bool-type)
    - [Integer Types](#integer-types)
    - [Float Types](#float-types)
    - [`char`acter type](#character-type)
  - [Built-In Compound Types](#built-in-compound-types)
    - [Reference Types](#reference-types)
    - [Slice Types](#slice-types)
    - [Array Types](#array-types)
    - [Tuple Types](#tuple-types)
  - [User-Defined Compound Types](#user-defined-compound-types)
    - [`struct` Types](#struct-declarations)
    - [`enum` Types](#enum-declarations)
    - [`union` Types](#union-declarations)
- [Destructive Moves](#destructive-moves)
- [Expressions](#expressions)
  - [Literals](#literals)
    - [Unit](#unit-literals)
    - [Boolean](#boolean-literals)
    - [Number](#number-literals)
    - [Character](#character-literals)
    - [String](#string-literals)
    - [Struct](#struct-literals)
    - [Tuple](#tuple-literals)
    - [Array](#array-literals)
    - [Enum](#enum-literals)
    - [Union](#union-literals)
    - [Function](#function-literals)
    - [Closure](#closure-literals)
    - [Range](#range-literals)
  - [Function Calls](#function-calls)
    - [Method Calls](#method-calls)
  - [Blocks](#blocks)
  - [Control Flow](#control-flow)
    - [Pattern Matching](#pattern-matching)
    - [Conditionals](#conditionals)
      - [`match`](#match)
      - [`if`](#if)
      - [`else`](#else)
    - [Labels](#labels)
    - [Loops](#loops)
      - [`while`](#while)
      - [`for`](#for)
    - [`defer`](#defer)
    - [Error Handling](#error-handling)
      - [`try`](#try)
      - [Panicking](#panicking)
  - [Operators](#operators)
- [Generics](#generics)
- [Constant Evaluation](#constant-evaluation)
- [Builtin Functions](#builtin-functions)
- [List of Annotations](#list-of-annotations)
- [Current Restrictions and Unimplemented Features](#current-restrictions-and-unimplemented-features)

[Table of Contents](#table-of-contents)

## Overview
C* is a general-purpose systems programming language. It is between the level of C and Zig on a semantic level, and syntactically it also borrows a lot from Rust (pun intended). It is meant primarily for programs that would otherwise be implemented in C for the speed, simplicity, and explicitness of the language, but want a few simple higher-level language constructs, more expressiveness, and some safety, but not so many overwhelming language features and implicit costs like in Rust, C++, or Zig.

It has manual memory management (no GC) and uses LLVM as its primary codegen backend, so it can be optimized as well as C, or even better in cases. All of C*'s higher-level language constructs are zero-cost, meaning none of those features give it any overhead over C, which often lead to a highly-optimized style where in C you would take less efficient shortcuts (e.x. function pointers and type-erased generics) and use dangerous constructs like goto. In the future, it may also have a C backend so that it can target any architecture where there is a C compiler.

While a general-purpose language, C* will probably have the most advantages when used in systems and embedded programming. It's expressivity and high-level features combined with its relative simplicity, performance, and explicitness is a perfect match for many of these low-level systems and embedded programs.

[Table of Contents](#table-of-contents)

## A C* Program
A C* program is a top-level C* module.

Note that italics will be used here to refer to 
placeholders for language items, not the items themselves.

### Modules
Every C* file (by default using a `.cstar` extension)
must be UTF-8.
Each file is implicitly a module, though modules can also be declared
inline with the `mod `*`name`*` {}` keyword[*](#current-restrictions-and-unimplemented-features).
Everything between the braces belongs to the module `name`.

A module is composed of a series of top-level items (aka declarations), which may be one of:
* [`use`](#use-declarations)
* [`let`](#let-declarations)
* [`fn`](#fn-function-declarations)
* [`struct`](#struct-declarations)
* [`enum`](#enum-declarations)
* [`union`](#union-declarations)
* [`impl`](#impl-blocks)

These items may be proceeded by a single [*`publicity`* modifier](#pub-publicity)
and any number of [annotations](#annotations).

[Comments](#comments) may also appear anywhere.

C* is not whitespace sensitive, i.e., 
any consecutive sequence of whitespace may be replaced by 
any other consecutive sequence of whitespace 
without changing the meaning of the program.
A unicode character is considered whitespace if it matches the [`\p{Pattern_White_Space}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B:Pattern_White_Space:%5D&abb=on&g=&i=) unicode property.

[Table of Contents](#table-of-contents)

### Identifiers
Identifiers in C* may be any UTF-8 string 
in which the first characters is `_`, `$`, or matches the [`\p{XID_Start}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AXID_Start%3A%5D&abb=on&g=&i=) unicode property,
and the remaining characters match the [`\p{XID_Continue}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AXID_Continue%3A%5D&abb=on&g=&i=) unicode property,
except for the following exceptions:

Identifiers may begin with `$` but are only definable by the compiler as intrinsics. 

There are no keywords at the lexer level, but identifiers may not be a C* [keyword](#keywords).
They may also not be the [boolean literals](#boolean-literals) `true` or `false`.

`_` is a valid C* identifier at the syntactic level,
but has a special meaning and cannot be used everywhere.
That is, it can only be assigned to.

Examples:
```rust
// valid identifiers
let validWord: u32 = 2;
fn get_num() = {}
enum 小笼包 {}

// invalid identifier
let 2words = 2;
struct const {}
```

[Table of Contents](#table-of-contents)

### Keywords
Keywords are reserved identifiers that cannot be used as regular identifiers for other purposes.

C* keywords:
* `use`
* `let`
* `mut`
* `pub`
* `try`
* `const`
* `impl`
* `fn`
* `struct`
* `enum`
* `union`
* `return`
* `break`
* `continue`
* `for`
* `while`
* `if`
* `else`
* `match`
* `defer`
* `undefer`

There are also reserved keywords:
* `trait`

[Table of Contents](#table-of-contents)
### Comments
C* contains multiple types of comments
* [single-line](#-single-line-comments)
* [nested multi-line](#--nested-multi-line-comments)
* [structural comments](#--structural-comments)

[Table of Contents](#table-of-contents)

#### `//` Single-Line Comments
Tokens followed by `//` until a `\n` newline are considered single-line comments.

[Table of Contents](#table-of-contents)

##### `///` Doc Comments
Tokens followed by `///` until a `\n` newline are considered doc comments.  They are a form of single-line comments, 
but may also be processed by tools for generating documentation.

[Table of Contents](#table-of-contents)

#### `/* */` Nested, Multi-Line Comments
Tokens followed by `/*` are considered multi-line comments. 
They can be nested, and end at the next `*/` that is not a part
of an inner multi-line comment.
They also do not have to be multi-line, 
and can comment out only part of a line.

[Table of Contents](#table-of-contents)

#### `/-` Structural Comments
`/-` denotes a structral comment.  It comments out the next item in the AST, which could be the next expression, function, type definition, etc.

Example:
```rust
// This is a regular single line comment.

/// This is a doc comment for the function below.
fn foo() = {}

/* This is a multiline comment
Everything inside here is commented out until "* /"
*/

/* They can be /* nested */, too. */
fn /* and appear in-between things */ bar() = {}

/- let x = 25; // This comments out the entire let expression.
```

[Table of Contents](#table-of-contents)

### `pub` Publicity
All top-level items (except [`impl` blocks](#impl-blocks)) 
may be prefixed with a publicity modifier.

The syntax for this is `pub`.

Following the `pub`, there may also be a module path 
within parentheses, like this: `(`*`path`*`)`.

If there is no publicity modifier, i.e. no `pub`,
then the publicity of the item is private, i.e. `pub(self)`.

Only public items may be [`use`](#use-declarations)d from other modules. 
Private items may only be used for the current module or its descendants.

[Table of Contents](#table-of-contents)

### Annotations
All items may be prefixed with any number of annotations,
which annotate the item with certain metadata.

The syntax for this is `@`*`annotation`*, 
where *`annotation`* is the name of the annotation.
Note that annotations may be imported (`use`d) 
or referred to with their fully-qualified path.

They may also have an *`argument_list`* after the annotation.
Having no *`argument_list`* is equivalent to having an empty, 0-length *`argument_list`*.
The *`argument_list`* is a normal C* *`argument_list`*,
except this one must be a compile-time constant.

The exact annotations available is still being decided,
but a few of them may be:
* `@extern`
* `@abi("`*`abi`*`")`, like `@abi("C")` or the default `@abi("C*")`
* `@inline`
* `@noinline`
* `@impl(`*`type1`*`, `*`...`*`, `*`typeN`*`)`
* `@align(`*`alignment`*`)`
* `@packed`
* `@allow("`*`warning_name`*`")`
* `@non_exhaustive`

For now, any available annotations will be implemented in the compiler,
though this could change in the future.

Annotations can also be applied to the current module.
In this case, they must appear before any other items in the module
and are prefixed with an extra `@`, like `@@allow("unused_variable")`.

[Table of Contents](#table-of-contents)

### `use` Declarations
`use` declarations are used to import items/declarations
from other modules, such as the standard library,
external libraries, your own defined modules, or certain types.

Their syntax is *`use `*`= use `*`path`*,
where *`path `*`= `*`identitifier`*`.`*`path`*.

That is, it imports a path to an item to be used
without path qualification within the current scope.

*`path`* can also end in `.*`. The `*` indicates all items, 
so this imports all items from the parent path.

[Table of Contents](#table-of-contents)

### `let`s
A `let` binds an expression to a name.
That expression can either be a [value](#value-lets) or a [type](#type-lets-aka-type-aliases).

Normally (in expressions), `let` bindings can be shadowed,
but they cannot be at the module level.

[Table of Contents](#table-of-contents)

#### Value `let`s
For values, the syntax of this is `let mut`*`?`*` `*`identifier`*`: `*`type `*`= `*`expr`*`;`*`?`*.

The `mut` is optional.  If there is no `mut`,
then the variable is an immutable const.
If there is a `mut`, then it is a mutable global variable.

In normal `let` bindings, *`expr`* can be any C* expression,
and the `: `*`type`* may be omitted where inferrable,
but at the top, global level, the *`expr`* must be constant evaluated
and the *`type`* must be annotated.
The way to do the former is by using a `const { ... }` block,
which evaluates the block to a constant at compile time.

A value `let` can also create zero, one, or multiple bindings
at once through destructuring a pattern.
If the pattern is tautological, i.e. the pattern always matches,
then the bindings are always created.
If the pattern may not match, then the `let` expression is a `bool` and may be used in `if`s or `match`es.
In this case, the `let` binding(s) are only created if the pattern matches and the `let` expression evaluated to `true`.
Note that `match`ing a non-tautological `let` is possible
but very un-idiomatic, since the binding could simply be done in the match itself.  Thus, it is normally used with `if`.

See [pattern matching](#pattern-matching) for more info on patterns and destructuring.

[Table of Contents](#table-of-contents)

#### Type `let`s aka Type Aliases
For types, the syntax of this is `let `*`identifier generic_parameter_list? `*`= `*`type`*`;`.

The *`type`* here may be any type expression that
a value would be annotated with.
For example, this includes named types, tuples, arrays, slices, function pointers.

See [below](#generic-parameters) for info on the optional *`generic_parameter_list`*.

Note that this only creates an alias of the type,
but does not actually create a new type.
For example, the type alias cannot be used as a namespace
for methods or enum variants.

For example, you could have these type aliases:
```rust
let Option<T> = Result<T, ()>;
let Bool = Option<()>;
let Point = (f64, f64);
```

[Table of Contents](#table-of-contents)

### `fn` Function Declarations
`fn` declarations declare functions.

The syntax of this is `fn `*`identifier generic_parameter_list? parameter_list`*`: `*`type `*`= `*`expr`*.

The *`identifier`* is the name of the function, 
the [*`generic_parameter_list`*](#generic-parameters) optional generic parameters,
the [*`parameter_list`*](#parameters) required normal (non-generic) parameters,
the *`type`* the [return type](#return-type) of the function,
and the *`expr`* the [return value](#return-value) of the function.

#### Generic Parameters
A *`generic_parameter_list`* is delimited by `<` `>` angle brackets 
and contains `,` comma-separated generic parameters.
A trailing comma is allowed.

Each generic parameter is a generic type or a generic constant[*](#current-restrictions-and-unimplemented-features).
If it is a generic constant, then it requires a `: `*`type`* annotation.

Note that an empty *`generic_parameter_list`* like `<>`
is semantically distinct from no *`generic_parameter_list`* at all.
Generic functions are monomorphized (see [generics](#generics) for more).

Also, the `<` `>` angle brackets as used for generics
has higher precedence than the `<` `>` comparison operators.

#### Parameters
A *`parameter_list`* is delimited by `(` `)` parentheses
and contains a `,` comma-separated parameters.
A trailing comma is allowed.
Each parameter is a `let` binding except without the `let` keyword.
However, in function declarations, the parameters must have `: `*`type`* annotations.
Note that the similar [function literals/values](#function-literals) do not require this.

#### Return Type
The `: `*`type`* may be omitted if the type is the unit `()` type.

#### Return Value
The *`expr`* that the function returns may be any expression.
However, normally it is a `{ ... }` block,
which is necessary to include multiple statements in a function.
The block (like any) may also have modifiers, 
like `try { ... }` or `const { ... }`.
Returning a `const { ... }` from a function in particular marks
that function as constant evaluatable[*](#current-restrictions-and-unimplemented-features).

Normally a `;` is required to end the return value,
except if a block is used as the return value,
then it does not require the `;`.

A function return block is slightly special in that 
`return` may be used within it, which is equivalent to a `break` from that top-level function block.

If a function is annotated with `@extern`,
then it must omit the ` =`*` expr`* and end with a `;`.
In this case, only the function signature is specified
and the `@extern`ed function must be available as a function symbol at link time or else there will be a compile error.

Note that `@abi("C")` is usually specified along with `@extern`
because the default `@abi("C*")` is unstable.

In an `@extern @abi("C")` function, 
the last (but not only) parameter may also be `...`,
which is a C varargs parameter and may be called with multiple arguments.
This is only for C FFI for functions like `syscall`,
which otherwise we'd need to implement with some assembly.

Note that `@extern` and `@abi("C")` may also be specified for an entire module,
in which case it applies to all items within that module.

#### Function Examples
For example, a non-generic function may look like this:
```rust
fn foo(_a: i32, b: usize, _c: String): usize = b * b;
```
or this:
```rust
fn string_len(c: String): usize = {
    c.len()
}
```
and a generic function may look like this:
```rust
fn equals<T>(a: T, b: T): bool = {
    a.equals(b)
}
```

[Table of Contents](#table-of-contents)

### `struct` Declarations
`struct` declarations declare a `struct` type,
which is a product type of its field types.
All fields are always initialized.

The syntax of this is `struct `*`identifier generic_parameter_list?`*`{ `*`fields `*`}`,
where *`identifier`* is the name of the `struct` type,
*`generic_parameter_list`* are its generic parameters,
and *`fields`* is a `,` comma-separated list of fields.
A trailing comma is allowed.
Zero fields is also allowed.

The syntax of each field is a value `let` without the `let` and the ` =`*` expr`*`;`.
Each field may also be prefixed by a *`publicity`* modifier.

Note that `mut` can be specified for these fields,
in which case they are have interior mutability,
i.e., they can be mutated through a non-`mut` pointer to the struct.

By default, `struct`s use `@abi("C*")`,
which means their layout and alignment is unspecified and unstable.
This allows for fields to be rearranged for optimizations.
If `@abi("C")` is specified, however, then the fields are
layed out in memory in the order they appear in,
and C alignment and padding rules are used.

[Table of Contents](#table-of-contents)

### `enum` Declarations
`enum` declarations declare an `enum` type,
which is a sum type of its variants.
That is, it is a discriminated union of variants,
each of which may have a value or not.
A value of an `enum` type is always one of its variants
and cannot be anything except those variants.
The discriminant value is stored.

The syntax of this is `enum `*`identifier generic_parameter_list?`*`{ `*`variants `*`}`,
where *`identifier`* is the name of the `struct` type,
*`generic_parameter_list`* its generic parameters,
and *`variants`* is a `,` comma-separated list of variants.
A trailing comma is allowed.
Zero variants is also allowed, but note that this means that
the `enum` can never be instantiated because it has no variants.

Each variant may have a value or not.
If a variant does not have a value, then the syntax is *`identifier`*.
By default, the discriminant value of each variant is chosen by the compiler,
but this may be overridden for each variant 
if all the variants of the `enum` have no value.
The syntax for this is *`identifier `*`= `*`expr`*,
where *`expr`* must be a `const { ... }` block 
evaluating to the integer to be used for the discriminant.

If a variant does have a value, then the syntax is *`identifier`*`(`*`type`*`)`.
Note that only one *`type`* is allowed here.
If you wish to include multiple types,
simple use a tuple or `struct` instead.

All variants of an `enum` implicity use `pub` as their publicity modifier, which cannot be changed.

By default, `enum`s use `@abi("C*")`,
which means their layout and alignment is unspecified and unstable.
This allows for the layout, including the discriminant, to be optimized.
Generally, though, the size of an `enum` type is the 
size of the discriminant plus the size of the largest variant data.

If all the variants have no values,
then `@abi("C")` may be specified.
In this case, you must also specify the size of the enum
by adding a `: `*`type`* following the *`identifier`* name,
where the *`type`* is a primitive integer type.
In this case, all the variant discriminants must fit within that type.

The `@non_exhaustive` attribute can also be applied to an `enum` type,
in which case matching all the variants is no longer considered an exhaustive match, 
and a catch-all `_ => ` match arm is required.

[Table of Contents](#table-of-contents)

### `union` Declarations [*](#current-restrictions-and-unimplemented-features)
`union` declarations declare a `union` type,
which is a non-discriminated union similar to C `union`s.
It is meant for C FFI and thus defaults to `@abi("C")`.

The syntax of a `union` type declaration is 
the same as a `struct` type declaration,
except the `struct` keyword is replaced by the `union` keyword.

The difference between the two is semantics.
The size of a union is the size of its largest field
and only one field may be active at any time.
Reading from an inactive field is undefined.

[Table of Contents](#table-of-contents)

### `impl` Blocks
`impl` blocks define associated items for a type, which includes methods.

The syntax for this is `impl `*`generic_parameter_list? type `*`{ `*`items `*`}`,
where *`type`* is the type you are defining associated items for,
*`generic_parameter_list`* is any generic parameters needed for *`type`*, and *`items`* are items like those in a module.

Within an `impl` block, there is an implicit type alias defined:
`let Self = `*`type`*`;`, where *`type`* is the same type being `impl`emented.

Items defined within an `impl` block are available 
through the type as if it were a module.
The exception is methods, which may be called in another way as well.
A method is a function in an `impl` block whose first parameter
is `self: Self`.
The `: Self` may be inferred (an exception for function declarations).
To call a method, you may also call it using `.` syntax on a value of the `impl` *`type`*.
That is, *`value`*`.`*`method`*`(`*`args`*`)` is syntactic sugar
for *`type`*`.`*`method`*`(`*`value`*`, `*`args`*`)` where *`value`*`: `*`type`*.

[Table of Contents](#table-of-contents)

## Type System
C* types can be split up into three kinds of types:
* [primitive types](#primitive-types)
* compound types
  * [built-in](#built-in-compound-types)
  * [user-defined](#user-defined-compound-types)

[Table of Contents](#table-of-contents)

### Primitive Types
The primitive types in C* are:
* the [`()` unit type](#-unit-type)
* [integer types](#integer-types)
* [float types](#float-types)
* the [`char`acter type](#character-type)

[Table of Contents](#table-of-contents)

#### `()` Unit Type

[Table of Contents](#table-of-contents)

#### `bool` Type
`bool` is the boolean type in C*,
except it is actually defined as an enum:
```rust
@allow("non_title_case_types")
enum bool {
    false = const { 0 },
    true = const { 1 },
}
```

Normally operator overloading is not allowed in C*.
The exception is `bool`, which defines the normal boolean operators.
See [operators](#operators) for details on them.

[Table of Contents](#table-of-contents)

#### Integer Types

[Table of Contents](#table-of-contents)


#### Float Types

[Table of Contents](#table-of-contents)

#### `char`acter Type

[Table of Contents](#table-of-contents)

### Built-In Compound Types
The built-in compound types in C* are:
* [reference types](#reference-types)
* [slice types](#slice-types)
* [array types](#array-types)
* [tuple types](#tuple-types)

[Table of Contents](#table-of-contents)

#### Reference Types
In C*, you can have a reference to any type, 
i.e., a pointer to a value of that type.
That reference is either immutable or mutable.

The syntax for an immutable reference is *`type`*`&`,
and the syntax for a mutable reference is *`type`*`&mut`.

An immutable reference can be created using the postfix
`.&` reference operator from either an immutable or mutable binding.
A mutable reference can be created using the postfix
`.&mut` mutable reference operator, but only from a mutable binding.

Both immutable and mutable references can be dereferenced 
using the postfix `.*` dereference operator.
This creates a temporary, unnamed, non-copied, immutable binding.
A mutable reference can also be dereferenced mutably
using the postfix `.*mut` mutable dereference operator.
This is the same as the `.*` deference operator,
except the resultant temporary is mutable.

Note that references can only be created by referencing an existing value.
Thus, null references are impossible to create.
Instead, `Option` should be used, like `Option<T&>`.

[Table of Contents](#table-of-contents)

#### Slice Types
In C*, you can also have a slice of a type, a contiguous collection of values of the same type.  The number of values is only known at runtime.

The syntax for this is *`type`*`[]`.

A slice `T[]` is similar to the struct
```rust
struct SliceT {
    len: usize,
    ptr: T&,
}
```
but there are a few important differences.
Slices store their values inline.  
They are thus unsized (i.e. dynamically sized) (`.$size_of()` is non-`const` for them).
However, references to slices are sized.
They are so-called fat pointers, i.e. the length and raw pointer both constitute the reference.

Slices are the only fundamentally unsized types.
Other compounds may only contain at most one unsized type,
and if they do, then they themselves are unsized.
Like slices, references to any unsized type are fat pointers.

To access the values of a slice,
the `[]` index operator may be used: *`value`*`[`*`index`*`]`,
where *`index`* is a value of an unsigned integer type
and *`value`* is a reference to a value of slice type.
Note that if you have a slice reference, 
it must be derefenced before indexing the slice directly.

Indexing a slice reference`T[]&` evaluates to `Result<T&, IndexBoundsError>`,
and indexing a mutable slice reference `T[]&mut` evaluates to `Result<T&mut, IndexBoundsError>`.
Thus, it is always bounds checked.
To [panic](#panicking) on an out-of-bounds index, simply `.unwrap()` 
the `Result` to get the `T&` or `T&mut`,
which can then be dereference to access.
To elimiate bounds checking, the `Result` can instead be `.unwrap_unchecked()` to get the `T&` or `T&mut` 
without checking if there was an error,
thus eliminating the bounds check.

Bounds checking can also be eliminated in many other safe ways.
Bounds checking is usually only a problem when it is done for many elements of a slice when it only needs to be done once.
For this case, multiple elements can be indexed using a slice pattern (see [patterns](#pattern-matching)),
or an iterator can be used, which will eliminate redundant bounds checking.

Slices can also be sliced to yield a smaller view of the original slice.
This is also done by the same `[]` indexing operator,
except now the syntax is *`value`*`[`*`range`*`]`,
where *`range`* is a value of [range](#range-literals) type.

Slicing a slice reference `T[]&` evaluates to `Result<T[]&, SliceBoundsError>`,
and slicing a mutable slice reference `T[]&mut` evaluates to `Result<T[]&mut, SliceBoundsError>`.

[Table of Contents](#table-of-contents)

### Array Types
In C*, there also arrays of a type,
which, like slices, are a contiguous collection of values of the same type,
but unlike slices, have a length known at compile time and not stored at runtime.
Thus, they are sized unliked slices.

The syntax for this type is *`type`*`[`*`size`*`]`,
where *`size`* is a const of an unsized integer type.

Arrays can also be indexed and sliced,
but since the length is known at compile time,
if the index or range is also known at compile time,
then indexing and slicing always succeeds at runtime 
(i.e. there is no `Result`) yielding another array, 
or else is a compile error.
The same syntax is used for indexing and slicing as is for slices.

To explicitly turn an array into a slice reference,
`.$cast<T[]>()` can be used.

[Table of Contents](#table-of-contents)

#### Tuple Types
In C*, you can also have a contiguous collection values of different types, i.e. a heterogenous array of sorts.
This is called a tuple and its length must be known at compile time.

The syntax for this type is `(`*`types`*`)`,
where *`types`* is a list of `,` comma-separated *`type`* s.
A trailing `,` comma is allowed.

The elements of a tuple can be accessed as fields like in a `struct`.
In fact, a tuple is syntax sugar for an anonymous `struct` 
with all public fields, though there is one caveat.
The fields of a tuple are decimal integer literals (the index),
which would not otherwise be allowed as an identifier for a field name.
Note that like `struct`s, tuple elements may be not layed out in memory in order.

[Table of Contents](#table-of-contents)

### User-Defined Compound Types
The user-defined compound types in C* are:
* [`struct` types](#struct-types)
* [`enum` types](#enum-types)
* [`union` types](#union-types)

They correspond to the item declarations of the same name.

[Table of Contents](#table-of-contents)

#### `struct` Types
See [`struct` declarations](#struct-declarations) for more.

[Table of Contents](#table-of-contents)

#### `enum` Types
See [`enum` declarations](#enum-declarations) for more.

[Table of Contents](#table-of-contents)


#### `union` Types
See [`union` declarations](#union-declarations) for more.

[Table of Contents](#table-of-contents)


## Destructive Moves
TODO

[Table of Contents](#table-of-contents)


## Expressions
Almost everything that is not a type in C* is an expression.
This includes all control flow constructs.

[Table of Contents](#table-of-contents)

### Literals
C* Literals: 
* [unit](#unit-literals)
* [bool](#boolean-literals)
* [int](#integer-literals)
* [float](#float-literals)
* [char](#character-literals)
* [string](#string-literals)
* [struct](#struct-literal)
* [tuple](#tuple-literalss)
* [array](#array-literals)
* [enum](#enum-literals)
* [union](#union-literals)
* [function](#function-literals)
* [closure](#closure-literals)
* [range](#range-literals)

[Table of Contents](#table-of-contents)

#### Unit Literals
In C*, every expression has a type.  Even statements that return "nothing",
they really return unit, or `()`.  
The type of this unit literal is also called unit and written `()` as well.

[Table of Contents](#table-of-contents)

#### Boolean Literals
There are two boolean literals of type `bool`: `true` and `false`.
These are actually enum variants of the `enum bool`.
See the [`bool` Type](#bool-type).

[Table of Contents](#table-of-contents)

#### Number Literals
In C*, number literals are composed of 4 (potentially optional) parts (in order):
* the integral part
* the floating part (optional)
* the exponent (optional)
* the suffix (optional)

For each of the integral part, floating part, and exponent, 
they contain an optional sign, optional base, 
and then a series of one or more digits.  
Note that each part may specify a different base.

The sign may be `+` for positive numbers, `-` for negative numbers, or nothing, which defaults to `+`.

The base and corresponding digits may be:
| Prefix |     Name    | Base |       Digits        |
| ------ | ----------- | ---- | ------------------- |
| none   | decimal     |  10  | `0-9`               |
| `0b`   | binary      |   2  | `0-1`               |
| `0o`   | octal       |   8  | `0-8`               |
| `0x`   | hexadecimal |  16  | `0-9`, `a-f`, `A-F` |

The series of digits may also be separated by
any number of `_` underscores between the digits.
It cannot begin or end with `_` underscores, however.

If there is a floating part, then a decimal point `.`
separates it from the preceeding integral part.
The floating part may not have a sign and is always positive (in itself).

If there is an exponent, then an `e` or `E` precedes it.

The (optional) suffix contains the type of number and a bit size.

The type of number may be:
* `u`: unsigned integer
* `i`: signed integer
* `f`: floating-point number

The bit size is usually a literal power of 2 number, 
but may be any positive integer for integer types.
It may also be a word whose bit size is architecture-dependent.

For integers (`u` and `i`), the common bit sizes are:
* `8`
* `16`
* `32`
* `64`
* `128`
* `size` (bit size necessary to store an array index)
* `ptr` (bit size necessary to store a pointer 
         or the difference between them)

For floats (`f`), the bit sizes are:
* `16`
* `32`
* `64`
* `128`

These suffixes are the primitive number types.
Thus, in total, they are (with their C equivalent for FFI):
| C*            | C                   |
| ------------- | ------------------- |
| `u8`          | `uint8_t`           |
| `i8`          | `int8_t`            |
| `u16`         | `uint16_t`          |
| `i16`         | `int16_t`           |
| `u32`         | `uint32_t`          |
| `i32`         | `int32_t`           |
| `u64`         | `uint64_t`          |
| `i64`         | `int64_t`           |
| `u128`        | `unsigned __int128` |
| `i128`        | `__int128`          |
| `usize`       | `size_t`            |
| `isize`       | `ssize_t`           |
| `uptr`        | `uintptr_t`         |
| `iptr`        | `intptr_t`          |
| `f16`         | `_Float16`          |
| `f32`         | `float`             |
| `f64`         | `double`            |
| `f128`        | `_Float128`         |

Integers always use 2's-complement
and floats always are IEEE 754 floating point numbers.

If the type is a float, then it must contain 
a `.` decimal point and a floating part.
If the type is an integer, then it must not.
Both can contain exponents, though for integers,
the exponent (in scientific notation) cannot cause
the integer to exceed its finite size.

If there is no suffix type, then the type is inferred.
If there is a `.` decimal point, then the type must be a float, and vice versa with integers.
If there is a `-` sign for the integral part,
then the type must be a float or a signed integer.
To infer the bit size of the number,
general type inference is used.
If it cannot be unambiguously inferred, 
then it is an error and the user must 
explicitly specify the suffix type.

[Table of Contents](#table-of-contents)

#### Character Literals
In C*, character literals are of type `char` and are denoted with single `''` quotes.
They are [unicode scalar values](https://www.unicode.org/glossary/#unicode_scalar_value),
which are slightly different from [unicode code points](https://www.unicode.org/glossary/#code_point).
This means they are always 32 bits on all architectures.

For the actual char literal within the quotes,
it may be any unicode scalar value, 
but some characters need to be or may be escaped.
The ascii values that must be escaped are:
* `\n`: newline
* `\r`: carriage return
* `\t`: tab
* `\0`: null char
* `\\`: backslash
* `\'`: single quote

Other ascii values may also be escaped as well using the syntax `\x7F`,
where `7F` is the hexadecimal value of the ascii character, 
from 0 to 127 (aka `0x7F`).
Thus it may only be two digits.

Unicode scalar values can also be escaped with the syntax `\u{7FFF}`.
The hexadecimal value is the 24-bit unicode character code.


Character literals can also be prefixed with a `b`: `b' '`,
in which case they are byte literals, i.e. a `u8`.
The required ascii escapes are the same, 
though the `\xFF` escape can now go up to 255 (aka `0xFF`),
and there may not be unicode escapes 
(since it's only a `u8` byte literal now).

[Table of Contents](#table-of-contents)

#### String Literals
There are multiple types of strings in C* owing to 
the inherent complexity of string-handling without incurring overhead. 
The default string literal type is `String`, which is UTF-8 encoded and 
wraps a `*[u8]`.  This is a borrowed slice type and can't change size. 
To have a growable string, there is the `StringBuf` type, 
but there is no special syntactic support for this owned string. 
`String`s are made of `char`s, unicode scalar values, when iterating 
(even though they are stored as `*[u8]`).

Then there are byte strings, which are just `*[u8]` and 
do not have to be UTF-8 encoded. 
String literals for this are prefixed with `b`, like `b"hello"`. 
The owning version of this is just a `Box<[u8]>` 
(notice the unsized slice use), and 
the growable owning version is just a `Vec<u8>`.

Furthermore, for easier C FFI, there is also `CString` and `CStringBuf`, 
which are explicitly null-terminated.  All other string types are 
not null-terminated, since they store their own length, 
which is way more efficient and safe. 
Literal `CString`s have a `c` prefix, like `c"/home"`.

And finally, there are format strings.  Written `f"n + m = {n + m}"`, 
they can interpolate expressions within `{}`.
Format, or `f`-strings, don't actually evaluate to a string, 
but rather evaluate to an anonymous struct that has methods to 
convert it all at once into a real string.  Thus, `f`-strings do not allocate.


For the character literals allowed in C* strings,
that depends on the string type, which are:
| Prefix |    Name     |             Type              |
| ------ | ----------- | ----------------------------- |
| none   | string      | `String`                      |
| `b`    | byte-string | `*[u8]`                       |
| `r`    | raw-string  | type without the `r`          |
| `c`    | c-string    | `CString`                     |
| `f`    | f-string    | anonymous struct with methods |

All of these string prefixes can be combined with each other,
except for `r` and `f`, since f-strings require escaping,
which goes against raw strings.

For `r` raw strings, no escapes are allowed.

For normal UTF-8 strings (which includes the `r`, `c`, and `f` modifiers), 
the string must contain [character literals](#character-literals), except there are no single `'` quotes anymore, 
double `"` quotes delimit strings, 
and double quotes must escaped (`\"`) instead of single quotes (`\'`).
Obviously the escapes don't apply to raw `r` strings.
For `f`-strings, braces must also be escaped: `\{` and `\}`,
since they are used to delimit expressions within the string.
And for `c`-strings, they must not contains any `\0` null characters.

For byte `b` strings, the string must contains [byte literals](#string-literals).
The other string modifiers apply in the same way,
and again, double quotes (`\"`) must be escaped instead of single quotes (`\'`).

[Table of Contents](#table-of-contents)

#### Struct Literals
Struct literals are literals that create a value of a struct type.
That is, if we have a struct `Example`:
```rust
struct Example {
    a: u32,
    b: f64,
    c: String,
}
```
then we can create a value of type `Example` with the struct literal
```rust
Example {
    a: 0,
    b: 0.0,
    c: "",
}
```
That is, we first have the struct type name, an open `{` brace,
the list of fields and their values, and then a closing `}` brace.
The fields are separate by `,` commas (a trailing `,` comma is allowed),
and `:` colons separate the field name and its value.

If the name of a field and its value expression are the same,
then the `:` colon and value may be omitted, like so:
```rust
let c = "";
Example {
    a: 0,
    b: 0.0,
    c,
}
```

Furthermore, `..` can be used to spread the fields of another struct into a struct literal, like so:
```rust
struct SmallExample {
    a: u32,
    b: f64,
}

let x = SmallExample {
    a: 0,
    b: 0.0,
};

Example {
    ..x,
    c: "",
}
```
Note that the struct type does not have to be the same,
but the fields that are being spread must match between the struct types in name and type.

[Table of Contents](#table-of-contents)

#### Tuple Literals
C* has tuples, but they are simply shorthand and syntax sugar for structs.
A tuple type is a finite, heterogenous list of types,
such as `(i32, usize, String)`,
and its field names are unsigned integers (`.0`, `.1`, and `.2` for this tuple).
This is the only difference between tuples and desugaring them to structs:
struct field names must be [valid C* identifiers](#identifiers),
but tuple field names begin with digits.
Otherwise, they are exactly the same.
The tuple type with 0 element types, `()`, is also valid,
but it is equivalent to the `()` unit type.

Tuple literals mirror tuple types.
The field names are unnamed (unlike [struct literals](#struct-literals)),
so it is just a `,` comma separated list of values of any type delimited by open `(` and close `)` parentheses.
There may be a trailing `,` comma separator,
and for 1-element tuple literals, this trailing `,` comma
is required to distinguish it from using `()` parentheses for associating general expressions.

[Table of Contents](#table-of-contents)

#### Array Literals
In C*, arrays are finite, homogenous lists of a single type.
There are delimited by open `[` and close `]` brackets,
as opposed to `()` parentheses for tuples.
Their values are also `,` comma separated.
Trailing `,` commas are allowed but never required, 
unlike in 1-element tuple literals.

Array types are denoted `[T; N]`, where `T` is any type
and `N: usize`.

[Table of Contents](#table-of-contents)

#### Enum Literals
In an enum, such as
```rust
enum Example {
    A,
    B(i32),
}
```
there are two possible forms of enum literals
depending on if the variant has any data or not.

In the case of the variant `A`, which has no data attached,
the enum literal `Example.A` (or just `A` if `A` is imported)
is a value of type `Example`.

In the case of the variant `B`, which has data attached,
the enum literal `Example.B` is a function of type `fn(i32): Example`
that returns the `B` variant with the given data attached.
Thus, `Example.B(0)` or `Example.B(100)` is normally written,
though the function can also be referred to by itself.

[Table of Contents](#table-of-contents)

#### Union Literals
Union literals are the same as struct literals
except only one field may be specified.

[Table of Contents](#table-of-contents)

#### Function Literals
In C*, there is very little difference between function declarations
and function literals (using them as values).

In function declarations, they are written
```rust
PUBLICITY fn FUNC_NAME GENERIC_ARGS ARGS = BODY_EXPRESSION
```
such as
```rust
fn foo<T>(t: T): T = { t * t }
```
In function literals, there is no more publicity modifier
and the function name is optional, 
since it usually specified as the let binding instead if named:
```rust
fn<T>(t: T): T = { t * t }
```
Furthermore, type inference of function arguments and return type
is allowed for function literals, since they cannot be public declarations.
If the types are ambiguous, though, type annotations are still required of course.

The type of a function literal is unique and opaque,
but can be casted to a function pointer like `fn(T): T`.

Note that annotations like `@abi("C")` can still be applied
to function literals just like function declarations.

[Table of Contents](#table-of-contents)

#### Closure Literals
Closure literals are very similar to function literals—in fact, 
they are a superset of function literals—except they also have a closure context.
That is, they can "enclose" over values in the current scope.

The syntax for a closure literal is simply a normal function literal with an anonymous struct literal, the closure context, following the `fn`.

The closure context is an anonymous struct literal
in that it has no named struct type. That is, instead of
```rust
Example {a: 0, b: 0.0, c: ""}
```
it would just be
```rust
{a: 0, b: 0.0, c: ""}
```

The fields in this closure context struct
are then immediately available within the function body
as if they were immediately destructured.

The type of a closure literal is unique and opaque.
Unlike function literals (in which there is no context),
the type of closure literals cannot be casted to a bare function pointer.
The closure function corresponds to a method on the closure context struct,
and as such, cannot be casted to a function pointer
since there is an implicit `*Self` argument.
Thus, the only way to accept a closure as an argument is by using generics, 
which ensures there is no pointer indirection
and the closure can be inlined into the call site.

[Table of Contents](#table-of-contents)

#### Range Literals
Range literals denote an integer range.
There are a few different forms of ranges,
which we will define in terms of set interval notation
as to what integers the range includes.

|  Range  |   Interval   |
| ------- | ------------ |
| `a..b`  | `[a, b)`     |
| `a..`   | `[a, ∞)`     |
| `..b`   | `(-∞, b)`    |
| `..`    | `(-∞, ∞)`    |
| `a..=b` | `[a, b]`     |
| `a..+b` | `[a, a + b)` |
| `..=b`  | `(-∞, b]`    |

[Table of Contents](#table-of-contents)

### Function Calls
TODO

[Table of Contents](#table-of-contents)

#### Method Calls
TODO

[Table of Contents](#table-of-contents)

### Blocks
TODO

[Table of Contents](#table-of-contents)

### Control Flow
TODO

[Table of Contents](#table-of-contents)

#### Pattern Matching
TODO

[Table of Contents](#table-of-contents)

#### Conditionals
TODO

[Table of Contents](#table-of-contents)

##### `match`
TODO
patterns

[Table of Contents](#table-of-contents)
##### `if`
`if` evaluates a block conditionally.

The syntax for this is *`expr`*`.if `*`block`*.
It is syntax sugar for a `match`: 

*`expr`*`.match { true => `*`block`*`, false => (), } `

[Table of Contents](#table-of-contents)

##### `else`
An `else` may immediately follow an `if` expression,
in which case the whole thing becomes an if-else expression.

The syntax for this is *`expr`*`.if `*`block `*`else`*` block`*.
It is syntax sugar for a `match`:

*`expr`*`.match { true => `*`block`*`, false => `*`block`*`, } `,
where the *`block`* are in the same order as in the if-else expression.

Normally the *`expr`* following an `else` must be a *`block`*,
but it can also be another if expression.

[Table of Contents](#table-of-contents)

#### Labels
TODO

[Table of Contents](#table-of-contents)

#### Loops
TODO

[Table of Contents](#table-of-contents)

##### `while`
TODO

[Table of Contents](#table-of-contents)

##### `for`
A `for` loop allows you to iterate through an iterator.
An iterator is just a type `Iter` that has 
a `fn next(self: Self) -> Option<T>` method, 
where `T` is the element type we are iterating over.

The syntax for this is *`expr`*`.for`*` binding block`*,
where the *`expr`* is a value that has 
a `.into_iter()` method returning the iterator,
the *`binding`* is the binding for the element name,
and *`block`* is the block of the `for` loop.

It is syntax sugar for:

`{ let iter = `*`expr`*`.into_iter(); (true).while { let `*`binding `*`= iter.next().?; `*` block`*` } }`

[Table of Contents](#table-of-contents)

#### `defer`
TODO

[Table of Contents](#table-of-contents)

#### Error Handling
TODO

[Table of Contents](#table-of-contents)

##### `try`
TODO
error handling

[Table of Contents](#table-of-contents)

##### Panicking
TODO

[Table of Contents](#table-of-contents)

### Operators
| Operator | Arity  | In-Place |    Type    |       Description        |     Example      |
| -------- | -----  | -------- | ---------- | ------------------------ | ---------------- |
| `+`      | binary | no       | arithmetic | addition                 | `2 + 2 `, `4.0 + 2.0`  |
| `-`      | binary | no       | arithmetic | subtraction              | `2 - 2`, `4.2 - 2.2`  |
| `*`      | binary | no       | arithmetic | multiplication           | `2 * 2`, `4.0 * 2.0`  |
| `/`      | binary | no       | arithmetic | division                 |  `2 / 2`, `4.0 / 2.0` |
| `%`      | binary | no       | arithmetic | modulus                  |  `2 % 2`              |
| `-`      | unary  | no       | arithmetic | negation                 |  `-a`                 |
| `==`     | binary | no       | relational | equal to                 |  `a == 2`             |
| `!=`     | binary | no       | relational | not equal to             |  `a != 2`             |
| `>`      | binary | no       | relational | greater than             |  `a > 2`              |
| `<`      | binary | no       | relational | less than                |  `a < 2`              |
| `>=`     | binary | no       | relational | greater than or equal to |  `a >= 2`             |
| `<=`     | binary | no       | relational | less than or equal to    |  `a <= 2`             |
| `&&`     | binary | no       | logical    | and                      |  `a && b`             |
| `\|\|`   | binary | no       | logical    | or                       |  `a \|\| b`           |
| `!`      | unary  | no       | logical    | not                      |  `!a`                 |
| `&`      | binary | no       | bitwise    | and                      |                       |
| `\|`     | binary | no       | bitwise    | or                       |                       |
| `^`      | binary | no       | bitwise    | xor                      |                       |
| `~`      | unary  | no       | bitwise    | not                      |                       |
| `<<`     | binary | no       | bitwise    | left shift               |                       |
| `>>`     | binary | no       | bitwise    | right shift              |                       |
| `[]`     | binary | no       | indexing   | index a slice            | `a[1]`                |
| `+=`     | binary | yes      | arithmetic | addition                 |                       |
| `-=`     | binary | yes      | arithmetic | subtraction              |                       |
| `*=`     | binary | yes      | arithmetic | multiplication           |                       |
| `/=`     | binary | yes      | arithmetic | division                 |                       |
| `%=`     | binary | yes      | arithmetic | modulus                  |                       |
| `&&=`    | binary | yes      | logical    | and                      |                       |
| `\|\|=`  | binary | yes      | logical    | or                       |                       |
| `&=`     | binary | yes      | bitwise    | and                      |                       |
| `\|=`    | binary | yes      | bitwise    | or                       |                       |
| `^=`     | binary | yes      | bitwise    | xor                      |                       |
| `<<=`    | binary | yes      | bitwise    | left shift               |                       |
| `>>=`    | binary | yes      | bitwise    | right shift              |                       |
| `++`     | unary  | yes      | arithmetic | increment                |                       |
| `--`     | unary  | yes      | arithmetic | decrement                |                       |

Arithmetic operators operate on expressions of the same number type 
and evaluate to the same number type as well.
`.@cast<>()` can be used here when the operands are of different type.
`%`, `++`, and `--` are not allowed for floats.

Relational operators operate on expressions of the same type
and evaluate to a `bool`.

Logical operators operate on `bool` expressions and evaluate to a `bool`.

Bitwise operators operate on expressions of the same number type
and evaluate to the same number type as well.
The except is the shift operators: `<<`, `>>`, `<<=`, and `>>=`,
whose right operand is the minimum unsigned integer type
that may be shifted by (i.e. the bit size of the left operand).
Otherwise it would be UB.
For example, if the left operand is `u64`, then the right operand is `u6`.
For signed integer types as the left operand, 
the sign bit is extended when shifting.

For indexing operators, see [slices](#slice-types) 
and [arrays](#array-types), which may be indexed.

In-place *`operator`*`=`s evalute to `()`.

[Table of Contents](#table-of-contents)

## Generics
Generics in C* are always monomorphized.

TODO

[Table of Contents](#table-of-contents)

## Constant Evaluation
TODO

[Table of Contents](#table-of-contents)

## Builtin Functions
TODO

[Table of Contents](#table-of-contents)

## List of Annotations
TODO

[Table of Contents](#table-of-contents)

## Current Restrictions and Unimplemented Features
The following features are currently unimplemented:
* non ASCII source code (normally UTF-8 is allowed)
* targets other than `x86_64-linux-gnu`
* user-defined `mod`ules, except for: 
  * the implicit single-file module 
  * those defined by the compiler or in the standard library
* `use` declarations except for the standard prelude, 
  which is implicitly `use`d
* strings and characters except for byte ones, i.e.:
  * `b`yte string literals
  * `b`yte literals
* type aliases except for:
  * those implemented by the compiler
* most attributes except for:
  * `@extern` and `@abi("C")` for functions (for calling libc)
  * `@impl(Clone)`
  * `@impl(Copy)`
  * all other annotations are allowed but ignored
* `...` trailing varargs parameter for `@extern @abi("C")` functions 
  unless it's needed for the standard library (using libc)
* `union`s
* non-temporary unsized types (slices must be references)
* const generics
* const evaluation other than constant literals

[Table of Contents](#table-of-contents)


_____________________________________

## Statements and Expressions

[Table of Contents](#table-of-contents)

### Statements 
Due to the expression oriented nature of C* all control flow statements are
themselves expressions.

[Table of Contents](#table-of-contents)

#### If-Else Statements
If-Else statements execute one of two cases. The first consists of typical
C-style semantics wherein we have:
```c
if (expr1)
    statement1
else
    statement2
```
Both `statement1` and `statement2` must evaluate to the unit type. Like
C the `else` part of the If-Else control flow block is optional. In addition to
the C-style control flow we also can have:
```c
if (expr1)
    expr2
else
    expr3
``` 
In both cases the expressions in the `if` statement are evaluated and in the case
they evaluate to a non-zero value the flow of execution continues down that
path otherwise the body of the `else` statement is executed. 

C* utilizes the same mechanism to eliminate ambiguity relating to a "dangling-else". An `else` is grouped to the nearest `if`. In the case of:
```rust
let i: i32 = 6;
let j: i32 = 7;

if(i > 4)
    if(j > i)
        println!("j is greater than i!");
    else
        println("j is less than or equal to i!");
```
While the indentation and print statements make clear which `if` the `else`
clause is grouped with it should be clear that barring the use of additional
brackets to direct control flow the `else` is grouped to the nearest `if` above
it.

[Table of Contents](#table-of-contents)

#### For Statements
For statements can execute over a range in the case of: 
```rust
for season in seasons.iter()
    println!(season);
```
In addition to the use of an explicit iterator it is also possible to use a range literal to bound the execution of the body of a for loop in the case of:
```rust
let mut day_ = 1;
for x in 1..365{
    println!("Day {} of 365", x);
}
```

[Table of Contents](#table-of-contents)

#### While Statements
Execution of the body of a while statement continues until the expression labeled `expr1` evaluates to zero. For example:
```c
while(expr1){
    statement1;
}
```
Similiar to `if` statements due to the expression oriented nature of C* `statement1` must evaluate to the unit type and it is possible to replace `statement1` with `expr2`.

[Table of Contents](#table-of-contents)

#### Defer
To aid in resource handling, C* has a `defer` keyword. 
`defer` defers the following statement or block until the function returns, 
but will run it no matter where the function returns from 
(but not `panic`s/`abort`s) (actually, the `defer` will run when 
its block exits, but its easier to just think about function blocks first).

For example, you can use this to ensure 
you correctly clean up resources in a function:
```rust
extern "C" fn open(path: *u8, flags: i32): i32;
extern "C" fn close(fd: i32): i32;

fn open_file_in_dir(dir: *[u8], filename: *[u8]): Result<i32, String> try = {
    let mut path = Vec.new(Mallocator());
    defer path.free();
    try {
        if (dir.len() > 0) {
            path.extend(dir).?;
            path.push(b'/').?;
        }
        path.extend(filename).?;
        path.push(0).?;
    }.map_err(fn(_) "alloc error").?;
    
    let path = path.as_ptr();
    let fd = open(path, O_RDWR).match {
        -1 => Err("open failed"),
        fd => fd,
    }.?;
    defer println(f"opened {fd}");
    return fd;
}
```

In this example, you have to allocate a path to store 
the directory and filename you combine, and then open 
that path and return the file descriptor if it was successful. 
You have to clean up the memory allocation, though, and do that 
while still handling all the allocation errors and the open error. 
The latter can be done elegantly with `try` and `.?`, 
but if you mix in the `path.free()`, you'd have to run it before every 
error return, which means you have to duplicate it and not use `.?` anymore.

Instead, you can use `defer` for this.  No matter where you 
return from the function, it will run its statement right before that. 
You can also use `defer` for any statement, not just resource cleanup, 
like logging for example.

However, sometimes you want to cancel a `defer`:
```rust
struct FilePair {
    fd1: i32,
    fd2: i32,
}

fn open_two_files(path1: *[u8], path2: *[u8]): Result<FilePair, String> try = {
    let fd1 = open_file_in_dir(b"", path1).?;
    close: defer close(fd1);
    let fd2 = open_file_in_dir(b"", path2).?;
    close: defer close(fd2);
    println(f"opened {fd1} and {fd2}");
    undefer close;
    FilePair {fd1, fd2}
}
```

In this example, you want open two files and return them if successfull. 
If only one is successful, though, that's an error and you 
should close the first one before returning the error. 
In order to do that cleanly, you can use the `undefer` keyword, 
which cancels an earlier labeled `defer`, in this case labeled `close`.

`defer` and `undefer` are actually syntax sugar 
for something a bit more low-level and wordy:
```rust
fn open_two_files(path1: *[u8], path2: *[u8]): Result<FilePair, String> try = {
    let fd1 = open_file_in_dir(b"", path1).?;
    let close1 = {fd1} fn() close(fd1);
    let close1 = close1.@defer());
    let fd2 = open_file_in_dir(b"", path2).?;
    let close2 = {fd1} fn() close(fd1);
    let close2 = close2.@defer());
    println(f"opened {fd1} and {fd2}");
    let close = [close2, close1];
    close.undo();
    FilePair {fd1, fd2}
}
```

That is, `.@defer()` places the closure on the stack and 
returns a `Defer` struct, which can be undone with `Defer.undo()` 
(`[Defer].undo()` just maps `Defer.undo()` over the array). 
`Defer.undo()` sets a bit in the `Defer` struct that it's been undone. 
Then when the stack unwinds, any none-undone `Defers` on the stack are run.

[Table of Contents](#table-of-contents)

### Expressions and Operators

[Table of Contents](#table-of-contents)

#### Unary Operators
Unary operators are operators that can act on an expression. C* uses the unary operators "-" and "!" to represent negation and the logical not repectively. "-" negates a number literal such as 
```rust
let x = -2
```
The logical not "!" represents negation for bool literals or boolean expressions such as
```rust
let a = true
let b = !a
```
where b returns the value of false. 

[Table of Contents](#table-of-contents)

#### Binary Operators
A binary operator acts on two expressions and can be show as follows:

Binary operator = expr * operator * expr

[Table of Contents](#table-of-contents)

##### Assignment operator
The assignment operator stores values into vairables. It uses the keyword "let" and the = symbol so that the left side variable stores the expression on the right.

Ex. 
``` rust
let a = 23 // a stores the value 23
```

[Table of Contents](#table-of-contents)

##### Arithmetic Operator
- The addition operator "+" adds two values of the same type. Automatic type conversion is applied when adding two number literals and can also be applied to string addition. 

Ex. 
```rust
1 + 2 // 3
12.3 + 10 // 22.3
"string" + "test" // "stringtest"
```
- The subtraction operator "-" subtracts two values of the same type. Automatic type conversion is applied when adding two number literals.

Ex. 
```rust
1 - 2 // -1
12.3 - 10 // 2.3
```

- The multiplication operator "*" multiplies two values of the same type. Automatic type conversion is applied when adding two number literals. 

Ex. 
```rust
1 * 2 // 2
12.3 * 10 // 123
```

- The division operator "/" divides two values of the same type. Automatic type conversion is applied when adding two number literals. 

Ex. 
```rust
1 / 2 // .5
12.3 / 10 // 1.23
```

- The modulus operator "%" takes the modulus of two values of the same type. Automatic type conversion is applied when adding two number literals. 

Ex. 
```rust
1 % 2 // 1
12.3 % 10 // 2.3
```

[Table of Contents](#table-of-contents)

##### Relational Operators
Relational operators represent how the operands relate to each other. Each expression using a relational operator has two values as inputs and outputs either true or false. The relational operators are: ==, !=, <, >, <=, >=, &, |.

```rust
1 < 2 // true
1 > 2 // false
1 != 2 // true
1 == 2 // false
true | false // true
true & false // false
```

[Table of Contents](#table-of-contents)

### Functions
Functions are a type of statement that can be declared one of two ways: 
```rust
fn name(parameters): return type = body
```

or 

```rust
fn name(parameters): return type = { body }
```

It takes in a list of parameters and returns a value based on the expression. Functions can be written with or without specifying the return type.

Ex. 
```rust
fn hello(): string = "hello world"

fn adding(a, b): = { return a + b }
```

[Table of Contents](#table-of-contents)

### Pattern Matching
Instead of having a `switch` statement like in C, 
C* has a generalized `match` statement, which can be used to match 
many more expressions, including integers (like in C), `enum` variants, 
dereferenced pointers, slices, arrays, and strings. 
Also, there is no fall-through, but `match` cases can be combined explicitly.

Furthermore, just like you can destructure to 
pattern match in a `match` statement, you can also do the same 
as a general statement, like in a `let`.  It's like an unconditional `match`.

```rust
let cow = CowString::Borrowed("🐄");
let len = match cow {
    Borrowed(s) => s.len(),
    Owned(s) => s.len(),
};
let String {ptr, len} = "🐄";
```

Note that string literals are of the `String` type similarly defined as above,
and you can redeclare/shadow variables like `len`.

[Table of Contents](#table-of-contents)

### Methods
C* has associated functions and simple methods, 
though these are largely syntactic sugar. 
To declare these for a type, simply write:

```rust
struct Person {
    first_name: String,
    last_name: String,
}

impl Hello {

    fn new(first_name: String, last_name: String): Self = {
        Self {first_name, last_name}
    }
    
    fn say_hi1(self: Self) = {
        print(f"Hi {self.first_name} {self.last_name}");
    }
    
    fn say_hi1(self: *Self) = {
        print(f"Hi {self.last_name}, {self.first_name}");
    }
    
    fn remove_last_name(self: *mut Self) = {
        self.last_name = "";
    }
    
}

fn main() {
    let mut person = Person.new("Khyber", "Sen");
    
    {
        person.say_hi1();
        person.&.say_hi2();
        person.&mut.remove_last_name();
        person.say_hi1();
    }
    {
        Person.say_hi1(person);
        Person.say_hi2(person.&);
        Person.remove_last_name(person.&mut);
        Person.say_hi1(person);
    }
}
```

In this example, we first declared a `struct Person`, 
and then an `impl` block for `Person` to define 
methods/associated functions for it. 
Note that this `impl` block can be anywhere, even in other modules.

In the `impl` block, we first declared an associated function `Person.new`, 
which is just a normal function but namespaced to `Person`. 
Similarly, the other three methods are just normal functions, too, 
as seen when we call them explicity in the second block in `main`. 
But we can also use `.` syntax to call them, 
which just allows us to explicitly name `Person`.

Inside an `impl` block, we can also use the `Self` type 
as an alias to the type being implemented. 
This is especially useful with generics.

Note that the `.&` and `*Self` are explicit, 
because we wan't these kinds of possible costs to be noted explicitly. 
For example, `Person.say_hi1` takes `Self` by value, 
which means it must copy the `Person` every time. 
If `Person` were a much larger struct, 
this could be very expensive and we don't want to hide that information. 
Also, the difference between `.&` and `.&mut` 
is explicit to make mutability explicit everywhere.

[Table of Contents](#table-of-contents)

### Postfix
Most unary operators and keywords can be used postfix as well.

* `.if {}`
* `.if {} else {}`
* `.match {}`
* `.for {}`
* `.*` for dereference
* `.&` for pointer to
* `.&mut` for mutable pointer to
* `.!` for negation
* `.@()` for builtins, like as (casting), size_of, etc.
    * `.@cast(T)`: convert to `T`, like an int to float cast, or an int widening cast
    * `.@ptr_cast<T>()`: cast a pointer like `*T` to `*U`
    * `.@bit_cast<T>()`: reinterpret the bits, like from `u32` to `f32`
    * `.@size_of()`: size of a type
    * `.@align_of()`: alignment of a type
    * `.@call(func)`: call a function or closure in a unified syntax

Combined with everything [being an expression](#expression-oriented), 
[`match`](#pattern-matching), and having [methods](#methods), 
this makes it much easier to write programs in a very fluid style.

Furthermore, and perhaps most importantly in practice, 
this makes autocompletion vastly better, because an IDE can narrow down 
what you may type next based on the type of the previous expression. 
This can't be done with postfix operators and functions (rather than methods).
You get to think in one forward direction, rather than 
having to jump from some prefix keywords to some postfix methods and fields.

[Table of Contents](#table-of-contents)

## Slices
C* also has slices.  These are a pointer and length, 
and are much preferred to passing the pointer and length separately, 
like you usually have to do in C.

They are implemented like this (not actually, but similarly):
```rust
struct Slice<T> {
    ptr: *T,
    len: usize,
}
```
But they can be written as `*[T]`.  Actually, slices are unsized types, 
so their type is just `[T]`, but usually `*[T]` is used and that 
is what's equivalent to the above `Slice<T>`.

Unlike pointers like `*T`, slices can be indexed.  By default, 
using the indexing operator, this is bounds checked for safety, 
but there are also unchecked methods for indexing.  Usually, though, 
bounds checking can be elided during sequential iteration, 
so the performance hit is minimal, and can be side-stepped if really needed.

Slices can also be sliced to create subslices by indexing them with 
a range (e.x. `[1..10]` or `[1..]`). 
Again, this is bounds checked by default.

[Table of Contents](#table-of-contents)

## Monadic Error-Handling
There are no exceptions in C*, just like C. 
It uses return values for error handling, similarly to C. 
But C* has much better support for this using the `Option` and `Result` types.

The definitions of these types are:
```rust
struct Option<T> {
    None,
    Some(T),
}

struct Result<T, E> {
    Ok(T),
    Err(E),
}
```
That is, `Option` represents an optional value, and `Result` 
represents either a successful `Ok` value or an error `Err` value.

There is special syntactic support for using these two monadic types 
for error-handling using the `.?` postfix operator in `try` blocks:
```rust
struct IndexError {
    index: usize,
}

fn get_by_index<T>(a: *[T], i: usize): Result<T, IndexError> {
    if (i < a.len()) {
        Ok(a[i])
    } else {
        Err(IndexError {index: i})
    }
}

struct IndexPair {
    first: usize,
    second: usize,
}

fn get_two_by_index<T>(a: *[T], i: usize, j: usize): Result<T, IndexError> try = {
    let first = try {
        get_by_index(a, i).?
    };
    let second = get_by_index(a, j).?;
    IndexPair {first, second}
}
```

This desugars to
```rust
fn get_two_by_index<T>(a: *[T], i: usize, j: usize): Result<T, IndexError> ={
    let first = try {
        get_by_index(a, i).match {
            Ok(i) => i,
            Err(e) => return Err(e),
        }
    };
    let second = get_by_index(a, j).match {
        Ok(i) => i,
        Err(e) => return Err(e),
    }
    Ok(IndexPair {first, second})
}
```

As you can see, without the try `.?` operator and `try` blocks, 
doing all the error handling with just `match` quickly becomes tedious. 
This is also kind of like a monadic `do` notation, except it is in C* 
limited to just the monads `Option<T>`, and `Result<T, E>` (over `T`).

Note also that `try` blocks can be specified at the function level 
as well as normal blocks.

[Table of Contents](#table-of-contents)

### Uncatchable Panics
While monadic error-handling with `Option` and `Result` is usually superior, 
there are still cases where you have unrecoverable errors 
(maybe you don't want to handle out of memory conditions), 
or where you'd rather just end the program than handle the error. 
In this case, you can `panic`, which will 
print an error message and immediately `abort`.

To do this with an `Option` or `Result`, 
you can just call `.unwrap()`, which will panic if 
it was `None` or `Err` and return the `Some` or `Ok` value.

There is no language-supported unwinding. 
`abort` is immediately called after a panic, and only the OS cleans things up.
Nothing is stopping you from calling `setjmp` and `longjmp` from C, 
but no unwinding of `defer` statements is done, 
and it may result in undefined behavior.  There is no undefined behavior, 
however, in a normal panic because you just simply `abort`.

[Table of Contents](#table-of-contents)

## Operator Precedence
The table below shows the operator precedence for binary and unary operators from lowest precedence to highest precedence. 

| Operator       | Description                    |    Associativity     |
| -----------    | ---------------------------    | ---------------- |
| ;  | sequencing                           |  Left    |
| =  | assignment                           |  Right   |
| .  | access                               |  Left    |
| |  | or                                   |  Left    |
| &  | and                                  |  Left    |
| == !=  | equality/inequality              |  Left    |
| < > <= >=  | comparison                   |  Left    |
| +-| addition/subtraction                  |  Left    |
| */ | multiplication/division              |  Left    |
| -  | negation                             |  Right   |
| !  | logical NOT                          |  Right   |
| ?  | conditional                          |  Left    |

In C* generics have a higher precedence than comparison thus removing ambiguity from "< >".

[Table of Contents](#table-of-contents)

## Examples

[Table of Contents](#table-of-contents)

### GCD
Here is how you write simple algorithms like GCD in C*:
```rust
fn gcd(a: i64, b: i64): i64 = {
    (fn gcd(a: u64, b: u64): u64 = {
        match b {
            0 => b,
            _ => gcd(b, a % b),
        }
    })(a.abs(), b.abs()).@cast(i64)
}
```

[Table of Contents](#table-of-contents)

### Systems Programming
Here is an example program in C* for part of a simple HTTP/1.0 server, 
equivalent to part0 of hw3 in Jae's OS class 
(https://gist.github.com/RyanLee64/hash-redacted). 
It showcases many of C*'s notable features, 
like enums, methods, generics, defer, expression-orientedness, 
postfix operators, pattern matching, closures, monadic error handling, 
and byte, c, and format strings.

That code (the ported part) is ~230 LOC, while the C* below is only ~80 LOC, 
and it is more correct in error handling and edge cases, 
faster in places (though IO dominates here), and the business logic 
stands out more (while less important aspects like errors, resource cleanup, 
allocations, and string handling stay in the background). 
That is, C* allows you to be simulatenously more expressive 
while still staying correct and explicit, 
and the performance is just as good if not better.

```rust
enum Status {
    Ok,
    NotImplemented,
    BadRequest,
    // rest skipped for brevity
}

struct RequestLine {
    method: *[u8],
    uri: *[u8],
    version: *[u8],
}

impl RequestLine {
    fn check(self: *Self): Result<(), Status> try = {
        let Self {method, uri, version} = self.*;
        match (method, version) {
            (b"GET", b"HTTP/1.0" | b"HTTP/1.1") => {},
            _ => Err(Status.NotImplemented).?,
        }
        if uri.starts_with(b'/').! || uri.equals(b"/..") || uri.contains(b"/../") {
            Err(Status.BadRequest).?;
        }
    }
}

fn main(): Result<(), AnyError> try = {
    let (port, web_root) = std.env.argv().match {
        [_, port, web_root] => (port.parse<u16>().?, web_root),
        [program, ...] => Err(f"usage: {program} <server_port> <web_root>").?,
    };
    let server_socket = Socket.new(PF_INET, SOCK_STREAM, IPPROTO_TCP).?;
    defer server_socket.&.close();
    server_socket.&.bind(SocketAddr {
        family: AF_INET,
        addr: InetAddr {
            addr: INADDR_ANY.to_be(),
        },
        port: port.to_be(),
    }).?;
    server_socket.&.listen(5).?;
    let mut request_line_buf = Vec.new();
    defer request_line_buf.free();
    let mut line_buf = Vec.new();
    defer line_buf.free();
    loop try {
        let client_socket = server_socket.&.accept().?;
client_socket_close:
        defer client_socket.&.close();
        let mut client_stream = fdopen(client_socket.fd, c"r").?;
        undefer client_socket_close; // stream (`FILE *` in C) takes ownership
        defer client_stream.&.close();
        let line_or_status = try {
            // read and parse request line
            let line = client_stream.&mut.read_line(buf.&mut)
                .map_err(fn(_) Status.BadRequest).?
                .split(fn(b) " \t\r\n".contains(b)).match {
                    [method, uri, version] => RequestLine { method, uri, version },
                    _ => Err(Status.NotImplemented).?,
                };
            line.&.check().?;
            // read headers, skip them
            loop {
                client_stream.&mut.read_line(buf.&mut)
                    .map_err(fn(_) Status.BadRequest).?
                    .match {
                        "\n" | "\r\n" => break,
                        _ => {},
                    }
            }
            line
        }
        let (line, status) = match line_or_status {
            Ok(line) => (line, Status.Ok),
            Err(status) => (RequestLine { method: b"", uri: b"", version: b"" }, status),
        };
        client_socket.write(f"HTTP/1.0 {status.code()} {status.reason()}\r\n\r\n").?;
        match line_or_status {
            Ok(_) => handle_request(web_root, line.uri, client_socket).?,
            Err(_) => client_socket.write(f"<html><body>\n<h1>{status.code()} {status.reason()}</h1>\n</body></html>").?;
        }
        eprintln(f"{client_socket.addr} \"{line.method} {line.uri} {line.version}\" {status.code()} {status.reason()}").?;
    }
}
```

[Table of Contents](#table-of-contents)


