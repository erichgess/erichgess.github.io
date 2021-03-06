Outline

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
### Remove
### Union
### Intersect
### IsSubset/IsSuperSet

## Conclusion
### It's basically exactly what you would do after reading _Purely Functional Data Structures_
#### This is awesome because that small book is clearly super good

