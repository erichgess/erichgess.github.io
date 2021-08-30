---
title: "Braid Compiler Error Handling"
date: 2021-08-30T14:19:21-04:00
draft: true
---

We need to take more time to love and appreciate the mediocre code that we write. Unless you
stop pushing your boundaries it's impossible to not occasionally write mediocre code.
If you're learning a new language, you'll write a _lot_ of mediocre code (unless the new
language is nearly identical to another language you know: e.g. Java to C#), or you're 
working in a completely new domain of engineering, or you've got a tight deadline, etc.
So, we should take time to appreciate our mediocre code; as that's the code we write when
we're growing. And a lot can be learned by thinking about what decisions were made that
sacrificed great code for mediocre code and why.

// Throw in error code from Braid

Writing the Braid Compiler was my first large project in Rust and presented a lot of design
trade offs driven by balancing lack of knowledge of Rust and getting features done. This
leads to writing code that is often not idiomatic even when it's clean and easy to use.
I'm always fighting with perfectionism and trying to just accept that code can be decent
or good enough and still be worth loving. Always thinking about how to design code 
perfectly or reading essays about a language you always see well designed code or code
that is written to perfectly express a design concept. But to be able to write really good
code, in any language, you have to develop some level of intuition for the language itself.
Which does not happen until you've written a lot in that language. So, this essay will
review some non-idiomatic but "good enough" design that I did for `braidc`; why I made the
decisions I made, what worked well with the design, what didn't work well, and what I 
would do now that I am much more proficient in Rust.

The design for error handling in `braidc` is very basic and not at all idiomatic for
Rust. When I started working in Rust, I had already had a few years of expreience writing
F#, which has a similar `Result` type that's used for expressing the possibility that
a function will fail. However, in .Net, you're still largely dealing with Exceptions being
thrown by libraries written in C# and with microservices I rarely had to create my own
error types or exception types. I knew how to use `Result` and I knew what to do with
`Result`'s in my code, but when it came to designing the Error types, I had no idea what
to do or even _what I wanted_.

Very early on in the writing of Braid, I had to start providing errors for the user. I made
a deliberate choice to use the simplest possible design for my Error types: just strings.
Why? One, I did not know enough Rust to make good judgements on how more complex design
choices might shape my productivity and code. Two, with so much Rust to learn, I made a choice
that I didn't have time to do a lot of reading about different error handling strategies:
lacking experience would make my judgements on the strategies untrustworthy and I would gain
more knowledge focusing on filling in other gaps in my Rust knowledge.

// Throw in error code from Braid

At the time, I felt unsatisfied with this decision, but I was also happy to make it. I
knew that I would make much better judgements on what error handling strategies and designs
would work best in `braidc`.  Being new to Rust and have very little intuition for the 
language meant that any choice I made would probably be wrong. I knew that picking the
design that left the smallest footprint on the code base would also leave me with the design
that's the easiest to change. The design needed to maintain the `Result` type for propagating
error information, because I knew I wanted the benefits of that type pattern and any good
error handling design in Rust will be built within the `Result` type. The error types I
used needed to be simple, so that they would be easily replaced with a better solution 
once I knew more Rust.

So, throughout `braidc` everything returns `Result<_, String>`. 

// Throw in error code from Braid

Why am I happy with this mediocre design?  It didn't consume a large amount of my time
to design and use.  I was able to write enough errors to get a sense of what I wanted
my error information to contain. I didn't find myself going back and rewriting or
redesigning my error handling for a very long time.  I always knew it was a "just fine"
design, but it never impacted my productivity or my code quality. So, I was able to focus
on getting the other parts of my code good to great.

Where will I take the design now? I didn't have answers to the following questions when
I started Braid:

1. What error type design pattern fits best with my style?
1. What do I want to include in the error information?
1. How will error handling influence the code around it?
1. The support functions and syntactic sugar that Rust provides to help with error handling.
(e.g. the `?` operator will implicitly call `into` to convert an error from the call site
to the surrounding functions error type).

I now have an answer to the first question. I can create an enum that covers the different
classes of errors that will happen in my code. Each submodule represents a key domain within
the compiler and will have very different types of errors from other modules: so I will create
an error enum for each module. One pattern that I've seen is the use of an `ErrorKind` inner
value, but I do not yet know if this will be used in my code.

An error needs to provide enough information that a user can fix what caused the error with
minimal effort. Obviously, this will include a text message explaining the nature of the
error.  But this will also need to include line information, so that the user can go
straight to the source.  The error also should include any lexemes, syntacts, or semantic
information that is related to the error: e.g., if a undeclared variable is used, the error
message should include the variable name.

I want the error information to have as little impact on the surrounding code as possible.
The biggest problem with my use of `String` is that I have to write `format!` expressions
in my code and deal with injecting the line number into the string. Ideally, creating an
error value would simply extract the line information from contextual data.

## What Will I Do In The Future?
1. Think within submodules.  Submodules provide a nice boundary for defining what the 
types of errors will be.
1. What information needs to be provided in each error? Errors are used when there is
something wrong with the input or an external dependency.  Enough information needs to
be provided to the user so they know exactly how to fix the problem. If the problem,
is input, then the user needs to know exactly what is wrong with the input. If it's a
dependency then the user needs to know what's wrong with the dependency (probalby the
best we can do here is propagate the error message the dependency threw). So, in the
future, Error types I design will be heavily grown from the structure of the input
interface between my module and the user. In the case of Braid, that input interface
is the source code: the struture of which is lines and columns and lexemes.
1. Start simple and minimize tentacles into surrounding code.  What I liked about 
`Result<_, String>` is that it was simple and I could easily use it anywhere and I
could easily make changes to errors to improve clarity.  I also did not have to write
any helper functions to work with my errors. One problem is that it had a little bit of
tentacleness: with needing line numbers for every error, which meant that I had to always
get a line number from a AST node and thread it down threw every place that I threw
an error.