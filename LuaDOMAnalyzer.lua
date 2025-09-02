
-- --[[
--     Расширенный стакан цен с запоминанием скрытых лотов
--     Хранит не только видимые, но и снятые/исполненные заявки
-- --]]

-- HiddenOrderBook = {}
-- HiddenOrderBook.__index = HiddenOrderBook

-- -- Конструктор
-- function HiddenOrderBook.new(class_code, sec_code)
--     local self = setmetatable({}, HiddenOrderBook)
    
--     self.class_code = class_code or "TQBR"
--     self.sec_code = sec_code or "SBER"
--     self.timestamp = os.time()
    
--     -- Видимый стакан
--     self.visible_bids = {}  -- {цена = объем}
--     self.visible_asks = {}  -- {цена = объем}
    
--     -- Полная история всех заявок (включая скрытые)
--     self.order_history = {} -- {order_id = {price, volume, type, timestamp, status}}
    
--     -- Агрегированные скрытые объемы по ценам
--     self.hidden_bids = {}   -- {цена = скрытый_объем}
--     self.hidden_asks = {}   -- {цена = скрытый_объем}
    
--     -- Статистика
--     self.stats = {
--         total_orders = 0,
--         hidden_orders = 0,
--         executed_volume = 0,
--         canceled_volume = 0
--     }
    
--     return self
-- end

-- -- Добавление новой заявки в стакан
-- function HiddenOrderBook:add_order(order_id, price, volume, order_type, is_hidden)
--     local order_data = {
--         id = order_id,
--         price = price,
--         volume = volume,
--         type = order_type,  -- "bid" или "ask"
--         timestamp = os.time(),
--         status = "active",
--         is_hidden = is_hidden or false
--     }
    
--     self.order_history[order_id] = order_data
--     self.stats.total_orders = self.stats.total_orders + 1
    
--     if is_hidden then
--         self.stats.hidden_orders = self.stats.hidden_orders + 1
--         self:_update_hidden_depth(order_data)
--     else
--         self:_update_visible_depth(order_data)
--     end
    
--     return order_data
-- end

-- -- Обновление видимого стакана
-- function HiddenOrderBook:_update_visible_depth(order_data)
--     if order_data.type == "bid" then
--         self.visible_bids[order_data.price] = (self.visible_bids[order_data.price] or 0) + order_data.volume
--     else
--         self.visible_asks[order_data.price] = (self.visible_asks[order_data.price] or 0) + order_data.volume
--     end
-- end

-- -- Обновление скрытых объемов
-- function HiddenOrderBook:_update_hidden_depth(order_data)
--     if order_data.type == "bid" then
--         self.hidden_bids[order_data.price] = (self.hidden_bids[order_data.price] or 0) + order_data.volume
--     else
--         self.hidden_asks[order_data.price] = (self.hidden_asks[order_data.price] or 0) + order_data.volume
--     end
-- end

-- -- Исполнение заявки (частичное или полное)
-- function HiddenOrderBook:execute_order(order_id, executed_volume)
--     local order = self.order_history[order_id]
--     if not order then return false end
    
--     if order.status == "active" then
--         if executed_volume >= order.volume then
--             order.status = "filled"
--             order.volume = 0
--         else
--             order.status = "partial"
--             order.volume = order.volume - executed_volume
--         end
        
--         self.stats.executed_volume = self.stats.executed_volume + executed_volume
        
--         -- Обновляем стакан
--         if not order.is_hidden then
--             if order.type == "bid" then
--                 self.visible_bids[order.price] = (self.visible_bids[order.price] or 0) - executed_volume
--                 if self.visible_bids[order.price] <= 0 then
--                     self.visible_bids[order.price] = nil
--                 end
--             else
--                 self.visible_asks[order.price] = (self.visible_asks[order.price] or 0) - executed_volume
--                 if self.visible_asks[order.price] <= 0 then
--                     self.visible_asks[order.price] = nil
--                 end
--             end
--         end
        
--         return true
--     end
--     return false
-- end

-- -- Отмена заявки
-- function HiddenOrderBook:cancel_order(order_id)
--     local order = self.order_history[order_id]
--     if not order or order.status ~= "active" then return false end
    
--     order.status = "canceled"
--     self.stats.canceled_volume = self.stats.canceled_volume + order.volume
    
