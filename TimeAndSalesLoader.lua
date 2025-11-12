-- function UploadTimeAndSales(class, ticker)

--     local all_trades = getClassInfo(class).all_trades
--     local trades = GetAllTrades(all_trades)
    

--     for i = 1, #trades do
--         local trade = trades[i]
--             if trade.sec_code == ticker then
--                 local trade_data = {
--                 -- Основные данные
--                 trade_id = trade.trade_id,
--                 datetime = trade.datetime,
--                 price = trade.price,
--                 quantity = trade.quantity,
                
--                 -- Дополнительная информация
--                 timestamp = os.time(trade.datetime),
--                 value = trade.price * trade.quantity,
                
--                 -- Анализ флагов
--                 is_buy = bit.band(trade.flags, 0x1) ~= 0,  -- Покупка
--                 is_sell = bit.band(trade.flags, 0x2) ~= 0, -- Продажа
--                 is_market = bit.band(trade.flags, 0x4) ~= 0 -- Рыночная сделка
--             }
            
--             table.insert(CurrentTimeAndSales, trade_data)
--             end
--         end
--  -- Сортировка по времени (если нужно)
--     table.sort(CurrentTimeAndSales, function(a, b) 
--         return a.timestamp < b.timestamp 
--     end)
    
--     return CurrentTimeAndSales
       
-- end
filtered_trades = {}

function OnAllTrade(alltrade)
    if alltrade.sec_code == "AFLT" and alltrade.class_code == "QJSIM" then
        local dt = alltrade.datetime
        local time_str = string.format("%02d:%02d:%02d", dt.hour, dt.min, dt.sec)
        
        -- Расшифровка флагов сделки
        local flags = alltrade.flags or 0
        local trade_info = {
            time = time_str,
            price = alltrade.price,
            volume = alltrade.qty,
            total_value = alltrade.price * alltrade.qty,
            trade_id = alltrade.trade_num,
            flags = flags,
            
            -- Основной тип сделки
            direction = bit.band(flags, 1) ~= 0 and "BUY" or 
                       bit.band(flags, 2) ~= 0 and "SELL" or "UNKNOWN",
            
            -- Детализация
            is_market = bit.band(flags, 4) ~= 0,      -- Рыночная заявка
            is_negotiated = bit.band(flags, 8) ~= 0,  -- Переговорная сделка
            is_multi = bit.band(flags, 16) ~= 0,      -- Многолотовая сделка
            is_canceled = bit.band(flags, 32) ~= 0,   -- Отмененная сделка
            
            -- Производные поля для удобства
            type_description = "",
            short_type = ""
        }
        
        -- Формируем текстовое описание
        if trade_info.is_canceled then
            trade_info.type_description = "CANCELED"
            trade_info.short_type = "C"
        else
            local parts = {}
            table.insert(parts, trade_info.direction)
            if trade_info.is_market then table.insert(parts, "MARKET") end
            if trade_info.is_negotiated then table.insert(parts, "NEGOTIATED") end
            if trade_info.is_multi then table.insert(parts, "MULTI") end
            
            trade_info.type_description = table.concat(parts, " ")
            trade_info.short_type = string.sub(trade_info.direction, 1, 1) .. 
                                   (trade_info.is_market and "M" or "L")
        end
        
        table.insert(filtered_trades, trade_info)
        
        message(string.format("AFLT: %s - %.2f x %d [%s]", 
               time_str, trade_info.price, trade_info.volume, 
               trade_info.type_description))
    end
end

function get_trades_array()
    return filtered_trades
end
