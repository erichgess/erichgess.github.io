---
layout: post
title: "Type Providers -  Tutorial Part 3 - Instantiables"
date: 2014-04-05 13:42:52 -0700
comments: true
categories: [F#, Tutorials, Type Providers]
---
In the last tutorial, we built a simple type named `Hello` which had some static members.  In this tutorial, we'll expand our `Hello` type to include a constructor, an instance property, and an instance method.  Adding these will allow us to create instances of `Hello` using the `new` operator:

{% codeblock lang:fsharp %}
let x = new Hello()
{% endcodeblock %}

We'll also make `Hello` store some data, that means our type providers will be one step closer to awesome.  Also, one step closer to being an effective means of interacting with structured data sources.
<!-- more -->
### Quick Overview
Here's the order of what we'll be doing in Part 3 of this tutorial series

1.  Add a constructor to `Hello` and make `Hello` store a single integer value.
1.  Add a parameterized construtor to `Hello`.  This will let us set the value for `Hello`.
1.  Add an instance property which returns the integer set by the constructor.
1.  Add an instance method which doubles the integer set by the constructor.

Along the way, we'll see the backing `obj` type for the first time.  This is where the idea of "Erased Types" I mentioned in Part 1 becomes important.  Remember, as far as the runtime is concerned, our generated types are just instances of `obj` (all the methods, properties, and names we generate with our Type Providers are illusions to help developers write better code).