'client
'run several copies of this client to see the interaction
'with the host
$SCREENHIDE
CONST false = 0, true = NOT false

RANDOMIZE TIMER

myWidth% = RND * 400
IF myWidth% < 150 THEN myWidth% = 150
myHeight% = RND * 250
IF myHeight% < 150 THEN myHeight% = 150
myColor~& = _RGBA32(RND * 255, RND * 255, RND * 255, 50)

SCREEN _NEWIMAGE(myWidth%, myHeight%, 32)

PRINT "Looking for host..."
host = _OPENCLIENT("TCP/IP:63450:localhost")
IF host = 0 THEN SYSTEM

PRINT "Connected to host; handshaking..."

start! = TIMER
reply = false
DO
    GET host, , incomingData$
    stream$ = stream$ + incomingData$
    IF INSTR(stream$, "<END>") THEN reply = true: EXIT DO
LOOP UNTIL TIMER - start! > 5 'timeout

IF reply THEN
    thisData$ = LEFT$(stream$, INSTR(stream$, "<END>") - 1)
    stream$ = MID$(stream$, INSTR(stream$, "<END>") + 5)
    thisCommand$ = LEFT$(thisData$, INSTR(thisData$, ">") - 1)
    IF thisCommand$ = "" THEN
        thisCommand$ = thisData$
    ELSE
        thisData$ = MID$(thisData$, LEN(thisCommand$) + 2)
    END IF

    IF thisCommand$ = "MSG" AND thisData$ = "HELLO!" THEN
        'we're in! let's send our dimensions
        b$ = "HELLO>" + MKI$(myWidth%) + MKI$(myHeight%)
        Send host, b$
    ELSE
        GOTO failed
    END IF
ELSE
    failed:
    SYSTEM
END IF

'connection established; wait for input and send the client's screen
ping = TIMER
DO
    IF _EXIT THEN
        b$ = "BYE!>"
        Send host, b$
        CLOSE host
        SYSTEM
    END IF

    GET host, , incomingData$
    stream$ = stream$ + incomingData$

    DO WHILE INSTR(stream$, "<END>")
        thisData$ = LEFT$(stream$, INSTR(stream$, "<END>") - 1)
        stream$ = MID$(stream$, INSTR(stream$, "<END>") + 5)
        thisCommand$ = LEFT$(thisData$, INSTR(thisData$, ">") - 1)
        IF thisCommand$ = "" THEN
            thisCommand$ = thisData$
        ELSE
            thisData$ = MID$(thisData$, LEN(thisCommand$) + 2)
        END IF

        SELECT CASE thisCommand$
            CASE "BYE!"
                SYSTEM
            CASE "CLICK"
                FOR i = 1 TO 30
                    CIRCLE (CVI(LEFT$(thisData$, 2)), CVI(RIGHT$(thisData$, 2))), i, _RGB32(255, 255, 255)
                NEXT
            CASE "PING"
                ping = TIMER
                b$ = "PONG>"
                Send host, b$
        END SELECT
    LOOP

    LINE (0, 0)-(_WIDTH, _HEIGHT), myColor~&, BF
    FOR i = 1 TO 1000
        PSET (RND * _WIDTH, RND * _HEIGHT), _RGB32(RND * 255, RND * 255, RND * 255)
    NEXT
    LOCATE 1, 1: PRINT RND

    myCanvas& = _COPYIMAGE(0)
    DIM imgMem AS _MEM
    imgMem = _MEMIMAGE(myCanvas&)
    b$ = SPACE$(imgMem.SIZE)
    _MEMGET imgMem, imgMem.OFFSET, b$
    _MEMFREE imgMem
    _FREEIMAGE myCanvas&

    IF prevImage$ <> b$ THEN
        prevImage$ = b$
        b$ = "IMAGE>" + b$
        Send host, b$
    END IF

    _DISPLAY
    _LIMIT 30
LOOP UNTIL TIMER - ping > 1
SYSTEM

SUB Send (channel, __theData$)
    theData$ = __theData$ + "<END>"
    PUT #channel, , theData$
END SUB

