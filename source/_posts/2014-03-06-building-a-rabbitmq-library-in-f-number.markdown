---
layout: post
title: "Building a RabbitMQ Library in F#"
date: 2014-03-06 07:44:30 -0800
comments: true
categories: [RabbitMQ, F#]
---

I've been doing a lot of experimenting with F# and distributed computing via messaging.  As evidenced by my previous, I'm using RabbitMQ as my messaging platform, for a couple of reasons: it's easy to use, it's free and open source, and I might decide to switch to RabbitMQ at work.  I've been having a lot of fun experimenting with RabbitMQ and F#.  However, I spend a lot of my time just writing and copy/pasting the boilerplate code needed to configure the RabbitMQ client libraries, add the fact that the .Net client library is written for C#, and you get a constant block of boring work.  So, purely for fun and profit, I'm going to write a quick F# wrapper.  The purpose of it being to let me very quickly setup RabbitMQ and, just as importantly, work with RabbitMQ in a manner that better fits F#.