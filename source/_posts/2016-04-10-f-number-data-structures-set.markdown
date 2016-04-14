---
layout: post
title: "F# Data Structures: Set"
date: 2016-04-10 11:15:48 -0400
comments: true
categories: [F#, Data Structures]
---

## How do the F# Core data structures work
To help improve my understanding of functional programming, I'm reading
through Chris Okasaki's _Purely Functional Data Structures_.  This book has been a great
refresher for my knowledge of data structures and algorithms.  Just for fun, I'm also
diving in the F# Core source code to see how many of the data structures that are covered
by Okasaki get implemented in real work functional source code.

Okasaki's book starts with implementing a Set data structure with a binary search tree.
So this small series also starts with F#'s implementation of Set.

## What are the important and interesting parts of Set?
There are a lot of functions in F#'s `Set` type and many of them aren't that interesting
and a dive into everything would make an over long post.  So we'll focus on just a few
of the core `Set` functions.  `Add`, `Contains`, and `Remove` are not, on the surface,
interesting but they provide a great way to explain on the underlying data structure
used for `Set` is implemented.

### Add
This function will add a new element to a Set, if it doesn't already exist.  If it does
already exist in the Set then it, of course, won't make any change to Set.

### Contains
Checks to see if a value is in the Set.

### Remove
Take a set and a value and if the value is in the set then return a new set without that
value.

### Union
Take two sets and return a new set which contains all the values from both sets.

### Intersect
Take two sets and return a new set which contains only the values that are in both sets.

### IsSubset/IsSuperSet
Takes two sets and returns true if all the values of one set are also in the other set.

## Implemented with a Binary Search Tree
Starting with the actual definition for the `Set` type <<<insert link to github>>>.
Which is actually built out of the `SetTree` type.
{% codeblock lang:fsharp %}
type Set<[<EqualityConditionalOn>]'T when 'T : comparison >(comparer:IComparer<'T>, tree: SetTree<'T>)
{% endcodeblock %}

So skipping up to the definition of `SetTree`:
{% codeblock lang:fsharp %}
type SetTree<'T> when 'T : comparison = 
    | SetEmpty                                          // height = 0   
    | SetNode of 'T * SetTree<'T> *  SetTree<'T> * int    // height = int 
    | SetOne  of 'T                                     // height = 1   
{% endcodeblock %}

So F#'s `Set` type is actually built out of a binary search tree which, as will be seen shortly,
is self balancing.  This is pretty much exactly how Okasaki implements Sets in his book.

## How each function is implemented
We already know that `Set` is built on top of a binary search tree named `SetTree`, but
lets first take a look at how `Set` implements `Add`, `Contains`, and `Removes`:

{% codeblock lang:fsharp %}
member s.Add(x) : Set<'T> = 
    new Set<'T>(s.Comparer,SetTree.add s.Comparer x s.Tree )

member s.Remove(x) : Set<'T> = 
    new Set<'T>(s.Comparer,SetTree.remove s.Comparer x s.Tree)

member s.Count = SetTree.count s.Tree

member s.Contains(x) = 
    SetTree.mem s.Comparer  x s.Tree
{% endcodeblock %}

It's not much surprise to see that `Set` just makes simple calls to `SetTree` for these
core actions.

### Add

Here's the implementation of `SetTree`'s `add` function:

{% codeblock lang:fsharp %}
let rec add (comparer: IComparer<'T>) k t = 
    match t with 
    | SetNode (k2,l,r,_) -> 
        let c = comparer.Compare(k,k2) 
        if   c < 0 then rebalance (add comparer k l) k2 r
        elif c = 0 then t
        else            rebalance l k2 (add comparer k r)
    | SetOne(k2) -> 
        // nb. no check for rebalance needed for small trees, also be sure to reuse node already allocated 
        let c = comparer.Compare(k,k2) 
        if c < 0   then SetNode (k,SetEmpty,t,2)
        elif c = 0 then t
        else            SetNode (k,t,SetEmpty,2)                  
    | SetEmpty -> SetOne(k)
{% endcodeblock %}

Adding a value to an empty set just returns the leaf type, `SetOne`, which has
no children.

Adding a value to a tree which has only one value is also pretty simple:  a comparison is made to
see if `t`, the tree passed into the function, should be on the left or right branch.  It's
important to note that by putting `t` as a child of the added value we get to reuse `t` and not
waste time or memory by creating a new node for that value.  
For the third case, the tree is complex enough to require checking for rebalancing when new
values are added.  Rebalancing insures that both branches of a tree are have nearly the same
height which keeps searches near the ideal of `n * log n`.

The `rebalance` function is critical and is also used by the `remove` function.  So now's a great
time to cover how it works.  This function is the the most important part of the binary search
tree's implementation (how a tree rebalances is the core difference between trees like AVL, red
black, and other search trees).

{% codeblock lang:fsharp %}
let mk l k r = 
    match l,r with 
    | SetEmpty,SetEmpty -> SetOne (k)
    | _ -> 
      let hl = height l 
      let hr = height r 
      let m = if hl < hr then hr else hl 
      SetNode(k,l,r,m+1)

let rebalance t1 k t2 =
    let t1h = height t1 
    let t2h = height t2 
    if  t2h > t1h + tolerance then // right is heavier than left 
        match t2 with 
        | SetNode(t2k,t2l,t2r,_) -> 
            // one of the nodes must have height > height t1 + 1 
            if height t2l > t1h + 1 then  // balance left: combination 
                match t2l with 
                | SetNode(t2lk,t2ll,t2lr,_) ->
                    mk (mk t1 k t2ll) t2lk (mk t2lr t2k t2r) 
                | _ -> failwith "rebalance"
            else // rotate left 
                mk (mk t1 k t2l) t2k t2r
        | _ -> failwith "rebalance"
    else
        if  t1h > t2h + tolerance then // left is heavier than right 
            match t1 with 
            | SetNode(t1k,t1l,t1r,_) -> 
                // one of the nodes must have height > height t2 + 1 
                if height t1r > t2h + 1 then 
                    // balance right: combination 
                    match t1r with 
                    | SetNode(t1rk,t1rl,t1rr,_) ->
                        mk (mk t1l t1k t1rl) t1rk (mk t1rr k t2)
                    | _ -> failwith "rebalance"
                else
                    mk t1l t1k (mk t1r k t2)
            | _ -> failwith "rebalance"
        else mk t1 k t2
{% endcodeblock %}

The `mk` function takes two trees `l` and `r` and a value `k` and creates
a new tree and updates the new height value.

`rebalance` also takes two trees, `t1` and `t2`, and a value `k`.  If the difference
between the heights of `t1` and `t2` is not greater than the `tolerance` (a parameter
for how much tolerance `SetTree` has for imbalance, then `rebalance` simply makes
a new tree with `t1` as the left and `t2` as the right branch, respectively, and `k`
as the value of the new root node.

If the difference in heights is greater than the tolerance then the tree needs to be
rebalanced.  We'll just cover how the rebalance works when `t2` is taller than `t1`,
because the reverse case follows the exact same process.

The `match` expression is used to deconstruct `t2` into it's value, `t2k`, and it's 
left and right branches, `t2l` and `t2r`.  Now we check to see if the `t2l` or `t2r`
is taller than `t1` which determines how we'll rebalance the tree.

If `t2r` is taller than `t1` then we'll rotate the tree to the left with this code:
{% codeblock lang:fsharp %}
mk (mk t1 k t2l) t2k t2r
{% endcodeblock %}

If `t2l` is taller than `t1` then the code is a little more complicated:
{% codeblock lang:fsharp %}
if height t2l > t1h + 1 then  // balance left: combination 
    match t2l with 
    | SetNode(t2lk,t2ll,t2lr,_) ->
        mk (mk t1 k t2ll) t2lk (mk t2lr t2k t2r) 
{% endcodeblock %}
Again `match` is used to deconstruct a tree node, `t2l`, into it's components:
`t2lk` (the value) and `t2ll` and `t2lr` (the left and right branches of `t2l`.

Once the `t2l` is deconstructed `rebalance` creates a new tree:

1.  The value of `t2l` becomes the new root of the tree.
1.  The left branch is a tree with the value `k`, this tree's left branch is `t1`
and it's right branch is `t2ll` (the left child of `t2l`, the left child of `t2`).
1.  The right branch is a tree with value `t2k`, which is the value of `t2`, and
this tree's left branch is `t2lr` (the right child of `t2l`, the left child of `t2`)
and it's left branch is `t2r` (the right branch of `t2`).

This image visually illustrates what happens when `rebalance t1 k t2` is called:
{% img /images/posts/fsharp_set/settree_rebalance_diagram.png %}

### Contains

Set `Contains` function is just a call to the `SetTree` function `mem`.

Here's `mem`:
{% codeblock lang:fsharp %}
let rec mem (comparer: IComparer<'T>) k t = 
    match t with 
    | SetNode(k2,l,r,_) -> 
        let c = comparer.Compare(k,k2) 
        if   c < 0 then mem comparer k l
        elif c = 0 then true
        else mem comparer k r
    | SetOne(k2) -> (comparer.Compare(k,k2) = 0)
    | SetEmpty -> false
{% endcodeblock %}

`mem` is the simplest of all these functions, because it doesn't make any changes
to the tree and so it doesn't trigger any rebalancing actions.

`mem` recurively walks through the binary search tree using the comparer argument
to determine whether it should follow the left child or the right child or if the
value has been found.  If it reaches an edge node it compares the node with the
value argument and returns that as the result.  If it reaches an empty tree then
the value is not in the tree and false is returned.

### Remove
{% codeblock lang:fsharp %}
let rec remove (comparer: IComparer<'T>) k t = 
    match t with 
    | SetEmpty -> t
    | SetOne (k2) -> 
        let c = comparer.Compare(k,k2) 
        if   c = 0 then SetEmpty
        else t
    | SetNode (k2,l,r,_) -> 
        let c = comparer.Compare(k,k2) 
        if   c < 0 then rebalance (remove comparer k l) k2 r
        elif c = 0 then 
          match l,r with 
          | SetEmpty,_ -> r
          | _,SetEmpty -> l
          | _ -> 
              let sk,r' = spliceOutSuccessor r 
              mk l sk r'
        else rebalance l k2 (remove comparer k r) 
{% endcodeblock %}

### Union
`Set.Union` might be the most complex of all the functions in `Set`.  Like
`add` and `remove` it makes use of helper functions which contain most of
the major complexity.  Below is the code for `SetTree.union` the code for the
two helper functions is further down, in this section, but we'll cover the
cases in `union` that don't reqiure the helper functions first.

{% codeblock lang:fsharp %}
let rec union comparer t1 t2 =
    // Perf: tried bruteForce for low heights, but nothing significant 
    match t1,t2 with               
    | SetNode(k1,t11,t12,h1),SetNode(k2,t21,t22,h2) -> // (t11 < k < t12) AND (t21 < k2 < t22) 
        // Divide and Conquer:
        //   Suppose t1 is largest.
        //   Split t2 using pivot k1 into lo and hi.
        //   Union disjoint subproblems and then combine. 
        if h1 > h2 then
          let lo,_,hi = split comparer k1 t2 in
          balance comparer (union comparer t11 lo) k1 (union comparer t12 hi)
        else
          let lo,_,hi = split comparer k2 t1 in
          balance comparer (union comparer t21 lo) k2 (union comparer t22 hi)
    | SetEmpty,t -> t
    | t,SetEmpty -> t
    | SetOne k1,t2 -> add comparer k1 t2
    | t1,SetOne k2 -> add comparer k2 t1
{% endcodeblock %}

`union` takes two trees, `t1` and `t2`, and puts them together as a tuple and
then de-structures that tuple.  This function is only complicated if both
`t1` and `t2` have children, for all other cases it's extremely simple.

Here are the simple patterns that `(t1,t2)` can match against
1.  `SetEmpty,t` or `t,SetEmpty`: because one of the two sets is empty, the union
is just whatever the value of the other set is.
1.  `SetOne k1,t2` or `t1,SetOne k2: one of the trees contains a single value,
so the union is can be gotten, efficiently, by just adding that value to the 
other tree.

The one remaining case is the complicated interesting one.  Obviously, the union
could be found by simply traversing the first tree and adding every value to the second
tree.  But the F# compiler is being more efficient in it's solution to this problem.
That's where the two helper fuctions, `balance` and `split`, come into play and their
code is listed below.

Note that `balance` calls `rebalance`, whose code is listed above.

{% codeblock lang:fsharp %}
let rec balance comparer t1 k t2 =
    // Given t1 < k < t2 where t1 and t2 are "balanced",
    // return a balanced tree for <t1,k,t2>.
    // Recall: balance means subtrees heights differ by at most "tolerance"
    match t1,t2 with
    | SetEmpty,t2  -> add comparer k t2 // drop t1 = empty 
    | t1,SetEmpty  -> add comparer k t1 // drop t2 = empty 
    | SetOne k1,t2 -> add comparer k (add comparer k1 t2)
    | t1,SetOne k2 -> add comparer k (add comparer k2 t1)
    | SetNode(k1,t11,t12,h1),SetNode(k2,t21,t22,h2) ->
        // Have:  (t11 < k1 < t12) < k < (t21 < k2 < t22)
        // Either (a) h1,h2 differ by at most 2 - no rebalance needed.
        //        (b) h1 too small, i.e. h1+2 < h2
        //        (c) h2 too small, i.e. h2+2 < h1 
        if   h1+tolerance < h2 then
            // case: b, h1 too small 
            // push t1 into low side of t2, may increase height by 1 so rebalance 
            rebalance (balance comparer t1 k t21) k2 t22
        elif h2+tolerance < h1 then
            // case: c, h2 too small 
            // push t2 into high side of t1, may increase height by 1 so rebalance 
            rebalance t11 k1 (balance comparer t12 k t2)
        else
            // case: a, h1 and h2 meet balance requirement 
            mk t1 k t2

let rec split (comparer : IComparer<'T>) pivot t =
    // Given a pivot and a set t
    // Return { x in t s.t. x < pivot }, pivot in t? , { x in t s.t. x > pivot } 
    match t with
    | SetNode(k1,t11,t12,_) ->
        let c = comparer.Compare(pivot,k1)
        if   c < 0 then // pivot t1 
            let t11Lo,havePivot,t11Hi = split comparer pivot t11
            t11Lo,havePivot,balance comparer t11Hi k1 t12
        elif c = 0 then // pivot is k1 
            t11,true,t12
        else            // pivot t2 
            let t12Lo,havePivot,t12Hi = split comparer pivot t12
            balance comparer t11 k1 t12Lo,havePivot,t12Hi
    | SetOne k1 ->
        let c = comparer.Compare(k1,pivot)
        if   c < 0 then t       ,false,SetEmpty // singleton under pivot 
        elif c = 0 then SetEmpty,true ,SetEmpty // singleton is    pivot 
        else            SetEmpty,false,t        // singleton over  pivot 
    | SetEmpty  -> 
        SetEmpty,false,SetEmpty
{% endcodeblock %}

#### Split
Of the two helper functions, `split` is the easiest.  It simply takes a tree, `t`,
and a value, `pivot`, and splits `t` into two subtrees:  one with all the values
that are greater than `pivot` and one with all the values smaller than `pivot`.
It evaluates to a tuple which contains those two trees and a boolean flag for if
`pivot` is in `t`.

#### Balance
This function is more complex than `split` and just looking at the code it's not
immediately obvious what purpose it plays.  `balance` takes 3 key arguments:
two trees, `t1` and `t2`, and a value, `k`.  These arguments must satisfy certain
requirements: every value in `t1` is smaller than every value in `t2` and k
is larger than every value in `t1` and smaller than every value in `t2`.
It basically takes two trees and a value
and puts them together into a single tree which is balanced.  The trivial cases
are when one of the trees is empty or contains only a single value.  The complex
case is when both trees contain multiple values.  `balance`'s goal is to add the
two tree's together into a single balanced tree.  So it looks at the heights of 
the two trees to see how much they differ:  if the heights of the two trees are within
the tolerance then it can simply make `k` a new root node and set the two trees
as the left and right children of `k`.

If the two trees differ in height by more than
the tolerance then `balance` has to do some extra work in order to evaluate to
a balanced tree.  It takes the smaller tree and makes it the child of the larger
tree, then does a rebalance in case the result is unbalanced.

#### Final Union Case


### Intersect
The `Set.Intersect a b` function takes two sets `a` and `b` and returns a new set
consisting of all the values which are in both `a` and `b`.  Intuitively, this
function seems like it will behave nearly identically to `Subset`: both functions
involve traversing two sets and finding all the elements that are in both sets. This
function merely needs to save all the elements that are in both sets rather than 
return a boolean value.

Below is the code from `FSharp.Core` for `SetTree` intersection.  Note that the real
work is done by the function `intersectionAux` the `intersection` function is used
to set the initial value for the accumulator argument to `SetEmpty`.

{% codeblock lang:fsharp %}
let rec intersectionAux comparer b m acc = 
    match m with 
    | SetNode(k,l,r,_) -> 
        let acc = intersectionAux comparer b r acc 
        let acc = if mem comparer k b then add comparer k acc else acc 
        intersectionAux comparer b l acc
    | SetOne(k) -> 
        if mem comparer k b then add comparer k acc else acc
    | SetEmpty -> acc

let intersection comparer a b = intersectionAux comparer b a SetEmpty
{% endcodeblock %}

`intersectionAux` takes the two sets, note that the labelling has changed to `b` and
`m`, and the accumulator argument, which will collect all the values which are in both
`b` and `m`.  `intersectionAux` traverses the tree `m` and for each value, `k`, in `m`
it checks to see if the value is also in `b`.  If `k` is in `b` then it's added to
the accumulator, `acc`, otherwise it's left out.  After completing the traversal of
`m`, `acc` will represent the intersection of `m` and `b`.

The argument `m` is deconstructed using `match` into it's possible values: `SetEmpty`,
`SetOne`, and `SetNode`.  If it's `SetEmpty` then there is no value in the node and
the only thing to do is return `acc`.  If it's `SetOne` we extract the value into `k`
and check if `k` exists in the set `b`:  if it does then add it to `acc` if it's not
in `b` then just return `acc` with no additions. Finally, if it's `SetNode` extract 
the value, `k`, and the children, `l` and `r`. Then
recursively call `intersectionAux` on `r` and add any elements that are in `r` and `b`
to `acc`.  Check if `k` is in `b` and if it is, add it to `acc`.  Finally, call
`intersectionAux` on `l` and add any values which are in both `l` and `b` to `acc`.

### IsSubset/IsSuperSet

{% codeblock lang:fsharp %}
let rec forall f m = 
    match m with 
    | SetNode(k2,l,r,_) -> f k2 && forall f l && forall f r
    | SetOne(k2) -> f k2
    | SetEmpty -> true          

let rec exists f m = 
    match m with 
    | SetNode(k2,l,r,_) -> f k2 || exists f l || exists f r
    | SetOne(k2) -> f k2
    | SetEmpty -> false         

let subset comparer a b  = forall (fun x -> mem comparer x b) a
{% endcodeblock %}

These two functions aren't that difficult to understand.  Much like `mem`
they don't modify the tree so there's no need for rebalancing.

`subset` traverses every node in `a` and checks to see if that node's value
also exists in `b`.  `forall` will short circuit if it hits a node which is
not in `b` and will evaluate to `false`.

The SuperSet function is exactly the same except it swaps the arguments and
tests if `b` is a subset of `a`.

## Conclusion

What's awesome is that, fundamentally, this is the same way that sets are
implemented in _Purely Functional Data Structures_.  Which just shows how
valuable that book still is, even with it being 20 years old!

The most important difference, of course, is that the book doesn't use a
self balancing binary search tree while F# uses an AVL tree.  But no one
would use a non-self balancing BST in a real implementation.