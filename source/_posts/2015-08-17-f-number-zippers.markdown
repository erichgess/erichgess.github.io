---
layout: post
title: "F# Zippers"
date: 2015-08-17 13:16:40 -0500
comments: true
categories: [F#, Functional Programming, Type Theory]
---

<!--
Purpose:
Primary: To teach what the Zipper type pattern is and what it can do.  Start with the Zipper of a List.  Explain how
to use the List Zipper.  Explain how it derives from the List ADT.  Then...
Seconary: To teach how to create a Zipper for an ADT by differentiating the ADT.  Derive the Zipper for a binary tree
using mathematical tools.
Tertiary: How cool is it that you can differentiate an ADT????? :D

Outline
- Introduction:  This blog post will cover the Zipper type structure.  The Zipper is analogous to the derivative of an
ADT.
- The Zipper of a list
- Why would I care about the Zipper?  Replacing specific values in a list in O(1).  Moving through the list in O(1).
-- The Zipper is a type which represents a cursor on the parent type.  It includes a set of functions for moving the
cursor through the data structure or for modifying the value at the cursor's current position; the functions take a
Zipper and return a new Zipper with the cursor moved.
- The Zipper of a Binary Tree
- Using the Tree Zipper
- The Zipper of a Tree with variable numbers of branches.
- Deriving the Zipper
-- the Zipper ADT compared to the parent type
-- The derivative of an ADT
-- 

-->

One of the coolest things about working with F# (and other ML languages) is the
incredibly elegant way that mathematics intersects with programming, to inform
powerful tools for our toolbox.  Algebraic Data Types (ADTs) are the source of a
large amount of this mathematical invention.  Recently, I've been exploring the
algebra and calculus of types and what happens when you take the derivative
of a type.

The derivative of a type leads us into the concept of the Zipper.

<!-- more -->

A few blog posts about ADTs and calculus (in particular, this article
from [Joel Burget](https://codewords.recurse.com/issues/three/algebra-and-calculus-of-algebraic-data-types)
and this series from [Chris Taylor](https://chris-taylor.github.io/blog/2013/02/13/the-algebra-of-algebraic-data-types-part-iii/))
helped clarify how the zipper works.  However, in order to get a true understanding
of how zippers work and what they can be used for, I decided to implement the list
and tree zippers in F#.

## Zippers in General

The zipper is a type which represents a cursor in an ordered data structure, that can
be moved around to focus on different elements in the structure.  Using the zipper
it becomes easy to move through a data structure in O(1) time and change the value
of the data structure at the cursor's position in O(1) time.

## List Zipper

The simplest zipper, that I know, is the list zipper.  Implementing the list zipper
just needs a type to represent the zipper and three functions:  one to move the
zipper left, one to move the zipper right, and one to change the value at the
zipper's position.

### List Zipper Mathematics
Here's an approximate type definition for a list:

{% codeblock lang:fsharp %}
type List<'a> = Empty | List of 'a * List<'a>
{% endcodeblock %}

This type definition is strictly to make how the algebra & calculus behind the list
zipper gets derived and to explicitly call out that the list type is, mathematically,
a recursive type.

Algebraicly, this List is represented as:

$$L = 1 + a\cdot L$$

The derivative of which is:

$$\partial_aL = L + a\partial_aL$$

$$\partial_aL(1 - a) = L$$

$$\partial_aL = \frac{L}{1 - a}$$

$$\partial_aL = \frac{1 + a + a^2 + a^3...}{1-a} = \frac{(1 + 2a + 3a^2 + ...)(1-a)}{1-a} = L^2$$


### List Zipper Type

The list zipper's type will need to represent three piecs of information

1. The list to the left of the zipper
2. The element at the zipper's position
3. The list to the right of the zipper

There's a small problem with the left side list: if we store elements in order then
adding and removing elements as we move the zipper will be very expensive list append
operations.  So, this list will be stored in reverse order.

The functions

- `createZipper` - This function takes a list and creates a zipper with that
list.
- `moveZipperRight` - If there are elements to the right of the zipper's current
position, then this function will put the zipper's current position onto the head
of the left list, then pop the head of the right list off and make that the current
position.
- `moveZipperLeft` - This is the same as `moveZipperRight` except in the left
direction.
- `updateZipperValue` - This returns a new zipper with the value at the zipper's
position changed to a new value.

{% codeblock lang:fsharp %}
type Zipper<'a> = Zipper of ('a list * 'a * 'a list)

let createZipper l =
    match l with
    | [] -> failwith "oops"
    | h :: t -> Zipper ([], h, t)

let moveZipperRight z =
    match z with
    | Zipper(l, z, []) -> Zipper(l, z, [])
    | Zipper(l, z, h::rt) -> Zipper(z::l, h, rt)

let moveZipperLeft z =
    match z with
    | Zipper([], z, r) -> Zipper([], z, r)
    | Zipper(h::lt, z, r) -> Zipper(lt, h, h::r)

let updateZipperValue z x =
    let (Zipper(l, _, r)) = z
    Zipper(l, x, r)
{% endcodeblock %}

With the list zipper it's trivial to add functions for inserting new
values into the list.

{% codeblock lang:fsharp %}
let insertBeforeZipper z x =
    let (Zipper(l, zx, r)) = z
    Zipper(x::l, xz, r)
    
let insertAfterZipper z x =
    let (Zipper(l, zx, r)) = z
    Zipper(l, xz, x::r)
{% endcodeblock %}

## Tree Zipper

### Tree Zipper Type

The tree zipper will need to meet similar requirements to the list zipper.
Primarily, the ability to move down the left or right branches and reverse
the path that was traversed down the graph.

{% codeblock lang:fsharp %}
type Tree<'a> =
    | Branch of Tree<'a> * 'a * Tree<'a>
    | Empty

type Branch = Left | Right

type TreeZipper<'a> = TreeZipper of Tree<'a> * 'a * Tree<'a> * ((Branch * 'a * Tree<'a>) list)

let createTreeZipper t =
    match t with
    | Empty -> failwith "oops"
    | Branch(l, x, r) -> TreeZipper(l, x, r, [])

let moveLeft tz =
    match tz with
    | TreeZipper(Empty, x, r, history) -> tz
    | TreeZipper(Branch(ll, lx, lr), x, r, history) -> 
        TreeZipper(ll, lx, lr, (Left, x, r)::history)

let moveRight tz =
    match tz with
    | TreeZipper(l, x, Empty, history) -> tz
    | TreeZipper(l, x, Branch(rl, rx, rr), history) -> 
        TreeZipper(rl, rx, rr, (Right, x, l)::history)

let moveBack tz =
    match tz with
    | TreeZipper(l, x, r, []) -> tz
    | TreeZipper(l, x, r, (Left, hx, hr)::history) -> 
        TreeZipper(Branch(l, x, r), hx, hr, history)
    | TreeZipper(l, x, r, (Right, hx, hl)::history) -> 
        TreeZipper(hl, hx, Branch(l, x, r), history)

let updateValue tz x =
    let (TreeZipper(l, _, r, history)) = tz
    TreeZipper(l, x, r, history)
{% endcodeblock %}

# What I Find Curious About the Zipper
In this section, I've sketched out a few hypotheses on more general laws of what
controls a zipper.

The zipper resembles the monad in a few ways:

1. It starts with a data type
1. Then a set of functions which meet certain needs on the data type
are defined.
1. This all adds up into a pattern which defines, not just a type, but
a way to compute or interact with a type.

Which raises the question, is there a set of laws which all zippers must meet?
Do those laws also define what types can create a zipper?

What would the zipper laws be?

- A directed graph.  This would cover linked lists, all types of trees, and
any other data structure which is made my linking nodes together and defines
some heirarchy.
- A function which takes a zipper and a value and returns a new zipper where
given value is assigned to the focus
- A set $$F$$ of functions which take the zipper and move the focus in the direction
of an edge in the graph
- A function which reverses the any action made by a function in the set $$F$$.