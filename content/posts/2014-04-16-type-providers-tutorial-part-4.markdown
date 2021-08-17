---
layout: post
title: "Type Providers Tutorial Part 4 - Base Types"
date: 2014-04-16 22:09:16 -0700
comments: true
categories: [F#, Type Providers, Tutorials]
---
In Part 3 of this Tutorial, I talked a little about erased types and how the types we generate are actually built on top of a `obj`.  Previously, I just used a plan `obj` type and cast an integer to and from the `obj` types.

```fsharp
InvokeCode= (fun args -> <@@ 0 :> obj @@>))
```

Using just the basic `obj` works well enough for a very simple generated type (like the simple integer from part 3).  However, it becomes a bit of a mess when you want to make anything complicated.

In this part, we will update our Type Provider to use a more advanced type as our base type.
<!-- more -->
The ultimate goal of this tutorial is to build a type provider, which takes a schema for a data source and generates a type which matches that schema.  For example, suppose our data source is a table with 3 columns labeled "Tom", "Dick", and "Harry", all three of integer type.  Then the type provider shall generate a type with 3 fields labeled "Tom", "Dick", and "Harry" of type `int`.  To make coding this managable, we will need an base type which can keep track of the names of our fields and the values each of each of those fields.

### Spring Cleaning
Tutorials Parts 1 through 3 were all about building up the basic skills and, most importantly, understanding needed to work with Type Providers.  Learning how to generate a type, how to add methods, properties, constructors, etc.  Through practice and application, hopefully, you get comfortable with erased types and how generated types are built on top of an base type.

Looking back at the `Hello` generated type we built in this tutorial; we've got something which is a bit slapdash.  That's fine for tinkering and learning the basics, but now that we have that under our belt it's time to build an actual (though still only practice) type provider.

All this adds up to: starting our code over.  Below is the fresh foundation from which we will build our Type Provider.  Note, that this does NOT include any constructor.
```fsharp
namespace Samples.FSharp.TutorialTypeProvider

open System
open System.Reflection
open Samples.FSharp.ProvidedTypes
open Microsoft.FSharp.Core.CompilerServices
open Microsoft.FSharp.Quotations

// This defines the type provider. When compiled to a DLL it can be added as a reference to an F#
// command-line compilation, script or project.
[<TypeProvider>]
type TutorialTypeProvider(config: TypeProviderConfig) as this = 

    // Inheriting from this type provides implementations of ITypeProvider in terms of the
    // provided types below.
    inherit TypeProviderForNamespaces()

    let namespaceName = "Tutorial"
    let thisAssembly = Assembly.GetExecutingAssembly()
    
    let CreateType () =
        let t = ProvidedTypeDefinition(thisAssembly,namespaceName,
                                        "TutorialType",
                                        baseType = Some typeof<TutorialType>)

        t

    let types = [ CreateType() ] 

    // And add them to the namespace
    do this.AddNamespace(namespaceName, types)

[<assembly:TypeProviderAssembly>] 
do()
```

### Data Source and Schema

The first thing we need is a data source and schema off of which we work.  Let's start with a simple data source: just a table with some number of columns.  To keep things simple, we will start with all the columns be integer values.  Our schema, then, would just be a list of the names of the columns.

For example, if we had a table with columns "Tom", "Dick", and "Harry"; then our schema would be `["Tom"; "Dick"; "Harry"]`. That would get passed to our type provider and a type with 3 integer fields named "Tom", "Dick", and "Harry" would be generated.

Our schema, then, will be a very simple list of column names.

### Base Type
Now that we know how to define what the data source looks like, it's time to make a type which can represent datum which matches our schema.  In our case, this would need to be able to store an integer for each column.  We also know how the generated type will look: a field named for each column defined in our schema.  This means that our base type will be randomly accessed.  So, we should use an array to store the value of each column.

```fsharp
type TutorialType = int array
```

I am using a type alias here, because in the future we will probably build this up in to a more complex type than just an integer array.

We must now configure our Type Provider to use our new base type rather than `obj`.  So we update the `ProvidedTypeDefinition` (in the function 'CreateType') and make the `baseType` be of type `TutorialType`:

```fsharp
let t = ProvidedTypeDefinition(thisAssembly,namespaceName,
                                "Hello",
                                baseType = Some typeof<TutorialType>)
```


### Schema To Type
Above in "Data Source and Schema", the schema was defined as just a list of column names.  This schema will need to be passsed to `CreateType` so that it will have the data needed to generate our type.  So, update `CreateType` to take a list of strings:
```fsharp
    let CreateType (columns: string list) =
```

And also update the call to `CreateType` to pass in some simple test data:
```fsharp
    let types = [ CreateType(["Tom"; "Dick"; "Harry"]) ] 
```

Now that `CreateType` has the schema for our data source, it's time to build up our type provider.

#### Constructor I barely know her
The first thing to add is the missing constructor.  This will be simple, based upon the number of column names passed to `CreateType` we want to create an array of integers, all initialized to 1.

```fsharp
        let ctor = ProvidedConstructor(parameters = [ ], 
                                       InvokeCode= (fun args -> <@@ Array.init columns.Length (fun i -> 0) @@>))

        // Add documentation to the provided constructor.
        ctor.AddXmlDocDelayed(fun () -> "This is the default constructor.  It sets the value of TutorialType to 0.")
```

#### Properties - Insert Uncle Pennybags Joke
The constructor will initialize the base data upon which our type is built.  Now we can add a field for each column, which will get and set the value of that field.  To do this, we will iterate the list of columns and create a property with the corresponding name.  The Getter and Setter functions will be defined as lambdas which store an index to the appropriate location in the array.
```fsharp
        columns |> List.mapi ( fun i col -> ProvidedProperty(col,
                                                typeof<int>,
                                                GetterCode = (fun args -> <@@ (%%args.[0] : TutorialType).[i] @@>),
                                                SetterCode = (fun args -> <@@ (%%args.[0] : TutorialType).[i] <- (%%args.[1] : int) @@>)))
                |> List.iter t.AddMember
```

Note in both `GetterCode` and `SetterCode` the lambda functions have `%%args.[0] : TutorialType)` instead of `%%args.[0] : obj`.  This is because we defined our `baseType` to be `TutorialType`.

### Validation - A Short Tangent
Something which is obviously missing is logic to make sure that a valid schema is passed in.  For example, what if a column name is "2", our code would try to create a property named "2" which is illegal.  Other cases would be: an empty list of columns, an empty or null string for a column name, illegal characters, and duplicate names.

Now, if you're like me, the next question you have is: what the fuck happens when a Type Provider throws an exception?  To find out, let's add some simple validation to our TypeProvider and run a test where we fail the validation.

We'll add some code to check if the list of columns is empty.  In the below codeblock, I added a new function `ValidateColumnSchema` and called that function at the beginning of `CreateType`.
```fsharp
    let ValidateColumnSchema (columns: string list) =
        if columns.Length = 0 then
            failwith "The column list is empty"

    let CreateType (columns: string list) =
        ValidateColumnSchema columns
```

Now, just for this test, update the call to create type to look like this:
```fsharp
    let types = [ CreateType([]) ] 
```
Build and send the project output to the FSI.  You should get an output that looks like:
```
stdin(2,1): error FS3053: The type provider 'Samples.FSharp.TutorialTypeProvider.TutorialTypeProvider' reported an error: The type provider constructor has thrown an exception: The column list is empty
```

Make sure to change the call to `CreateType` back to:
```fsharp
    let types = [ CreateType(["Tom"; "Dick"; "Harry"]) ] 
```

### Summary
In this tutorial, we examined the base type which our Type Provider uses as the base for generated types.  We updated the function which generates our type, so that it will take a list of field names and generate a type which has the corresponding fields.