

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
            direction = bit.band(flags, 2) ~= 0 and "BUY" or 
                       bit.band(flags, 1) ~= 0 and "SELL" or "UNKNOWN",
            is_market = bit.band(flags, 4) ~= 0,
            is_negotiated = bit.band(flags, 8) ~= 0,
            is_multi = bit.band(flags, 16) ~= 0,
            is_canceled = bit.band(flags, 32) ~= 0,
            type_description = "",
            short_type = "",
            iceberg_suspicion = "NO" -- Подозрение на айсберг: NO, LOW, MEDIUM, HIGH
        }
        
        -- Проверка на айсберг
        if not trade_info.is_canceled then
            trade_info.iceberg_suspicion = checkIcebergSuspicion(trade_info)
        end
        
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
            if trade_info.iceberg_suspicion ~= "NO" then 
                table.insert(parts, "ICEBERG_"..trade_info.iceberg_suspicion)
            end
            
            trade_info.type_description = table.concat(parts, " ")
            trade_info.short_type = string.sub(trade_info.direction, 1, 1) .. 
                                   (trade_info.is_market and "M" or "L") ..
                                   (trade_info.iceberg_suspicion ~= "NO" and "I" or "")
        end
        
        table.insert(filtered_trades, trade_info)

         if #filtered_trades % 5 == 0 or os.time() - last_iceberg_analysis >= 30 then
            analyzeIcebergPatterns()
        end
        
        -- message(string.format("AFLT: %s - %.2f x %d [%s] Iceberg: %s", 
        --        time_str, trade_info.price, trade_info.volume, 
        --        trade_info.type_description, trade_info.iceberg_suspicion))
        
    end
end

