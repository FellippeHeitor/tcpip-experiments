': This form was generated by
': InForm - GUI system for QB64 - Beta version 7
': Fellippe Heitor, 2016-2018 - fellippe@qb64.org - @fellippeheitor
'-----------------------------------------------------------
SUB __UI_LoadForm

    DIM __UI_NewID AS LONG

    __UI_NewID = __UI_NewControl(__UI_Type_Form, "TheHost", 300, 290, 0, 0, 0)
    SetCaption __UI_NewID, "The host"
    Control(__UI_NewID).Font = SetFont("arial.ttf", 12)

    __UI_NewID = __UI_NewControl(__UI_Type_Button, "NewRectangleBT", 99, 72, 49, 96, 0)
    SetCaption __UI_NewID, "New rectangle"
    Control(__UI_NewID).CanHaveFocus = True

    __UI_NewID = __UI_NewControl(__UI_Type_Button, "MakeItRedBT", 99, 72, 14, 208, 0)
    SetCaption __UI_NewID, "Make it Red"
    Control(__UI_NewID).CanHaveFocus = True

    __UI_NewID = __UI_NewControl(__UI_Type_Button, "MakeItARandomColorBT", 168, 72, 118, 208, 0)
    SetCaption __UI_NewID, "Make it a random color"
    Control(__UI_NewID).CanHaveFocus = True

    __UI_NewID = __UI_NewControl(__UI_Type_Label, "ConnectionStatusLB", 108, 21, 14, 14, 0)
    SetCaption __UI_NewID, "Connection status:"

    __UI_NewID = __UI_NewControl(__UI_Type_Label, "offlineLB", 168, 59, 118, 14, 0)
    SetCaption __UI_NewID, "offline"
    Control(__UI_NewID).WordWrap = True

    __UI_NewID = __UI_NewControl(__UI_Type_Button, "NewCircleBT", 99, 72, 153, 96, 0)
    SetCaption __UI_NewID, "New circle"
    Control(__UI_NewID).CanHaveFocus = True

    __UI_NewID = __UI_NewControl(__UI_Type_PictureBox, "PictureBox1", 277, 236, 14, 27, 0)
    Control(__UI_NewID).BackColor = _RGB32(0, 0, 0)
    Control(__UI_NewID).Stretch = True
    Control(__UI_NewID).HasBorder = True
    Control(__UI_NewID).Align = __UI_Center
    Control(__UI_NewID).VAlign = __UI_Middle
    Control(__UI_NewID).Hidden = True

END SUB

SUB __UI_AssignIDs
    TheHost = __UI_GetID("TheHost")
    NewRectangleBT = __UI_GetID("NewRectangleBT")
    MakeItRedBT = __UI_GetID("MakeItRedBT")
    MakeItARandomColorBT = __UI_GetID("MakeItARandomColorBT")
    ConnectionStatusLB = __UI_GetID("ConnectionStatusLB")
    offlineLB = __UI_GetID("offlineLB")
    NewCircleBT = __UI_GetID("NewCircleBT")
    PictureBox1 = __UI_GetID("PictureBox1")
END SUB
