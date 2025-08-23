function main()
    -- Создаем таблицу
    local t_id = AllocTable()
    
    -- Добавляем колонки
    AddColumn(t_id, 1, "Тип", true, QTABLE_STRING_TYPE, 8)
    AddColumn(t_id, 2, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(t_id, 3, "Лотов", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 4, "Сумма", true, QTABLE_DOUBLE_TYPE, 12)
    
    -- Создаем окно таблицы
    local window_id = CreateWindow(t_id)
    SetWindowCaption(window_id, "AFLT - Стакан котировок")
    SetWindowPos(window_id, 100, 100, 350, 500)
    
    -- Запускаем основной цикл
    is_run = true
    
    while is_run do
        update_stakan_table(t_id, "AFLT")
        sleep(1000)  -- Обновление каждую секунду
        
        -- Проверяем, не закрыто ли окно
        if isWindowClosed(window_id) then
            is_run = false
            message("Окно таблицы закрыто")
        end
    end
    
    return true
end

function update_stakan_table(t_id, ticker)
    local quote = getQuoteLevel2("QJSIM",ticker)
    if not quote then
        return
    end
    
    -- Очищаем таблицу
    Clear(t_id)
    
    local row = 0
    
    -- Продажи (ASK) - выводим сверху вниз
    if #quote.offer > 0 then
        for i = math.min(5, #quote.offer), 1, -1 do
            local level = quote.offer[i]
            local sum = level.price * level.quantity
            
            InsertRow(t_id, -1)
            SetCell(t_id, row, 1, "SELL")
            SetCell(t_id, row, 2, string.format("%.2f", level.price))
            SetCell(t_id, row, 3, tostring(level.quantity))
            SetCell(t_id, row, 4, string.format("%.0f", sum))
            
            -- Красный цвет для продаж
            SetColor(t_id, row, 1, RGB(255, 100, 100), RGB(0, 0, 0))
            SetColor(t_id, row, 2, RGB(255, 100, 100), RGB(0, 0, 0))
            
            row = row + 1
        end
    end
    
    -- Разделительная строка
    InsertRow(t_id, -1)
    SetCell(t_id, row, 1, "---")
    SetCell(t_id, row, 2, "---")
    SetCell(t_id, row, 3, "---")
    SetCell(t_id, row, 4, "---")
    row = row + 1
    
    -- Покупки (BID)
    if #quote.bid > 0 then
        for i = 1, math.min(5, #quote.bid) do
            local level = quote.bid[i]
            local sum = level.price * level.quantity
            
            InsertRow(t_id, -1)
            SetCell(t_id, row, 1, "BUY")
            SetCell(t_id, row, 2, string.format("%.2f", level.price))
            SetCell(t_id, row, 3, tostring(level.quantity))
            SetCell(t_id, row, 4, string.format("%.0f", sum))
            
            -- Зеленый цвет для покупок
            SetColor(t_id, row, 1, RGB(100, 255, 100), RGB(0, 0, 0))
            SetColor(t_id, row, 2, RGB(100, 255, 100), RGB(0, 0, 0))
            
            row = row + 1
        end
    end
    
    -- Итоговая информация
    InsertRow(t_id, -1)
    SetCell(t_id, row, 1, "Время:")
    SetCell(t_id, row, 2, os.date("%H:%M:%S"))
    row = row + 1
    
    if #quote.bid > 0 and #quote.offer > 0 then
        local spread = quote.offer[1].price - quote.bid[1].price
        InsertRow(t_id, -1)
        SetCell(t_id, row, 1, "Спред:")
        SetCell(t_id, row, 2, string.format("%.2f", spread))
    end
end

function OnStop()
    is_run = false
end