---
layout: post
title: "Using RabbitMQ with F#"
date: 2014-03-04 19:56:20 -0800
comments: true
categories: [F#, RabbitMQ]
---

Over the last few years, one of the topics on which I have done much of my work has been distributed computing using message queues.  Recently, I've been playing around with RabbitMQ, not for any reason other than that I wanted a simple, easy to setup, and easy to use messaging framework, which I could use for little experiments at home.

I'm not going to talk about RabbitMQ.  What I am going to talk about is one of the many ways in which F# makes programming just an absolute blast.

Outside of work, most of my programming has been with F# (with a tiny bit of Clojure).  Naturally, I've done some experiments with using F# and RabbitMQ.  I'll cover that, but that's not really what this post is about.

My first attempt at this was to just follow the basic C# tutorial from www.rabbitmq.com, twisting it here and there for F#.  The tutorial you build a simple sender/receiver system:  one app sends messages to another app, which prints them to the console.  Which got me with some good workable boring code:
```
let factory = new ConnectionFactory(HostName = "localhost")
use connection = factory.CreateConnection()
use channel = connection.CreateModel()

channel.QueueDeclare( "hello", false, false, false, null )
let consumer = new QueueingBasicConsumer(channel)
channel.BasicConsume("hello", true, consumer)

while true do
    let ea = consumer.Queue.Dequeue() :> BasicDeliverEventArgs
    let body = ea.Body
    let message = Encoding.UTF8.GetString(body)
    printfn "%s" message
```
This will do its job.  Listening on the queue and writing the messages as they come in.  It's not spectaculor and it doesn't use any of the Consumer class framework which comes with RabbitMQ.  But again, this post isn't about using RabbitMQ, it's about using *sequence expressions*.

The Sequence Expression is a fun little construct in F# that lets you write programmatic enumerables.  For example, I want an enumerable with the numbers from 1 to 100, I would just write
```
let example = seq{ 1 .. 100 }
```
Or, what if I want a sequence of data, where everytime I ask for an element it gives me the current time:
```
let example2 = seq { 
						while true do
							yield DateTime.Now
				   }
```

The sequence expression got me to thinking about trying that out with the message queues.  So, I changed my receiver code to look like this:
```
let factory = new ConnectionFactory(HostName = "localhost")
use connection = factory.CreateConnection()
use channel = connection.CreateModel()

channel.QueueDeclare( "hello", false, false, false, null )
let consumer = new QueueingBasicConsumer(channel)
channel.BasicConsume("hello", true, consumer)

// I wrap the queue in a sequence expression
let queue = seq{
                while true do
                    let ea = consumer.Queue.Dequeue() :> BasicDeliverEventArgs
                    let body = ea.Body
                    let message = Encoding.UTF8.GetString(body)
                    yield message
            }
```
This creates an enumerable data structure called `queue`.  And this is where things get awesome, because I can now write *queries* to my queue of messages, exactly as I would to a database or list:
```
let qQuery = query{
                for message in queue do
                select i.ToUpper()
             }
qQuery |> Seq.iter (printfn "%d")
```
This query will select each message from the queue and convert it to all capital letters.  The Seq.iter will then pull each message from the query result and print it to the screen.  Do note that the `seq{...}` I bound to `queue` is an infinite loop, so `qQuery |> Seq.iter (printfn "%d")` will run forever, printing out each message as it arrives in the queue.

If you take a look at the [MSDN](http://msdn.microsoft.com/en-us/library/hh225374.aspx) article on F#'s Query Expressions, you'll see that there is a lot that can be done.  For example, if we had two different queues:
```
let doubleQuery = query{
                    for m1 in queue do
                    join m2 in queue2 on
                        (m1 = m2)
                    select (m1, m2)
                  }
```
Or maybe even a join between the message queue and a database query.

The long and short of all this is that I keep falling more in love with F#.  I get to spend so much time not writing boilerplate code and squiggly braces and so much time just doing.