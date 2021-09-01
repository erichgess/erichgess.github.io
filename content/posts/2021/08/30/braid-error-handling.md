---
title: "Learning to Love Mediocre Code"
date: 2021-08-30T14:19:21-04:00
draft: true
---

I need love the mediocre code that I write. Unless you
stop pushing your boundaries it's impossible to not occasionally write mediocre code.
If you're learning a new language, you'll write a _lot_ of mediocre code, or you're 
working in a completely new domain of engineering, or you've got a tight deadline, etc.
So, we should take time to appreciate our mediocre code; as that's the code we write when
we're growing. And a lot can be learned by thinking about what decisions were made that
sacrificed great code for mediocre code and why.

```rust
_ => Err(format!("L{}: {} is not a unary operator", line, op)),
```

Writing the Braid Compiler was my first large project in Rust. So, I had a lot to
learned while also designing my language and my compiler. This led to me figuring out
a lot of ways to balance devoting time to _learn_ how to write really good idiotmatic
Rust and actually building features for my compiler. Leading me to write code that I
judged as mediocre but acceptable and moving on. On my best days, I am a perfectionist
and want my code to be as efficiently communicative as possible. The silly result of
this is that I hate my mediocre code and unneccessarily feel a bit ashamed about it.

But there's nothing _wrong_ with writing mediocre code. In fact, it's unavoidable when
you're first learning something that's far outside of your comfort zone. Writing great
code requires a strong intuition for the problem domain you're working in _and_ the
fundamentals of the language you're using; because writing great code requires some
level of present mental focus on the design of the code and if all your mental energy
is on remembering how the language works or how intuitive sense of the parts of a 
compiler, then you have no bandwidth for the code itself. So, writing mediocre code
can represent that beautiful period of time when you are _truly_ learning.

There's something wonderful when you consciously write mediocre code as an aid to
learning.  And you can write _good_ mediocre code, by writing code that uses your
past experience and your awareness of your current gaps in knowledge to mitigate the
cost of mediocrity and provide a path for turning the code into great code in the 
future.

To help me spend less time worrying about writing mediocre code and stressing about 
other people judging my code. I will review one of my mediocre designs and think about:
why it's mediocre (IMO), why I made certain decisions, what I got by making those
decisions, and what I learned and would do instead with that learning.

The design for error handling in `braidc` is very basic and not idiomatic 
Rust. <Why is it not idiomatic? Point out the importance of the types used for errors> 

From the very start of my compiler, errors cases had to be handled; after all, giving
errors is the most important job of a compiler. I made
a deliberate choice to use the simplest possible design for my Error types: just strings.
<Why was this simple and why was it mediocre? (Is this a repitition of above and is that wrong?)>
Why? One, I did not know enough Rust to make good judgements on how more complex design
choices might shape my productivity and code. Two, with so much Rust to learn, I made a choice
that I didn't have time to do a lot of reading about different error handling strategies:
lacking experience would make my judgements on the strategies untrustworthy and I would gain
more knowledge focusing on filling in other gaps in my Rust knowledge.

```rust
pub fn unary_op(
    line: u32,
    op: &Lex,
    operand: Box<Self>,
) -> ParserResult<Expression<ParserContext>> {
    match op {
        Lex::Minus => Ok(Some(Expression::UnaryOp(
            line,
            UnaryOperator::Negate,
            operand,
        ))),
        Lex::Not => Ok(Some(Expression::UnaryOp(line, UnaryOperator::Not, operand))),
        _ => Err(format!("L{}: {} is not a unary operator", line, op)),
    }
}
```

At the time, I felt unsatisfied with this decision, but I was also happy to make it. I
knew that I would make much better judgements on what error handling strategies and designs
would work best in `braidc`.  Being new to Rust and have very little intuition for the 
language meant that my choices would probably be wrong. The
design that left the smallest footprint on the code base would also be the design
that's the easiest to change. The design needed to maintain the `Result` type for propagating
error information, because the structure that creates is what's _fundamental_ to Rusts's
error handling.

Right now, in `braidc` everything returns `Result<_, String>`. 

```rust
fn extern_def(stream: &mut TokenStream) -> ParserResult<Extern<u32>> {
    match stream.next_if(&Lex::Extern) {
        Some(token) => match function_decl(stream, true)? {
            Some((fn_line, fn_name, params, has_varargs, fn_type)) => {
                if has_varargs && params.len() == 0 {
                    return Err("An extern declaration must have at least one \\
                     parameter before a VarArgs (...) parameter"
                        .into());
                }
                stream.next_must_be(&Lex::Semicolon)?;
                Ok(Some(Extern::new(
                    &fn_name,
                    fn_line,
                    params,
                    has_varargs,
                    fn_type,
                )))
            }
            None => Err(format!(
                "L{}: expected function declaration after extern",
                token.l
            )),
        },
        None => Ok(None),
    }
}
```

Why do I love this mediocre design?  It was fast to design and use in my code _and_
it still imposed the _structure_ in my code that even the best Rust error handling idioms
would impose; therefore, making a more idiomatic set of Error types would be contained to
just the parts of my code that created the Error value. And I was able to write 
enough errors to learn what my error types need to capture. I didn't find myself going back and rewriting or
redesigning my error handling for a very long time.  I always knew it was a "just fine"
design, but it never impacted my productivity or my code quality. So, I was able to focus
on getting the other parts of my code good to great.

I now know that these are the key questions I need to answer:

1. What error type design pattern fits best with my style?
1. What information do the error types need to capture?
1. How will error handling influence the code around it?
1. The support functions and syntactic sugar that Rust provides to help with error handling.
(e.g. the `?` operator will implicitly call `into` to convert an error from the call site
to the surrounding functions error type). <This was not touched upon earlier>
1. How do I aggregate multiple errors together?

For the first question: I can create an enum that covers the different
classes of errors that will happen in my code. Each submodule represents a key domain within
the compiler and will have very different types of errors from other modules: so I will create
an error enum for each module. One pattern that I've seen is the use of an `ErrorKind` inner
value, but I do not yet know if this will be used in my code.

An error needs to provide enough information that a user can fix what caused the error with
minimal effort. Obviously, this will include a text message explaining the nature of the
error.  And this will also need to tell the user where the source of the error is in the
input file.  The error also should include any lexemes, syntacts, or semantic
information that is related to the error: e.g., if a undeclared variable is used then the error
message should include the variable name.

The error information should have as little impact on the surrounding code as possible.
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
<This is way too long, shorten by a lot>
1. Start simple and minimize tentacles into surrounding code.  What I liked about 
`Result<_, String>` is that it was simple and I could easily use it anywhere and I
could easily make changes to errors to improve clarity.  I also did not have to write
any helper functions to work with my errors. One problem is that it had a little bit of
tentacleness: with needing line numbers for every error, which meant that I had to always
get a line number from a AST node and thread it down threw every place that I threw
an error.
1. Begin with a simple Error enumeration.
1. Use helper functions and macros to simplify creating error values.

What's great about just diving in and using a mediocre design for my error handling
rather than just copying a strategy, is that I built a much more effective intuition
of what good error types need to capture. Mediocrity meant that I put a lot more thought
into what I was doing so that I could make it better in the future. If we want to get
good at something, we must be willing to do it poorly; that's the only way to build
intuition and become great.
