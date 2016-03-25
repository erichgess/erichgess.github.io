---
layout: post
title: "Purely Functional Data Structures: Chapter 2 - Binary Search Trees"
date: 2016-03-21 22:41:37 -0400
comments: true
categories: [F#, Purely Functional Data Structures, Algorithms, Functional Programming]
---
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

### IsMember
Checking membership in the tree is the first of the two absolutely necessary functions
for our BST.  The logic is rather simple, but here I've started trying out the `function`
  structure for when I'm writing a "polymorphic" function and leaving out explicity
  parameters.  I rarely used the `function` expression in the past so this is helping
  me to get a feel for this as a part of my toolbox.
  
Leaving out the parameters in the 
function definition is the [point free](https://en.wikipedia.org/wiki/Tacit_programming) 
style of programming.  Since point free style cuts out one source of self documentation
in code, I'm not sure I really like it.  However, it fits well with the `function` expression
since the focus is the _patterns_ that are being matched and that documents the parameters
well enough.

{% codeblock lang:fsharp %}
let rec isMember = function
  | (x,Empty) -> false
  | (x, Tree(l, n, r)) ->
    if x < n then isMember (x, l)   // Experimenting with a new format for if/then.  I like having the condition and it's direct conclusion on the same line
    elif x > n then isMember(x,r)
    else true
{% endcodeblock %}

### Insert
The insert function is a little more complex than `isMember`:  it needs to handle inserting
a new value into an immutable tree data structure:
{% codeblock lang:fsharp %}
let rec insert (x,s) =
  match s with
  | Empty -> Tree (Empty, x, Empty)
  | Tree(l,n,r) ->
    if x < n then Tree(insert (x,l), n, r)
    elif x > n then Tree(l, n, insert (x,r))
    else s
{% endcodeblock %}
`insert` travels from the root node, down the tree, visiting only the nodes on the way to
where the new node will get inserted.  This is called the _search path_.  As it moves, 
`insert` makes a copy of each node on the search path.  The nodes are copied so that they
can store the path to the new value, the nodes on the search path are the minimum number
of nodes that need to be copied.  And of course, because data is immutable, we have to
copy some nodes in order to make our insert.

This diagram shows what's happening in a nicely visual form.  The brown nodes are the
copied nodes on the search path, the dashed lines represent the new links in those nodes.
Note that most of the original tree remains used in the new 'post insert' tree.  A copy of
`7` was made and it's left child is the new `5` node, then a copy of `4` is made so that
`4`'s right points to the new `7`.  `4`'s left still points to the old tree.
{% img /images/posts/purefds_ch2/bst_insert.png %}

### Problem 2.2
In this problem, we have to update `isMember` to reduce the number of conditions in the
execution path.  This is done by propagating the last checked value through the traversal
and removing the `>` check:

{% codeblock lang:fsharp %}
let isMember2 (x, t) =
  let rec check = function
  | (x, None, Empty) -> false  
  | (x, Some prev, Empty) ->  x = prev
  | (x, prev, Tree(l,n,r)) ->
    if x < n then check (x, None, l)
    else check (x, Some n, r)

  check (x, None, t)
{% endcodeblock %}

`isMember2` was my first attempt.  While the last pattern matching expression has only
one conditional rather than two, it also has an additional pattern match check and so
it seems unlikely that the number of condition checks is actually reduced.  I took a look
at the IL for this code and verified that it does indeed have just as many conditions
as `isMember.  The worst part is, that pattern match check must get executed every time.

My second attempt became less idiomatic but it successfully reduces the number of 
required conditionals:

{% codeblock lang:fsharp %}
let rec isMember2' (x, prev: 'a option, t) =
  match (x, prev, t) with
  | (x, prev, Empty) ->  if prev.IsSome then x = prev.Value else false
  | (x, prev, Tree(l,n,r)) ->
    if x < n then isMember2' (x, None, l)
    else isMember2' (x, Some n, r)
{% endcodeblock %}

While working on this code, I noticed that in F# I'm much more comfortable writing
`if` expressions on a single line.  In other languages, I almost never do this (not
counting the ternary operator in the C family).

### Problem 2.3: improving insert
If we insert a value that's already in the tree, then the resulting tree will be
identical to the input tree.  However, the current `insert` function will still
copy all the nodes on the search path.  This problem Okasaki has us fix that by
throwing a fault if the value is already in the tree.  This will bubble a break
up through the recursive path and break the execution path before any copies
are made:

{% codeblock lang:fsharp %}
let rec insert2 (x,s) =
  match s with
  | Empty -> Tree (Empty, x, Empty)
  | Tree(l,n,r) ->
    if x < n then Tree(insert2 (x,l), n, r)
    elif x > n then Tree(l, n, insert2 (x,r))
    else failwith "Element already exists
{% endcodeblock %}

Finally, we combine this update with the update to `isMember` to optimize insertion
even more:

{% codeblock lang:fsharp %}
let rec insert3 (x, prev: 'a option, t) =
  match t with
  | Empty -> if prev.IsSome && x = prev.Value 
             then failwith "Element already exists" 
             else Tree (Empty, x, Empty)
  | Tree(l, n, r) ->
    if x < n 
    then Tree(insert3 (x, prev, l), n, r)
    else Tree(l, n, insert3 (x, Some n, r)
{% endcodeblock %}
