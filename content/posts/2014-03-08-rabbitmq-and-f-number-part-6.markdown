---
layout: post
title: "RabbitMQ and F# - Part 6"
date: 2014-03-08 22:08:19 -0800
comments: true
categories: [RabbitMQ, F#]
---
A final round of polish.  Now that I have the layout and flow for using my RabbitMQ library defined, it's time to go through and do a bit of clean up on my names.  There's a lot I can do to make it so that code you write with this library becomes as readable and literate as possible.

Here's the code you write to do the initial setup:
```fsharp
let connection = openConnection "localhost"
let myChannel = openChannel connection
```

If I just look at this, I have to ask:  open connection to what?  Context would probably help, but this function will get called only once in an entire application, so there's not much reason to hold back on the name.  I like the fluent style of naming, so I'll go with:
```fsharp
let connection = connectToRabbitMqServerAt "localhost"
```
I'll also make the second line a little more fluent:
```fsharp
let myChannel = openChannelOn connection
```

Which turns my setup code to:
```fsharp
let connection = connectToRabbitMqServerAt "localhost"
let myChannel = openChannelOn connection
```

And that's it for now!  I have a library which will let me write code to connect to and send a message on RabbitMQ in about 4 lines of code.  Pretty damn good, IMO.
```fsharp
let connection = connectToRabbitMqServerAt "localhost"
let channel = openChannelOn connection

let writeToHelloQueue = createQueueWriter channel "MyQueue"
"Hello" |> writeToHelloQueue
```