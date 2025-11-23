local is_printing = false
local is_printing = false
local spoofing_id = nil -- ID таблицы для спуфинга

-- Глобальные переменные для обнаружения спуфинга
local spoofing_events = {}
local SPOOFING_HISTORY_SIZE = 50
local last_orderbook_snapshot = {}
local spoofing_analysis_counter = 0
local SPOOFING_ANALYSIS_INTERVAL = 5

-- Инициализация таблицы спуфинга
function InitSpoofingTable()
    
    SetWindowPos(spoofing_id, 100, 100, 600, 400)
    SetWindowCaption(spoofing_id, "Обнаружение спуфинга - AFLT")
    
    -- Создаем колонки
    AddColumn(spoofing_id, 1, "Время", true, QTABLE_STRING_TYPE, 15)
    AddColumn(spoofing_id, 2, "Тип", true, QTABLE_STRING_TYPE, 12)
    AddColumn(spoofing_id, 3, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(spoofing_id, 4, "Объем", true, QTABLE_INT_TYPE, 10)
    AddColumn(spoofing_id, 5, "Уровень", true, QTABLE_STRING_TYPE, 8)
    AddColumn(spoofing_id, 6, "Скор", true, QTABLE_INT_TYPE, 8)
    AddColumn(spoofing_id, 7, "Описание", true, QTABLE_STRING_TYPE, 25)
end


-- Основная функция обнаружения спуфинга
function DetectSpoofing()
    if not orderbook_data or #orderbook_data.bids == 0 or #orderbook_data.asks == 0 then
        return
    end
    
    local current_time = os.date("%H:%M:%S")
    local spoofing_detected = false
    
    -- 1. Обнаружение крупных заявок далеко от текущей цены
    local distant_large_orders = findDistantLargeOrders()
    for _, order in ipairs(distant_large_orders) do
        addSpoofingEvent({
            time = current_time,
            type = "DISTANT_LARGE_ORDER",
            price = order.price,
            volume = order.volume,
            level = order.level,
            score = order.score,
            description = order.description
        })
        spoofing_detected = true
    end
    
    -- 2. Обнаружение быстрого размещения/снятия заявок
    local rapid_cancel_events = detectRapidCancelation()
    for _, event in ipairs(rapid_cancel_events) do
        addSpoofingEvent({
            time = current_time,
            type = "RAPID_CANCEL",
            price = event.price,
            volume = event.volume,
            level = event.level,
            score = event.score,
            description = event.description
        })
        spoofing_detected = true
    end
    
    -- 3. Обнаружение ложных стен
    local fake_walls = detectFakeWalls()
    for _, wall in ipairs(fake_walls) do
        addSpoofingEvent({
            time = current_time,
            type = "FAKE_WALL",
            price = wall.price,
            volume = wall.volume,
            level = wall.level,
            score = wall.score,
            description = wall.description
        })
        spoofing_detected = true
    end
    
    -- 4. Обнаружение манипуляций лучшими ценами
    local best_price_manipulation = detectBestPriceManipulation()
    for _, manipulation in ipairs(best_price_manipulation) do
        addSpoofingEvent({
            time = current_time,
            type = "PRICE_MANIPULATION",
            price = manipulation.price,
            volume = manipulation.volume,
            level = manipulation.level,
            score = manipulation.score,
            description = manipulation.description
        })
        spoofing_detected = true
    end
    
    -- 5. Обнаружение паттерна "насос и сброс"
    local pump_dump_patterns = detectPumpAndDump()
    for _, pattern in ipairs(pump_dump_patterns) do
        addSpoofingEvent({
            time = current_time,
            type = "PUMP_DUMP",
            price = pattern.price,
            volume = pattern.volume,
            level = pattern.level,
            score = pattern.score,
            description = pattern.description
        })
        spoofing_detected = true
    end
    
    -- Обновляем таблицу если были обнаружены события
    if spoofing_detected then
        UpdateSpoofingTable()
    end
end

-- Поиск крупных заявок далеко от текущей цены
function findDistantLargeOrders()
    local events = {}
    local best_bid, best_ask = GetBestBidAsk()
    
    if best_bid == 0 or best_ask == 0 then return events end
    
    local spread = best_ask - best_bid
    local distant_threshold = spread * 3 -- В 3 раза дальше спреда
    
    -- Проверяем биды (покупки)
    for i, bid in ipairs(orderbook_data.bids) do
        local distance_from_best = best_bid - bid.price
        if distance_from_best > distant_threshold then
            local volume_ratio = bid.quantity / getAverageVisibleVolume()
            if volume_ratio > 5 then -- Объем в 5 раз больше среднего
                local score = math.min(100, math.floor(volume_ratio * 10 + distance_from_best / spread * 5))
                table.insert(events, {
                    price = bid.price,
                    volume = bid.quantity,
                    level = "BID_" .. i,
                    score = score,
                    description = string.format("Крупный бид далеко от рынка (x%.1f от среднего)", volume_ratio)
                })
            end
        end
    end
    
    -- Проверяем аски (продажи)
    for i, ask in ipairs(orderbook_data.asks) do
        local distance_from_best = ask.price - best_ask
        if distance_from_best > distant_threshold then
            local volume_ratio = ask.quantity / getAverageVisibleVolume()
            if volume_ratio > 5 then
                local score = math.min(100, math.floor(volume_ratio * 10 + distance_from_best / spread * 5))
                table.insert(events, {
                    price = ask.price,
                    volume = ask.quantity,
                    level = "ASK_" .. i,
                    score = score,
                    description = string.format("Крупный аск далеко от рынка (x%.1f от среднего)", volume_ratio)
                })
            end
        end
    end
    
    return events
end

-- Обнаружение быстрого размещения/снятия заявок
function detectRapidCancelation()
    local events = {}
    
    if #orderbook_history < 2 then return events end
    
    local current_snapshot = orderbook_history[#orderbook_history]
    local previous_snapshot = orderbook_history[#orderbook_history - 1]
    
    -- Анализируем изменения в бидах
    analyzeOrderbookSideForCancelation(previous_snapshot.bids, current_snapshot.bids, "BID", events)
    -- Анализируем изменения в асках
    analyzeOrderbookSideForCancelation(previous_snapshot.asks, current_snapshot.asks, "ASK", events)
    
    return events
end

function analyzeOrderbookSideForCancelation(previous_side, current_side, side_type, events)
    local best_bid, best_ask = GetBestBidAsk()
    local best_price = (side_type == "BID") and best_bid or best_ask
    
    for _, prev_order in ipairs(previous_side) do
        local order_found = false
        local is_large_order = tonumber(prev_order.quantity) > tonumber(getAverageVisibleVolume()) * 3
        
        -- Ищем эту заявку в текущем стакане
        for _, curr_order in ipairs(current_side) do
            if math.abs(prev_order.price - curr_order.price) < 0.001 then
                order_found = true
                break
            end
        end
        
        -- Если крупная заявка исчезла и была близко к лучшей цене
        if not order_found and is_large_order then
            local distance_from_best = math.abs(prev_order.price - best_price)
            local spread = best_ask - best_bid
            
            if distance_from_best <= spread * 2 then -- В пределах 2 спредов от лучшей цены
                local score = math.min(100, math.floor((prev_order.quantity / getAverageVisibleVolume()) * 8))
                table.insert(events, {
                    price = prev_order.price,
                    volume = prev_order.quantity,
                    level = side_type .. "_CANCEL",
                    score = score,
                    description = "Быстрое снятие крупной заявки"
                })
            end
        end
    end
end

-- Обнаружение ложных стен
function detectFakeWalls()
    local events = {}
    local best_bid, best_ask = GetBestBidAsk()
    
    if best_bid == 0 or best_ask == 0 then return events end
    
    local average_volume = getAverageVisibleVolume()
    
    -- Проверяем биды на наличие стен
    for i, bid in ipairs(orderbook_data.bids) do
        if i <= 5 then -- Только первые 5 уровней
            local volume_ratio = bid.quantity / average_volume
            if volume_ratio > 10 then -- Очень крупная заявка
                -- Проверяем, не является ли это стеной
                local is_wall = true
                local next_volume_ratio = 0
                
                -- Проверяем следующий уровень
                if orderbook_data.bids[i + 1] then
                    next_volume_ratio = orderbook_data.bids[i + 1].quantity / average_volume
                    if next_volume_ratio > 5 then
                        is_wall = false -- Следующий уровень тоже крупный, вероятно не спуфинг
                    end
                end
                
                if is_wall then
                    local score = math.min(100, math.floor(volume_ratio * 6))
                    table.insert(events, {
                        price = bid.price,
                        volume = bid.quantity,
                        level = "BID_WALL",
                        score = score,
                        description = string.format("Возможная ложная стена (x%.1f от среднего)", volume_ratio)
                    })
                end
            end
        end
    end
    
    -- Проверяем аски на наличие стен
    for i, ask in ipairs(orderbook_data.asks) do
        if i <= 5 then
            local volume_ratio = ask.quantity / average_volume
            if volume_ratio > 10 then
                local is_wall = true
                local next_volume_ratio = 0
                
                if orderbook_data.asks[i + 1] then
                    next_volume_ratio = orderbook_data.asks[i + 1].quantity / average_volume
                    if next_volume_ratio > 5 then
                        is_wall = false
                    end
                end
                
                if is_wall then
                    local score = math.min(100, math.floor(volume_ratio * 6))
                    table.insert(events, {
                        price = ask.price,
                        volume = ask.quantity,
                        level = "ASK_WALL",
                        score = score,
                        description = string.format("Возможная ложная стена (x%.1f от среднего)", volume_ratio)
                    })
                end
            end
        end
    end
    
    return events
end

-- Обнаружение манипуляций лучшими ценами
function detectBestPriceManipulation()
    local events = {}
    
    if #orderbook_history < 3 then return events end
    
    local current_snapshot = orderbook_history[#orderbook_history]
    local previous_snapshot = orderbook_history[#orderbook_history - 1]
    local older_snapshot = orderbook_history[#orderbook_history - 2]
    
    -- Анализ изменений лучших цен
    local current_best_bid = current_snapshot.bids[1] and current_snapshot.bids[1].price or 0
    local previous_best_bid = previous_snapshot.bids[1] and previous_snapshot.bids[1].price or 0
    local older_best_bid = older_snapshot.bids[1] and older_snapshot.bids[1].price or 0
    
    local current_best_ask = current_snapshot.asks[1] and current_snapshot.asks[1].price or 0
    local previous_best_ask = previous_snapshot.asks[1] and previous_snapshot.asks[1].price or 0
    local older_best_ask = older_snapshot.asks[1] and older_snapshot.asks[1].price or 0
    
    -- Проверяем резкие изменения лучших цен без значительных сделок
    local bid_change1 = math.abs(current_best_bid - previous_best_bid)
    local bid_change2 = math.abs(previous_best_bid - older_best_bid)
    local ask_change1 = math.abs(current_best_ask - previous_best_ask)
    local ask_change2 = math.abs(previous_best_ask - older_best_ask)
    
    local price_tolerance = getPriceTolerance(current_best_bid)
    
    if bid_change1 > price_tolerance and bid_change2 > price_tolerance then
        table.insert(events, {
            price = current_best_bid,
            volume = 0,
            level = "BEST_BID",
            score = 75,
            description = "Подозрительные резкие изменения лучшего бида"
        })
    end
    
    if ask_change1 > price_tolerance and ask_change2 > price_tolerance then
        table.insert(events, {
            price = current_best_ask,
            volume = 0,
            level = "BEST_ASK",
            score = 75,
            description = "Подозрительные резкие изменения лучшего аска"
        })
    end
    
    return events
end

-- Обнаружение паттерна "насос и сброс"
function detectPumpAndDump()
    local events = {}
    
    -- Анализируем последние сделки на наличие паттернов
    if #filtered_trades < 10 then return events end
    
    local recent_trades = {}
    for i = math.max(1, #filtered_trades - 20), #filtered_trades do
        table.insert(recent_trades, filtered_trades[i])
    end
    
    -- Ищем последовательность: несколько крупных покупок -> резкое движение цены -> крупные продажи
    local large_buys = 0
    local large_sells = 0
    local price_increase = 0
    local first_price = recent_trades[1].price
    local last_price = recent_trades[#recent_trades].price
    
    for i, trade in ipairs(recent_trades) do
        if trade.volume > getAverageTradeVolume() * 3 then
            if trade.direction == "BUY" then
                large_buys = large_buys + 1
            else
                large_sells = large_sells + 1
            end
        end
    end
    
    price_increase = ((last_price - first_price) / first_price) * 100
    
    -- Если есть паттерн насоса и сброса
    if large_buys >= 2 and large_sells >= 2 and price_increase > 0.5 then
        table.insert(events, {
            price = last_price,
            volume = 0,
            level = "PATTERN",
            score = 85,
            description = string.format("Паттерн 'насос и сброс' (+%.2f%%)", price_increase)
        })
    end
    
    return events
end

-- Вспомогательные функции для спуфинга
function getAverageVisibleVolume()
    local total_volume = 0
    local count = 0
    
    for _, bid in ipairs(orderbook_data.bids) do
        total_volume = total_volume + bid.quantity
        count = count + 1
        if count >= 10 then break end
    end
    
    for _, ask in ipairs(orderbook_data.asks) do
        total_volume = total_volume + ask.quantity
        count = count + 1
        if count >= 20 then break end
    end
    
    return count > 0 and total_volume / count or 1000
end

function addSpoofingEvent(event)
    table.insert(spoofing_events, 1, event) -- Добавляем в начало
    
    -- Ограничиваем размер истории
    if #spoofing_events > SPOOFING_HISTORY_SIZE then
        table.remove(spoofing_events)
    end
end

-- Обновление таблицы спуфинга
function UpdateSpoofingTable()
    if not spoofing_id then
        InitSpoofingTable()
    end
    
    Clear(spoofing_id)
    
    for i, event in ipairs(spoofing_events) do
        if i > 20 then break end -- Показываем только последние 20 событий
        
        InsertRow(spoofing_id, -1)
        
        SetCell(spoofing_id, i, 1, event.time)
        SetCell(spoofing_id, i, 2, event.type)
        SetCell(spoofing_id, i, 3, tostring(event.price))
        SetCell(spoofing_id, i, 4, tostring(event.volume))
        SetCell(spoofing_id, i, 5, event.level)
        SetCell(spoofing_id, i, 6, tostring(event.score))
        SetCell(spoofing_id, i, 7, event.description)
        
        -- Устанавливаем цвет в зависимости от уровня угрозы
        setSpoofingRowColor(i, event.score)
    end
end

function setSpoofingRowColor(row, score)
    local text_color, background_color
    
    if score >= 80 then
        text_color = RGB(255, 255, 255)
        background_color = RGB(200, 0, 0) -- Красный для высокого риска
    elseif score >= 60 then
        text_color = RGB(255, 255, 255)
        background_color = RGB(255, 140, 0) -- Оранжевый для среднего риска
    else
        text_color = RGB(255, 255, 255)
        background_color = RGB(100, 100, 100) -- Серый для низкого риска
    end
    
    for col = 1, 7 do
        SetColor(spoofing_id, row, col, text_color, background_color, text_color, background_color)
    end
end





function FindIceberg()
    if #IcebergArray == 0 or IcebergArray == nil then
        Initial()
    else
        -- Принудительная синхронизация при ручном вызове
        SyncWithOrderbook()
    end
    PrintValues()
end

function Initial()
    if #MyQuote == 0 then
        message("Пустой стакан")
        return
    end
    
    -- Очищаем массив перед инициализацией
    IcebergArray = {}
    
    for i = 1, #MyQuote do
        local defaultTable = {
            Price = MyQuote[i].Price,
            Type = "",  -- вместо "null"
            direction = "",  -- вместо "buy/sell"
            Volume = 0,
            Avg_Volume = 0,
            TotalBeyond = 0  -- Новый столбец: объем айсбергов за пределами лучших цен
        }
        table.insert(IcebergArray, defaultTable)
    end
end


function PrintValues()

    -- Защита от рекурсивных вызовов
    if is_printing then
        return
    end

    is_printing = true

    if #IcebergArray == 0 then
        Clear(iceberg_id)
        is_printing = false
        return
    end

     -- Получаем текущие лучшие цены
    local best_bid, best_ask = GetBestBidAsk()

    -- Рассчитываем суммарные объемы айсбергов выше Ask и ниже Bid
    CalculateTotalBeyondVolumes(tonumber(best_bid), tonumber(best_ask))

    -- Ограничиваем количество строк для безопасности
    local max_rows = 100
    local display_count = math.min(#IcebergArray, max_rows)
    
    Clear(iceberg_id)

    -- Сортируем по цене (от высокой к низкой для отображения)
    table.sort(IcebergArray, function(a, b)
        return tonumber(a.Price) > tonumber(b.Price)
    end)

    local row = 1
    for i = 1, #IcebergArray do
        InsertRow(iceberg_id, -1)

        local current_price = tonumber(IcebergArray[i].Price)
        local is_best_bid = (math.abs(current_price - best_bid) < 0.001)
        local is_best_ask = (math.abs(current_price - best_ask) < 0.001)

        SetCell(iceberg_id, row, 1, tostring(IcebergArray[i].Price))
        SetCell(iceberg_id, row, 2, tostring(IcebergArray[i].Type))
        SetCell(iceberg_id, row, 3, tostring(IcebergArray[i].direction))
        SetCell(iceberg_id, row, 4, tostring(IcebergArray[i].Volume))
        SetCell(iceberg_id, row, 5, tostring(IcebergArray[i].Avg_Volume))
        SetCell(iceberg_id, row, 6, tostring(IcebergArray[i].TotalBeyond))  -- Новый столбец

        -- Устанавливаем цвет ТОЛЬКО для столбца с ценой
        if is_best_bid then
            -- Выделяем только столбец цены для лучшего бида
            SetBestBidPriceColor(row)
            -- Остальные столбцы - стандартные цвета в зависимости от направления
            SetOtherColumnsColor(row, IcebergArray[i].direction)
        elseif is_best_ask then
            -- Выделяем только столбец цены для лучшего аска
            SetBestAskPriceColor(row)
            -- Остальные столбцы - стандартные цвета в зависимости от направления
            SetOtherColumnsColor(row, IcebergArray[i].direction)
        else
            -- Стандартные цвета для всех столбцов
            if IcebergArray[i].direction == "BUY" then
                SetIcebergColor("BUY", row)
            elseif IcebergArray[i].direction == "SELL" then
                SetIcebergColor("SELL", row)
            else
                -- Стандартный цвет для всех столбцов
                for col = 1, 6 do
                    SetColor(iceberg_id, row, col, RGB(255, 255, 255), RGB(40, 40, 40), RGB(255, 255, 255), RGB(40, 40, 40))
                end
            end
        end
        
        row = row + 1
    end
    is_printing = false
end

function CalculateTotalBeyondVolumes(best_bid, best_ask)
    if not best_bid or not best_ask or best_bid == 0 or best_ask == 0 then
        return
    end

    local total_above_ask = 0
    local total_below_bid = 0

    -- Сначала вычисляем общие суммы
     for i = 1, #IcebergArray do
        local iceberg = IcebergArray[i]
        if iceberg and iceberg.Price then
            local price = tonumber(iceberg.Price)
            local volume = tonumber(iceberg.Volume) or 0
        
        -- Проверяем, является ли это айсбергом (имеет направление и объем)
        if iceberg.direction and iceberg.direction ~= "" and volume > 0 then
            if price > best_ask then
                -- Айсберг выше лучшего аска
                total_above_ask = total_above_ask + volume
            elseif price < best_bid then
                -- Айсберг ниже лучшего бида
                total_below_bid = total_below_bid + volume
            end
        end
    end
end

    -- Теперь устанавливаем значения для каждой строки
    for i = 1, #IcebergArray do
        local iceberg = IcebergArray[i]
        if iceberg and iceberg.Price then
            local price = tonumber(iceberg.Price)
        
        if price > best_ask then
            iceberg.TotalBeyond = total_above_ask
        elseif price < best_bid then
            iceberg.TotalBeyond = total_below_bid
        else
            -- Для цен внутри спреда оставляем 0 или можно показать другую информацию
            iceberg.TotalBeyond = 0
        end
    end
end
end


-- Функции для выделения только столбца цены
function SetBestBidPriceColor(row)
    -- Только столбец цены - яркий синий
    SetColor(iceberg_id, row, 1, RGB(200, 200, 255), RGB(0, 0, 100), RGB(200, 200, 255), RGB(0, 0, 100))
end

function SetBestAskPriceColor(row)
    -- Только столбец цены - яркий оранжевый
    SetColor(iceberg_id, row, 1, RGB(255, 220, 180), RGB(100, 50, 0), RGB(255, 220, 180), RGB(100, 50, 0))
end

-- Функция для установки цвета остальных столбцов
function SetOtherColumnsColor(row, direction)
    if direction == "BUY" then
        -- Столбцы 2-6 красные для покупок
        for col = 2, 6 do
            SetColor(iceberg_id, row, col, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
        end
    elseif direction == "SELL" then
        -- Столбцы 2-6 зеленые для продаж
        for col = 2, 6 do
            SetColor(iceberg_id, row, col, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
        end
    else
        -- Столбцы 2-6 стандартные
        for col = 2, 6 do
            SetColor(iceberg_id, row, col, RGB(255, 255, 255), RGB(40, 40, 40), RGB(255, 255, 255), RGB(40, 40, 40))
        end
    end
end

function SetBestBidColor(row)
    -- Яркий синий цвет для лучшего бида
    SetColor(iceberg_id, row, 1, RGB(200, 200, 255), RGB(0, 0, 100), RGB(200, 200, 255), RGB(0, 0, 100))
    SetColor(iceberg_id, row, 2, RGB(200, 200, 255), RGB(0, 0, 100), RGB(200, 200, 255), RGB(0, 0, 100))
    SetColor(iceberg_id, row, 3, RGB(200, 200, 255), RGB(0, 0, 100), RGB(200, 200, 255), RGB(0, 0, 100))
    SetColor(iceberg_id, row, 4, RGB(200, 200, 255), RGB(0, 0, 100), RGB(200, 200, 255), RGB(0, 0, 100))
    SetColor(iceberg_id, row, 5, RGB(200, 200, 255), RGB(0, 0, 100), RGB(200, 200, 255), RGB(0, 0, 100))
end

function SetBestAskColor(row)
    -- Яркий оранжевый цвет для лучшего аска
    SetColor(iceberg_id, row, 1, RGB(255, 220, 180), RGB(100, 50, 0), RGB(255, 220, 180), RGB(100, 50, 0))
    SetColor(iceberg_id, row, 2, RGB(255, 220, 180), RGB(100, 50, 0), RGB(255, 220, 180), RGB(100, 50, 0))
    SetColor(iceberg_id, row, 3, RGB(255, 220, 180), RGB(100, 50, 0), RGB(255, 220, 180), RGB(100, 50, 0))
    SetColor(iceberg_id, row, 4, RGB(255, 220, 180), RGB(100, 50, 0), RGB(255, 220, 180), RGB(100, 50, 0))
    SetColor(iceberg_id, row, 5, RGB(255, 220, 180), RGB(100, 50, 0), RGB(255, 220, 180), RGB(100, 50, 0))
end

 function SetIcebergColor(type, row)
    if type == "SELL" then
        -- Зеленый для продаж
        for col = 1, 6 do
            SetColor(iceberg_id, row, col, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
        end
    else
        -- Красный для покупок
        for col = 1, 6 do
            SetColor(iceberg_id, row, col, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
        end
    end
end
-----------------------------------------------------------------------------------

local sync_counter = 0
local SYNC_INTERVAL = 10  -- синхронизировать каждые 10 обновлений стакана

-- Функция для обновления стакана
function OnQuote(class_code, sec_code)
    if sec_code == "AFLT" and class_code == "QJSIM" then

        
        -- Сохраняем предыдущий снимок стакана
        saveOrderbookSnapshot()
        -- Получаем стакан
        local bids = getQuoteLevel2(class_code, sec_code).bid
        local asks = getQuoteLevel2(class_code, sec_code).offer
        
        -- Обновляем данные стакана
        orderbook_data.bids = {}
        orderbook_data.asks = {}
        
        for i = 1, #bids do
            table.insert(orderbook_data.bids, {
                price = bids[i].price,
                quantity = bids[i].quantity
            })
        end
        
        for i = 1, #asks do
            table.insert(orderbook_data.asks, {
                price = asks[i].price,
                quantity = asks[i].quantity
            })
        end

        -- ОБНОВЛЯЕМ TotalBeyond при каждом обновлении стакана
        local best_bid, best_ask = GetBestBidAsk()
        CalculateTotalBeyondVolumes(tonumber(best_bid), tonumber(best_ask))

        -- Периодическая синхронизация с текущим стаканом
        sync_counter = sync_counter + 1
        if sync_counter >= SYNC_INTERVAL then
            SyncWithOrderbook()
            sync_counter = 0
            -- UpdateStatistic()
        end

         -- Периодический анализ спуфинга
        spoofing_analysis_counter = spoofing_analysis_counter + 1
        if spoofing_analysis_counter >= SPOOFING_ANALYSIS_INTERVAL then
            DetectSpoofing()
            spoofing_analysis_counter = 0
        end

         -- Запускаем анализ айсбергов
        safe_AnalyzeIcebergPatterns()  --может не нужно?

        safe_PrintValues()
    end
    
end

-- Функция для ручного запуска обнаружения спуфинга
function FindSpoofing()
    message("Запуск обнаружения спуфинга...")
    DetectSpoofing()
    UpdateSpoofingTable()
end

-- Функция для очистки таблицы спуфинга
function ClearSpoofingTable()
    spoofing_events = {}
    if spoofing_id then
        Clear(spoofing_id)
    end
    message("Таблица спуфинга очищена")
end




-- Добавляем функцию для принудительного обновления всех данных
function UpdateIcebergTable()
    local best_bid, best_ask = GetBestBidAsk()
    CalculateTotalBeyondVolumes(tonumber(best_bid), tonumber(best_ask))
    safe_PrintValues()
end

function getCumulativeVolumeInOrderbook(price, direction, depth_levels)
    local cumulative_volume = 0
    local levels = (direction == "BUY") and orderbook_data.asks or orderbook_data.bids
    
    -- Сортируем уровни по близости к цене сделки
    local sorted_levels = {}
    for _, level in ipairs(levels) do
        table.insert(sorted_levels, level)
    end
    
    table.sort(sorted_levels, function(a, b)
        if direction == "BUY" then
            return a.price < b.price  -- Для покупок: от нижней цены к верхней
        else
            return a.price > b.price  -- Для продаж: от верхней цены к нижней
        end
    end)
    
    -- Берем ближайшие depth_levels уровней
    for i = 1, math.min(depth_levels, #sorted_levels) do
        local level = sorted_levels[i]
        
        -- Проверяем, находится ли уровень в разумной близости от цены сделки
        local price_diff = math.abs(level.price - price)
        local price_tolerance = getPriceTolerance(price)
        
        if price_diff <= price_tolerance then
            cumulative_volume = cumulative_volume + level.quantity
        end
    end
    
    return cumulative_volume
end

function getPriceTolerance(price)
    -- Для акций типа Аэрофлота: 0.5-1% от цены
    return tonumber(price) * 0.01
end

-- Функция проверки на айсберг-заявку
function checkIcebergSuspicion(trade)
    local suspicion = "NO"
    local total_score = 0
    
     -- 1. Проверка объема сделки
    if trade.volume >= 3000 then -- Большой объем (Аэрофлот)
        total_score = total_score + 1
    end

    -- 1. Проверка объема сделки против ВИДИМОГО объема на 5 уровнях
    local visible_volume_1_level = getVisibleVolumeInOrderbook(trade.price, trade.direction)
    local visible_volume_3_levels = getCumulativeVolumeInOrderbook(trade.price, trade.direction, 3)
    local visible_volume_5_levels = getCumulativeVolumeInOrderbook(trade.price, trade.direction, 5)
    
    -- Если объем сделки значительно превышает видимый объем на нескольких уровнях
    if trade.volume > visible_volume_5_levels * 2 then
        total_score = total_score + 3
    elseif trade.volume > visible_volume_3_levels * 2 then
        total_score = total_score + 2
    elseif trade.volume > visible_volume_1_level * 2 then
        total_score = total_score + 1
    end
    
    -- 3. Проверка распределения объемов в стакане
    local volume_distribution_score = analyzeVolumeDistribution(trade.direction)
    total_score = total_score + volume_distribution_score

    -- 2. Проверка "симметричных" крупных заявок на противоположной стороне
    local opposite_side_score = checkOppositeSideLargeOrders(trade.price, trade.direction, trade.volume)
    total_score = total_score + opposite_side_score
    
    
    -- 4. Проверка "исчезновения" объемов после сделки (по нескольким уровням)
    local disappearance_score = checkVolumeDisappearance(trade)
    total_score = total_score + disappearance_score
    
    -- Остальные проверки из вашего кода...
    total_score = total_score + checkTemporalPatterns(trade)
    total_score = total_score + checkVolumePatterns(trade) 
    total_score = total_score + checkOrderbookBehavior(trade)
    total_score = total_score + performStatisticalAnalysis(trade)

    -- 6. Проверка на повторяющиеся сделки по тому же price
    if checkRepeatedTrades(trade.price, trade.volume, trade.direction) then
        total_score = total_score + 2
    end
    
    -- Определение уровня подозрения
    if total_score >= 8 then
        suspicion = "HIGH"
    elseif total_score >= 6 then
        suspicion = "MEDIUM_HIGH"
    elseif total_score >= 4 then
        suspicion = "MEDIUM"
    elseif total_score >= 2 then
        suspicion = "LOW"
    end
    
    if total_score >= 4 then
        -- message(string.format("Iceberg score: %d [V:%d T:%d O:%d S:%d R:%d D:%d]", 
        --        total_score, checkVolumePatterns(trade), checkTemporalPatterns(trade),
        --        checkOrderbookBehavior(trade), performStatisticalAnalysis(trade),
        --        checkRepeatedTrades(trade.price, trade.volume, trade.direction) and 2 or 0,
        --        disappearance_score))
    end
    return suspicion
end

function analyzeVolumeDistribution(direction)
    local score = 0
    local levels = (direction == "BUY") and orderbook_data.asks or orderbook_data.bids
    
    if #levels < 3 then return 0 end
    
    -- Проверяем наличие "ступенчатого" распределения объемов
    -- (характерно для айсбергов, разбитых на несколько уровней)
    local has_decreasing_volumes = true
    local has_uniform_volumes = true
    
    local first_volume = levels[1].quantity
    local volume_sum = first_volume
    
    for i = 2, math.min(5, #levels) do
        volume_sum = volume_sum + levels[i].quantity
        
        -- Проверка на убывающую последовательность
        if tonumber(levels[i].quantity) > levels[i-1].quantity * 0.8 then
            has_decreasing_volumes = false
        end
        
        -- Проверка на однородность объемов
        if math.abs(levels[i].quantity - first_volume) / first_volume > 0.5 then
            has_uniform_volumes = false
        end
    end
    
    -- Ступенчатое распределение + относительно постоянные объемы = подозрительно
    if has_decreasing_volumes and has_uniform_volumes then
        score = score + 2
    end
    
    -- Проверка на аномально большие объемы на дальних уровнях
    local avg_volume = volume_sum / math.min(5, #levels)
    for i = 1, math.min(5, #levels) do
        if tonumber(levels[i].quantity) > avg_volume * 3 then
            score = score + 1
            break
        end
    end
    
    return score
end

--Проверка крупных заявок на противоположной стороне
function checkOppositeSideLargeOrders(price, direction, trade_volume)
    local score = 0
    local opposite_levels = (direction == "BUY") and orderbook_data.bids or orderbook_data.asks
    
    -- Ищем крупные заявки на противоположной стороне вблизи цены сделки
    local large_orders_nearby = 0
    
    for _, level in ipairs(opposite_levels) do
        local price_diff = math.abs(level.price - price)
        local price_tolerance = getPriceTolerance(price)
        
        if price_diff <= price_tolerance and tonumber(level.quantity) >= trade_volume * 0.7 then
            large_orders_nearby = large_orders_nearby + 1
        end
    end
    
    if large_orders_nearby >= 2 then
        score = score + 2  -- Несколько крупных заявок на противоположной стороне
    elseif large_orders_nearby >= 1 then
        score = score + 1
    end
    
    return score
end
-- Функция получения видимого объема в стакане по определенной цене
function getVisibleVolumeInOrderbook(price, direction)
    local volume = 0
    local levels = (direction == "BUY") and orderbook_data.asks or orderbook_data.bids
    
    for _, level in ipairs(levels) do
        if math.abs(level.price - price) < 0.001 then -- Учитываем погрешность округления
            volume = level.quantity
            break
        end
    end
    
    return volume
end

-- Функция проверки повторяющихся сделок
function checkRepeatedTrades(price, volume, direction)
    local similar_trades = 0
    local time_window = 180 -- 5 минут в секундах
    local current_time = os.time()
    
    for i = #filtered_trades, math.max(1, #filtered_trades - 100), -1 do
        local past_trade = filtered_trades[i]

        if past_trade and not past_trade.is_canceled then
            local trade_time = convertTimeToTimestamp(past_trade.time)
        
           if current_time - trade_time <= time_window and
               past_trade.direction == direction and
               math.abs(past_trade.price - price) < 0.001 and
               math.abs(past_trade.volume - volume) / math.max(volume, 1) < 0.5 then -- 50% отличие
            
            similar_trades = similar_trades + 1

            if similar_trades >= 2 then
                    return true
                end
            end 
        end
    end
    
    return similar_trades >= 2 -- Если было 2+ похожих сделки
end

-- Дополнительная функция для анализа паттернов айсбергов
-- Глобальные переменные для контроля частоты сообщений
last_iceberg_analysis = last_iceberg_analysis or 0
analysis_interval = 20 -- секунд между анализами
reported_clusters = reported_clusters or {} -- таблица уже сообщенных кластеров
volume_statistics = volume_statistics or {mean = 1000, std_dev = 500} -- Значения по умолчанию

-- Глобальная таблица для хранения истории стаканов
MAX_ORDERBOOK_HISTORY = 10

function saveOrderbookSnapshot()
    local snapshot = {
        timestamp = os.time(),
        bids = {},
        asks = {}
    }
    
    -- Копируем текущий стакан
    for _, level in ipairs(orderbook_data.bids) do
        table.insert(snapshot.bids, {
            price = level.price,
            quantity = level.quantity
        })
    end
    
    for _, level in ipairs(orderbook_data.asks) do
        table.insert(snapshot.asks, {
            price = level.price,
            quantity = level.quantity
        })
    end
    
    -- Сохраняем снимок
    table.insert(orderbook_history, snapshot)
    
    -- Удаляем старые снимки
    if #orderbook_history > MAX_ORDERBOOK_HISTORY then
        table.remove(orderbook_history, 1)
    end
end

function checkVolumeDisappearance(trade)
    if #orderbook_history < 2 then return 0 end
    
    local current_snapshot = orderbook_history[#orderbook_history]
    local previous_snapshot = orderbook_history[#orderbook_history - 1]
    
    local score = 0
    local direction_levels = (trade.direction == "BUY") and "asks" or "bids"
    
    -- Сравниваем объемы на ближайших 3 уровнях
    for i = 1, 3 do
        if previous_snapshot[direction_levels][i] and current_snapshot[direction_levels][i] then
            local prev_volume = tonumber(previous_snapshot[direction_levels][i].quantity)
            local curr_volume = tonumber(current_snapshot[direction_levels][i].quantity)
            local price_diff = math.abs(previous_snapshot[direction_levels][i].price - trade.price)
            
            -- Если объем значительно уменьшился на уровне близком к цене сделки
            if price_diff < getPriceTolerance(trade.price) and curr_volume < prev_volume * 0.3 then
                score = score + 1
            end
        end
    end
    
    return math.min(score, 2)
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
function analyzeIcebergPatterns()
    local current_time = os.time()
    
    -- Проверяем интервал между анализами
    if current_time - (last_iceberg_analysis or 0) < analysis_interval then
        return
    end

    last_iceberg_analysis = current_time

    
    
    local iceberg_candidates = {}
    local new_clusters_found = false
    
    -- Собираем кандидаты только за последние 15 минут
    local time_threshold = current_time - 900

    -- Сначала обновляем статистики объемов
    updateVolumeStatistics()
    
    for i, trade in ipairs(filtered_trades) do
        if trade.iceberg_suspicion ~= "NO" and trade.iceberg_suspicion ~= "LOW" then
            -- Преобразуем время сделки в timestamp для фильтрации
            
            local trade_time = convertTimeToTimestamp(trade.time)
            local var = trade_time - time_threshold
            
            if trade_time >= time_threshold or trade_time < time_threshold then    --if trade_time >= time_threshold then
                
                -- Рассчитываем дополнительный score для фильтрации
                local additional_score = calculateAdditionalIcebergScore(trade)
                
                -- Добавляем только если общий score достаточно высок
                if additional_score >= 2 then
                table.insert(iceberg_candidates, {
                    time = trade.time,
                    price = trade.price,
                    volume = trade.volume,
                    direction = trade.direction,
                    suspicion_level = trade.iceberg_suspicion,
                    timestamp = trade_time,
                    additional_score = additional_score,
                    trade_object = trade
                })
            end
            end
        end
    end
    
    -- Сортируем кандидатов по времени (от новых к старым)
    table.sort(iceberg_candidates, function(a, b)
        return a.timestamp > b.timestamp
    end)

     -- Анализ кластеров с улучшенной фильтрацией и проверкой уникальности
    local processed_clusters = {}
    local found_new_icebergs = false

    for i, candidate in ipairs(iceberg_candidates) do
        local cluster_key = string.format("%s_%.4f_%d", candidate.direction, candidate.price, math.floor(candidate.timestamp / 300)) -- Группируем по 5-минутным интервалам
        
        -- Пропускаем если уже обрабатывали этот кластер
        if not processed_clusters[cluster_key] then
            local cluster_volume = candidate.volume
            local cluster_trades = 1
            local cluster_max_volume = candidate.volume
            local cluster_min_volume = candidate.volume
            local cluster_total_score = candidate.additional_score
            local cluster_start_time = candidate.time
            local cluster_end_time = candidate.time
            local cluster_members = {candidate}
            
            -- Ищем сделки в том же кластере
            for j = i + 1, #iceberg_candidates do
                local other = iceberg_candidates[j]
                local other_cluster_key = string.format("%s_%.4f_%d", other.direction, other.price, math.floor(other.timestamp / 300))
                
                if cluster_key == other_cluster_key then
                    cluster_volume = cluster_volume + other.volume
                    cluster_trades = cluster_trades + 1
                    cluster_total_score = cluster_total_score + other.additional_score
                    cluster_max_volume = math.max(cluster_max_volume, other.volume)
                    cluster_min_volume = math.min(cluster_min_volume, other.volume)
                    cluster_start_time = other.time -- Более раннее время
                    table.insert(cluster_members, other)
                end
            end

            -- Проверяем качество кластера
            if isHighQualityCluster(cluster_trades, cluster_volume, cluster_total_score, cluster_members) then
                processed_clusters[cluster_key] = true
                
                -- Проверяем не сообщали ли мы уже об этом кластере
                local report_key = string.format("%s_%.4f", candidate.direction, candidate.price)
                if not reported_clusters[report_key] or (current_time - reported_clusters[report_key]) > 1800 then -- 30 минут
                    
                    reported_clusters[report_key] = current_time
                    found_new_icebergs = true
                    new_clusters_found = true
                    
                    -- Детальная информация о кластере
                    local avg_volume = math.floor(cluster_volume / cluster_trades)
                    local volume_ratio = cluster_max_volume / math.max(cluster_min_volume, 1)
                    local time_span = getTimeDifference(cluster_end_time, cluster_start_time)
                    
                    -- Определяем тип айсберга по характеристикам
                    local iceberg_type = classifyIcebergType(cluster_trades, cluster_volume, volume_ratio, time_span)
                    
                    message(string.format("?? %s ICEBERG: %s %s-%s | Price: %.2f | %d trades, %d lots | Avg: %d | Span: %ds | Type: %s",
                           iceberg_type,
                           candidate.direction,
                           cluster_start_time,
                           cluster_end_time,
                           candidate.price,
                           cluster_trades,
                           cluster_volume,
                           avg_volume,
                           time_span,
                           getIcebergCharacteristics(cluster_members)))
                    
                           AddIcebergOrders(candidate.price,iceberg_type,candidate.direction,cluster_volume,avg_volume)
                    -- Дополнительная аналитика для высококачественных кластеров
                    if cluster_trades >= 5 and cluster_volume >= 10000 then
                        analyzeClusterPattern(cluster_members, candidate.direction, candidate.price)
                    end
                end
            end
        end
    end
    
    -- Очистка старых записей
    cleanupReportedClusters()
    
    -- Статистика анализа
    if #iceberg_candidates > 0 then
        -- message(string.format("Iceberg analysis: %d candidates, %d clusters found", 
        --        #iceberg_candidates, getTableSize(processed_clusters)))
    end
    safe_PrintValues()
end

function AddIcebergOrders(price, type, direction, volume, avg_volume)
    local found = false

    -- Сначала убедимся, что цена есть в массиве
    local price_key = string.format("%.4f", tonumber(price))
    local price_exists = false
    
    for i = 1, #IcebergArray do
        if IcebergArray[i] and IcebergArray[i].Price then
            local existing_price_key = string.format("%.4f", tonumber(IcebergArray[i].Price))
            if existing_price_key == price_key then
                price_exists = true
                break
            end
        end
    end
    
    -- Если цены нет, добавляем её
    if not price_exists then
        local newOrder = {
            Price = price,
            Type = type,
            direction = direction,
            Volume = volume,
            Avg_Volume = avg_volume,
            TotalBeyond = 0  -- Новый столбец
        }
        table.insert(IcebergArray, newOrder)
        found = true
        
    else
        -- Ищем существующую запись с такой ценой для обновления
        for i = 1, #IcebergArray do
            if IcebergArray[i] and IcebergArray[i].Price then
                local existing_price_key = string.format("%.4f", tonumber(IcebergArray[i].Price))
                if existing_price_key == price_key then
                    -- Обновляем существующую запись
                    IcebergArray[i].Type = type
                    IcebergArray[i].direction = direction
                    IcebergArray[i].Volume = volume
                    IcebergArray[i].Avg_Volume = avg_volume
                     -- TotalBeyond будет рассчитан автоматически в CalculateTotalBeyondVolumes
                    found = true
                    
                    break
                end
            end
        end
    end
    
    -- Сортируем массив по цене
    table.sort(IcebergArray, function(a, b)
        return tonumber(a.Price) < tonumber(b.Price)
    end)

     -- ОБНОВЛЯЕМ данные TotalBeyond сразу после добавления/обновления айсберга
    local best_bid, best_ask = GetBestBidAsk()
    CalculateTotalBeyondVolumes(tonumber(best_bid), tonumber(best_ask))
    
    return found
end
-------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

function isHighQualityCluster(trades_count, total_volume, total_score, members)
    -- Минимальные требования для кластера
    if trades_count < 2 then return false end    --было3
    if total_volume < 50 then return false end  --2000 было
    
    -- Проверка разнообразия объемов (не все сделки одинаковые)
    local unique_volumes = {}
    for _, member in ipairs(members) do
        unique_volumes[member.volume] = true
    end
    
    -- Средний score на сделку
    local avg_score = total_score / trades_count
    
    -- return avg_score >= 1.5 and getTableSize(unique_volumes) >= 2
    return avg_score >= 1.5
end

-- Функция преобразования времени в timestamp
function convertTimeToTimestamp(time_str)
    local hour, min, sec = string.match(time_str, "(%d+):(%d+):(%d+)")
    local current_time = os.time()
    local current_date = os.date("*t",current_time)
    return os.time({
        year = current_date.year,
        month = current_date.month,
        day = current_date.day,
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)
    })
end

function calculateAdditionalIcebergScore(trade)
    local score = 0
    
    -- 1. Проверка объема относительно среднего
    local avg_volume = getAverageTradeVolume()
    if avg_volume > 0 then
        local volume_ratio = trade.volume / avg_volume
        if volume_ratio > 8 then score = score + 2
        elseif volume_ratio > 5 then score = score + 1 end
    end
    
    -- 2. Проверка на "круглые" объемы
    if isRoundVolume(trade.volume) then score = score + 1 end
    
    -- 3. Проверка уровня подозрения
    if string.find(trade.iceberg_suspicion or "", "HIGH") then score = score + 2 end
    if string.find(trade.iceberg_suspicion or "", "MEDIUM") then score = score + 1 end
    
    -- 4. Проверка повторяющихся сделок
    if checkRepeatedTradesSimple(trade.price, trade.volume, trade.direction) then 
        score = score + 1 
    end
    
    return score
end

function isRoundVolume(volume)
    local round_volumes = {1000, 2000, 5000, 10000, 15000, 20000, 25000, 50000, 100000}
    for _, round_vol in ipairs(round_volumes) do
        if math.abs(volume - round_vol) <= round_vol * 0.1 then -- ±10%
            return true
        end
    end
    return false
end

function getTableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function checkRepeatedTradesSimple(price, volume, direction)
    local similar_count = 0
    local price_tolerance = 0.001
    local volume_tolerance = 0.3
    
    for i = math.max(1, #filtered_trades - 50), #filtered_trades do
        local trade = filtered_trades[i]
        if trade and not trade.is_canceled and
           trade.direction == direction and
           math.abs(trade.price - price) < price_tolerance and
           math.abs(trade.volume - volume) / math.max(volume, 1) < volume_tolerance then
            similar_count = similar_count + 1
        end
    end
    
    return similar_count >= 2
end

-- function hasRegularTimePattern(trade)
--     local recent_trades = getRecentTradesByPrice(trade.price, trade.direction, 5)
--     if #recent_trades < 3 then return false end
    
--     local intervals = {}
--     for i = 2, #recent_trades do
--         local time_diff = getTimeDifference(recent_trades[i].time, recent_trades[i-1].time)
--         table.insert(intervals, time_diff)
--     end
    
function getTimeDifference(time_end, time_start)
    local ts_end = convertTimeToTimestamp(time_end)
    local ts_start = convertTimeToTimestamp(time_start)
    return math.abs(ts_end - ts_start)
end

function getRecentTradesByPrice(price, direction, max_count)
    local similar = {}
    local price_tolerance = 0.001
    
    for i = #filtered_trades, math.max(1, #filtered_trades - 200), -1 do
        local trade = filtered_trades[i]
        if trade and not trade.is_canceled and
           trade.direction == direction and
           math.abs(trade.price - price) < price_tolerance then
            table.insert(similar, trade)
            if #similar >= max_count then break end
        end
    end
    
    return similar
end

function classifyIcebergType(trades_count, total_volume, volume_ratio, time_span)
    if total_volume >= 15000 then
        return "LARGE"
    elseif time_span <= 60 and trades_count >= 4 then
        return "AGGRESSIVE"
    elseif volume_ratio <= 2.0 and trades_count >= 3 then
        return "STEALTH"
    elseif time_span >= 300 then
        return "PASSIVE"
    else
        return "STANDARD"
    end
end

function getIcebergCharacteristics(members)
    local characteristics = {}
    
    -- Анализ распределения объемов
    local volumes = {}
    for _, member in ipairs(members) do
        table.insert(volumes, member.volume)
    end
    
    local avg_vol = calculateAverage(volumes)
    local std_dev = calculateStandardDeviation(volumes, avg_vol)
    
    if std_dev / avg_vol < 0.3 then
        table.insert(characteristics, "uniform")
    else
        table.insert(characteristics, "varied")
    end
    
    -- Анализ временных интервалов
    local times = {}
    for _, member in ipairs(members) do
        table.insert(times, convertTimeToTimestamp(member.time))
    end
    table.sort(times)
    
    local intervals = {}
    for i = 2, #times do
        table.insert(intervals, times[i] - times[i-1])
    end
    
    local avg_interval = calculateAverage(intervals)
    if avg_interval <= 30 then
        table.insert(characteristics, "fast")
    elseif avg_interval <= 120 then
        table.insert(characteristics, "medium")
    else
        table.insert(characteristics, "slow")
    end
    
    return table.concat(characteristics, "/")
end

function analyzeClusterPattern(members, direction, price)
    local volumes = {}
    local times = {}

    for _, member in ipairs(members) do
        table.insert(volumes, member.volume)
        table.insert(times, convertTimeToTimestamp(member.time))
    end
    
    -- Анализ тренда объемов
    local volume_trend = analyzeVolumeTrend(volumes)
    local time_pattern = analyzeTimePattern(times)
    
    message(string.format("   ?? Cluster analysis: %s trend, %s execution", volume_trend, time_pattern))
    
    -- Прогноз оставшегося объема
    local estimated_remaining = estimateRemainingVolume(members, direction, price)
    if estimated_remaining > 0 then
        message(string.format("   ?? Estimated remaining: %d lots", estimated_remaining))
    end
end

function analyzeVolumeTrend(volumes)
    if #volumes < 3 then return "unknown" end
    
    local increasing = true
    local decreasing = true
    
    for i = 2, #volumes do
        if volumes[i] <= volumes[i-1] then increasing = false end
        if volumes[i] >= volumes[i-1] then decreasing = false end
    end
    
    if increasing then return "increasing"
    elseif decreasing then return "decreasing"
    else return "mixed" end
end

function analyzeTimePattern(times)
    if #times < 2 then return "single" end
    
    table.sort(times)
    local intervals = {}
    
    for i = 2, #times do
        table.insert(intervals, times[i] - times[i-1])
    end
    
    local avg_interval = calculateAverage(intervals)
    if #intervals == 0 then return "single" end
    
    local std_dev = calculateStandardDeviation(intervals, avg_interval)
    
    if std_dev / math.max(avg_interval, 1) < 0.5 then
        return "regular"
    elseif avg_interval <= 30 then
        return "burst"
    else
        return "irregular"
    end
end

function estimateRemainingVolume(members, direction, price)
    -- Простая эвристика: предполагаем что айсберг составляет 20-50% от общего объема
    local total_volume = 0
    for _, member in ipairs(members) do
        total_volume = total_volume + member.volume
    end
    
    -- Предполагаем что видимая часть - это 20-30% от общего объема айсберга
    local estimated_total = total_volume * 3.5
    local remaining = math.max(0, estimated_total - total_volume)
    
    return math.floor(remaining)
end

-- Очистка устаревших кластеров
function cleanupReportedClusters()
    local current_time = os.time()
    local to_remove = {}
    
    for cluster_key, reported_time in pairs(reported_clusters) do
        if current_time - reported_time > 1800 then -- 30 минут
            table.insert(to_remove, cluster_key)
        end
    end
    
    for _, key in ipairs(to_remove) do
        reported_clusters[key] = nil
    end
end

--  Анализ временных паттернов
function checkTemporalPatterns(trade)
    local patterns_score = 0
    
    -- Проверка регулярности интервалов между сделками
    local recent_trades = getRecentTradesByPrice(trade.price, trade.direction, 10)
    if #recent_trades >= 3 then
        local intervals = {}
        for i = 2, #recent_trades do
            local time_diff = getTimeDifference(recent_trades[i].time, recent_trades[i-1].time)
            table.insert(intervals, time_diff)
        end
        
        -- Проверяем регулярность интервалов (стандартное отклонение)
        local avg_interval = calculateAverage(intervals)
        local std_dev = calculateStandardDeviation(intervals, avg_interval)
        
        if std_dev < 5 then -- Интервалы регулярные (малое отклонение)
            patterns_score = patterns_score + 2
        end
    end
    
    -- Проверка времени суток (айсберги чаще в активные часы)
    local hour = tonumber(string.sub(trade.time, 1, 2))
    if (hour >= 10 and hour <= 12) or (hour >= 14 and hour <= 16) then
        patterns_score = patterns_score + 1
    end
    
    return patterns_score
end

-- Анализ объемов и их распределения
function checkVolumePatterns(trade)
    local volume_score = 0
    
    -- Проверка на "круглые" объемы (характерно для айсбергов)
    local round_volumes = {1000, 2000, 5000, 10000, 20000, 50000}
    for _, round_vol in ipairs(round_volumes) do
        if math.abs(trade.volume - round_vol) / round_vol < 0.1 then -- ±10%
            volume_score = volume_score + 1
            break
        end
    end
    
    -- Проверка отношения объема к среднему объему по инструменту
    local avg_trade_volume = getAverageTradeVolume()
    if avg_trade_volume > 0 then
        local volume_ratio = trade.volume / avg_trade_volume
        if volume_ratio > 10 then -- Объем в 10 раз больше среднего
            volume_score = volume_score + 2
        elseif volume_ratio > 5 then
            volume_score = volume_score + 1
        end
    end
    
    -- Проверка на кратные объемы в последовательных сделках
    local similar_trades = findSimilarTrades(trade.price, trade.direction, 5)
    if #similar_trades >= 2 then
        local base_volume = math.min(similar_trades[1].volume, similar_trades[2].volume)
        local all_multiple = true
        
        for _, t in ipairs(similar_trades) do
            if t.volume % base_volume ~= 0 then
                all_multiple = false
                break
            end
        end
        
        if all_multiple then
            volume_score = volume_score + 2
        end
    end
    
    return volume_score
end

-- Анализ поведения стакана
function checkOrderbookBehavior(trade)
    local orderbook_score = 0
    
    -- Проверка "исчезновения" крупной заявки после сделки
    local visible_before = tonumber(getVisibleVolumeInOrderbook(trade.price, trade.direction))
    
    -- Ждем немного и проверяем стакан снова (в реальном коде это нужно делать асинхронно)
    if visible_before > 0 then
        -- В реальной реализации здесь нужно добавить задержку и перепроверку
        orderbook_score = orderbook_score + 1
    end
    
    -- Проверка наличия крупных заявок на соседних ценах
    local nearby_levels = getNearbyLevels(trade.price, trade.direction, 3)
    local large_orders_nearby = 0
    
    for _, level in ipairs(nearby_levels) do
        if tonumber(level.quantity) > trade.volume * 0.7 then
            large_orders_nearby = large_orders_nearby + 1
        end
    end
    
    if large_orders_nearby >= 2 then
        orderbook_score = orderbook_score + 1
    end
    
    -- Проверка изменения спреда
    local current_spread = getCurrentSpread()
    if current_spread > 0 and current_spread < 0.1 then -- Узкий спред
        orderbook_score = orderbook_score + 1
    end
    -- После сделки спред может резко измениться если айсберг "съели"
    
    return orderbook_score
end

-- Статистический анализ
function performStatisticalAnalysis(trade)
    local stats_score = 0
    
    -- Z-score объема (отклонение от среднего)
    local volume_stats = calculateVolumeStatistics()
    if volume_stats.mean > 0 and volume_stats.std_dev > 0 then
        local z_score = (trade.volume - volume_stats.mean) / volume_stats.std_dev
        if z_score > 2.5 then -- Статистически значимое отклонение
            stats_score = stats_score + 2
        elseif z_score > 1.5 then
            stats_score = stats_score + 1
        end
    end
    
    -- Анализ кластерности по времени
    local time_clusters = findTimeClusters(trade.direction, trade.price, 300) -- 5 минут
    if #time_clusters >= 1 then
        stats_score = stats_score + 1
    end
    
    return stats_score
end

function findTimeClusters(direction, price, time_window)
    local clusters = {}
    local price_tolerance = 0.001
    local current_time = os.time()
    
    -- Собираем все сделки по заданному направлению и цене за временное окно
    local relevant_trades = {}
    
    for i = #filtered_trades, math.max(1, #filtered_trades - 500), -1 do
        local trade = filtered_trades[i]
        if trade and not trade.is_canceled and
           trade.direction == direction and
           math.abs(trade.price - price) < price_tolerance then
            
            local trade_timestamp = convertTimeToTimestamp(trade.time)
            if current_time - trade_timestamp <= time_window then
                table.insert(relevant_trades, {
                    time = trade.time,
                    timestamp = trade_timestamp,
                    volume = trade.volume
                })
            end
        end
    end
    
    -- Сортируем по времени
    table.sort(relevant_trades, function(a, b)
        return a.timestamp < b.timestamp
    end)
    
    -- Находим кластеры по времени
    if #relevant_trades > 0 then
        local current_cluster = {relevant_trades[1]}
        
        for i = 2, #relevant_trades do
            local time_diff = relevant_trades[i].timestamp - relevant_trades[i-1].timestamp
            
            if time_diff <= 60 then -- Сделки в пределах 60 секунд считаем одним кластером
                table.insert(current_cluster, relevant_trades[i])
            else
                if #current_cluster >= 2 then
                    table.insert(clusters, current_cluster)
                end
                current_cluster = {relevant_trades[i]}
            end
        end
        
        -- Добавляем последний кластер
        if #current_cluster >= 2 then
            table.insert(clusters, current_cluster)
        end
    end
    
    return clusters
end

-- Получение среднего объема сделок
function getAverageTradeVolume()
   return volume_statistics.mean or 1000
end

-- Поиск схожих сделок
function findSimilarTrades(price, direction, lookback)
    local similar = {}
    local price_tolerance = 0.001
    
    for i = math.max(1, #filtered_trades - lookback), #filtered_trades do
        local trade = filtered_trades[i]
        if trade and not trade.is_canceled and
           trade.direction == direction and
           math.abs(trade.price - price) < price_tolerance then
            table.insert(similar, trade)
        end
    end
    
    return similar
end

-- Расчет статистик объема
function calculateVolumeStatistics()
    local volumes = {}
    
    for i = math.max(1, #filtered_trades - 200), #filtered_trades do
        local trade = filtered_trades[i]
        if trade and not trade.is_canceled then
            table.insert(volumes, trade.volume)
        end
    end
    
    local mean = calculateAverage(volumes)
    local std_dev = calculateStandardDeviation(volumes, mean)
    
    return {mean = mean, std_dev = std_dev}
end

-- Математические функции
function calculateAverage(values)
    if #values == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(values) do sum = sum + v end
    return sum / #values
end

function calculateStandardDeviation(values, mean)
    if #values == 0 then return 0 end
    local sum_sq = 0
    for _, v in ipairs(values) do
        sum_sq = sum_sq + (v - mean) ^ 2
    end
    return math.sqrt(sum_sq / #values)
end

function updateVolumeStatistics()
    local volumes = {}
    local lookback = math.min(200, #filtered_trades)
    
    for i = math.max(1, #filtered_trades - lookback), #filtered_trades do
        local trade = filtered_trades[i]
        if trade and not trade.is_canceled then
            table.insert(volumes, trade.volume)
        end
    end
    
    if #volumes > 10 then
        volume_statistics.mean = calculateAverage(volumes)
        volume_statistics.std_dev = calculateStandardDeviation(volumes, volume_statistics.mean)
    end
end

function getNearbyLevels(price, direction, levels_count)
    local nearby_levels = {}
    local orderbook_side = (direction == "BUY") and orderbook_data.asks or orderbook_data.bids
    
    if not orderbook_side or #orderbook_side == 0 then
        return nearby_levels
    end
    
    -- Сортируем уровни по близости к цене сделки
    local sorted_levels = {}
    for _, level in ipairs(orderbook_side) do
        table.insert(sorted_levels, level)
    end
    
    table.sort(sorted_levels, function(a, b)
        if direction == "BUY" then
            return a.price < b.price  -- Для покупок: ближайшие ask цены
        else
            return a.price > b.price  -- Для продаж: ближайшие bid цены
        end
    end)
    
    -- Берем ближайшие levels_count уровней
    for i = 1, math.min(levels_count, #sorted_levels) do
        table.insert(nearby_levels, sorted_levels[i])
    end
    
    return nearby_levels
end

function getCurrentSpread()
    if not orderbook_data.bids or not orderbook_data.asks or 
       #orderbook_data.bids == 0 or #orderbook_data.asks == 0 then
        return 0
    end
    
    local best_bid = orderbook_data.bids[1].price
    local best_ask = orderbook_data.asks[1].price
    
    return best_ask - best_bid
end

function safe_AnalyzeIcebergPatterns()
    local status, err = pcall(analyzeIcebergPatterns)
    if not status then
        message("Ошибка в analyzeIcebergPatterns: " .. tostring(err))
    end
end

function safe_PrintValues()
    local status, err = pcall(PrintValues)
    if not status then
        message("Ошибка в PrintValues: " .. tostring(err))
    end
end


function SyncWithOrderbook()
    if #MyQuote == 0 then
        return
    end
    
    
    -- Создаем временную таблицу для быстрого поиска существующих цен
    local existing_prices = {}
    for i = 1, #IcebergArray do
        if IcebergArray[i] and IcebergArray[i].Price then
            local price_key = string.format("%.4f", tonumber(IcebergArray[i].Price))
            existing_prices[price_key] = IcebergArray[i]
        end
    end
    
    -- Добавляем отсутствующие цены из стакана
    local added_count = 0
    for i = 1, #MyQuote do
        if MyQuote[i] and MyQuote[i].Price then
            local price_key = string.format("%.4f", tonumber(MyQuote[i].Price))
            
            if not existing_prices[price_key] then
                -- Добавляем новую запись для отсутствующей цены
                local newTable = {
                    Price = MyQuote[i].Price,
                    Type = "",
                    direction = "",
                    Volume = 0,
                    Avg_Volume = 0,
                    TotalBeyond = 0
                }
                table.insert(IcebergArray, newTable)
                added_count = added_count + 1
            end
        end
    end
    
    -- Удаляем устаревшие цены, которых нет в текущем стакане (опционально)
    local removed_count = CleanOldPrices(existing_prices)
    
    -- Сортируем массив по цене
    table.sort(IcebergArray, function(a, b)
        return tonumber(a.Price) < tonumber(b.Price)
    end)

    -- ОБНОВЛЯЕМ TotalBeyond после синхронизации
    local best_bid, best_ask = GetBestBidAsk()
    CalculateTotalBeyondVolumes(tonumber(best_bid), tonumber(best_ask))
    
    return added_count
end

-- Добавляем функцию для ручного обновления таблицы
function ManualRefresh()
    message("Ручное обновление таблицы айсбергов")
    local best_bid, best_ask = GetBestBidAsk()
    CalculateTotalBeyondVolumes(tonumber(best_bid), tonumber(best_ask))
    safe_PrintValues()
end


function CleanOldPrices(existing_prices)
    if not CLEAN_OLD_PRICES then
        return 0
    end
    
    local removed_count = 0
    local current_prices = {}
    
    -- Собираем текущие цены из стакана
    for i = 1, #MyQuote do
        if MyQuote[i] and MyQuote[i].Price then
            local price_key = string.format("%.4f", tonumber(MyQuote[i].Price))
            current_prices[price_key] = true
        end
    end
    
    -- Удаляем записи, которых нет в текущем стакане
    for i = #IcebergArray, 1, -1 do
        if IcebergArray[i] and IcebergArray[i].Price then
            local price_key = string.format("%.4f", tonumber(IcebergArray[i].Price))
            
            -- Если цены нет в текущем стакане И это не айсберг, удаляем
            if not current_prices[price_key] and 
               (not IcebergArray[i].direction or IcebergArray[i].direction == "") then
                table.remove(IcebergArray, i)
                removed_count = removed_count + 1
            end
        end
    end
    
    return removed_count
end

-- Глобальная настройка (можно включить/выключить очистку старых цен)
CLEAN_OLD_PRICES = true  -- true - удалять устаревшие цены, false - оставлять


function GetBestBidAsk()
    local best_bid = 0
    local best_ask = 0
    
    if orderbook_data and #orderbook_data.bids > 0 then
        best_bid = orderbook_data.bids[#orderbook_data.bids].price
    end
    
    if orderbook_data and #orderbook_data.asks > 0 then
        best_ask = orderbook_data.asks[1].price
    end
    
    return best_bid, best_ask
end