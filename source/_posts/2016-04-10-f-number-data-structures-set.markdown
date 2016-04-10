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
what type of binary search tree:

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
