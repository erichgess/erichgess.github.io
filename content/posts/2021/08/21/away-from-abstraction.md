---
title: "Away From Abstraction"
subtitle: "Amplification in Languages"
date: 2021-08-21T01:18:12-04:00
draft: true
---

I have come to believe that one of the greatest weaknesses of programming language evolution is the
move towards more and more abstraction of the underlying architecture that executes said programs.
The abstraction simplifies the process of learning how to program and writing programs. But it also
divorces us completely from the laws of physics which dictate what our programs will actually do.
Abstraction of reality makes it harder for us to understand the _actual_ consequences of our code;
instead, we have a general idea or hunch, but trying to understand the real reality is like trying
to feel with numb fingers. We know the basic shape but the texture is lost.

Leslie Lamport said that distributed systems problems are all, ultimately, physics problems. That's
also true of almost every other difficult to solve programming problem.

All values created within a program have a lifetime that is equal to or less than the lifetime of
the program itself. This could be a value that is created on the stack and lives only so long as the
stack pointer never goes below the stack frame: the value lives as long as the stack frame lives.
Or a value created within the heap and shared between many routines within a program: it needs to 
live as long as there exist live references to the value.  This property of values has existed as
long as values themselves. But for most programming languages it is implicit.  In languages like C,
it is something you must simply build an intuition.  Later languages, such as Java and C#, brought
in garbage collection and hiding away pointers: lifetimes were still implicit but now the language
would deal with it. It's still there, but you never even feel it, so you can never even gain an
intuition for this key property of values that must occur because of the laws of reality.

This is what I find fascinating about Rust's lifetimes.  Lifetimes are no longer abstracted away
and the runtime will no longer make sure your data will be alive as long as it's needed. Instead,
the physical property of a values lifetime is made explicit.  It is a semantic feature of the 
language itself and now the compiler can protect you rather than the runtime. This means that you
must write and design code that properly handles all the lifetimes of every value. You are now
explicitly expressing something that as always implicitly expressed before or completely ignored.

I want to push this further, to surface as much of the physical reality a program interacts with
into explicit semantic features of the languages we write with. I see there being two major 
realities that must be considered when writing code.  The logical reality: what we intend by our 
code.  The physical reality: how what we write actually interacts with the physical world (where
data is stored in memory, what it tells the CPU to do, etc.).

For example, we may have a string
with a "length" field and we store a copy of that field into a local variable called "len".  There
are now two physical locations (at least) with that data but they are logically the same. So, well
written code would probably avoid changing the value of "len" because it would violate the logical
reality we have created and that is implied by the variable name. This is a simple example, but it
is one that we use constantly in our code and which can be the source of bugs because it is so
easy to make a code change that leads to our expectation of logical consistency to be violated in
physical reality. This is because we only imply the logical reality we want our code to maintain
in physical reality.

So much of this logical reality must be expressed implicitly and can only be conveyed to readers
of the code in an implicit manner and maybe through documentation. A person writing very expressive
code and doing sufficient comments may be able to insure that a reader of the code will have a correct
understanding of the intended logical reality of a program. However, this hinges entirely on the
writer being very good at writing code. Worse, it requires the writer to _know_ that they are 
writing code that needs to clearly express a logical reality that may be easy to violate in the
physical reality.