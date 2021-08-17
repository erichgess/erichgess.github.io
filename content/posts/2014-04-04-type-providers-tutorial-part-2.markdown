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

![New Project](/images/typeprov_tut_p2/1-newproj.png)

I then download the [ProvidedTypes-0.4.fs file from the F# 3.0 Sample Pack](http://fsharp3sample.codeplex.com/SourceControl/latest#SampleProviders/Shared/ProvidedTypes-0.4.fs) and add that to my project:

![Privided Types](/images/typeprov_tut_p2/2-providedtypes.png)

Now it's time to create our Type Provider.  Add a new F# source code file beneath the "ProvidedTypes-0.4.fs" and name it "HelloWorld.fs".

![Add Below](/images/typeprov_tut_p2/3-addbelow.png)
![New Source](/images/typeprov_tut_p2/4-newsource.png)

### Skeleton Code
We'll build up from the very bare minimum needed for a Type Provider.  Starting with the boilerplate code which actually tells the compiler our type is a Type Provider:

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

[<assembly:TypeProviderAssembly>] 
do()
```

This code will compile, but won't do anything fun yet :).

##### Breakdown
1.  `[<TypeProvider>]` this attribute tells the compiler that my type `HelloWorldTypeProvider` is a Type Provider.
1.  Within `HelloWorldTypeProvider` we will put the code which actually generates new types.
1.  `[<assembly:TypeProviderAssembly]>` this attribute indicates that this assembly contains a Type Provider.

### The `Hello` Type
With the skeleton in place, it's time to start adding a little muscle.  The following code will create a type named `Hello`.  This type won't do anything because there are no members (static or instance).  The code tells the type what assembly it belongs to, what namespace it is in, and the name of the type.
```fsharp
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
```

##### Breakdown
1.  I added the method `CreateType` which will return a new provided type when called.  Right now, all this method does is create the most boring type ever.
1.  `types` is a list of types which the Type Provider generates
1.  `do this.AddNamespace(namespaceName, types)` adds the generated types to the namespace `namespaceName` so that they can be used by a developer.

##### Testing
Build the library.  When the build is complete, right click on the project in the Solution Explorer and choose "Send Project Output To F# Interactive":

![First Build](/images/typeprov_tut_p2/5-firstbuild.png)

In F# Interactive run:
```
> open Tutorial;;
> Tutorial.Hello;;
```

When you run `Tutorial.Hello` you'll get an error about not having a constructor.  This is a good thing.  The compiler can find the type, but there's no constructor so it bombs out.

** Before Proceeding make sure to reset F# Interactive **
![Reset FSI](/images/typeprov_tut_p2/6-resetfsi.png)
Do this by right clicking on the FSI window and choosing the reset option.

### Adding a Static Property
Time to make that `Hello` type actually do something.  We'll add a static property to this type called `StaticProperty` which will return the string "World!".  Once we've added that, we'll be able to write `Tutorial.Hello.World` in our code and it will compile!

To add the static property, I'm going to update the `CreateType()` method.  It will create a static property by using the `ProvidedProperty` type, then that value will be added as a member to the generated type.

Here's the code
```fsharp
let CreateType () =
    let t = ProvidedTypeDefinition(thisAssembly,namespaceName,
                                    "Hello",
                                    baseType = Some typeof<obj>)

    // create a new static property
    let staticProp = ProvidedProperty(propertyName = "StaticProperty",     // specify the name of the property
                                        propertyType = typeof<string>,     // make it a string type
                                        IsStatic=true,                     // make it a static property
                                        GetterCode= (fun args -> <@@ "World!" @@>))  // code quotation.  When someone gets this property 
                                                                                     // this function will be executed and "World!" will be returned

    // Add documentation to the provided static property.
    staticProp.AddXmlDocDelayed(fun () -> "This is a static property")

    // Add the static property to the type.
    t.AddMember staticProp
    t
```

##### Breakdown
1.  The function `ProvidedProperty` is the most important piece in this step.  It creates a Property member which can then be added to our generated type.
1.  `t.AddMember staticProp` we add the Static Property we created to our type `Hello`.
1.  `staticProp.AddXmlDocDelayed` just adds Intellisense documentation for this property.  You'll see this text if you over your mouse over `Tutorial.Hello.StaticProperty`.

##### Testing
Build and send our Library to F# Interactive then open the "Tutorial" namespace.  Try executing `Tutorial.Hello.StaticProperty` and see what you get.  It should be `val it : string = "World!"`.  Which is awesome!  We now have a generated type which actually does something!

### Adding a Static Method
Finally, we'll add a static method to our `Hello` type.  To keep things consistent, this method will also return "World!".

Again, the work will be done by updating `CreateType()`.  In this case, we'll add a ProvidedMethod to our `Hello` type.  In the code sample below, I left out the StaticProperty to keep the code snippet small:
```fsharp
        let staticMeth = 
            ProvidedMethod(methodName = "StaticMethod", 
                           parameters = [], 
                           returnType = typeof<string>, 
                           IsStaticMethod = true,
                           InvokeCode = (fun args -> 
                              <@@ "World!" @@>))
        t.AddMember staticMeth
```

##### Breakdown

There isn't much which is different between adding a static method and a static property.  We use a different type: `ProvidedMethod`.  Also note that to make this static we set the `IsStaticMethod` property to `true` rather than the `IsStatic` property.  `InvokeCode` is the function which will be executed when this method is called.  In our case, it will just return "World!".

##### Testing

Try executing `Tutorial.Hello.StaticMethod();;` and see what you get :).