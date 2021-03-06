DIM SHARED client AS LONG, host AS LONG
SCREEN _NEWIMAGE(500, 500, 32)

mousecursor$ = "D13 E4 R5 H9"

PRINT "Connecting to host...";
host = _OPENCLIENT("TCP/IP:60710:localhost")
IF host = 0 THEN

    'this is the host program

    PRINT "not found."
    PRINT "Starting host...";
    host = _OPENHOST("TCP/IP:60710")
    IF host THEN
        PRINT "done."
        DO
            PRINT "Listening on port 60710..."
            DO
                client = _OPENCONNECTION(host)
                _LIMIT 30
                userQuits = _EXIT
                IF userQuits THEN
                    SYSTEM
                END IF
            LOOP UNTIL client

            a$ = "MSG>HELLO!"
            Send client, a$
            PRINT "Connected. Waiting for requests..."

            DO
                incomingData$ = ""
                GET #client, , incomingData$
                stream$ = stream$ + incomingData$

                DO WHILE INSTR(stream$, "<END>") > 0
                    'process requests from the client
                    'custom format: REQUEST>data to be sent<END>

                    'separate command, data and remove this command from the stream
                    thisData$ = LEFT$(stream$, INSTR(stream$, "<END>") - 1)
                    stream$ = MID$(stream$, INSTR(stream$, "<END>") + 5)
                    thisCommand$ = LEFT$(thisData$, INSTR(thisData$, ">") - 1)
                    IF thisCommand$ = "" THEN
                        thisCommand$ = thisData$
                    ELSE
                        thisData$ = MID$(thisData$, LEN(thisCommand$) + 2)
                    END IF

                    SELECT CASE UCASE$(thisCommand$)
                        CASE "TIME"
                            myData$ = "MSG>" + TIME$
                            Send client, myData$
                        CASE "DATE"
                            myData$ = "MSG>" + DATE$
                            Send client, myData$
                        CASE "WISDOM"
                            myData$ = "MSG>Time flies like bananas."
                            Send client, myData$
                        CASE "MSG"
                            PRINT "Message from client: "; thisData$
                        CASE "BYE"
                            PRINT thisData$
                            PRINT "Disconnected."
                            myData$ = "MSG>BYE!"
                            Send client, myData$
                            CLOSE client
                            client = 0
                            EXIT DO
                        CASE "MOUSEX"
                            mX = CVI(thisData$)
                        CASE "MOUSEY"
                            mY = CVI(thisData$)
                        CASE "MOUSEDOWN"
                            PCOPY 1, 0 'restore screenshot
                            mouseDown = -1
                            screenShotSaved = 0
                        CASE "MOUSEUP"
                            mouseDown = 0
                            shapeStarted = 0
                            oldMx = -1: oldMy = -1
                        CASE "CLS"
                            CLS
                            PCOPY 0, 1
                    END SELECT
                LOOP

                IF (mX <> oldMx OR mY <> oldMy) THEN
                    IF mouseDown THEN
                        IF shapeStarted THEN
                            LINE (oldMx, oldMy)-(mX, mY)
                        ELSE
                            PSET (mX, mY)
                            shapeStarted = -1
                        END IF
                    ELSE
                        IF NOT screenShotSaved THEN
                            PCOPY 0, 1
                            screenShotSaved = -1
                        ELSE
                            'place mouse indicator
                            PCOPY 1, 0
                            DRAW "bm" + STR$(mX) + "," + STR$(mY) + mousecursor$
                        END IF
                    END IF
                    oldMx = mX
                    oldMy = mY
                END IF

                _LIMIT 30
                userQuits = _EXIT
                IF userQuits THEN
                    myData$ = "MSG>BYE!"
                    Send client, myData$
                    CLOSE client
                    SYSTEM
                END IF
            LOOP WHILE client
        LOOP
    ELSE
        PRINT "failed."
    END IF
ELSE

    'this is the client program

    PRINT
    PRINT "Connected."
    PRINT "Click around to send mouse data; hit space to enter command..."

    DO
        DO
            incomingData$ = ""
            GET #host, , incomingData$
            stream$ = stream$ + incomingData$
        LOOP WHILE LEN(incomingData$)

        DO WHILE INSTR(stream$, "<END>") > 0
            'process responses from the host
            'custom format: RESPONSE>data received<END>

            'separate command, data and remove this command from the stream
            thisData$ = LEFT$(stream$, INSTR(stream$, "<END>") - 1)
            thisCommand$ = LEFT$(thisData$, INSTR(thisData$, ">") - 1)
            thisData$ = MID$(thisData$, LEN(thisCommand$) + 2)
            stream$ = MID$(stream$, INSTR(stream$, "<END>") + 5)

            SELECT CASE UCASE$(thisCommand$)
                CASE "MSG"
                    PRINT "Message from host: "; thisData$
                    IF thisData$ = "BYE!" THEN
                        PRINT "Disconnected."
                        CLOSE host
                        END
                    END IF
            END SELECT
        LOOP

        DO WHILE _MOUSEINPUT
            mX = _MOUSEX
            mY = _MOUSEY
            mb = _MOUSEBUTTON(1)
        LOOP

        IF mX <> oldMx OR mY <> oldMy THEN
            oldMx = mX
            oldMy = mY
            c$ = "MOUSEX>" + MKI$(mX)
            Send host, c$
            c$ = "MOUSEY>" + MKI$(mY)
            Send host, c$
        END IF

        IF mb THEN
            IF NOT mouseDown THEN
                c$ = "MOUSEDOWN>" + MKI$(1)
                Send host, c$
                mouseDown = -1
            END IF
        ELSE
            IF mouseDown THEN
                c$ = "MOUSEUP>" + MKI$(1)
                Send host, c$
                mouseDown = 0
            END IF
        END IF


        IF INKEY$ = " " THEN
            INPUT "Command (CLS, TIME, DATE, WISDOM, MSG>your message, BYE:", c$

            IF INSTR(c$, ">") = 0 THEN c$ = c$ + ">"
            Send host, c$
            c$ = ""
        END IF

        _LIMIT 30
        userQuit = _EXIT
        IF userQuit THEN
            Send host, "BYE"
            CLOSE
            SYSTEM
        END IF
    LOOP WHILE host
END IF

SUB Send (channel, __theData$)
    theData$ = __theData$ + "<END>"
    PUT #channel, , theData$
END SUB

