'host
SCREEN _NEWIMAGE(800, 600, 32)

CONST false = 0, true = NOT false

DO
    IF attempts > 1000 THEN PRINT "Unable to start as host.": END
    host = _OPENHOST("TCP/IP:63450")
    attempts = attempts + 1
LOOP UNTIL host

Status "Listening on port 63450..."

TYPE CLIENT
    id AS LONG
    handle AS LONG
    active AS _BYTE
    image AS LONG
    x AS INTEGER
    y AS INTEGER
    w AS INTEGER
    h AS INTEGER
    ping AS SINGLE
END TYPE

maxConnections = 10
DIM SHARED client(1 TO maxConnections) AS CLIENT
DIM SHARED stream(1 TO maxConnections) AS STRING
DIM SHARED totalClients AS INTEGER, totalIDs AS LONG

DO
    'get mouse data
    WHILE _MOUSEINPUT: WEND
    mX = _MOUSEX
    mY = _MOUSEY
    mb = _MOUSEBUTTON(1)
    mb2 = _MOUSEBUTTON(2)

    'detect which client is being hovered
    IF mX <> oldMx OR mY <> oldMy THEN
        hover = 0
        oldMx = mX
        oldMy = mY
        FOR i = totalClients TO 1 STEP -1
            IF mX >= client(i).x AND mX <= client(i).x + client(i).w AND mY >= client(i).y AND mY <= client(i).y + client(i).h THEN
                IF client(i).active THEN
                    hover = i
                    EXIT FOR
                END IF
            END IF
        NEXT
    END IF

    IF mb THEN
        IF NOT mouseDown THEN
            mouseDown = true
            IF hover < totalClients THEN
                SWAP client(hover), client(totalClients)
                hover = totalClients
            END IF
            IF hover > 0 THEN
                dragging = hover: dragX = mX: dragY = mY
                originalX = mX: originalY = mY
                Status "Dragging client #" + STR$(dragging)
            END IF
        ELSE
            IF dragging THEN
                client(dragging).x = client(dragging).x + (mX - dragX)
                client(dragging).y = client(dragging).y + (mY - dragY)
                dragX = mX
                dragY = mY
            END IF
        END IF
    ELSE
        IF mouseDown THEN
            IF dragging THEN
                IF mX = originalX AND mY = originalY THEN
                    'just a click
                    b$ = "CLICK>" + MKI$(mX - client(dragging).x) + MKI$(mY - client(dragging).y)
                    Send client(dragging).handle, b$
                END IF
                dragging = false
            END IF
            Status "Idle."
            mouseDown = false
        END IF
    END IF

    IF mb2 THEN
        IF NOT mouse2down THEN mouse2down = true
    ELSE
        IF mouse2down THEN
            mouse2down = false
            IF hover > 0 THEN
                'close this client
                closeClient hover
            END IF
        END IF
    END IF

    IF totalClients < UBOUND(client) THEN
        'look for new clients until limit is reached
        newClient = _OPENCONNECTION(host)
        IF newClient THEN
            Status "new client connected; handshaking..."
            _DISPLAY

            totalClients = totalClients + 1

            client(totalClients).handle = newClient
            Send newClient, "MSG>HELLO!"

            start! = TIMER
            reply = false
            DO
                GET newClient, , incomingData$
                stream(totalClients) = stream(totalClients) + incomingData$
                IF INSTR(stream(totalClients), "<END>") THEN reply = true: EXIT DO
            LOOP UNTIL TIMER - start! > 5 'timeout

            IF reply THEN
                thisData$ = LEFT$(stream(totalClients), INSTR(stream(totalClients), "<END>") - 1)
                stream(totalClients) = MID$(stream(totalClients), INSTR(stream(totalClients), "<END>") + 5)
                thisCommand$ = LEFT$(thisData$, INSTR(thisData$, ">") - 1)
                IF thisCommand$ = "" THEN
                    thisCommand$ = thisData$
                ELSE
                    thisData$ = MID$(thisData$, LEN(thisCommand$) + 2)
                END IF

                IF thisCommand$ = "HELLO" THEN
                    client(totalClients).x = RND * (_WIDTH / 3)
                    client(totalClients).y = RND * (_HEIGHT / 3)
                    client(totalClients).w = CVI(LEFT$(thisData$, 2))
                    client(totalClients).h = CVI(RIGHT$(thisData$, 2))
                    client(totalClients).active = true
                    client(totalClients).ping = TIMER
                    totalIDs = totalIDs + 1
                    client(totalClients).id = totalIDs
                ELSE
                    GOTO failed
                END IF
            ELSE
                failed:
                Status "Connection failed!"
                totalClients = totalClients - 1
            END IF
        END IF
    END IF

    COLOR _RGB32(255, 255, 255), _RGB32(0, 0, 0)
    CLS
    PRINT "total clients:"; totalClients

    Status ""

    FOR i = 1 TO totalClients
        IF client(i).active THEN
            b$ = "PING>"
            Send client(i).handle, b$

            GET client(i).handle, , incomingData$
            stream(i) = stream(i) + incomingData$

            DO WHILE INSTR(stream(i), "<END>")
                thisData$ = LEFT$(stream(i), INSTR(stream(i), "<END>") - 1)
                stream(i) = MID$(stream(i), INSTR(stream(i), "<END>") + 5)
                thisCommand$ = LEFT$(thisData$, INSTR(thisData$, ">") - 1)
                IF thisCommand$ = "" THEN
                    thisCommand$ = thisData$
                ELSE
                    thisData$ = MID$(thisData$, LEN(thisCommand$) + 2)
                END IF

                SELECT CASE thisCommand$
                    CASE "IMAGE"
                        IF client(i).image < -1 THEN _FREEIMAGE client(i).image
                        client(i).image = _NEWIMAGE(client(i).w, client(i).h, 32)
                        DIM imgMem AS _MEM
                        imgMem = _MEMIMAGE(client(i).image)
                        _MEMPUT imgMem, imgMem.OFFSET, thisData$
                        _MEMFREE imgMem
                    CASE "BYE!"
                        IF client(i).image < -1 THEN _FREEIMAGE client(i).image
                        client(i).active = false
                        totalClients = totalClients - 1
                        GOTO nextClient
                    CASE "PONG"
                        client(i).ping = TIMER

                        'show ping:
                        FOR c = 1 TO 20 STEP RND * 10
                            CIRCLE (client(i).x, client(i).y), c, _RGB32(255, 255, 255)
                        NEXT
                END SELECT
            LOOP

            'window bg
            LINE (client(i).x, client(i).y)-STEP(client(i).w, client(i).h + 40), _RGBA32(255, 255, 255, 100), BF

            'window contents
            IF client(i).image < -1 THEN
                _PUTIMAGE (client(i).x, client(i).y + 40), client(i).image
            END IF

            'window frame
            IF hover = i THEN
                FOR c = 0 TO 4
                    LINE (client(i).x - c, client(i).y - c)-STEP(client(i).w + c * 2, client(i).h + 40 + c * 2), _RGB32(255, 255, 255), B
                    LINE (client(i).x - c, client(i).y - c)-STEP(client(i).w + c * 2, 40 + c * 2), _RGB32(255, 255, 255), B

                    LINE (client(i).x + (client(i).w - 40) + c, client(i).y + c)-STEP(40 - c * 2, 40 - c * 2), _RGB32(255, 255, 255), B
                NEXT
            ELSE
                LINE (client(i).x, client(i).y)-STEP(client(i).w, client(i).h + 40), _RGB32(255, 255, 255), B
                LINE (client(i).x, client(i).y)-STEP(client(i).w, 40), _RGB32(255, 255, 255), B

                'close button
                LINE (client(i).x + client(i).w, client(i).y)-STEP(-40, 40), _RGB32(255, 255, 255), B
            END IF

            'window title
            t$ = "Client #" + LTRIM$(STR$(client(i).id))
            COLOR _RGB32(0, 0, 0), 0
            _PRINTSTRING (client(i).x + 5 + 1, client(i).y + 20 - _FONTHEIGHT / 2 + 1), t$
            COLOR _RGB32(255, 255, 255), 0
            _PRINTSTRING (client(i).x + 5, client(i).y + 20 - _FONTHEIGHT / 2), t$

            IF TIMER - client(i).ping > .5 THEN
                closeClient i
            END IF
        END IF
        nextClient:
    NEXT

    _DISPLAY
    _LIMIT 30
LOOP

SUB closeClient (ID AS LONG)
    b$ = "BYE!>"
    Send client(ID).handle, b$
    _DELAY .1 'give time for BYE! to be sent
    CLOSE client(ID).handle
    client(ID).active = false
    IF client(ID).image < -1 THEN _FREEIMAGE client(ID).image: client(ID).image = 0
    FOR i = ID + 1 TO totalClients
        client(i - 1) = client(i)
    NEXT
    totalClients = totalClients - 1
END SUB

SUB Send (channel, __theData$)
    theData$ = __theData$ + "<END>"
    PUT #channel, , theData$
END SUB

SUB Status (__text$)
    STATIC lastStatus$

    IF LEN(__text$) THEN lastStatus$ = __text$
    IF LEN(lastStatus$) = 0 THEN EXIT SUB

    LINE (0, _HEIGHT - 2 - _FONTHEIGHT)-(_WIDTH, _HEIGHT), _RGB32(194, 194, 194), BF
    COLOR _RGB32(0, 0, 0), _RGB32(194, 194, 194)
    _PRINTSTRING (5, (_HEIGHT - _FONTHEIGHT - 1)), lastStatus$
END SUB