--     -- Удаляем из стакана
--     if not order.is_hidden then
--         if order.type == "bid" then
--             self.visible_bids[order.price] = (self.visible_bids[order.price] or 0) - order.volume
--             if self.visible_bids[order.price] <= 0 then
--                 self.visible_bids[order.price] = nil
--             end
--         else
--             self.visible_asks[order.price] = (self.visible_asks[order.price] or 0) - order.volume
--             if self.visible_asks[order.price] <= 0 then
--                 self.visible_asks[order.price] = nil
--             end
--         end
--     else
--         -- Удаляем из скрытых объемов
--         if order.type == "bid" then
--             self.hidden_bids[order.price] = (self.hidden_bids[order.price] or 0) - order.volume
--             if self.hidden_bids[order.price] <= 0 then
--                 self.hidden_bids[order.price] = nil
--             end
--         else
--             self.hidden_asks[order.price] = (self.hidden_asks[order.price] or 0) - order.volume
--             if self.hidden_asks[order.price] <= 0 then
--                 self.hidden_asks[order.price] = nil
--             end
--         end
--     end
    
--     return true
-- end

-- -- Получение полной картины стакана с учетом скрытых объемов
-- function HiddenOrderBook:get_full_depth(levels)
--     levels = levels or 10
    
--     local result = {
--         bids = {},
--         asks = {},
--         spread = 0,
--         total_bid_volume = 0,
--         total_ask_volume = 0,
--         hidden_bid_volume = 0,
--         hidden_ask_volume = 0
--     }
    
