---
layout: post
title: "Type Providers -  Tutorial Part 3 - Instantiables"
date: 2014-04-05 13:42:52 -0700
comments: true
categories: [F#, Tutorials, Type Providers]
---
In the last tutorial, we built a simple type named `Hello` which had some static members.  In this tutorial, we'll expand our `Hello` type to include a constructor, an instance property, and an instance method.  Adding these will allow us to create instances of `Hello` using the `new` operator:

```fsharp
let x = new Hello()
```

We'll also make `Hello` store some data, that means our type providers will be one step closer to awesome.  Also, one step closer to being an effective means of interacting with structured data sources.

The full code for what we make in this part will be at the end of this post.
<!-- more -->
### Quick Overview
Here's the order of what we'll be doing in Part 3 of this tutorial series

1.  Add a constructor to `Hello` and make `Hello` store a single integer value.
1.  Add a parameterized construtor to `Hello`.  This will let us set the value for `Hello`.
1.  Add an instance property which returns the integer set by the constructor.
1.  Add an instance method which doubles the integer set by the constructor.

Along the way, we'll see the backing `obj` type for the first time.  This is where the idea of "Erased Types" I mentioned in Part 1 becomes important.  Remember, as far as the runtime is concerned, our generated types are just instances of `obj` (all the methods, properties, and names we generate with our Type Providers are illusions to help developers write better code).

### Constructors - Tonka Tough
In order to make our type instantiable, we have to have a constructor.  It could be a default constructor or one with parameters, it doesn't matter, but at least one must exist.

The ProvidedTypes module includes a nice type specifically for handling constructors:  `ProvidedConstructor`.  Not a very surprising name, if you've been paying attention :).

We're going to add a default constructor to `Hello` (meaning it takes no parameters) which sets the value of our `Hello` instance to 0.

```fsharp
    let CreateType () =
    	/// ....
    	/// Code from the previous tutorials, removed to save space
    	/// ....
        let ctor = ProvidedConstructor(parameters = [ ], 
                                       InvokeCode= (fun args -> <@@ 0 :> obj @@>))

        // Add documentation to the provided constructor.
        ctor.AddXmlDocDelayed(fun () -> "This is the default constructor.  It sets the value of Hello to 0.")

        // Add the provided constructor to the provided type.
        t.AddMember ctor
        t
```

##### Breakdown
There really is not much to talk about here, it's very simple.  Except, I want to call out the `InvokeCode`, because this is the first time we interact with the backing `obj`.

```fsharp
InvokeCode= (fun args -> <@@ 0 :> obj @@>))
```

As I mentioned before, our `Hello` type basically sits on top of an instance of a formless `obj` type.  `InvokeCode` defines a function which gets executed when the construtor for `Hello` is called.  The value returned by our function is assigned to our underlying `obj`.  In our case, our `InvokeCode` function just returns `0`, because this will get assigned to a `obj' type we cast it to `obj` using `0 :> obj`.

### Constructors with Parameters - Construx
Now, being able to instantiate `Hello` is nice, but pretty pointless if we can't give it any values other than 0.  So here's how we create a constructor which takes a parameter.

```fsharp
        let ctorParams = ProvidedConstructor(parameters = [ ProvidedParameter("v", typeof<int>)], 
                                       InvokeCode= (fun args -> <@@ ( %%(args.[0]) : int) :> obj @@>))

        // Add documentation to the provided constructor.
        ctorParams.AddXmlDocDelayed(fun () -> "This another constructor.  It sets the value of Hello to the parametr.")

        // Add the provided constructor to the provided type.
        t.AddMember ctorParams
```

##### Breakdown
1.  `ProvidedParameter("v", typeof<int>)]` - This is how we define a parameter for a function or constructor.  The `"v"` is the name of the parameter.  Followed by the type of our parameter.
1.  `<@@ ( %%(args.[0]) : int) :> obj @@>` - This extracts the value of our first parameter (which is `v` for those keeping score), casts it to an integer, and then boxes it to `obj`.  The `%%` is a Code Quotation operator used for "splicing"; this is used to "splice" the `args` value into a Code Quotation.

##### Testing
Try loading our new type provider into F# interactive and executing `let x = new Tutorial.Hello(1)`!

### Instance Property - 9/10 of the Law
Now we can instantiate our `Hello` type.  We have some data behind our type.  Let's add a way to get that data!

```fsharp
        let instProperty = ProvidedProperty("Value",
                                            typeof<int>,
                                            GetterCode = (fun args -> <@@ (%%(args.[0]) : obj) :?> int @@>))
        t.AddMember instProperty
