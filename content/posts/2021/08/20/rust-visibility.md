---
title: "Rust Visibility"
date: 2021-08-20T20:24:52-04:00
draft: true
---

Understanding whether or not I should make struct fields public was one of the hardest
challenges in learning Rust. With OO languages such as Java and C# the rule is incredibly
easy: always make fields private and use getters and setters for access. And when
starting with Rust, my immediate impulse was to follow this same rule, but it quickly 
becomes clear that that simple rule is not right for Rust.

My philosophy is only a little more complex than "always make all fields private":
1. If the struct is the state for a process, then make the fields private.
1. If the struct is the definition for a type of data, then make the fields public.

There are nuances. For example, a `Vec` actually is the state for a process, not a data
definition. And, at first, you may think that the ability to control the range of values
a field can have is lost; but I propose a solution that allows fields to be public while
still giving you the ability to validate the values they are given.

Structure variants in enums were the first clue that "hiding data" was not simpatico with
Rust. When you create an enumeration in Rust, the variants can be a unitary valued label,
or they can be associated with tuples, or the variant can be a structure with named
fields (which are always public). Enumerations mean `match` expressions and
deconstrution: where the elements of a tuple variant or the fields of a struct variant
are bound to labels for easy access in the branches of the `match` expression. Through
this, the power of using deconstruction and `match` expressions to build code around
enumerations made the benefits of public fields obvious.

There's a lot of value to making fields private. One benefit, that I've always loved, is
that the struct completely controls setting a field's value. A "setter" function can
validate the proposed value and make it impossible for the field to be set to something
invalid. Making fields public, makes this kind of defensive programming much harder.

The experience with enumerations and deconstruction created a sense of conflict between
structs and the enumeration's struct variant. My instinct was to always make the fields
of a struct private, but the struct variant made this rule obviously inconsistent within
Rust itself. Further, the ability to deconstruct a struct into a small set of locally
defined bindings is incredibly expressive syntactic sugar, especially when coupled with
the `match`. So, for my first few months writing Rust, I found myself frequently making
fields public, because making them private and using getters & setters and losing
deconstruction was often too painful.

Trying to figure out what the idioms were around field visibility in Rust was the first
design question I could not solve on my own.  Asking on the Rust community forum, gave
a mixed set of answers. Some people saying that fields should always be private and some
saying that either is fine.  But no one giving a clear philosophy on how to make such a
decision. What I needed was a way to answer the question "why is this public" or "why is
this private".

It turns out the answer is simple: if the structure represents the state of some process
then the fields are private and if the structure represents a value or data make the 
fields public. And a free lemma: a structure can represent the state of a process or
represent a value/data but _not_ both. 

Examples of stateful structs, the `BufWriter` is a process which
writes bytes to some physical destination, its fields are private because they are the
state of the writing process and tampering with them will break the writer. A `Vec` is
another example of a stateful structure: it uses state to help manage memory as it
grows and shrinks.

Structs where fields should be public are structs which is itself a single value. For
example, a struct for Cartessian coordinates or a structure representing an RGB color.
An address may also be another example of a struct which is a value not a state and so
all fields should be public, but then you seemingly use the value of validating all
fields for correctness.

Trying to get the best of both worlds: while writing this essay, I realized that there
may be a way to get the best of both worlds. The problem with making fields private is
that you lose the power of deconstruction.  The problem with makign fields public is that
you lose the power of validation. So, define expressive types for those fields which
want validation and make those types use getters and setters.  Then a multi-field type
can be deconstructed but the individual fields can only be set through a method that can
perform validation.

```rust
fn main() {
    let mut us = Example::UnitSquare {
        x: Example::UnitLine::default(),
        y: Example::UnitLine::default(),
    };
    
    // I can deconstruct UnitSquare and get references to individual 
    // fields
    let Example::UnitSquare { x, y } = &mut us;

    // But using the wrapper type UnitLine lets me force a user to 
    // go through a setter function to set the value of the field.  
    // Wherein, validation is done.
    println!("{}", x.set(0.5).is_ok());    // Succeeds, will print "true"
    println!("{}", y.set(50.0).is_ok());   // Fails, will print "false"

    // us.x was successfully changed, but us.y remains the same
    println!("{:?}", us);
    // Prints:
    // UnitSquare { x: UnitLine(0.5), y: UnitLine(0.0) }
}

mod Example {
    #[derive(Debug, Default)]
    pub struct UnitSquare {
        pub x: UnitLine,
        pub y: UnitLine,
    }

    #[derive(Debug, Default)]
    pub struct UnitLine(f32);

    impl UnitLine {
        pub fn set(&mut self, f: f32) -> Result<(), ()> {
            if 0. <= f && f <= 1. {
                self.0 = f;
                Ok(())
            } else {
                Err(())
            }
        }

        #[inline]
        pub fn get(&self) -> f32 {
            self.0
        }
    }
}
```

There are three things that I really like about this tactic. One, it allows the user to 
use deconstruction whenever and whereever they want. Two, it allows me to validate that
the user is providing strictly legal values for each field.  Three, it increases the
expressivity of my code: the fields have types which explicitly name what that field
can represent. It would be really nice to capture these things at compile time rather
than runtime; but it is what it is.  This, of course, can be made even more expressive
by defining an Error value that clearly names what the valid range is.

What I don't like about this design, is it creates a little more clunkiness when creating
new values of the `UnitSquare` type. At least for values which are basically just a single
primitive, it adds a little extra boilerplate code: you need to call a `new` function
and then deal with the fact that you get a `Result` back. I will need to try this out in
some of my own code before I come to an opinion, but I have high hopes.

Also, remember that Rust gives you more fidelity when setting the visibility of a field.
One common idiom I use is making a field `pub(mod)`; so within a submodule where a struct
is used heavily, I can easily access any field and use deconstruction to my hearts content.
But outside of the submodule, where there is a separation of concerns, the fields are
not visible.

Rust provides many new syntactic tools that make the question of field visibility much
more complex. I have found that by understanding if the struct represents the state of
a process or if it defines the syntax of a type of value is the most important question.
For a process, the user sees and cares about the process (what it is doing) and the user
should only have the methods which control that process. For a value definition, the user cares
about the data itself and using that data, so they will want simple and flexible access
to that data. The latter case is more complex, because improving access to the data
could cost you the ability to define acceptable values for primitive fields.  However,
the proposed method above solves that problem while increasing the expressiveness of
your code.
