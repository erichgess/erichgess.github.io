---
title: "The Painful Experience of Learning"
date: 2021-08-05T17:05:06-04:00
draft: true
---

The experience of learning a new language. Around the beginning of the year, I began to teach myself
the Rust programming language. While learning Rust, one sensation that I felt to an incredible degree
was the sense of being "dumb". As I wrote code in Rust, the code quality felt poor, my designs felt
clumsy, and I felt like I'd lost all my abilities to write code. What bothered me was why?  Why did
I feel like this and why was my code so much worse than I expect of myself?  Was I over the hill, 
had I lost my skill, or what.

This is something that I really wanted to get to the bottom of, because it made me feel bad and in
turn, throttled my motivation to learn, and my confidence in my abilities. More than anything, I 
wanted to know why I felt like the designs I created felt so clumsy and wrong.

What finally gave me they key was a video of mathematician 
[Terrence Tao](https://www.youtube.com/watch?v=48Hr3CT5Tpk) talking about the stages
of learning. There's a pre-formal phase where you're just using gut feeling to smash things together,
then there's a formal phase where you learn the existing formal rules for how things work, and
finally, a post formal phase, where you go back to working primarily off of intuition but you have
enough formal knowledge that your intuition is generally right.

While learning Rust, I was now in a position where I had no knowledge of the language, no strong
intuition for how write code in the language, and next to no experience. The result was, that all
of my brain power was devoted to just learning the language, looking things up online, and, generally,
stumbling around. With all my conscious effort being directed towards just writing code, I had no
free energry or time to think about design or layout. The end result was, code that worked but designs
which always felt just a little too wrong.

Basic things like error handling became a huge design problem for me at first.  The idea of using
Result types is simple, but what to use for error values, how to design and group those errors, etc.
These were things that I didn't have a strong instinct for.  Both because I was new to Rust and
because most programs I've written in the past did not require _me_ to write my own error or
exception types.  Those came from libraries and I merely had to decide whether to handle them or 
propagate them.

What I had to accept was, I wouldn't be comfortably and naturally writing well designed code until
I had built a strong intuition for Rust.  And I wouldn't get that intuition until I had spent a
lot of time programming Rust.  I was in the "pre-formal" phase, just banging code together and 
clumsily writing code until I had done enough to have a strong feel for how Rust works. After a bit,
I finally hit that moment where Rust felt incredibly natural and obvious.  I knew how to do what I
wanted and make it work and have code that was at least decent.  At the same moment, I found that
I got more value from reading documentation or guides or blogposts.  I could read a blog post about
error handling design and walk away with a better philosophy for using error handling to express
information and build code that would insure correctness as my program grows.

It's important to dive into the deep end once in a while and learning something that is far outside
of your base of intuition. It helps remind you of what it's like to be ignorant, your knowledge and
skill expands at the fastest rate possible, and its fun. But it's worth remember, when you do this,
you will feel really dumb, clumsy, and incompetent for awhile; and the more experience you have the
more intense those feelings will be.