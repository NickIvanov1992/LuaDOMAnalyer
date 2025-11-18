    
dofile(getScriptPath().."\\global.lua")
    
function CreateLevel2(class, ticker)
    
    local current_quote = getQuoteLevel2(class, ticker)

    if current_quote and (not last_quote or has_quote_changed(last_quote, current_quote)) then
            Update_Level_Table(l_id,current_quote)
            last_quote = current_quote  
        end
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

function Update_Level_Table(table_Id,current_quote)
                 for i = 1, #current_quote.bid do
                    if current_quote.bid[i].price then
                        local isMatch = find_Element(MyQuote,current_quote.bid[i].price)
                        if  isMatch ~= nil then
                            MyQuote[isMatch].Volume = current_quote.bid[i].quantity
                        else
                            AddOnQuoteValue(current_quote.bid[i].price,current_quote.bid[i].quantity)
                        end
                    end
                 end


                for i = 1, #current_quote.offer do
                    if current_quote.offer[i] then
                        local isMatchOffer = find_Element(MyQuote,current_quote.offer[i].price)
                        if  isMatchOffer ~= nil then
                            MyQuote[isMatchOffer].Volume = current_quote.offer[i].quantity
                        else
                            AddOnQuoteValue(current_quote.offer[i].price,current_quote.offer[i].quantity)
                        end
                    end
                end
                
            Print_Values(table_Id,MyQuote,current_quote)
            PrintValues()
    end

    function find_Element(array,price)
        if array == nil or #array == 0 then
        return nil
    end
    
    for j = 1, #array do
        if math.abs(array[j].Price - price) < 0.0001 then
            return j
        end
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
        if #array == 0 then
        Clear(id)
        return
        end

        Set_Filter(array,quote)

        table.sort(array, function (a,b)
            return a.Price < b.Price        
        end)

        Clear(id)
        local row = 1
        for i = #array, 1, -1 do
            InsertRow(id, -1)
            SetCell(id, row, 1, tostring(array[i].Price))
            SetCell(id, row, 2, tostring(array[i].Volume))
            SetStyle(quote, id, row, array[i].Price, array[i].Volume)
            SetCell(id, row, 3, CreateHistogram(array[i].Volume,GetMaxVolume(quote),20))
            SetLevel2Color(quote,id,row,array[i].Price)
            row = row + 1
        end
    end

    function Set_Filter(array, quote)
    if #quote.bid == 0 or #quote.offer == 0 then
        return
    end
    
    -- Получаем худшие цены (самые низкие у бидов и самые высокие у асков)
    local worstBid = quote.bid[1].price  -- самый низкий бид
    local worstAsk = quote.offer[#quote.offer].price         -- самый высокий аск
    
    -- Создаем нормализованный набор текущих цен
    local currentPrices = {}
    for j = 1, #quote.bid do
        local normalizedPrice = math.floor(quote.bid[j].price * 10000 + 0.5) / 10000
        currentPrices[normalizedPrice] = true
    end
    for j = 1, #quote.offer do
        local normalizedPrice = math.floor(quote.offer[j].price * 10000 + 0.5) / 10000
        currentPrices[normalizedPrice] = true
    end
    
    -- Удаляем уровни, которые находятся между worstBid и worstAsk, но отсутствуют в текущих котировках
    local i = #array
    while i >= 1 do
        local price = array[i].Price
        local normalizedPrice = math.floor(price * 10000 + 0.5) / 10000
        
        -- Если цена находится между худшим бидом и аском И отсутствует в текущих котировках
        if price >= worstBid and price <= worstAsk then
            if not currentPrices[normalizedPrice] then
                table.remove(array, i)
            end
        end
        
        i = i - 1
    end
end

function SetStyle(level2, tableId, row, price, volume)
            local bestBid = level2.bid[#level2.bid].price
            local bestAsk = level2.offer[1].price

            --???????? ?=?????? Bid
            if price == bestBid then
               SetColor(tableId, row, 1, RGB(60, 200, 60), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
               SetColor(tableId, row, 2, RGB(60, 200, 60), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
               SetColor(tableId, row, 3, RGB(60, 200, 60), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
            elseif price == bestAsk then
                SetColor(tableId, row, 1, RGB(200, 50, 50), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                SetColor(tableId, row, 2, RGB(200, 50, 50), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                SetColor(tableId, row, 3, RGB(200, 50, 50), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                -- SetCell(tableId, row, 3, CreateProgressBar(20,100,10))
            end

        end

        function CreateHistogram(value,max_value, width)
            local percent = value / max_value
            local filled = math.floor(percent * width)
            local empty = width - filled
            local bar = ""..string.rep("#", filled)..string.rep(" ", empty)..""

            return bar
        end

        function GetMaxVolume(myQuote)
            local maxValue = 0
            if #myQuote.bid > 0 then
                for e = 1, #myQuote.bid do
                    maxValue = math.max(maxValue,tonumber(myQuote.bid[e].quantity))
                end
            end

            if #myQuote.offer > 0 then
                for e = 1, #myQuote.offer do
                    maxValue = math.max(maxValue,tonumber(myQuote.offer[e].quantity))
                end
            end
            return maxValue
        end

        function SetLevel2Color(level2,tableId,row,price)
            if price < level2.bid[#level2.bid].price then
                SetColor(tableId, row, 1, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
                SetColor(tableId, row, 2, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
                SetColor(tableId, row, 3, RGB(150, 255, 150), RGB(40, 40, 40), RGB(150, 255, 150), RGB(40, 40, 40))
            elseif price > level2.offer[1].price then
                SetColor(tableId, row, 1, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                SetColor(tableId, row, 2, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
                SetColor(tableId, row, 3, RGB(255, 150, 150), RGB(40, 40, 40), RGB(255, 150, 150), RGB(40, 40, 40))
            end
        end