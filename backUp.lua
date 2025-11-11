
function OnInit()
    MyQuote = {}
end
function main()

    local t_id = AllocTable()
    local l_id = AllocTable()
    
    AddColumn(t_id, 1, "����", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(t_id, 2, "�����", true, QTABLE_INT_TYPE, 10)

    AddColumn(l_id, 1, "����", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(l_id, 2, "�����", true, QTABLE_INT_TYPE, 10)
    AddColumn(l_id, 3, "�����������", true, QTABLE_STRING_TYPE,30)
    
    local window_id = CreateWindow(t_id)
    local Level_Window = CreateWindow(l_id)

    SetWindowCaption(t_id, "������")
    SetWindowPos(t_id, 100, 100, 350, 500)

    SetWindowCaption(l_id,"������")
    SetWindowPos(l_id,50,50,350,800)

    local last_quote = nil
    local is_run = true
    
    while is_run do
        if IsWindowClosed(t_id) or IsWindowClosed(l_id) then
            is_run = false
            message("���������� ������")
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
        --     message("������"..current_quote.bid[1].price)
        -- end
            --��������� ����
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


            --��������� ����
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
            SetStyle(quote, id, row, array[i].Price, array[i].Volume)
            SetCell(id, row, 3, CreateProgressBar(array[i].Volume,GetMaxVolume(quote),20))
            SetLevel2Color(quote,id,row,array[i].Price)
            row = row + 1
        end
    end

    function Set_Filter(array,quote)
        --�� ������� ������� �������������� ������
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
                        -- message("deletePrice"..tostring(deletePos.Price))

                        -- for k =1, #array do
                        --     message(''..array[k].Price)
                        -- end
                        break
                    end
                end
            end
        end  
----------------------------------------------------------------------------------------------
        function SetStyle(level2, tableId, row, price, volume)
            local bestBid = level2.bid[#level2.bid].price
            local bestAsk = level2.offer[1].price

            --�������� �=������ Bid
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

        function CreateProgressBar(value,max_value, width)
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