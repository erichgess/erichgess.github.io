---
title: "Learning to Love Mediocre Code"
date: 2021-08-30T14:19:21-04:00
draft: true
---

I need love my mediocre code. Mediocre code is what you write when no intuition about 
what you're doing or what you're using: in other words, when you're outside your comfort
zone. Unless you stop pushing your boundaries it's impossible to not occasionally write mediocre code.
If you're learning a new language, you'll write a _lot_ of mediocre code.
So, we should take time to appreciate our mediocre code; as that's the code we write when
we're growing. And a lot can be learned by thinking about what decisions were made that
sacrificed great code for mediocre code and why.

Personally, I've always found a sense of slight shame and embarrassment when I 
write mediocre code.  But that, I've come to realize, is a hindrance and waste of
time and emotional energy. And to get over those feelings, I wrote this essay to
force me to expose some of my own mediocre code to the world. On my best days, I am a perfectionist
and want my code to be as efficiently communicative as possible. The silly result of
this is that I hate my mediocre code and unnecessarily feel a bit ashamed about it.

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

```rust
_ => Err(format!("L{}: {} is not a unary operator", line, op)),
```

Writing the Braid Compiler was my first large project in Rust. So, I had a lot to
learn about it, while also learning about language design and compiler construction. 
I was working in a world with essentially no intuition about anything: when I wasn't
trying to figure out what features needed to be added to my compiler and how to 
design them in Rust, I was being baffled by lifetimes and trying to remember how 
to use the std. Everyday was a balancing act between figuring out how to do something
right way in Rust, how to fit compiler components in the Rust semantics, and just 
getting things done. The perfect situation that can only be solved by biting the 
bullet and _choosing_ to write some mediocre code.

From the very start of my compiler, errors cases had to be handled; after all, giving
errors is the most important job of a compiler. The `Result` type is one of my favorite
tools, but there's the thorny question of what the error type ought to be. I made
a deliberate choice to use the simplest possible design for my Error types: just strings.
<Why was this simple and why was it mediocre? (Is this a repetition of above and is that wrong?)>
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
language meant that my choices would probably be wrong; no matter how much I learned about
error type strategies at _that_ moment. The
design that left the smallest footprint on the code base would also be the design
that's the easiest to change. The design needed to maintain the `Result` type for propagating
error information, because the structure that creates is what's _fundamental_ to Rust's
error handling.

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

Why do I love this mediocre design?  It got `braidc` what it needed  _and_
it still imposed the _structure_ in my code that even the best Rust error handling idioms
would impose. And, because I knew it was mediocre, I paid extra attention whenever I wrote
error handling into my code to _really_ understand what would make it great. 

And from that experience, came a set of goals that would lead me to a great design:
1. What error type design pattern fits best with my style?
1. What information do the error types need to capture?
1. How will error handling influence the code around it?
1. The support functions and syntactic sugar that Rust provides to help with error handling.
(e.g. the `?` operator will implicitly call `into` to convert an error from the call site
to the surrounding functions error type). <This was not touched upon earlier>
1. How do I aggregate multiple errors together?

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