--     -- Собираем все уникальные цены
--     local all_prices = {}
--     for price in pairs(self.visible_bids) do all_prices[#all_prices + 1] = price end
--     for price in pairs(self.hidden_bids) do all_prices[#all_prices + 1] = price end
--     for price in pairs(self.visible_asks) do all_prices[#all_prices + 1] = price end
--     for price in pairs(self.hidden_asks) do all_prices[#all_prices + 1] = price end
    
--     -- Сортируем цены
--     table.sort(all_prices, function(a, b) return a > b end)
    
--     -- Формируем стакан
--     for _, price in ipairs(all_prices) do
--         local visible_bid = self.visible_bids[price] or 0
--         local hidden_bid = self.hidden_bids[price] or 0
--         local visible_ask = self.visible_asks[price] or 0
--         local hidden_ask = self.hidden_asks[price] or 0
        
--         local total_bid = visible_bid + hidden_bid
--         local total_ask = visible_ask + hidden_ask
        
--         if total_bid > 0 then
--             table.insert(result.bids, {
--                 price = price,
--                 visible_volume = visible_bid,
--                 hidden_volume = hidden_bid,
--                 total_volume = total_bid
--             })
--             result.total_bid_volume = result.total_bid_volume + total_bid
--             result.hidden_bid_volume = result.hidden_bid_volume + hidden_bid
--         end
        
--         if total_ask > 0 then
--             table.insert(result.asks, {
--                 price = price,
--                 visible_volume = visible_ask,
--                 hidden_volume = hidden_ask,
--                 total_volume = total_ask
--             })
--             result.total_ask_volume = result.total_ask_volume + total_ask
--             result.hidden_ask_volume = result.hidden_ask_volume + hidden_ask
--         end
--     end
    
--     -- Сортируем bids по убыванию, asks по возрастанию
--     table.sort(result.bids, function(a, b) return a.price > b.price end)
--     table.sort(result.asks, function(a, b) return a.price < b.price end)
    
--     -- Ограничиваем количество уровней
--     result.bids = {unpack(result.bids, 1, math.min(levels, #result.bids))}
--     result.asks = {unpack(result.asks, 1, math.min(levels, #result.asks))}
    
--     -- Вычисляем спред
--     if #result.bids > 0 and #result.asks > 0 then
--         result.spread = result.asks[1].price - result.bids[1].price
--     end
    
--     return result
-- end

-- -- Анализ скрытой ликвидности
-- function HiddenOrderBook:analyze_hidden_liquidity()
--     local analysis = {
--         hidden_bid_levels = 0,
--         hidden_ask_levels = 0,
--         max_hidden_bid = 0,
--         max_hidden_ask = 0,
--         avg_hidden_size = 0,
--         hidden_concentration = 0
--     }
    
--     local total_hidden = 0
--     local hidden_count = 0
    
--     for price, volume in pairs(self.hidden_bids) do
--         analysis.hidden_bid_levels = analysis.hidden_bid_levels + 1
--         analysis.max_hidden_bid = math.max(analysis.max_hidden_bid, volume)
--         total_hidden = total_hidden + volume
--         hidden_count = hidden_count + 1
--     end
    
--     for price, volume in pairs(self.hidden_asks) do
--         analysis.hidden_ask_levels = analysis.hidden_ask_levels + 1
--         analysis.max_hidden_ask = math.max(analysis.max_hidden_ask, volume)
--         total_hidden = total_hidden + volume
--         hidden_count = hidden_count + 1
--     end
    
--     if hidden_count > 0 then
--         analysis.avg_hidden_size = total_hidden / hidden_count
--         analysis.hidden_concentration = analysis.max_hidden_bid + analysis.max_hidden_ask
--     end
    
--     return analysis
-- end

-- -- Визуализация стакана
-- function HiddenOrderBook:print_depth(levels)
--     levels = levels or 5
--     local depth = self:get_full_depth(levels)
    
--     message("=== СТАКАН " .. self.class_code .. ":" .. self.sec_code .. " ===")
--     message("Спред: " .. string.format("%.2f", depth.spread))
--     message("Скрытые объемы: Bid=" .. depth.hidden_bid_volume .. " Ask=" .. depth.hidden_ask_volume)
--     message("")
--     message("=== ASKS ===")
    
--     for i = math.min(levels, #depth.asks), 1, -1 do
--         local ask = depth.asks[i]
--         local hidden_info = ask.hidden_volume > 0 and 
--             string.format("(+%d скр.)", ask.hidden_volume) or ""
--         message(string.format("%.2f | %6d %s", ask.price, ask.visible_volume, hidden_info))
--     end
    
--     message("---")
    
--     for i = 1, math.min(levels, #depth.bids) do
--         local bid = depth.bids[i]
--         local hidden_info = bid.hidden_volume > 0 and 
--             string.format("(+%d скр.)", bid.hidden_volume) or ""
--         message(string.format("%.2f | %6d %s", bid.price, bid.visible_volume, hidden_info))
--     end
    
--     message("=== BIDS ===")
-- end

-- -- Очистка старых данных
-- function HiddenOrderBook:cleanup_old_orders(max_age_seconds)
--     max_age_seconds = max_age_seconds or 3600 -- 1 час по умолчанию
--     local current_time = os.time()
--     local removed = 0
    
--     for order_id, order in pairs(self.order_history) do
--         if current_time - order.timestamp > max_age_seconds and order.status == "active" then
--             self:cancel_order(order_id)
--             removed = removed + 1
--         end
--     end
    
--     return removed
-- end

-- -- Глобальный объект стакана
-- local order_books = {}

-- -- Инициализация стакана для инструмента
-- function init_order_book(class_code, sec_code)
--     local key = class_code .. ":" .. sec_code
--     if not order_books[key] then
--         order_books[key] = HiddenOrderBook.new(class_code, sec_code)
--         message("Создан стакан для " .. key)
--     end
--     return order_books[key]
-- end

-- -- Команда для вывода текущего стакана
-- function show_order_book(class_code, sec_code)
--     local key = class_code .. ":" .. sec_code
--     if order_books[key] then
--         order_books[key]:print_depth(10)
--     else
--         message("Стакан для " .. key .. " не инициализирован")
--     end
-- end

-- -- Команда для анализа скрытой ликвидности
-- function analyze_hidden_liquidity(class_code, sec_code)
--     local key = class_code .. ":" .. sec_code
--     if order_books[key] then
--         local analysis = order_books[key]:analyze_hidden_liquidity()
--         message("Анализ скрытой ликвидности " .. key .. ":")
--         message("Уровней bid: " .. analysis.hidden_bid_levels)
--         message("Уровней ask: " .. analysis.hidden_ask_levels)
--         message("Макс. скрытый объем: " .. math.max(analysis.max_hidden_bid, analysis.max_hidden_ask))
--         message("Средний размер: " .. string.format("%.1f", analysis.avg_hidden_size))
--     end
-- end

-- -- Функция для ручного добавления заявки (для тестирования)
-- function add_test_order(class_code, sec_code, order_id, price, volume, order_type, is_hidden)
--     local book = init_order_book(class_code, sec_code)
--     book:add_order(order_id, price, volume, order_type, is_hidden)
--     message("Добавлена тестовая заявка: " .. order_id)
-- end

-- -- Функция для ручного исполнения заявки
-- function execute_test_order(class_code, sec_code, order_id, volume)
--     local book = init_order_book(class_code, sec_code)
--     if book:execute_order(order_id, volume) then
--         message("Исполнена заявка: " .. order_id .. ", объем: " .. volume)
--     else
--         message("Не удалось исполнить заявку: " .. order_id)
--     end
-- end

-- -- Функция для ручной отмены заявки
-- function cancel_test_order(class_code, sec_code, order_id)
--     local book = init_order_book(class_code, sec_code)
--     if book:cancel_order(order_id) then
--         message("Отменена заявка: " .. order_id)
--     else
--         message("Не удалось отменить заявку: " .. order_id)
--     end
-- end

-- -- Функция для очистки старых данных
-- function cleanup_old_orders(class_code, sec_code, hours)
--     local key = class_code .. ":" .. sec_code
--     if order_books[key] then
--         local removed = order_books[key]:cleanup_old_orders((hours or 1) * 3600)
--         message("Удалено старых заявок: " .. removed)
--     end
-- end

-- -- Демонстрация работы стакана
-- function demo_order_book()
--     local class_code, sec_code = "TQBR", "SBER"
    
--     -- Добавляем тестовые заявки
--     add_test_order(class_code, sec_code, 1001, 150.50, 100, "bid", false)
--     add_test_order(class_code, sec_code, 1002, 150.45, 50, "bid", true)  -- скрытая
--     add_test_order(class_code, sec_code, 1003, 150.60, 80, "ask", false)
--     add_test_order(class_code, sec_code, 1004, 150.65, 30, "ask", true)  -- скрытая
    
--     -- Показываем стакан
--     show_order_book(class_code, sec_code)
    
--     -- Анализируем скрытую ликвидность
--     analyze_hidden_liquidity(class_code, sec_code)
    
--     -- Исполняем часть заявки
--     execute_test_order(class_code, sec_code, 1001, 30)
    
--     -- Отменяем скрытую заявку
--     cancel_test_order(class_code, sec_code, 1002)
    
--     -- Снова показываем стакан
--     show_order_book(class_code, sec_code)
-- end

-- -- Запускаем демо при загрузке скрипта
-- message("Скрипт стакана цен загружен. Для демо запустите: demo_order_book()")
-- message("Доступные команды:")
-- message("  init_order_book(class, sec) - инициализировать стакан")
-- message("  show_order_book(class, sec) - показать стакан")
-- message("  add_test_order(class, sec, id, price, vol, type, hidden) - добавить заявку")
-- message("  execute_test_order(class, sec, id, vol) - исполнить заявку")
-- message("  cancel_test_order(class, sec, id) - отменить заявку")
-- message("  analyze_hidden_liquidity(class, sec) - анализ скрытой ликвидности")




-- local iceberg_suspicious = {}

-- function detect_possible_iceberg(class_code, sec_code)
--     local quote = getQuoteLevel2(class_code, sec_code)
--     if not quote or #quote.bid < 3 or #quote.offer < 3 then return end
    
--     -- Поиск одинаковых объемов на разных уровнях (признак айсберга)
--     for i = 1, math.min(3, #quote.bid) do
--         for j = i + 1, math.min(5, #quote.bid) do
--             if math.abs(quote.bid[i].quantity - quote.bid[j].quantity) < 10 then
--                 local key = "bid_" .. quote.bid[i].price .. "_" .. quote.bid[j].price
--                 iceberg_suspicious[key] = (iceberg_suspicious[key] or 0) + 1
                
--                 if iceberg_suspicious[key] > 3 then
--                     message("Возможный айсберг на покупку: " .. quote.bid[i].price)
--                 end
--             end
--         end
--     end
-- end



-- function calculate_order_book_imbalance(class_code, sec_code)
--     local quote = getQuoteLevel2(class_code, sec_code)
--     if not quote then return end
    
--     local total_bid = 0
--     local total_ask = 0
    
--     for i = 1, math.min(5, #quote.bid) do
--         total_bid = total_bid + quote.bid[i].quantity
--     end
    
--     for i = 1, math.min(5, #quote.offer) do
--         total_ask = total_ask + quote.offer[i].quantity
--     end
    
--     local imbalance = (total_bid - total_ask) / (total_bid + total_ask)
    
--     if math.abs(imbalance) > 0.7 then -- Сильный дисбаланс
--         message("Сильный дисбаланс стакана: " .. string.format("%.1f%%", imbalance * 100))
--     end
-- end


-- local prev_bids = {}
-- local prev_asks = {}

-- function OnQuote(class_code, sec_code)
--     local quote = getQuoteLevel2(class_code, sec_code)
    
--     if quote then
--         detect_hidden_activity(quote, prev_bids, prev_asks)
--         -- Сохраняем текущее состояние
--         prev_bids = deep_copy(quote.bid)
--         prev_asks = deep_copy(quote.offer)
--     end
    
--     return 1
-- end

-- function detect_hidden_activity(quote, prev_bids, prev_asks)
--     -- Внезапное исчезновение больших объемов
--     for i = 1, #prev_bids do
--         local found = false
--         for j = 1, #quote.bid do
--             if prev_bids[i].price == quote.bid[j].price then
--                 found = true
--                 if prev_bids[i].quantity > quote.bid[j].quantity + 5000 then
--                     message("Большой объем снят с покупки: " .. prev_bids[i].price)
--                 end
--                 break
--             end
--         end
--         if not found and prev_bids[i].quantity > 5000 then
--             message("Уровень покупки исчез: " .. prev_bids[i].price)
--         end
--     end
-- end

-- function OnTrade(class_code, sec_code)
--     local trade = getParamEx(class_code, sec_code, "LAST")
--     local volume = getParamEx(class_code, sec_code, "VOLUME")
    
--     if tonumber(volume.param_value) > 10000 then -- Крупная сделка
--         message("Крупная сделка: " .. volume.param_value .. " лотов по " .. trade.param_value)
--         log_large_trade(class_code, sec_code, trade.param_value, volume.param_value)
--     end
    
--     return 1
-- end

-- local last_volume = 0
-- local large_trades = {}

-- function OnQuote(class_code, sec_code)
--     local quote = getQuoteLevel2(class_code, sec_code)
    
--     if quote then
--         -- Анализ необычных объемов в стакане
--         analyze_hidden_liquidity_signals(quote)
--     end
    
--     return 1
-- end

-- function analyze_hidden_liquidity_signals(quote)
--     -- Внезапное появление больших объемов
--     for i = 1, #quote.bid do
--         if quote.bid[i].quantity > 10000 then -- Большой объем
--             message("Большой объем на покупку: " .. quote.bid[i].price)
--         end
--     end
    
--     for i = 1, #quote.offer do
--         if quote.offer[i].quantity > 10000 then -- Большой объем
--             message("Большой объем на продажу: " .. quote.offer[i].price)
--         end
--     end
-- end

-- function main()
--     analyze_hidden_liquidity()
--     sleep(5000)
-- end

function OnInit()
    MyQuote = {}
end
function main()

    local t_id = AllocTable()
    local l_id = AllocTable()
    
    AddColumn(t_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(t_id, 2, "Объем", true, QTABLE_INT_TYPE, 10)

    AddColumn(l_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(l_id, 2, "Объем", true, QTABLE_INT_TYPE, 10)
    
    local window_id = CreateWindow(t_id)
    local Level_Window = CreateWindow(l_id)

    SetWindowCaption(t_id, "Уровни")
    SetWindowPos(t_id, 100, 100, 350, 500)

    SetWindowCaption(l_id,"Уровни")
    SetWindowPos(l_id,50,50,300,800)

    local last_quote = nil
    local is_run = true
    
    while is_run do
        if IsWindowClosed(t_id) or IsWindowClosed(l_id) then
            is_run = false
            message("Завершение работы")
            break
        end
        
        local current_quote = getQuoteLevel2("QJSIM", "AFLT")
        
        if current_quote and (not last_quote or has_quote_changed(last_quote, current_quote)) then
            update_stakan_table(t_id, current_quote)
            Update_Level_Table(l_id,current_quote)
            last_quote = current_quote  
        end
        
        sleep(100)  
    end
    
    DestroyTable(t_id)
    return true
end

function has_quote_changed(old_quote, new_quote)
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
    local row = 1
    
--(ASK)
    if #quote.offer > 0 then
        for i = #quote.offer, 1, -1 do
            local level = quote.offer[i]
            if level then
                local sum = level.price * level.quantity
                InsertRow(t_id, -1)
                SetCell(t_id, row, 1, string.format("%.2f", level.price))
                SetCell(t_id, row, 2, tostring(level.quantity))
                
                for col = 1, 2 do
                    SetColor(t_id, row, col, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                end
                row = row + 1
            end
        end
    end
    
    --(BID)
    if #quote.bid > 0 then
        for i = #quote.bid, 1, -1 do
            local level = quote.bid[i]
            if level then
                local sum = level.price * level.quantity
                InsertRow(t_id, -1)
                SetCell(t_id, row, 1, string.format("%.2f", level.price))
                SetCell(t_id, row, 2, tostring(level.quantity))
                
                for col = 1, 2 do
                   SetColor(t_id, row, col, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
                end
                row = row + 1
            end
        end
    end
    
    return true
    
end

function Update_Level_Table(table_Id,current_quote)
        -- if #current_quote.bid + #current_quote.offer > #MyQuote then
        --     message("пиздец"..current_quote.bid[1].price)
        -- end
            --Обновляем биды
                 for i = 1, #current_quote.bid do
                    if current_quote.bid[i].price then
                        local isMatch = find_Element(MyQuote,current_quote.bid[i].price)
                        if  isMatch ~= nil then
                            MyQuote[isMatch][2] = current_quote.bid[i].quantity
                        else
                            AddOnQuoteValue(current_quote.bid[i].price,current_quote.bid[i].quantity)
                        end
                    end
                 end


            --Обновляем аски
                for i = 1, #current_quote.offer do
                    if current_quote.offer[i] then
                        local isMatchOffer = find_Element(MyQuote,current_quote.offer[i].price)
                        if  isMatchOffer ~= nil then
                            MyQuote[isMatchOffer][2] = current_quote.offer[i].quantity
                        else
                            AddOnQuoteValue(current_quote.offer[i].price,current_quote.offer[i].quantity)
                        end
                    end
                end
                
            Print_Values(table_Id,MyQuote,current_quote)
            
    end

    function find_Element(array,price)
        if #array ~= nil then
            for j = 1, #array do
            if array[j].Price == price then
                return j
            end
        end
        else
        return nil
        end     
        return nil
    end

    function AddOnQuoteValue(price,volume)
        local newValue = {
            Price = price,
            Volume = volume
        }
        table.insert(MyQuote,newValue)
    end

    function Print_Values(id,array,quote)

        Set_Filter(array,quote)

        table.sort(array, function (a,b)
            return a.Price < b.Price        
        end)
        -- if #array > 1 then
        --         for i = 1, #array do
        --             message(""..array[i].Price.." "..array[i].Volume)
        --         end
        -- end
        Clear(id)
        local row = 1
        for i = #array, 1, -1 do
            InsertRow(id, -1)
            SetCell(id, row, 1, tostring(array[i].Price))
            SetCell(id, row, 2, tostring(array[i].Volume))

            row = row + 1
        end
    end

    function Set_Filter(array,quote)
        --по дефолту удалить неиспользуемые Уровни
        local firstElement = quote.offer[#quote.offer].price
        local lastElement = quote.bid[1].price
        -- message("firstElement"..firstElement)
        -- message("lastElement"..lastElement)
        -- message("firstArray"..array[1].Price)
            for i = 1, #array do
                if array[i].Price < firstElement and array[i].Price > lastElement then
                    local deleteFlag = true
                     for j = 1, #quote.offer  do
                        if array[i].Price == quote.offer[j].price then
                         deleteFlag = false
                        --  message("false offer"..array[i].Price)
                        end
                    end
                     for j = 1, #quote.bid  do
                        if array[i].Price == quote.bid[j].price then
                         deleteFlag = false
                        --  message("false bid"..array[i].Price)
                        end
                    end

                     if deleteFlag == true then
                        local deletePos = table.remove(array,i)
                        message("deletePrice"..tostring(deletePos.Price))

                        for k =1, #array do
                            message(''..array[k].Price)
                        end
                        break
                    end
                end
            end
        end  
