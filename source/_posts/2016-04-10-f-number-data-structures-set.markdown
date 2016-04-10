---
layout: post
title: "F# Data Structures: Set"
date: 2016-04-10 11:15:48 -0400
comments: true
categories: [F#, Data Structures]
---

As I've been going through Okasaki's book on functional data structures, it occurred to
me that it'd also be a lot of fun to run through the F# implementation of it's core data
structures and compare them with the book _Purely Functional Data Structures_.

It's a lot of fun seeing how fundamental and still powerful the data structures used in
_Purely Functional Data Structures_ are and has made reading through this book even more
satisfying.


The first significant data structure in Okasaki is the Set, which is implemented using
a binary search tree.  It's simple enough to find the F# Core implementation of set in
the GitHub [repository](https://github.com/fsharp/fsharp/blob/master/src/fsharp/FSharp.Core/set.fs#L17).

<!-- more -->

{% codeblock lang:fsharp %}
type SetTree<'T> when 'T : comparison = 
    | SetEmpty                                          // height = 0   
    | SetNode of 'T * SetTree<'T> *  SetTree<'T> * int    // height = int 
    | SetOne  of 'T                                     // height = 1 
{% endcodeblock %}

and a little further down in the source file we find this definition of `Set`:
{% codeblock lang:fsharp %}
type Set<[<EqualityConditionalOn>]'T when 'T : comparison >(comparer:IComparer<'T>, tree: SetTree<'T>)
{% endcodeblock %}

So the `Set` type is definitely built on top of a binary search tree.  Now the question is,
what type of binary search tree and that can be determined by looking at the functions
used on the `SetTree` type.  There's the expected `add` and `remove` and within those
functions are calls to a `rebalance` function.  Meaning that F# is using a self balancing
BST for its `Set` implementation.  Here's the code for the `rebalance` function:

{% codeblock lang:fsharp %}
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

So F# is using what looks like a slightly modified AVL tree, which uses a definable
tolerance for how unbalanced the tree can get before rebalancing happens.  The
strict AVL tree rebalances if the difference in height between the left and right
branches is greater than 1.

There's another interesting function nestled within the `SetTree` module: `split`.
This function interested me because it wasn't referenced in the balance or the
`add`/`remove` functions.

{% codeblock lang:fsharp %}
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

This function has type `SetTree, boolean, SetTree` and takes a `SetTree t` and a pivot
value `pivot`.  The first `SetTree` in the return type is the set of all values in `t`
which are less than `pivot`, the boolean is true if `pivot` is in `t`, and the right
`SetTree` contains all the values in `t` which are greater than `pivot`.

The `split` function is used in the union function:
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
This function takes two trees `t1` and `t2` and merges them together and returns a
single `TreeSet` with all the elements from `t1` and `t2`.  Here's how split is used
in this function:

1.  Assuming `t1` is taller than `t2` (it's basically the same if `t2` is taller than
`t1`)
1.  `split` all the elements in `t2` by if they are smaller than the root value of `t1`.
Call the set of nodes smaller than the `t1` root `lo` and the set of larger nodes `hi`.
1.  Use `union` to merge the left subtree of `t1` with `lo` and to merge the right subtree
of `t1` with `hi`.
1.  Balance the to newly generated subtrees.  This leaves a set of all the values smaller
than the `t1` value and a set of all the values larger than `t1`.  These can then be used
to create a new `TreeSet` representing the fully balanced merging of `t1` and `t2`.

This process will merge the two trees into a new balanced tree.
