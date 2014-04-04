---
layout: post
title: "Type Providers - Tutorial Part 1"
date: 2014-04-03 20:36:12 -0700
comments: true
categories: [F#, Type Providers, Tutorials]
---

I've only been working with the F# language for the last year.  Which means that all of my learning has been with version 3.x of the F# language.  One of the biggest features of 3.x, and something which I have yet to work with, is the Type Provider.  Type Providers dynamically generate new types, usually from some data source (e.g. databases, XML documents, web services), which a developer can use in their code.  For C# developers this is analogous to the Entity Framework or the "Add Service Reference" in VS, both of which take a database or WSDL, respectively, and generate classes and functions that can be used in code.  For Java this would be similar to Hibernate or wsdl2java.  Just to be clear, when you create a Type Provider, what you've built is an Entity Framework or a wsdl2java.  What F# provides is a framework for building your own Type Providers as easily as possible.

In order to learn how to build Type Providers, I decided to try my hand at writing a tutorial.  This will, I think, be the first tutorial I've ever written.  I'm going to break this tutorial into several phases.  The first phase will be building a very simple "Hello World" type provider, which just creates a type which can be referenced in code (it won't do anything).  The next phase will be to add static and instance methods, fields, and properties, but, again, the type will be predefined.  Finally, I want to do a true type provider for a data source (I'm thinking Cassandra) which will take the schema for a database and generate a set of types from that schema.

