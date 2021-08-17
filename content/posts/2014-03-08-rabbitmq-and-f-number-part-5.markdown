---
layout: post
title: "RabbitMQ and F# - Part 5"
date: 2014-03-08 22:00:00 -0800
comments: true
categories: [RabbitMQ, F#]
---
Alright, I now have a simple usable RabbitMQ client library which fits comfortably with F#.  However, there's still some inconsistency in the design which I want to polish out:

1. To create a consumer on a  queue, you call:
```fsharp
createQueueConsumer myChannel "myQueue"
```
2. To create a read function for a queue, you call:
```fsharp
let (readFrom,_) = createQueueFuntions myChannel
let readFromMyQueue = readFrom "myQueue"
```
3. To create a write function for a queue, you call:
```fsharp
let (_,writeTo) = createQueueFuntions myChannel
let writeToMyQueue = writeTo "myQueue"
```
		
Why have a function which manages both the read AND the writes for a channel?  Why not split the read and write out to their own functions?  This is better in my opinion for one very obvious reason:  the code will explicitly explain what is happening.  With my current createQueueFuntions  function, there is nothing which tells you that you get a tuple and that the first element in the tuple is a write function and the second element is a read function.
<!-- more -->

Let's make things more explicit and thus more readable:
```fsharp
let createQueueReader channel queue = 
    readFromQueue channel queue

let createQueueWriter channel queue =
    publishToQueue channel queue
```

This will change the Sender application to this:
```fsharp
[<EntryPoint>]
let main argv = 
    let connection = openConnection "localhost"
    let channel = openChannel connection
    
    let writeToHelloQueue = createQueueWriter channel "hello"

    let mutable i = 0
    while true do
        i <- i + 1
        let message = sprintf "%d,test" ((i + 1) % 10)  // send a message with a number from 0 to 9 along with some text
        printfn "Sending: %s" message
        message |> writeToHelloQueue
        System.Threading.Thread.Sleep(1000)

    0 // return an integer exit code
```

BAM!  Now only what you need to survive is in the actual written code!

=====================================

There is a final bit of polish I want to hit for this version of my library.  This is my publish function:
```fsharp
let publishToQueue (channel:IModel) queueName (message:string) =
    declareQueue channel queueName |> ignore
    let body = Encoding.UTF8.GetBytes(message)
    channel.BasicPublish("", queueName, null, body)
```

The problem is the call to declareQueue.  This won't harm anything, what it does is create the queue if it does not already exist.  However, it will perform this action every single time you write a message to a queue.  That's definitely not needed.  I'll move this code over to where I create the writer function:
```fsharp
let createQueueWriter channel queue =
    declareQueue channel queue |> ignore
    publishToQueue channel queue
```

Now, declareQueue will only be called when you create a reader or a writer for a queue.

The complete source code to date:
```fsharp
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

    let publishToQueue (channel:IModel) queueName (message:string) =
        let body = Encoding.UTF8.GetBytes(message)
        channel.BasicPublish("", queueName, null, body)
        
    let createQueueReader channel queue = 
        declareQueue channel queue |> ignore
        
        fun () -> 
            let ea = channel.BasicGet(queue, true)
            if ea <> null then
                let body = ea.Body
                let message = Encoding.UTF8.GetString(body)
                Some message
            else
                None

    let createQueueWriter channel queue =
        declareQueue channel queue |> ignore
        publishToQueue channel queue

    let createQueueConsumer channel queueName =
        let consumer = new QueueingBasicConsumer(channel) 
        channel.BasicConsume(queueName, true, consumer) |> ignore

        fun () ->
            let ea = consumer.Queue.Dequeue()
            let body = ea.Body
            Encoding.UTF8.GetString(body)
```