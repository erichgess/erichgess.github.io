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
I am doing very little with RabbitMQ in my experiments.  I am not using subjects, or fan-out exchanges, or anything; except making queues, publishing messages to the queue, and reading from the queue.  The messages, for this post, will also just be simple text messages, so no serialization/deserialization.  So this is all I need (in version 1 :) ):

1. Create a queue on a RabbitMQ server
1. Publish a message to a specific queue
1. Read messages from a specific queue
1. Messages are just text messages

Easy Enough!  My first version of the RabbitMQ F# client will only do those 3 things.

##### Problem 2 Needs
This is purely aesthetic.  The more I worke in F#, the more I find writing up classes and implementing interfaces to feel a bit "ehhh".  So I want to make the way a developer uses and interacts with RabbitMQ to be more functional.  This is a bit more vague than I'd like, because this will require a bit more learning on my part; which is why I put it here!

##### Scope
At the end of all of this, my library will do just provide these three features:

1. Connect to or create a specified queue on a RabbitMQ server
1. Provide a way to publish messages to the queue
1. Provide a way to read messages from the queue

Behind the scenes it will do whatever setup/teardown is needed to get those 3 features to work.

#### The Design
The design needs to be more functional than OO, so that it fits better with the general aesthetic flow of writing F#.  Being new to functional design, I'll start with the [NOOO Manifesto](http://simontcousins.azurewebsites.net/manifesto/) as my guide:

- Functions and Types over classes
- Purity over mutability
- Composition over inheritance
- Higher-order functions over method dispatch
- Options over nulls

#### Queue Interaction
I'll start with designing how a developer will interact with the queue itself, because this will be 90% of what he or she would use this library for.  After that, will be the design for the part of the library which handles connecting to/creating the queue.

In OO design, I might represent the queue as a class which has methods for publishing and reading.  The first line of the NOOO Manifesto is "Functions and Types over classes": I want functions to represent the two actions of publishing and reading.  The queue itself can be represented by just the name for now, so that would be a string.

Both publish and read functions will require the target queue.  The read function won't require any other parameters, but the publish function will require the message.  The read function will return a message from the queue; that means a return type of string.  For the publish function:  RabbitMQ's `BasicPublish` is a void so that means that my function will be of type unit.

Here are the signatures of my first design:
{% codeblock lang:fsharp %}
let publishToQueue queueName message = ...
let readFromQueue queueName = ...
{% endcodeblock %}
Please note that I put the queue name as the first parameter for both functions.  This will let us take advantage of currying and partial application.  If there's a queue named "MyQueue" the developer can do partial application:
{% codeblock lang:fsharp %}
let publishToMyQueue  = publishToQueue "MyQueue"

publishToMyQueue "Hello, World"
{% endcodeblock %}
Being able to easily create unique functions for each queue will make our code easier to read, debug, refactor, and write.

That's it.  These two functions will define the basic interaction with queues.  A developer can use partial application to create a unique function for each queue in his or her system.  I'll do the actual implementation of the code at the end of the post.  This section was just about the design.

That's neat, but it's not as awesome as it could be.  In an earlier post, I showed how to build a sequence expression to encapsulate reading from the queue.  This is easily done, using the readFromQueue function:
{% codeblock lang:fsharp %}
seq{
    while true do
        yield readFromQueue queueName
}
{% endcodeblock %}

#### Connecting to the Queue
With RabbitMQ, the setup logic is pretty clear cut.  You start by building a connection factory (this is where you configure the location of the RabbitMQ server).  The factory is used to open a connection.  The connection is used to create a channel.  The channel is what you use to create or connect to or read from or write to the queue.