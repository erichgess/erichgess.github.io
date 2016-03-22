---
layout: post
title: "Purely Functional Data Structures: Chapter 2 - Lists"
date: 2016-03-21 21:40:30 -0400
comments: true
categories: [F#, Purely Functional Data Structures, Algorithms]
---

Chapter 2 covers the efficient implementation of stack and binary search 
trees when your data structures
must be immutable.  This chapter wound up being a lot of fun to work on because
it helped me focus a lot on how to approach structuring my F# code and start
laying the foundation for how to approach building elegant F# code.

<!-- more -->

## Stacks
There are two implementations of the stack in this chapter.  The first is
rather uninteresting and the second is significantly more educational.  This
section on Lists appeared to be more focused on using lists to represent
other data structures in this case to build a stack data structure.

### Using Lists
The first implementation is merely built on top of the existing list
data structure.  Below is the direct conversion into F#:

{% codeblock lang:fsharp %}
module Lists =
  type ListStack<'a> =
    'a list
  let Empty:ListStack<_> = []
  let isEmpty s = List.isEmpty s
  let cons a s:ListStack<_> = a :: s
  let hd s = List.head s
  let tl s = List.tail s
{% endcodeblock %}

There really wasn't a whole lot of interesting stuff in this first example.

### Custom Stack
The second section is much more fun:  a custom data structure is built to
represent the stack.  Built as a recursively nested tuple.  Which is
actually identical to the traditional way of representing a regular list.
This provides a nice way of building up an immutable list from primitives
(tuples) in order to build a more complex data structure (a stack).

This was also the first part where I had an opportunity to experiment
with how to write this well in F# and reason through the pros and cons
of a specific approach.  My first attempt was to get as close to the 
book as possible and I used a `type` with member methods to group the
`CustomStack` with its associated functions.  The second approach uses
`module CustomStack` to group the type with the associated functions.

{% codeblock lang:fsharp %}
type CustomStack<'a> =
  | Empty
  | Cons of 'a * CustomStack<'a>
with
  static member empty = Empty
  // Note:
  // I tried naming this IsEmpty but it won't compile
  // F# auto generates Is* functions for each element of a DU.
  static member CheckEmpty = function
                          | Empty -> true
                          | _ -> false
  
  static member cons (x, s) =
    Cons(x, s)

  static member head = function
    | Empty -> failwith "empty"
    | Cons(x, _) -> x

  static member tail s =
    match s with
    | Empty -> failwith "empty"
    | Cons(x, Empty) -> x
    | Cons(x, s) -> CustomStack<'a>.tail s
{% endcodeblock %}

The first thing I learned was that the F# compiler autogenerates a function
called `IsEmpty`.  Despite working with the language for several months,
I'd somehow never noticed that when you create a discriminated union type
F# automatically adds member methods for check if a value is a specific
element in the discriminated union.

Using static member methods to group the related functions to the type didn't
feel particularly elegant:  you'd always have to prepend all calls to functions
with `CustomStack.`.  So I tried using another approach:  using a 
module named `CustomStack` to group the functions with the type.  This would
provide the option of just calling the functions or prepending the module
name (`CustomStack.`).

{% codeblock lang:fsharp %}
module CustomStack =
  type CustomStack<'a> = Empty | Cons of 'a * CustomStack<'a>
  let empty = Empty
  
  let isEmpty = function Empty -> true | _ -> false
  
  let cons (x,s) = Cons(x, s)
  
  let head = function
    | Empty -> failwith "empty"
    | Cons(x,_) -> x

  let tail = function
    | Empty -> failwith "empty"
    | Cons(_, s) -> s

  let rec (++) a b =
    match a with
    | Empty -> b
    | Cons(x, s) -> Cons(x, s ++ b)

  let rec update = function
    | (Empty, _, _) -> failwith "subscript is invalid"
    | (Cons(_, s), 0, x) -> Cons(x, s)
    | (Cons(_, s), i, x) when i > 0 -> update (s, i-1, x)
    | _ -> failwith "subscript is invalid"
{% endcodeblock %}

This version felt much better to me, I also took the opportunity to create
an operator `++` for appends.  There is an interesting consequence that
this approach creates by disconnecting the type parameter restrictions
that functions require from the type definition; this will come up
explicitly in the binary search trees section.

I tried a slightly different format for `type CustomStack` and `isEmpty`:
placing the patterns on one line.  I'm not sure how I feel about
this approach.  It seems very easy to miss the `|` and not properly
see the pattern definitions.  Having everything on one line also
implies that everything is part of the same operation and that is
decidely not the case with pattern matching and DU definitions.
