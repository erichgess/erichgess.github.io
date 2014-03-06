---
layout: post
title: "Building a RabbitMQ Library in F#"
date: 2014-03-06 07:44:30 -0800
comments: true
categories: [RabbitMQ, F#]
---

I've been doing a lot of experimenting with F# and distributed computing via messaging.  As evidenced by my previous, I'm using RabbitMQ as my messaging platform, for a couple of reasons: it's easy to use, it's free and open source, and I might decide to switch to RabbitMQ at work.  I've been having a lot of fun experimenting with RabbitMQ and F#.  However, I spend a lot of my time just writing and copy/pasting the boilerplate code needed to configure the RabbitMQ client libraries, add the fact that the .Net client library is written for C#, and you get a constant block of boring work.  So, purely for fun and profit, I'm going to write a quick F# wrapper.  The purpose of it being to let me very quickly setup RabbitMQ and, just as importantly, work with RabbitMQ in a manner that better fits F#.

Design
------
I want to use this as an opportuntity to practice all of my engineering skills.  So, I'm going to start by defining the problem I want to solve, the scope of work, and then the design itself.  For the problem: I will try to understand what my needs are, right now, and predict what they will be in the future.  For the scope of work:  RabbitMQ has a lot of stuff, so I will use the definition of the problem to decide how much of the RabbitMQ framework I will expose with my wrapper.  The design:  this is when I will figure out how I want to use this library and how to make it fit the F#/functional paradigm.  I will do all of this, before I start writing any code!

#### The Problem(s)
Right now, I have two problems when I'm trying to do a messaging experiment in F#:
1. I have to rewrite the RabbitMQ setup code every time I make a new endpoint.
1. It's OO/C# focused design doesn't fit very well with F#.  It works, but, I think, it will be better if it's functional.