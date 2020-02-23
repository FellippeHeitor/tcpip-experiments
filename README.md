# TCP/IP Experiments in QB64

The code in this repository demonstrates how to use a local TCP/IP connection to exchange data between two running instances of QB64 programs.

# Contents

All of the samples below require you to "unblock" them at the first run, as Windows requests your permission for them to open a port for local communication.

## simple-host-client

![](screenshots/drawing.png?raw=true)

This single-module experiment works both as host and client, so you will have to run the executable twice to get to see it working.

When run, it attempts to connect to an existing host. If that fails, it becomes the host itself and starts listening for connections in arbitrarily numbered port 60710.

When a client connects, the host sends a "HELLO" message and starts listening for commands. At this point, the user can draw in the client window and see the result in the host window, as mouse data is being transferred.

If the user hits SPACE in the client window, a prompt will be presented and a command can be typed. The available commands are:

* TIME - requests the current time from the host
* DATE - requests the current date from the host
* WISDOM - requests a smart-aleck sentence from the host.
* MSG - sends a message to the host. The format is `MSG>your message`.
* CLS - instructs the host to clear its window.
* BYE - disconnected from the host and ends the CLIENT execution.

The "protocol"  for communication follows the pattern "COMMAND>contents<END>", which gets transfered via SUB Send().

Closing either side will also send a BYE message to the other party, so that connection can be properly closed.

## inform-host-client

![](screenshots/inform.png?raw=true)

These are two separate modules written using InForm for QB64. The host waits for a client to connect and then sends commands to render graphics on the client's window.

Launch both and click the "offline" text in the client, so connection can take place.

After connected, click the buttons in the host to add a "New rectangle" or a "New circle" to the client's PictureBox control. As soon as you create either shape, you can change their color to red with the "Make it Red" button or to a random color with the appropriate button. You can only change the color of the last created shape.

If you click the picture in the client's window, the image will be sent over to the host, which will display it.

The "protocol"  for communication is slightly different here, with each message being marked by a "signal" the the start (using the return of the MKI$() function of an arbitraty value), followed by the data to be sent and the "<END>" marker, which is parsed for.

## windowing-host-client

![](screenshots/windowing.png?raw=true)

These two modules are the most ambitious of the trio. With regards to how they communicate, they still work the same as the samples before. The message protocol here is more similar to the first _simple-host-client_ sample above, but the contents being shared are what make this one different.

Run the windowingHost first, and it will begin listening for connections through arbitrarily numbered port 63450.

Then run the windowingClient module. You will not see a new program launch this time, but the client will instead send its rendered contents over TCP/IP to the host, which will display the window inside its own window.

You should launch more instances of teh windowingClient to see this sample really shine. Each new instance of the client will get its own window inside the host. These are draggable and you can even click inside them. The clicks will be sent to each client and you will see them react accordingly, by drawing a circle on the indicated coordinates.
