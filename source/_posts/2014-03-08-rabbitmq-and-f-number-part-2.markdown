---
layout: post
title: "RabbitMQ and F# - Part 2"
date: 2014-03-08 21:15:36 -0800
comments: true
categories: [RabbitMQ, F#]
---

Notes about RabbitMQ:
	- You should have one connection per application and one channel per thread (http://stackoverflow.com/a/10501593)

I was able to build and run my sender and receiver, both using my client.

However, something odd happened.  The receiver was only printing out every other message which the Sender sent.

<!-- more -->

{% img /images/posts/rabbitmq_and_fsharp/missing_messages.png %}

Here's the secret of what's happening:

{% img /images/posts/rabbitmq_and_fsharp/too_many_consumers.png %}

OH SNAP!  There are two consumers on the queue and RabbitMQ is splitting the messages evenly between the two consumers.

My suspicion is that the Sender is also opening up a consumer.  I can verify this easily by starting only the Sender and looking at the RaabbitMQ console:

{% img /images/posts/rabbitmq_and_fsharp/too_many_consumers_2.png %}

Sure enough, there's one consumer!  So the Sender is also opening up a consumer and reading messages from the queue.

The culprit is almost certainly this bit of code:
{% codeblock lang:fsharp %}
let consumer = new QueueingBasicConsumer(channel) 
channel.BasicConsume(queueName, true, consumer) |> ignore

{Name = queueName; 
Read = (fun () -> readFromQueue consumer queueName); 
Publish = (publishToQueue channel queueName)}
{% endcodeblock %}

I create a consumer and attach it to the queue every time a request is made to open a queue.  My assumption had been that a message would only be read from the queue when `consumer.Queue.Dequeue()` was called.  This is a fairly obvious error, in hindsight.  Reading the documentation further, I see that the consumer sets up a subscription to a queue and messages are automatically read; making this a push pattern.  To do a pull pattern, I would just use BasicGet on the queue.
 
A basic get example, in C#:
{% codeblock lang:csharp %}
BasicGetResult result = channel.BasicGet(queueName, noAck);
{% endcodeblock %}

I do want to have subscriptions and for this to be useful in my future projects.  However, for now my goal is to get a simple functioning library.  So I will switch my code over to use the basic get.
{% codeblock lang:fsharp %}
let connectToQueue connection (channel:IModel) queueName =           
    declareQueue channel queueName |> ignore

    {Name = queueName; 
    Read = (fun () -> 
                    let ea = channel.BasicGet(queueName, true)
                    if ea <> null then
                        let body = ea.Body
                        let message = Encoding.UTF8.GetString(body)
                        message
                    else
                        ""); 
    Publish = (publishToQueue channel queueName)}
{% endcodeblock %}

The Read function now does a BasicGet and decodes the message.

The result:

{% img /images/posts/rabbitmq_and_fsharp/right_number_consumers.png %}

No more extra consumer!

I really don’t like the part where I return "" if there is nothing in the queue.  There's already a great way of handling that in F#.  So I'll change the Read function to return a string option, which will change my code to:
{% codeblock lang:fsharp %}
Read = (fun () -> 
                let ea = channel.BasicGet(queueName, true)
                if ea <> null then
                    let body = ea.Body
                    let message = Encoding.UTF8.GetString(body)
                    Some message
                else
                    None);
{% endcodeblock %}

This is good, because it will force developers using this function to deal with both the case where a message is on the queue and the case where there is no message on the queue.
