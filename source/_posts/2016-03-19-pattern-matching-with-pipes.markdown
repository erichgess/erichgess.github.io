---
layout: post
title: "Pattern Matching With Pipes"
date: 2016-03-19 12:09:26 -0400
comments: true
categories: [F#, Programming Style]
---

One of my favorite things to do in F# is pipe functions together.  I like the elegant flow that the
semantics visualizes and the fact that it removes the need for intermediate variables.  Given that,
one of the minor, but consistent, annoyances I've had is when piping a DU type which generally need
to be piped into a pattern match expression.  This is annoying because the `match` expression doesn't
lend itself to piping which has meant that my nice workflow needs to be broken up with an intermediate
variable that can be used in the `match` expression.

Looking at some old code I wrote, I just realized something that is probably pretty obvious to every
experienced F# programmer out there.  The `function` expression actually does exactly what `match` does
but it creates a function and that's exactly what I've been wanting this whole time!

<!-- more -->

Here is a quick and dirty example of using a function which takes a value and returns  a discriminated
union.  The type of function which almost always means that pattern matching will have to be done with
its result:

{% codeblock lang:fsharp %}
type DU =
| A of int
| B of string
| C of bool

let doSomething x = 
  match x with
  | x when x < 0 -> A(x)
  | x when x = 0 -> B("zero")
  | _ -> C(true)
{% endcodeblock %}

Previously, I always used one of the two following styles (`style_1` and `style_2`):

{% codeblock lang:fsharp %}
let style_1 x =
  let du = doSomething x
  
  match du with
  | A(i) -> printfn "%d" i
  | B(s) -> printfn "%s" s
  | C(b) -> printfn "%b" b
{% endcodeblock %}

{% codeblock lang:fsharp %}
let style_2 x =
  x
  |> doSomething
  |> fun a -> match a with
              | A(i) -> printfn "%d" i
              | B(s) -> printfn "%s" s
              | C(b) -> printfn "%b" b
{% endcodeblock %}

Both `style_1` and `style_2` leave a lot to be desired.  Both `style_1` and `style_2` require the use of an intermediate variable and 
`style_2` needs the clunky `fun a ->` rigging.  The choice between two types of clunkiness always frustrated me,
because I felt that there must be some easy way to pipe the result of a function into a pattern match.

The pattern matching `function` makes it possible to elegantly integrate a pattern match into a `|>` flow.
Here's my new style implementation of the above code:

{% codeblock lang:fsharp %}
let style_3 x = 
  x
  |> doSomething 
  |> function
     | A(i) -> printfn "%d" i
     | B(s) -> printfn "%s" s
     | C(b) -> printfn "%b" b
{% endcodeblock %}

This is no profound revelation or anything, but it's a tiny step closer to producing truly
elegant F# code.  That makes me supremely happy.
