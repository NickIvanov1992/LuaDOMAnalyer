    MyQuote = {}
    t_id = AllocTable()
    l_id = AllocTable()
    AddColumn(t_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(t_id, 2, "Объем", true, QTABLE_INT_TYPE, 10)

    AddColumn(l_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(l_id, 2, "Объем", true, QTABLE_INT_TYPE, 10)
    AddColumn(l_id, 3, "Гистограмма", true, QTABLE_STRING_TYPE,30)
    
    local window_id = CreateWindow(t_id)
    local Level_Window = CreateWindow(l_id)

    SetWindowCaption(t_id, "Уровни")
    SetWindowPos(t_id, 100, 100, 350, 500)

    SetWindowCaption(l_id,"Уровни")
    SetWindowPos(l_id,50,50,350,800)
    local last_quote = nil