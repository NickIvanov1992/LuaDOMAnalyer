
    l_id = AllocTable()
    iceberg_id = AllocTable()

    AddColumn(l_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(l_id, 2, "Объем", true, QTABLE_INT_TYPE, 10)
    AddColumn(l_id, 3, "Гистограмма", true, QTABLE_STRING_TYPE,30)

    AddColumn(iceberg_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(iceberg_id, 2, "Тип", true, QTABLE_STRING_TYPE,10)
    AddColumn(iceberg_id, 3, "Объем", true, QTABLE_INT_TYPE, 10)
    
    local Level_Window = CreateWindow(l_id)
    local iceberg_Window = CreateWindow(iceberg_id)

    SetWindowCaption(l_id,"Уровни")
    SetWindowPos(l_id,50,50,350,800)

    SetWindowCaption(iceberg_id,"Текущие айсберги")
    SetWindowPos(iceberg_id,50,350,230,800)


    local last_quote = nil