```

##### Breakdown
The instance `ProvidedProperty` is very similar to the one we used for making a static property:  we specify the name of the property and its type.  However, the `GetterCode` is important for us to review:
```fsharp
GetterCode = (fun args -> <@@ (%%(args.[0]) : obj) :?> int @@>))
```
What's important here is the `(%%(args.[0]) : obj)`.  More specifically, I want to call out the `args.[0]`:  when dealing with instance methods or properties `arg.[0]` is where the value of our instance is stored.  In the case of `Hello`, our instance is just an integer, so we case `arg.[0]` to an integer and return that value.

##### Testing
Try running this in the F# Interactive console:
```fsharp
open Tutorial;;
let c = new Tutorial.Hello(3);;
c.Value;;
```

### Instance Methods - Elementary
Finally, to wrap up this part of the tutorial.  We will add an instance method which, when invoked, will return twice the `Value` of our instance of `Hello`.

The code for this is eerily similar to most of the other code we've written for properties, methods, and constructors:
```fsharp
        let instanceMeth = 
            ProvidedMethod(methodName = "DoubleValue", 
                           parameters = [], 
                           returnType = typeof<int>,
                           InvokeCode = (fun args -> 
                              <@@ ((%%(args.[0]) : obj) :?> int) * 2 @@>))
        t.AddMember instanceMeth
```

##### Testing
Try running:
```fsharp
open Tutorial;;
let c = new Tutorial.Hello(3);;
c.DoubleValue();;
```

### Conclusion
This is probably the most important part of the tutorial so far.  We have actually created a Type Provider which generates a type named `Hello` that can store some data (granted only a single integer :)).  We also made this an instantiable type.  The most important thing is that we got to see the underlying `obj` upon which our generated type is built.

This underlying type is critical and we will explore it further in a later section of this tutorial.

If anything is learned from Part 3, it's that our generated type is really just some frosting put on top of an existing type (in `Hello`'s case an integer).  This may seem silly right now, but keep in mind, the real purpose of a type provider is to allow us to point to a source of data and get a bunch of types which will let us work with that data source in a very F# like manner.

## Full Code
```fsharp
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

    let namespaceName = "Tutorial"
    let thisAssembly = Assembly.GetExecutingAssembly()
    
    let CreateType () =
        let t = ProvidedTypeDefinition(thisAssembly,namespaceName,
                                        "Hello",
                                        baseType = Some typeof<obj>)

        let staticProp = ProvidedProperty(propertyName = "StaticProperty", 
                                            propertyType = typeof<string>, 
                                            IsStatic=true,
                                            GetterCode= (fun args -> <@@ "World!" @@>))

        // Add documentation to the provided static property.
        staticProp.AddXmlDocDelayed(fun () -> "This is a static property")

        // Add the static property to the type.
        t.AddMember staticProp

        // Add a static method
        let staticMeth = 
            ProvidedMethod(methodName = "StaticMethod", 
                           parameters = [], 
                           returnType = typeof<string>, 
                           IsStaticMethod = true,
                           InvokeCode = (fun args -> 
                              <@@ "World!" @@>))
        t.AddMember staticMeth

        let ctor = ProvidedConstructor(parameters = [ ], 
                                       InvokeCode= (fun args -> <@@ 0 :> obj @@>))

        // Add documentation to the provided constructor.
        ctor.AddXmlDocDelayed(fun () -> "This is the default constructor.  It sets the value of Hello to 0.")

        // Add the provided constructor to the provided type.
        t.AddMember ctor

        let ctorParams = ProvidedConstructor(parameters = [ ProvidedParameter("v", typeof<int>)], 
                                       InvokeCode= (fun args -> <@@ ( %%(args.[0]) : int) :> obj @@>))

        // Add documentation to the provided constructor.
        ctorParams.AddXmlDocDelayed(fun () -> "This another constructor.  It sets the value of Hello to the parametr.")

        // Add the provided constructor to the provided type.
        t.AddMember ctorParams

        let instProperty = ProvidedProperty("Value",
                                            typeof<int>,
                                            GetterCode = (fun args -> <@@ (%%(args.[0]) : obj) :?> int @@>))
        t.AddMember instProperty

        let instanceMeth = 
            ProvidedMethod(methodName = "DoubleValue", 
                           parameters = [], 
                           returnType = typeof<int>,
                           InvokeCode = (fun args -> 
                              <@@ ((%%(args.[0]) : obj) :?> int) * 2 @@>))
        t.AddMember instanceMeth

        t

    let types = [ CreateType() ] 

    // And add them to the namespace
    do this.AddNamespace(namespaceName, types)

[<assembly:TypeProviderAssembly>] 
do()
```