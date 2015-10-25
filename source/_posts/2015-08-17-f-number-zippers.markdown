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

Flow:
- Reader needs to know what the topic of the blog post will be. 
- Reader needs to know what the structure of the post will be.  --> introduction

- What's the easiest way to explain what and why of a Zipper?  --> Demonstrate the List zipper

- Now that the mechanics of a Zipper are explained, dive into the math behind a zipper.  The reader will understand
how the Zipper works and can focus on understanding the theoretical part of a zipper and why it's worth learning
how to derive new Zippers.

- Show an applicative demonstration of the math behind the Zipper.  Derive a Zipper for a binary tree.

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
-- The derivative of an ADT - Holes!
-- Filling the hole
-->

One of the coolest things about working with F# (and other ML languages) is the
incredibly elegant way that mathematics intersects with programming, to inform
powerful tools for our toolbox.  Algebraic Data Types (ADTs) are the source of a
large amount of this mathematical invention.  Recently, I've been exploring the
algebra and calculus of types and what happens when you take the derivative
of a type.

Zippers are a type pattern which provide a functional way to interact with and transform data structures:  linked lists,
binary trees, rose trees, etc.  The Zipper is a type with a set of functions that create a cursor which moved through a
data structure, much like you move through your computers file directory tree, and can be used to modify the data
structure.  They're also a really cool demonstration of the intersection between programming and higher math, in this
case: derivatives.

In this blog post, I will explain both the mechanics of the Zipper type and the mathematics of the Zipper.  First,
I'll explain the list Zipper:  how to make one in F# and what can be done with it.  Second, the list zipper will be used
as the basis for teaching how to take the derivative of an Algebraic Data Type (ADT).  Finally, the derivative
operation will be usd to create a Zipper for the binary tree.

<!-- more -->

## The List Zipper
To start with, we'll skip the math completely and focus just on the F# code: the type and the functions that, combined,
form a Zipper.   After that, will be how to use the list zipper to interact with a list.

### The F# List Zipper
Imagine that you have a slide show deck that you want to represent in F#.  You'll want to be able to move back and forth
through the deck as you give your presentation.  You also want to be able to change a specific slide as you work on your
presentation.

A list makes a good type to represent our slide show, as a first version.  However, how can we move back and forth
through the deck and how can we swap out slides as we move through the deck?  We want a type which stores an ordered
set of slides, has a focus on the slide which is being projected to a screen, and has functions for moving the focus
to the previous slide, to the next slide, or swapping in a new slide.

The type we just described is the list zipper.  And the above paragraph describes all the things the list Zipper needs
to have:  something which represents the current slide, all the slides before the current slide, all the slides after
the current slide, and functions to navigate the slide show.  If we take all of those requirements we get this type in
F#:

{% codeblock lang:fsharp %}
type Zipper<'a> = Zipper of ('a list * 'a * 'a list) with
    static member create l =
        match l with
        | [] -> failwith "oops"
        | h :: t -> Zipper ([], h, t)

    member z.right () =
        match z with
        | Zipper(l, z, []) -> Zipper(l, z, [])
        | Zipper(l, z, h::rt) -> Zipper(z::l, h, rt)

    member z.left () =
        match z with
        | Zipper([], z, r) -> Zipper([], z, r)
        | Zipper(h::lt, z, r) -> Zipper(lt, h, z::r)

    member z.update x =
        let (Zipper(l, _, r)) = z in Zipper(l, x, r)
{% endcodeblock %}

This also has a constructor function which takes a list and returns a zipper on that list.

The core of this type is the tuple: `'a list * 'a * 'a list`.  The first type represents the list of elements which
precede the cursor.  The second type, `'a`, represents the value in the list which the cursor points to.  The third
type, `'a list`, represents the list of elements which come after the cursor.

#### Demonstration of the List Zipper

Start by creating a zipper from a list
{% codeblock lang:fsharp %}
let z = Zipper.create [1; 2; 3; 4]
// val z : Zipper<int> = Zipper ([], 1, [2; 3; 4])
{% endcodeblock %}
The cursor points to the first element in the list, there are no elements to the left of the cursor so that list is
empty, and all the other elements are to the right of the cursor so they are in the respective list.

Move the cursor to the right
{% codeblock lang:fsharp %}
z.right();;
// val it : Zipper<int> = Zipper ([1], 2, [3; 4])
{% endcodeblock %}
Calling the right function has returned a new zipper with the cursor now pointing to the second element in the list.

Take the new zipper and move the cursor right one more time
{% codeblock lang:fsharp %}
it.right();;
// val it : Zipper<int> = Zipper ([2; 1], 3, [4])
{% endcodeblock %}
Note that the left list is storing the elements in reverse order.  This is becaues when the cursor moves left in a
list it is traversing the list in reverse order.

Update the value at the cursor:
{% codeblock lang:fsharp %}
it.update -3;;
// val it : Zipper<int> = Zipper ([2; 1], -3, [4])
{% endcodeblock %}

Move to the left:
{% codeblock lang:fsharp %}
it.left();;
// val it : Zipper<int> = Zipper ([1], 2, [-3; 4])
{% endcodeblock %}

## The Math Behind the List Zipper
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

If we take $$L^2$$ and convert it to a type we get:
{% codeblock lang:fsharp %}
type partial_l = 'a list * 'a list
{% endcodeblock %}
Which is close to our Zipper type but not quite there.

As explained in Colin McBrides paper on the topic of zippers and type derivatives, we can think of the derivative of a
type as a hole which is poked into the type where the hole represents the cursor.  The hole can can take any value of
the type `'a`.  We can think of the pair of lists representing where in the list the hole is and the `'a` respresents
the value of the hole.  In other words, take the derivative of `List<'a>` and multiply it by `'a` and you have the
zipper:
{% codeblock lang:fsharp %}
type Zipper = 'a list * 'a * 'a list
{% endcodeblock %}

## Deriving the Binary Tree Zipper
Now that we know how to use differentiation to create the zipper for the List type, let's use the same technique to
create the zipper for a binary tree.  This will start with defining a simple type for the binary tree, then
evaluating the derivative of the binary tree type, and, finally, converting the result into an F# type.

Here's the binary tree type we'll work with:
{% codeblock lang:fsharp %}
type Tree<'a> =
    | Branch of Tree<'a> * 'a * Tree<'a>
    | Empty
{% endcodeblock %}

# Old Post

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