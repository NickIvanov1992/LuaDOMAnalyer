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
        direction = "buy/sell",
        Volume = 0,
        Avg_Volume = 0

        }
           table.insert(IcebergArray,defaultTable)
    end

end


function PrintValues()
     if #IcebergArray == 0 then
         Clear(iceberg_id)
        return
    end
    message("Вывод айсбергов"..#IcebergArray)

Clear(iceberg_id)

    table.sort(IcebergArray, function (a,b)
            return tonumber(a.Price ) < tonumber(b.Price)      
        end)

    local row = 1
        for i = #IcebergArray, 1, -1 do
            InsertRow(iceberg_id, -1)
            SetCell(iceberg_id, row, 1, tostring(IcebergArray[i].Price))
            SetCell(iceberg_id, row, 2, tostring(IcebergArray[i].Type))
            SetCell(iceberg_id, row, 3, tostring(IcebergArray[i].direction))
            SetCell(iceberg_id, row, 4, tostring(IcebergArray[i].Avg_Volume))

            SetIcebergColor(IcebergArray[i].Type,row)
            row = row + 1
        end

    

    
end

 function SetIcebergColor(type,row)
            if type == "SELL" then
                SetColor(iceberg_id, row, 1, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
                SetColor(iceberg_id, row, 2, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
                SetColor(iceberg_id, row, 3, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
                SetColor(iceberg_id, row, 4, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
            else
                SetColor(iceberg_id, row, 1, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                SetColor(iceberg_id, row, 2, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                SetColor(iceberg_id, row, 3, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                SetColor(iceberg_id, row, 4, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
            end
        end
-----------------------------------------------------------------------------------


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
    end
    
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
    PrintValues()
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
last_iceberg_analysis = 0
analysis_interval = 10 -- секунд между анализами
reported_clusters = {} -- таблица уже сообщенных кластеров
volume_statistics = {mean = 1000, std_dev = 500} -- Значения по умолчанию

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
    PrintValues()
end

function AddIcebergOrders(price,type,direction,volume,avg_volume)
    if (#MyQuote > 0) then
        --Добавим акутальные цены стакана
        local found = false
        message("IcebergArray"..#IcebergArray)

        if (#IcebergArray > 0) then
            for i = 1, #IcebergArray do
            if(IcebergArray[i].Price == price) then
                IcebergArray[i].Type = type
                IcebergArray[i].direction = direction
                IcebergArray[i].Volume = volume
                IcebergArray[i].Avg_Volume = avg_volume
                found = true
            end
        end
        end
        
         if not found then
                local newOrder = {
                Price = price,
                Type = type,
                direction = direction,
                Volume = volume,
                Avg_Volume = avg_volume
                }
                table.insert(IcebergArray, newOrder)
                message("Added order^ "..#IcebergArray)
        end
        
    end
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