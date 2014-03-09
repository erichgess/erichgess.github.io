---
layout: post
title: "RabbitMQ and F# - Part 4"
date: 2014-03-08 21:55:44 -0800
comments: true
categories: [RabbitMQ, F#]
---
In my previous post, I made my RabbitMQ client library a bit more functional by removing the Queue record type and replacing it with higher order functions.  These higher order functions are used for creating functions for reading/writing queues.  If you want to use "MyQueue" for writing, you use the "writeTo" higher order function to create a function for writing to "MyQueue".  It's sounds more complex than it really is.

I did that because I mentioned two things about my initial effort which bothered me:  it wasn't functional enough and it didn't support RabbitMQ consumers.  I got the first taken care of.  Now I am going to get the second.

I will follow the same higher order function approach:
{% codeblock lang:fsharp %}
let createQueueConsumer channel queueName =
    let consumer = new QueueingBasicConsumer(channel) 
    channel.BasicConsume(queueName, true, consumer) |> ignore

    fun () ->
        let ea = consumer.Queue.Dequeue()
        let body = ea.Body
        Encoding.UTF8.GetString(body)
{% endcodeblock %}
This will take a channel and a queue name, then return a function which will return one message from the consumer queue.

The complete source code up until now:
<!-- more -->
{% codeblock lang:fsharp %}
namespace RabbitMQ.FSharp

open RabbitMQ.Client
open RabbitMQ.Client.Events
open System.Text

module Client =
    type Queue = { Name: string; Read: unit -> string option; Publish: string -> unit }

    let openConnection address = 
        let factory = new ConnectionFactory(HostName = address)
        factory.CreateConnection()

    // I need to declare the type for connection because F# can't infer types on classes
    let openChannel (connection:IConnection) = connection.CreateModel()

    let declareQueue (channel:IModel) queueName = channel.QueueDeclare( queueName, false, false, false, null )

    let readFromQueue (channel:IModel) queueName =
        declareQueue channel queueName |> ignore

        fun () -> 
            let ea = channel.BasicGet(queueName, true)
            if ea <> null then
                let body = ea.Body
                let message = Encoding.UTF8.GetString(body)
                Some message
            else
                None

    let publishToQueue (channel:IModel) queueName (message:string) =
        declareQueue channel queueName |> ignore
        let body = Encoding.UTF8.GetBytes(message)
        channel.BasicPublish("", queueName, null, body)

    let createQueueFuntions channel =
        (readFromQueue channel, publishToQueue channel)

    let createQueueConsumer channel queueName =
        let consumer = new QueueingBasicConsumer(channel) 
        channel.BasicConsume(queueName, true, consumer) |> ignore

        fun () ->
            let ea = consumer.Queue.Dequeue()
            let body = ea.Body
            Encoding.UTF8.GetString(body)
{% endcodeblock %}