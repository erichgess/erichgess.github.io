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
type HelloWorldTypeProvider(config: TypeProviderConfig) as this = 

    // Inheriting from this type provides implementations of ITypeProvider in terms of the
    // provided types below.
    inherit TypeProviderForNamespaces()

[<assembly:TypeProviderAssembly>] 
do()
{% endcodeblock %}

This code will compile, but won't do anything fun yet :).

##### Breakdown
1.  `[<TypeProvider>]` this attribute tells the compiler that my type `HelloWorldTypeProvider` is a Type Provider.
1.  Within `HelloWorldTypeProvider` we will put the code which actually generates new types.
1.  `[<assembly:TypeProviderAssembly]>` this attribute indicates that this assembly contains a Type Provider.

#### The `Hello` Type
With the skeleton in place, it's time to start adding a little muscle.  The following code will create a type named `Hello`.  This type won't do anything because there are no members (static or instance).  The code tells the type what assembly it belongs to, what namespace it is in, and the name of the type.
{% codeblock lang:fsharp %}
    let namespaceName = "Tutorial"
    let thisAssembly = Assembly.GetExecutingAssembly()
    
    let CreateType () =
        let t = ProvidedTypeDefinition(thisAssembly,namespaceName,
                                        "Hello",
                                        baseType = Some typeof<obj>)
        t

    let types = [ CreateType() ] 

    // And add them to the namespace
    do this.AddNamespace(namespaceName, types)
{% endcodeblock %}

##### Breakdown
1.  I added the method `CreateType` which will return a new provided type when called.  Right now, all this method does is create the most boring type ever.
1.  `types` is a list of types which the Type Provider generates
1.  `do this.AddNamespace(namespaceName, types)` adds the generated types to the namespace `namespaceName` so that they can be used by a developer.