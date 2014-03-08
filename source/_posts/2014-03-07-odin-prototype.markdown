---
layout: post
title: "Odin Prototype"
date: 2014-03-07 23:32:30 -0800
comments: true
categories: 
---
In my previous post, I described a distributed monitoring system called Odin.  Which I am building because it will help me learn and explore topics in distributed computing independent of work.

I've been slowly working on it when I get a chance and have put together a very basic prototype:
https://github.com/erichgess/OdinPrototype

This prototype is some hacking I did over a few, very spread out days, to try out some concepts.  It has a very simple agent, which reads %CPU used and sends a message to a receiver.  That receiver this publishes that message as an IObservable.  Multiple mailbox processors subscribe to the Observable and use Reactive to do some queries on the incoming messages.

This is very very little.  However, it served as a way for me to try out a few different concepts: RabbitMQ, Mailbox Processors, and Reactive.