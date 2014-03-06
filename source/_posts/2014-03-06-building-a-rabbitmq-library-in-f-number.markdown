---
layout: post
title: "Building a RabbitMQ Library in F#"
date: 2014-03-06 07:44:30 -0800
comments: true
categories: [RabbitMQ, F#]
---

I've been doing a lot of experimenting with F# and distributed computing via messaging.  As evidenced by my previous, I'm using RabbitMQ as my messaging platform, for a couple of reasons: it's easy to use, it's free and open source, and I might decide to switch to RabbitMQ at work.  I've been having a lot of fun experimenting with RabbitMQ and F#.  However, I spend a lot of my time just writing and copy/pasting the boilerplate code needed to configure the RabbitMQ client libraries, add the fact that the .Net client library is written for C#, and you get a constant block of boring work.  So, purely for fun and profit, I'm going to write a quick F# wrapper.  The purpose of it being to let me very quickly setup RabbitMQ and, just as importantly, work with RabbitMQ in a manner that better fits F#.

<!-- more -->

Design
------
I want to use this as an opportuntity to practice all of my engineering skills.  So, I'm going to start by defining the problem I want to solve, the scope of work, and then the design itself.  For the problem: I will try to understand what my needs are, right now, and predict what they will be in the future.  For the scope of work:  RabbitMQ has a lot of stuff, so I will use the definition of the problem to decide how much of the RabbitMQ framework I will expose with my wrapper.  The design:  this is when I will figure out how I want to use this library and how to make it fit the F#/functional paradigm.  I will do all of this, before I start writing any code!

#### The Problem(s)
Right now, I have two problems when I'm trying to do a messaging experiment in F#:

1. I have to rewrite the RabbitMQ setup code every time I make a new endpoint.
1. It's OO/C# focused design doesn't fit very well with F#.  It works, but, I think, it will be better if it's functional.
1. Long term, I'd like to make up a simple RabbitMQ F# Client library which anyone could use.

I threw number 3 on there, not because it is a problem I am trying to solve right now, but because this something which could contribute to the F# community.  By keeping this in mind as a long term goal, it will help me write my solution so that it is easy to expand.

#### The Scope
For scope, I'll look at the first two problems and ignore the third.  Problem 2 shouldn't impact the scope very much, as it's really a restriction on my design:  make the design fit the functional paradigm.  Problem 1 definitely can impact the scope of work:  there is a lot to RabbitMQ and doing a full client implementation in F# would be a LOT of work.  To define the scope of work I am going to do, I'll focus on explicitly writing out my needs and then only do the amount of work necessary to meet those needs.

##### Problem 1 Needs
I am doing very little with RabbitMQ in my experiments.  I am not using subjects, or fan-out exchanges, or anything; except making queues, publishing messages to the queue, and reading from the queue.  So this is all I need (in version 1 :) ):

1. Create a queue on a RabbitMQ server
1. Publish a message to a specific queue
1. Read messages from a specific queue

Easy Enough!  My first version of the RabbitMQ F# client will only do those 3 things.

##### Problem 2 Needs
This is purely aesthetic.  The more I worke in F#, the more I find writing up classes and implementing interfaces to feel a bit "ehhh".  So I want to make the way a developer uses and interacts with RabbitMQ to be more functional.  This is a bit more vague than I'd like, because this will require a bit more learning on my part; which is why I put it here!

