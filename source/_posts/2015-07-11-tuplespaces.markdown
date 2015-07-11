---
layout: post
title: "Tuplespaces?"
date: 2015-07-11 14:01:31 -0500
comments: true
categories: Distributed Programming, Clojure, Data Stores 
---

I have recently become very interested in the tuplespace architecture.  What got me interested (also what even made me aware at all) was a [blog post](http://writings.quilt.org/2014/05/12/distributed-systems-and-the-end-of-the-api/) from Chas Emerick.  In that post, he talked about alternative ways for communication in distributed systems.  The usual things were covered:  event sourcing, streaming, messaging, etc.  Tuplespaces were also mentioned, and I had no idea what that was, but the name is intriguing and I had to explore.

<!-- more -->

In my free time, I've been reading what I can find on the topic.  The problem is, there really isn't that much.  I have gotten the original paper on Linda:  a programming language based upon the tuplespace concept.  The lack of reading material makes it hard to figure out how to build a prototype system.

The basic concept is easy.  A tuple is a datastructure with a name and a set of values.  Some examples are: <"foo", 1, 2> (the name is "foo" and the value is (1,2)), <"name", "erich", 33>, or <"example", 1, 1.0, 3.0>.  Applications that want to communicate put and read tuples from a data store.  Tuples are looked up by name and pattern matching the values.  So you can specify a strict tuple: get(<"foo", 1, 2>) would check the tuplespace for <"foo", 1, 2>.  You can also search with a pattern: get(<"foo", 1, float>) this would find any tuple with the name "foo", first value is 1, and the second value is a float.  Multiple tuples can have the same name and exact duplicates can also be put into the tuplespace.  There are three basic operations:  put - write a tuple to the space, get - take a tuple from the space (the tuple is deleted), copy - make a copy of the tuple matching the pattern but don't delete it from the space.

Right now, I'm trying to figure out:

1. Is the tuplespace data storage handled at the application level or is there a central tuplespace service?  I would expect it to be like RabbitMQ where there is a central tuplespace store that all services ping when they want to work with data.  These seems like the only way a tuplespace could work.
1. What happens when there are duplicate tuples?  It is possible to have duplicate tuples in the space.  When you read from the space, do you get all the tuples or only one?
1. When asking for a tuple from the tuplespace, you can specify a pattern the tuple must match (e.g. the name is "foo" and the first value is 1 and the second value is a float.  This would match on the tuples <"foo", 1, 0.5> and <"foo", 1, 2.3>).  When you ask for a pattern with multiple matches, what do you get back?  Is it all the matches or just the first one?
1. Why allow duplicate tuples in the tuplespace?

I've been playing around with building a demo tuplespace system in Clojure, so that I am forced to find the answers to these questions.
