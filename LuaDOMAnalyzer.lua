function main()
    local t_id = AllocTable()
    
    AddColumn(t_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(t_id, 2, "Лотов", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 3, "Сумма", true, QTABLE_DOUBLE_TYPE, 12)
    
    local window_id = CreateWindow(t_id)
    SetWindowCaption(t_id, "AFLT - Стакан котировок")
    SetWindowPos(t_id, 100, 100, 350, 500)

    -- Переменные для отслеживания изменений
    local last_quote = nil
    local is_run = true
    
    while is_run do
        if IsWindowClosed(t_id) then
            is_run = false
            message("Окно таблицы закрыто")
            break
        end
        
        local current_quote = getQuoteLevel2("QJSIM", "AFLT")
        
        -- Обновляем только если есть изменения
        if current_quote and (not last_quote or has_quote_changed(last_quote, current_quote)) then
            update_stakan_table(t_id, current_quote)
            last_quote = current_quote  -- Сохраняем текущий стакан
        end
        
        sleep(100)  -- Уменьшаем задержку для быстрой реакции
    end
    
    DestroyTable(t_id)
    return true
end

function has_quote_changed(old_quote, new_quote)
    -- Проверяем изменения в стакане покупок
    if #old_quote.bid ~= #new_quote.bid then
        return true
    end
    
    for i = 1, #new_quote.bid do
        if not old_quote.bid[i] or 
           old_quote.bid[i].price ~= new_quote.bid[i].price or 
           old_quote.bid[i].quantity ~= new_quote.bid[i].quantity then
            return true
        end
    end
    
    -- Проверяем изменения в стакане продаж
    if #old_quote.offer ~= #new_quote.offer then
        return true
    end
    
    for i = 1, #new_quote.offer do
        if not old_quote.offer[i] or 
           old_quote.offer[i].price ~= new_quote.offer[i].price or 
           old_quote.offer[i].quantity ~= new_quote.offer[i].quantity then
            return true
        end
    end
    
    return false
end

function update_stakan_table(t_id, quote)
    if not quote or not quote.bid or not quote.offer then
        return false
    end
    
    Clear(t_id)
    local row = 0
    
    -- Продажи (ASK)
    if #quote.offer > 0 then
        for i = #quote.offer, 1, -1 do
            local level = quote.offer[i]
            if level then
                local sum = level.price * level.quantity
                InsertRow(t_id, -1)
                SetCell(t_id, row, 1, string.format("%.2f", level.price))
                SetCell(t_id, row, 2, tostring(level.quantity))
                SetCell(t_id, row, 3, string.format("%.0f", sum))
                
                for col = 1, 3 do
                    SetColor(t_id, row, col, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                end
                row = row + 1
            end
        end
    end
    
    -- Разделитель
    InsertRow(t_id, -1)
    SetCell(t_id, row, 1, "---")
    SetCell(t_id, row, 2, "---")
    SetCell(t_id, row, 3, "---")
    row = row + 1
    
    -- Покупки (BID)
    if #quote.bid > 0 then
        for i = #quote.bid, 1, -1 do
            local level = quote.bid[i]
            if level then
                local sum = level.price * level.quantity
                InsertRow(t_id, -1)
                SetCell(t_id, row, 1, string.format("%.2f", level.price))
                SetCell(t_id, row, 2, tostring(level.quantity))
                SetCell(t_id, row, 3, string.format("%.0f", sum))
                
                for col = 1, 3 do
                   SetColor(t_id, row, col, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
                end
                row = row + 1
            end
        end
    end
    
    return true
end