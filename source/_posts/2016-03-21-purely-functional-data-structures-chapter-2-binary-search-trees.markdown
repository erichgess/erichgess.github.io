---
layout: post
title: "Purely Functional Data Structures: Chapter 2 - Binary Search Trees"
date: 2016-03-21 22:41:37 -0400
comments: true
categories: [F#, Purely Functional Data Structures, Algorithms, Functional Programming]
---
The second section of Chapter 2 deals focuses on binary search trees.  Like the section
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

{% img /images/posts/purefds_ch2/bst_insert.png %}


