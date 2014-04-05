---
layout: post
title: "Type Providers - Tutorial Part 2"
date: 2014-04-04 17:51:36 -0700
comments: true
categories: [F#, Tutorials, Type Providers]
---
In Part 1 of this series, I briefly explained what a Type Provider was and some of the main concepts which you would need to know.  In Part 2, I am going to build a very simple Type Provider.  The purpose of Part 2 is to cover the basics of developing Type Providers, how to test them with F# Interactive, and the support tools which make developing Type Providers easy.

I will make a Type Provider which generates a single type named "Hello".  At first it will just have a static property which returns the string `"World"`.  Then I will add a static method which takes no parameters.  Finally, I will add a static method which takes a parameter.
<!-- more -->
I start by creating a new F# Library Project and name it "TypeProviderTutorial":

// Insert picture of newproj.png

I then download the ProvidedTypes-0.4.fs file from the F# 3.0 Sample Pack and add that to my project:

// insert picture 2-providedtypes.png

Now it's time to create our Type Provider.  Add a new F# source code file beneath the "ProvidedTypes-0.4.fs" and name it "HelloWorld.fs".

// insert 3-addbelow.png
// insert 4-newsource.png

#### Skeleton Code
We'll build up from the very bare minimum needed for a Type Provider.  Starting with the boilerplate code which actually tells the compiler our type is a Type Provider:

{% codeblock lang:fsharp %}
namespace Samples.FSharp.HelloWorldTypeProvider

open System
open System.Reflection
open Samples.FSharp.ProvidedTypes
open Microsoft.FSharp.Core.CompilerServices
open Microsoft.FSharp.Quotations

// This defines the type provider. When compiled to a DLL it can be added as a reference to an F#
// command-line compilation, script or project.
[<TypeProvider>]
type SampleTypeProvider(config: TypeProviderConfig) as this = 

    // Inheriting from this type provides implementations of ITypeProvider in terms of the
    // provided types below.
    inherit TypeProviderForNamespaces()

    let namespaceName = "Samples.HelloWorldTypeProvider"
    let thisAssembly = Assembly.GetExecutingAssembly()
{% endcodeblock %}