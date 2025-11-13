function FindIceberg ()
    if #IcebergArray == 0 or IcebergArray == nil then
        Initial()
        PrintValues()
    end
end

function Initial()
    if #MyQuote == 0 then
        message("Пустой стакан")
        return
    end
    for i = 1, #MyQuote do
         local defaultTable = {
        Price = MyQuote[i].Price,
        Type = "null",
        Volume = 0
        }
           table.insert(IcebergArray,defaultTable)
    end

end


function PrintValues()
     if #IcebergArray == 0 then
         Clear(iceberg_id)
        return
    end

    table.sort(IcebergArray, function (a,b)
            return a.Price < b.Price        
        end)
    
    
    message(#IcebergArray)
        for i = #IcebergArray, 1, -1 do
            InsertRow(iceberg_id, -1)
            SetCell(iceberg_id, i, 1, tostring(IcebergArray[i].Price))
            SetCell(iceberg_id, i, 2, tostring(IcebergArray[i].Type))
            SetCell(iceberg_id, i, 3, tostring(IcebergArray[i].Volume))
        end
end
-----------------------------------------------------------------------------------


-- Функция для обновления стакана
function OnQuote(class_code, sec_code)
    if sec_code == "AFLT" and class_code == "QJSIM" then
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
    end
end

-- Функция проверки на айсберг-заявку
function checkIcebergSuspicion(trade)
    local suspicion = "NO"
    
    -- 1. Проверка объема сделки
    if trade.volume >= 10000 then -- Большой объем (настройте под ваш инструмент)
        suspicion = "LOW"
    end
    
    -- 2. Проверка наличия в стакане до сделки
    local visible_volume = tonumber(getVisibleVolumeInOrderbook(trade.price, trade.direction))
    
    if visible_volume > 0 then
        -- 3. Сравнение объема сделки с видимым объемом в стакане
        if trade.volume > visible_volume * 2 then -- Сделка значительно больше видимого объема
            suspicion = "HIGH"
        elseif trade.volume > visible_volume * 1.5 then
            suspicion = "MEDIUM"
        elseif trade.volume > visible_volume and suspicion == "LOW" then
            suspicion = "MEDIUM"
        end
    end
    
    -- 4. Проверка на повторяющиеся сделки по тому же price
    if checkRepeatedTrades(trade.price, trade.volume, trade.direction) then
        if suspicion == "HIGH" then
            suspicion = "HIGH_REPEATED"
        else
            suspicion = "MEDIUM_REPEATED"
        end
    end
    
    return suspicion
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
    local time_window = 300 -- 5 минут в секундах
    
    for i = #filtered_trades, math.max(1, #filtered_trades - 50), -1 do
        local past_trade = filtered_trades[i]
        
        -- Проверяем сделки за последние time_window секунд
        if past_trade and not past_trade.is_canceled and
           past_trade.direction == direction and
           math.abs(past_trade.price - price) < 0.001 and
           math.abs(past_trade.volume - volume) / volume < 0.3 then -- Объем отличается не более чем на 30%
            
            similar_trades = similar_trades + 1
        end
    end
    
    return similar_trades >= 2 -- Если было 2+ похожих сделки
end

-- Дополнительная функция для анализа паттернов айсбергов
-- Глобальные переменные для контроля частоты сообщений
last_iceberg_analysis = 0
analysis_interval = 10 -- секунд между анализами
reported_clusters = {} -- таблица уже сообщенных кластеров

function analyzeIcebergPatterns()
    local current_time = os.time()
    
    -- Проверяем интервал между анализами
    if current_time - last_iceberg_analysis < analysis_interval then
        return
    end
    
    last_iceberg_analysis = current_time
    
    local iceberg_candidates = {}
    local new_clusters_found = false
    
    -- Собираем кандидаты только за последние N минут
    local time_threshold = current_time - 600 -- 10 минут
    
    for i, trade in ipairs(filtered_trades) do
        if trade.iceberg_suspicion ~= "NO" then
            -- Преобразуем время сделки в timestamp для фильтрации
            local trade_time = convertTimeToTimestamp(trade.time)
            if trade_time >= time_threshold then
                table.insert(iceberg_candidates, {
                    time = trade.time,
                    price = trade.price,
                    volume = trade.volume,
                    direction = trade.direction,
                    suspicion_level = trade.iceberg_suspicion,
                    timestamp = trade_time
                })
            end
        end
    end
    
    -- Анализ кластеров с проверкой уникальности
    for i, candidate in ipairs(iceberg_candidates) do
        local cluster_volume = candidate.volume
        local cluster_trades = 1
        local cluster_key = string.format("%s_%.4f", candidate.direction, candidate.price)
        
        -- Пропускаем уже сообщенные кластеры
        if not reported_clusters[cluster_key] then
            
            for j = i + 1, #iceberg_candidates do
                local other = iceberg_candidates[j]
                
                if math.abs(other.price - candidate.price) < 0.001 and
                   other.direction == candidate.direction and
                   math.abs(other.timestamp - candidate.timestamp) < 300 then -- 5 минут
                   
                    cluster_volume = cluster_volume + other.volume
                    cluster_trades = cluster_trades + 1
                end
            end
            
            if cluster_trades >= 3 then
                -- Помечаем кластер как сообщенный
                reported_clusters[cluster_key] = true
                new_clusters_found = true
                
                message(string.format("ICEBERG CLUSTER: %s %s - %.2f - %d trades, total volume: %d",
                       candidate.direction, candidate.time, candidate.price, cluster_trades, cluster_volume))
            end
        end
    end
    
    -- Очистка старых записей
    cleanupReportedClusters()
end

-- Функция преобразования времени в timestamp
function convertTimeToTimestamp(time_str)
    local hour, min, sec = string.match(time_str, "(%d+):(%d+):(%d+)")
    local current_date = os.date("*t")
    return os.time({
        year = current_date.year,
        month = current_date.month,
        day = current_date.day,
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)
    })
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