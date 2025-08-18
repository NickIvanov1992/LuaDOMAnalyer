
-- name_bot = "Сеточный бот" --имя робота
-- version = "1.0" 
-- ticker = "SBER"
-- class ="no_class"
-- Name = "Сеточный робот" -- имя


-- function Color(color,id,line,column)
--     If not column then column = QTABLE_NO_INDEX end --Окрасить строку если индекс не указан
--     if color == "Голубой" then SetColor(id, line, column, RGB(173,216,230), RGB(0,0,0), RGB(173,216,230),RGB(0,0,0)) end
--     if color == "Белый-Красный" then SetColor(id, line, column, RGB(255,255,255), RGB(217,20,29), RGB(255,255,255),RGB(217,20,29)) end
--     if color == "Желтый" then SetColor(id, line, column, RGB(255,255,0), RGB(0,0,0), RGB(255,255,0),RGB(0,0,0)) end
--     if color == "Серый" then SetColor(id, line, column, RGB(230,230,230), RGB(0,0,0), RGB(230,230,230),RGB(0,0,0)) end
--     if color == "Синий" then SetColor(id, line, column, RGB(44,112,188), RGB(255,255,255), RGB(44,112,188),RGB(255,255,255)) end
--     if color == "Оранжевый" then SetColor(id, line, column, RGB(255,165,0), RGB(0,0,0), RGB(255,165,0),RGB(0,0,0)) end
--     if color == "Зеленый" then SetColor(id, line, column, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128),RGB(0,0,0)) end
--     if color == "Красный" then SetColor(id, line, column, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164),RGB(0,0,0)) end
    
-- end

-- function CreateTable()
--     t_id = AllocTable() -- Получить доступный id для создания
--     --Добавить колонки
--     AddColumn(t_id,1,name_bot,true,QTABLE_INT_TYPE,17)
--     AddColumn(t_id,2,ticker,true,QTABLE_INT_TYPE,15)
--     AddColumn(t_id,3,version,true,QTABLE_INT_TYPE,5)

--     CreateWindow(t_id) --Создать таблицу
--     SetWindowCaption(t_id,Name) --Установить заголовок

--     SetWindowPos(t_id,0,0,290,220) --Задатьб положение таблицы и размеры окна

--     for m=1, 9 do
--     InsertRow(t_id,-1)
--     end

--     --Строка1
--     SetCell(t_id,1,1, tostring("Старт"));Color("Голубой",t_id,1,1)
--     SetCell(t_id,1,2, tostring("не работает"));Color("Белый-Красный",t_id,1,2)
    
--     --Строка2
--     SetCell(t_id,2,1, tostring("Цена"));Color("Желтый",t_id,2,1)
--     Color("Желтый",t_id,2,1); Color("Желтый",t_id,2,3);

--     --Строка3
--     SetCell(t_id,3,1, tostring("Позиция"));Color("Серый",t_id,3,1)
--     Color("Серый",t_id,3,2); 
--     SetCell(t_id,3,3, tostring("- "));Color("Серый",t_id,3,3);

--     --Строка4
    
    
-- end



--Обработка событий РМ QUIK в функции main() посредством очереди FIFO
--с выделением приоритета OnTrade и фильтрации OnQuote
function main()
    quotelvl = getQuoteLevel2("QJSIM","SBER")
    if quotelvl then
        if quotelvl.offer then
            offer = tonumber(quotelvl.offer[1].price)
            quant = tonumber(quotelvl.offer[1].quantity)

            message("Best offer price: " ..offer)
            message("Current price volume: " ..quant)
            message("Count offers: " ..quotelvl.offer_count)
        else
            message("No data offers")
        end
        if quotelvl.bid then
            bid = tonumber(quotelvl.bid[tonumber(quotelvl.bid_count)].price)
            quant = tonumber(quotelvl.bid[tonumber(quotelvl.bid_count)].quantity)

            message("Best BID price: "..bid)
            message("Curent price count: "..quant)
            message("BID count: "..quotelvl.bid_count)
        else
            message("No BID data")
        end
    end
end