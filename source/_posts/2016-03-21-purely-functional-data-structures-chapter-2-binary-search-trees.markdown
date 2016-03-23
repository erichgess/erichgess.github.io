---
layout: post
title: "Purely Functional Data Structures: Chapter 2 - Binary Search Trees"
date: 2016-03-21 22:41:37 -0400
comments: true
categories: [F#, Purely Functional Data Structures, Algorithms, Functional Programming]
---
_This post is in progress_

The second section of Chapter 2 deals focuses on binary search trees (BST) and uses BSTs to
implement a set data structure.  Like the section
on lists, this gives a nice little explanation on how to deal with inserts to a tree data
structure when the data is immutable in as efficient a way as possible.  The most brute
force solution to this would be to create a complete duplicate of the tree save for the
newly added value, this section shows that, while copying is necessary, only the search
path from the root to the new element needs to be copied.  The new tree will then reference
as much of the old tree as possible; minimizing both copies and memory used.

What this post will cover:  how to represent a binary search tree (BST) in F#, how to efficiently
update the BST while using immutable data structures, and some discussion on design and style.

<!-- more -->

First thing:  how to represent the binary search tree in F#.  A BST has two possible values:
it's either Empty or it's a some value with 2 children.  So a discriminated union captures
this set and a tuple can store the value and 2 children.  Leading, as with the list, to
a recursive type:

{% codeblock lang:fsharp %}
type Tree<'a> = Empty | Tree of Tree<'a> * 'a * Tree<'a>
{% endcodeblock %}

The Tree on the left of `Tree<'a> * 'a * Tree<'a>` stores the left branch and the right
`Tree` stores the right branch.

A requirement for a BST is that `'a` must have a total ordering:  you must be able to take
any two values of type `'a` and check if one is less than the other.  The above definition
does not capture this requirement and so we can make a `Tree` of any type.  In Purely
Functional Data Structure this is solved by using ML's _functor_ feature, which F# doesn't
have.  In F# this can be captured using a _constraint_ on the type:

{% codeblock lang:fsharp %}
type BinarySearchTree<'a when 'a: comparison> = 
  | Empty 
  | Tree of BinarySearchTree<'a> * 'a * BinarySearchTree<'a>
{% endcodeblock %}

`'a when 'a: comparison` tells the F# compiler that `'a` must implement the IComparable
interface which guarantees that the `<` operator can be used on two values of type `'a`.

I changed the name of the type from `Tree` to `BinarySearchTree` to capture the more focused
nature of the type when a constraint is added.  The `Tree` can be use to create any type of
binary tree structure, with the constraint the type becomes focused specifically on ordering
and searching.  The updated name helps to reflect this focus.  This type could also be put
into a `module` named _BinarySearchTree_ to capture that information and then keep the type
named simply _Tree_.  However, I am not yet sure which is superior, though I feel that
capturing the nature of the type, intrinsically, in the name so that it can't be seperated
is the better path to follow.

As a note, there is another option with F# for capturing the comparability requirement. We
don't have to put the constraint in the type definition.  When we write our `insert` and
`search` functions, the F# compiler with infer that, for _those_ functions, `'a` must
have the `comparison` constraint.  This decouples the use of the tree from the type definition.
If we want the type to capture only the structure of a binary tree, then this approach makes
sense.  However, if we want the type to capture both the structure and the purpose (searching)
then this approach seems like it will be fragile and confusing.

I initially thought that there was a third option:  add the search and insert functions as
member methods to the definition of `Tree`.  It seemed likely that the F# compiler would
infer that `'a` must have the `comparison` constraint.  Testing proved that this is not the
case and, in fact, the compiler throws an error because `Tree` must explicitly have the
`comparison` constraint in order for the member methods to work.

{% img /images/posts/purefds_ch2/bst_insert.png %}
