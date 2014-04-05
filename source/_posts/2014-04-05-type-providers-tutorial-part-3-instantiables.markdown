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
