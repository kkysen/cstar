# C* - Language Reference Manual

| Name        | UNI     |       Role       |
| ----------- | ------- | ---------------- |
| Shannon Jin | sj2802  | Manager          |
| Khyber Sen  | ks3343  | Language Guru    |
| Ryan Lee    | dbl2127 | System Architect |
| Joanne Wang | jyw2118 | Tester           |

## Table of Contents
1. Overview
2. Lexical Conventions
    - Comments
    - Identifiers
    - Operators
    - Keywords
    - Separators
    - Literals
        - String
        - Int
        - Float
        - Char
        - Boolean
        - Unit
        - Struct
        - Tuple
        - Closure
        - Function
        - Range
3. Algebraic Data Types
    - Structs
4. Generics
5. Statements and Expressions
    - Statements
        - If Else Statements
        - For Statements
    - Expressions and Operators
        - Unary Operators
        - Binary Operators
        - Relational Operators
    - Function Class
    - Assignment
    - Pattern Matching
    - Postfix
6. Slices
7. Monadic Error Handling
8. Classes
9. Standard Library
    - Lists
    - Strings
10. Operator Precedence
11. Examples

## Overview
C* is a general-purpose systems programming language. It is between the level of C and Zig on a semantic level, and syntactically it also borrows a lot from Rust (pun intended). It is meant primarily for programs that would otherwise be implemented in C for the speed, simplicity, and explicitness of the language, but want a few simple higher-level language constructs, more expressiveness, and some safety, but not so many overwhelming language features and implicit costs like in Rust, C++, or Zig.

It has manual memory management (no GC) and uses LLVM as its primary codegen backend, so it can be optimized as well as C, or even better in cases. All of C*'s higher-level language constructs are zero-cost, meaning none of those features give it any overhead over C, which often lead to a highly-optimized style where in C you would take less efficient shortcuts (e.x. function pointers and type-erased generics) and use dangerous constructs like goto. In the future, it may also have a C backend so that it can target any architecture where there is a C compiler.

While a general-purpose language, C* will probably have the most advantages when used in systems and embedded programming. It's expressivity and high-level features combined with its relative simplicity, performance, and explicitness is a perfect match for many of these low-level systems and embedded programs.


## Lexical Conventions
### Comments
C* implements single-line, multi-line and structural comments. Tokens followed by ```//``` are considered single line comments and tokens followed by ```/*``` are considered multi-line comments. C* also has an additional structural comment ```/-``` which will comment out the next item, whether that be the next expression, the next line, or the next function.
/// are doc comments

Example:
```
// This is a regular single line comment

/* This is a multiline comment
Everything inside here is commented out until "*/"
*/

/- let x = 25 //this comments out the entire let expression
```


### Identifiers
All identifiers in C* must be created from ASCII letters and decimal digits. Identifiers may contain underscore but must begin with a letter. They can not be a C* keyword.

Examples:
```rust=
//valid identifier
let validWord = 2
fn get_num(): {}

//invalid identifier
let 2words = 2
fn static(): = {}
```

### Operators
| Operator       | Description                    |     Example      |
| -----------    | ---------------------------    | ---------------- |
| +  | binary arthmetic addition                  | 2+2, 4.0+2.0     |
| -  | binary arithmetic subtraction              | 2-2, 4.2-2.2     |
| *  | binary arithmetic multiplication           | 2 * 2, 4.0 * 2.0 |
| /  | binary arithmetic division                 |  2/2, 4.0/2.0    |
| %  | binary arithmetic modulus                  |  2%2             |
| >  | binary relational greater than             |  a>2             |
| <  | binary relational less than                |  a<2             |
| >= | binary relational greater than or equal to |  a>=2            |
| <= | binary relational less than or equal to    |  a<=2        |
| == | binary relational equal                    |  a==2        |
| != | binary relational not equal                |  a!=2        |
| -  | unary negation                             |  -a          |
| && | binary logical AND                         |  a && b      |
| || | binary locical OR                          |  a || b      |
| !  | unary locial NOT                           |  !a          |
| ?  | 

### Keywords
Keywords are reserved identifiers that cannot be used as regular identifiers for other purposes. 
C* keywords:
- for, if, else, return, int, float, char, void, let, match, defer, break, label (add more)

### Separators
| Separator | Description | 
| --------- | ----------- |
| (         | Left parenthesis for expression |
| )         | Right parenthesis for expression |
| {         | Left bracket for function |
| }         | Right bracket for function |
| <         | Left arrow for generics |
| >         | Right arrow for generics |
| ;         | Semicolon to separate expressions |
| ,         | Comma to separate elements |

### Literals
C* Literals: string, int, float, char, boolean, unit, struct, tuple, closure, function, range

#### String Literals
There are multiple types of strings in C* owing to the inherent complexity of string-handling without incurring overhead. The default string literal type is String, which is UTF-8 encoded and wraps a *[u8]. This is a borrowed slice type and can't change size. To have a growable string, there is the StringBuf type, but there is no special syntactic support for this owned string. Strings are made of chars, unicode scalar values, when iterating (even though they are stored as *[u8]). chars have literals like c'\n'.

