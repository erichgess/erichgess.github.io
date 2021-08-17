---
layout: post
title: "Type Providers - Tutorial Part 1 - Concepts"
date: 2014-04-03 20:36:12 -0700
comments: true
categories: [F#, Type Providers, Tutorials]
---

I've only been working with the F# language for the last year.  Which means that all of my learning has been with version 3.x of the F# language.  One of the biggest features of 3.x, and something which I have yet to work with, is the Type Provider.  Type Providers dynamically generate new types, usually from some data source (e.g. databases, XML documents, web services), which a developer can use in their code.  For C# developers this is analogous to the Entity Framework or the "Add Service Reference" in VS, both of which take a database or WSDL, respectively, and generate classes and functions that can be used in code.  For Java this would be similar to Hibernate or wsdl2java.  Just to be clear, when you create a Type Provider, what you've built is an Entity Framework or a wsdl2java.  What F# provides is a framework for building your own Type Providers as easily as possible.
<!-- more -->
In order to learn how to build Type Providers, I decided to try my hand at writing a tutorial.  This will, I think, be the first tutorial I've ever written.  I'm going to break this tutorial into several phases.  The first phase will be building a very simple "Hello World" type provider, which just creates a type which can be referenced in code (it won't do anything).  The next phase will be to add static and instance methods, fields, and properties, but, again, the type will be predefined.  Finally, I want to do a true type provider for a data source (I'm thinking Cassandra) which will take the schema for a database and generate a set of types from that schema.

### Important Things

#### ProvidedTypes.fs
This is an F# source code file provided by the F# team.  It includes a bunch of things for simplifying the construction of Type Providers.  I'll be making heavy use of this in my tutorial.  If you plan on writing your own Type Provider, you definitely want to get this:  it can be found in the F# 3.0 sample pack (http://fsharp3sample.codeplex.com/).

#### Erased Types
Most of the time, when building Type Providers, you'll be creating erased types:  although this type may have members and functions when compiled it will be convered into an Object type by the compiler.  With the type provider, you are creating a set of methods, fields, properties, and constructors which enable a developer to work with your type, but, when compiled, all of that is "erased" and it just becomes and Object.  There's a section in the Type Provider MSDN article which explains erased types (http://msdn.microsoft.com/en-us/library/hh361034.aspx#BK_Erased).

What's important is that this means there will be a lot of casting to and from the `obj` type in Type Provider code.  This also means that if the Type Provider is going to work with any kind of meaningful data sources, an underlying type (on which the generated types are built) must be defined.  If you look at the MSDN Type Provider Tutorial (http://msdn.microsoft.com/en-us/library/hh361034.aspx), the underlying type is `string`.

#### Developing Type Providers
A Type Provider cannot be defined in anything except a Library project.  This seems like a pain but it does make sense:  if you are going to use a Type Provider in your code it must be fully compiled before you use it.

#### Debugging Type Providers
This is probably the biggest pain point of developing Type Providers, in my humble opinion.  Do not create a console project in your Type Provider solution and try to use that console project to test your Type Providers.  The problem is that when you build the console project, VS will lock the DLLs from the Type Provider library project.  Once the DLLs are locked you won't be able to build the Type Provider library until you restart VS.

Use the F# Interactive Console.  Build the library project then right click on it in the Solution Explorer and choose "Send to F# Interactive".  In the interactive console you can test out your type provider.  IMPORTANT:  Before you try building your project again make sure to reset the interactive console, otherwise it will lock the DLLs and your build will fail.