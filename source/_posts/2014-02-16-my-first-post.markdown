---
layout: post
title: "Experimenting with Quotations"
date: 2014-02-16 20:37:19 -0800
comments: true
categories: F#
---

One of the more interesting featuers of F# is the Code Quotation.  Though I do find this interesting now, it has taken over a year before I saw any reason I might have even slight interest.  Even now, as I have taken a much greater interest in the topic, it's been difficult finding anything detailed on the topic.

Anyone familiar with Lisp or one of its dialects, such as Clojure, will find Quotations familiar.  To put it simply, Quotations allow you to represent F# code as data.  Take the following example, where I bind a Quotation to ```q```:

{% codeblock lang:fsharp %}
let q = <@ 2 @>
{% endcodeblock %}


Running this in the FSI gives the following output:
{% codeblock lang:fsharp %}
val q : Quotations.Expr<int> = Value (2)
{% endcodeblock %}


The operator ```<@ @>``` takes the F# code which it wraps and converts it into a Quotation data structure.  In this case, it takes the value 2 and creates a Value type, which is part of the ```Quotations.Expr``` discriminated union.

I'll do a more interesting example, which will better show what a Quotation actually gives you, using the FSI:
{% codeblock lang:fsharp %}
> let q = <@ (2 + 3) * ( 3 - 1 ) @>;;

val q : Quotations.Expr<int> =
  Call (None, op_Multiply,
      [Call (None, op_Addition, [Value (2), Value (3)]),
       Call (None, op_Subtraction, [Value (3), Value (1)])])
{% endcodeblock %}

The Quotation gives you the Abstract Syntax Tree (AST) for a given F# expression.  Which, when I first started learning F# a year ago, was nothing but a curiousity.  In fact, it wasn't until just the other day that I actually started to get excited about Quotations.

Whenever I read about Code Quotations, it seems it's always about using Quotations to handle translating F# code into another language.  The best example of this use case, in my opinion, is WebSharper; which takes F# code and translates it into JavaScript.

However, it's the possibilities of using Quotations with distributed computing which caused my sudden spike in interest.  What's been bouncing around in my brain is:  can I write code in F#, break it apart into discrete chunks, send those chunks to be executing on different servers and then collect the results (MapReduce for sure).