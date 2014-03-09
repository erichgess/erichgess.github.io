---
layout: post
title: "RabbitMQ and F# - Part 3"
date: 2014-03-08 21:38:01 -0800
comments: true
categories: [RabbitMQ, F#]
---

I now have a functioning RabbitMQ Library!  Though, there is a lot more to be done to make it satisfactory.

There are two problems:

1. Missing the Queue Consumer functionality.  This makes it a lot easier to deal with RabbitMQ so I definitely want to get this in.
1. I'm not happy with using the record type to capture the Read and Publish functions for a queue.   After all, how often are you going to be writing to and reading from a specific queue in the same process?

I will start by fixing #2, as that is bothering me the most.  The design, at present, has this flow:

1. Connect to a RabbitMQ server
2. Open a channel
3. Request a connection to a queue
4. Receive a function for writing to the queue and a function for reading from the queue

The first question I have is:  how often are you going to be reading from and writing to the same queue in the same code?  Probably not very often.  Which means that, most of the time, only half of what I am returning is useful.   We can simplify this.  Rather than build the Read and Write functions for you, they should be built only when you need them.

I will change the design so that rather than opening a queue and getting back two functions.  There will be two functions which can write or read to any queue.

My next design approach will be to update the function which creates a channel to now also return two functions:  one function will be for using the channel to write to a queue, the function is for using the channel to read from a queue.  Now if you want to setup a publishing function to "MyQueue" you use the returned write function and partial application to build the writeToMyQueue function.

I've modified my readFromQueue function so that it now takes a channel and a queue name and returns a function which will read one message from the queue:
{% codeblock lang:fsharp %}
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
{% endcodeblock %}

Then I made this new function:
{% codeblock lang:fsharp %}
let createQueueFuntions channel =
    (readFromQueue channel, publishToQueue channel)
{% endcodeblock %}
Which will take a channel and return two functions.  One for writing to a specific queue and one for reading from a specific queue.  You can then use these two functions to connect to queues as you need.  Once a developer reaches this point, all he or she needs to think about are: queue names, do I want to read from this queue, and do I want to write to this queue.

For example, in my receiver the code is now:
{% codeblock lang:fsharp %}
[<EntryPoint>]
let main argv = 
    let connection = openConnection "localhost"
    let myChannel = openChannel connection
    let (readFrom,_) = createQueueFuntions myChannel

    let readFromHelloQueue = readFrom "hello"

    while true do
        let message = readFromHelloQueue()
        match message with
        | Some(s) -> printfn "%s" s
        | _ -> ()

    0 // return an integer exit code
{% endcodeblock %}
I don't care about writing to queues at all, so I completely ignore the write function which createQueueFunctions returns.

The Sender code now looks like this:
{% codeblock lang:fsharp %}
[<EntryPoint>]
let main argv = 
    let connection = openConnection "localhost"
    let channel = openChannel connection
    let (_,writeTo) = createQueueFuntions channel
    
    let writeToHelloQueue = writeTo "hello"

    let mutable i = 0
    while true do
        i <- i + 1
        let message = sprintf "%d,test" ((i + 1) % 10)  // send a message with a number from 0 to 9 along with some text
        printfn "Sending: %s" message
        message |> writeToHelloQueue
        System.Threading.Thread.Sleep(1000)

    0 // return an integer exit code
{% endcodeblock %}
I find that this design is a lot better.  Functions for reading and writing are only created when you need to read or write to a queue.  The channel object can now safely be ignored after the initial setup, instead everything boils down to: what do I want to do with this queue.  When you write with this framework, you now are no longer concerned with what objects you have at hand and what you can do with those objects; you are just concerned with what you want to do.

The complete source as of this point:
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

    let connectToQueue connection (channel:IModel) queueName =            
        declareQueue channel queueName |> ignore

        {Name = queueName; 
        Read = (fun () -> 
                        let ea = channel.BasicGet(queueName, true)
                        if ea <> null then
                            let body = ea.Body
                            let message = Encoding.UTF8.GetString(body)
                            Some message
                        else
                            None); 
        Publish = (publishToQueue channel queueName)}
{% endcodeblock %}