Then there are byte strings, which are just *[u8] and do not have to be UTF-8 encoded. String literals for this are prefixed with b, like b"hello" (and for char byte literals, a b prefix, too: b'c'). The owning version of this is just a Box<[u8]>.

Furthermore, for easier C FFI, there is also CString and CStringBuf, which are explicitly null-terminated. All other string types are not null-terminated, since they store their own length, which is way more efficient and safe. Literal CStrings have a c prefix, like c"/home".

And finally, there are format strings. Written `f"n + m = {n + m}"`, they can interpolate expressions within {}. Types that can be used like this must have a format method (might change). Format, or f-strings, don't actually evaluate to a string, but rather evaluate to an anonymous struct that has methods to convert it all at once into a real string. Thus, f-strings do not allocate.

#### Int Literals

#### Float Literals

#### Char Literals

#### Boolean Literals

#### Unit Literal
- void type

#### Struct Literal
literal for intializing a struct

#### Tuple Literal

#### Closure Literal

#### Function Literal
- pass function in as a param
also encloses state, when you create a new function that references a local vairable - makes anonymous struct that contains all of the enclosed context variables

### Range Literal
0..1 

`a..b` - `[a, b)`  
`a..=b` - `[a, b]`  
`a..+b` `[a, a + b)`  
`a..`  
`..b`  


## Algebraic Data Types
C* has `struct`s for product types and `enum`s for sum types. 
This is very powerful combined with [pattern matching](#pattern-matching). 
`enum`s in particular, which are like tagged unions, 
are much safer and correct compared to C unions. 
These data types are also fully zero-cost; there is no automatic boxing, 
and the same performance as C can be easily be achieved. 
Sometimes even better, because the layout of compound types 
is unspecified in C*.

For example, you can do this to make a copy-on-write string.
```rust
struct String {
    ptr: *u8,
    len: usize,
}

struct StringBuf {
    ptr: *u8,
    len: usize,
    cap: usize,
}

enum CowString {
    Borrowed(String),
    Owned(StringBuf),
}
```

### Structs
C* has `struct`s for product types and `enum`s for sum types. 
This is very powerful combined with [pattern matching](#pattern-matching). 
`enum`s in particular, which are like tagged unions, 
are much safer and correct compared to C unions. 
These data types are also fully zero-cost; there is no automatic boxing, 
and the same performance as C can be easily be achieved. 
Sometimes even better, because the layout of compound types 
is unspecified in C*.

For example, you can do this to make a copy-on-write string.
```rust
struct String {
    ptr: *u8,
    len: usize,
}

struct StringBuf {
    ptr: *u8,
    len: usize,
    cap: usize,
}

enum CowString {
    Borrowed(String),
    Owned(StringBuf),
}
```

## Generics
C* supports generic types and values, 
but they are at this point unconstrained. 
That is, they are like C++'s concept-less templates. 
They are always monomorphic, except when the exact same code can be shared (no boxing ever). They are not currently higher-kinded. 
Types and functions can be generic over both types and values, like this:
```rust
enum Option<T> {
    None,
    Some(T),
}

enum ShortVec<T, N: u8> {
    Inline {
        array: [T; N],
        len: u8,
    },
    Allocated {
        ptr: Option<*T>,
        len: usize,
        cap: usize,
    },
}

fn short_vec_len<T, N: u8>(v: *ShortVec<T, N>): usize {
    v.match {
        Inline {len, _} => len.@cast(),
        Allocated {len, _} => len,
    }
}
```

## Statements and Expressions
### Statements 
#### If-Else Statements

#### For Statements

#### While Statements

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

fn open_file_in_dir(dir: *[u8], filename: *[u8]): Result<i32, String> try {
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

fn open_two_files(path1: *[u8], path2: *[u8]): Result<FilePair, String> try {
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
fn open_two_files(path1: *[u8], path2: *[u8]): Result<FilePair, String> try {
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






keyword@label

for@a (...) {
    break@a;
}

defer@b x.free();
undefer@b;


### Expressions and Operators
#### Unary Operators
#### Binary Operators
#### Relational Operators

### Functions
fn(): return type = x - for closures

### Function Class

### Assignment

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

    fn new(first_name: String, last_name: String): Self {
        Self {first_name, last_name}
    }
    
    fn say_hi1(self: Self) {
        print(f"Hi {self.first_name} {self.last_name}");
    }
    
    fn say_hi1(self: *Self) {
        print(f"Hi {self.last_name}, {self.first_name}");
    }
    
    fn remove_last_name(self: *mut Self) {
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

fn get_two_by_index<T>(a: *[T], i: usize, j: usize): Result<T, IndexError> try {
    let first = try {
        get_by_index(a, i).?
    };
    let second = get_by_index(a, j).?;
    IndexPair {first, second}
}
```

This desugars to
```rust
fn get_two_by_index<T>(a: *[T], i: usize, j: usize): Result<T, IndexError> {
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

## Standard Library
### Option

### Result

### Strings

### Vector

## Operator Precedence
generic higher than comparison

## Examples