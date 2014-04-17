---
layout: post
title: "Type Providers Tutorial Part 4 - Backing Types"
date: 2014-04-16 22:09:16 -0700
comments: true
categories: [F#, Type Providers, Tutorials]
---
In Part 3 of this Tutorial, I talked a little about erased types and how the types we generate are actually built on top of a `obj`.  Previously, I just used a plan `obj` type and cast an integer to and from the `obj` types.

{% codeblock lang:fsharp %}
InvokeCode= (fun args -> <@@ 0 :> obj @@>))
{% endcodeblock %}

Using just the basic `obj` works well enough for a very simple generated type (like the simple integer from part 3).  However, it becomes a bit of a mess when you want to make anything complicated.

In this part, we will update our Type Provider to use a more advanced type as our backing type.
<!-- more -->
The ultimate goal of this tutorial is to build a type provider, which takes a schema for a data source and generates a type which matches that schema.  For example, suppose our data source is a table with 3 columns labeled "Tom", "Dick", and "Harry", all three of integer type.  Then the type provider shall generate a type with 3 fields labeled "Tom", "Dick", and "Harry" of type `int`.  To make coding this managable, we will need an underlying type which can keep track of the names of our fields and the values each of each of those fields.

### Data Source and Schema

The first thing we need is a data source and schema off of which we work.  Let's start with a simple data source: just a table with some number of columns.  To keep things simple, we will start with all the columns be integer values.  Our schema, then, would just be a list of the names of the columns.

For example, if we had a table with columns "Tom", "Dick", and "Harry"; then our schema would be `["Tom"; "Dick"; "Harry"]`. That would get passed to our type provider and a type with 3 integer fields named "Tom", "Dick", and "Harry" would be generated.

Our schema, then, will be a very simple list of column names.

### Underlying Type
Now that we know how to define what the data source looks like, it's time to make a type which can represent datum which matches our schema.  In our case, this would need to be able to store an integer for each column.  We also know how the generated type will look: a field named for each column defined in our schema.  This means that our underlying type will be randomly accessed.  So, we should use an array to store the value of each column.

{% codeblock lang:fsharp %}
type TutorialType = int array
{% endcodeblock %}

I am using a type alias here, because in the future we will probably build this up in to a more complex type than just an integer array.