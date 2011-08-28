Coffee-IRC
==========
(I imagine I'll come up with a better name for this at some point)

Basically, the long term objective is to write a browser-based IRC client with a built in javscript/coffeescript prompt thingy.
Obviously javascript in web browsers can't just open sockets, so the client will have to communicate with a proxy server which
then does the communication on its behalf.

Somewhere I needed to write or use an actual IRC client, So I had two choices:
1. Have all the IRC logic on the server, and write a dumb client that just sends basic commands.
2. Have all the IRC logic on the client, and have the server simply shuttle raw data from websocket->TCP

I'm going for 3: Write a library which will work on the server OR client, and decide where to stick it later on.
I've a feeling I'll probably go for option 2, though.
