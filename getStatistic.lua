statistic_id = AllocTable()

AddColumn(statistic_id, 1, "Время", true, QTABLE_DATETIME_TYPE, 20)
AddColumn(statistic_id, 2, "Лучший аск", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 3, "Лучший Бид", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 4, "1 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 5, "1 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 6, "2 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 7, "2 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 8, "3 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 9, "3 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 10, "4 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 11, "4 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 12, "5 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 13, "5 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 14, "6 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 15, "6 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 16, "7 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 17, "7 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 18, "8 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 19, "8 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 20, "9 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 21, "9 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 22, "10 sell price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 23, "10 sell vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 24, "1 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 25, "1 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 26, "2 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 27, "2 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 28, "3 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 29, "3 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 30, "4 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 31, "4 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 32, "5 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 33, "5 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 34, "6 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 35, "6 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 36, "7 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 37, "7 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 38, "8 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 39, "8 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 40, "9 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 41, "9 buy vol", true, QTABLE_INT_TYPE, 10)
AddColumn(statistic_id, 42, "10 buy price", true, QTABLE_DOUBLE_TYPE, 10)
AddColumn(statistic_id, 43, "10 buy vol", true, QTABLE_INT_TYPE, 10)

local Statistic_Window = CreateWindow(statistic_id)
SetWindowCaption(statistic_id,"Статистика")
SetWindowPos(statistic_id,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20)

function UpdateStatistic()
    local data = {
        time = os.time(),
        bestAsk = orderbook_data.asks[1].price,
        bestBid = orderbook_data.bids[1].price,
        sell1Price = getIcebergSellPrice(1),
        sell1Vol = getIcebergSellVol(1),
        sell2Price = getIcebergSellPrice(2),
        sell2Vol = getIcebergSellVol(2),
        sell3Price = getIcebergSellPrice(3),
        sell3Vol = getIcebergSellVol(3),
        sell4Price = getIcebergSellPrice(4),
        sell4Vol = getIcebergSellVol(4),
        sell5Price = getIcebergSellPrice(5),
        sell5Vol = getIcebergSellVol(5),
        sell6Price = getIcebergSellPrice(6),
        sell6Vol = getIcebergSellVol(6),
        sell7Price = getIcebergSellPrice(7),
        sell7Vol = getIcebergSellVol(7),
        sell8Price = getIcebergSellPrice(8),
        sell8Vol = getIcebergSellVol(8),
        sell9Price = getIcebergSellPrice(9),
        sell9Vol = getIcebergSellVol(9),
        sell10Price = getIcebergSellPrice(10),
        sell10Vol = getIcebergSellVol(10),
        buy1Price = getIcebergBuyPrice(1),
        buy1Vol = getIcebergBuyVol(1),
        buy2Price = getIcebergBuyPrice(2),
        buy2Vol = getIcebergBuyVol(2),
        buy3Price = getIcebergBuyPrice(3),
        buy3Vol = getIcebergBuyVol(3),
        buy4Price = getIcebergBuyPrice(4),
        buy4Vol = getIcebergBuyVol(4),
        buy5Price = getIcebergBuyPrice(5),
        buy5Vol = getIcebergBuyVol(5),
        buy6Price = getIcebergBuyPrice(6),
        buy6Vol = getIcebergBuyVol(6),
        buy7Price = getIcebergBuyPrice(7),
        buy7Vol = getIcebergBuyVol(7),
        buy8Price = getIcebergBuyPrice(8),
        buy8Vol = getIcebergBuyVol(8),
        buy9Price = getIcebergBuyPrice(9),
        buy9Vol = getIcebergBuyVol(9),
        buy10Price = getIcebergBuyPrice(10),
        buy10Vol = getIcebergBuyVol(10)
    }
end

local sellarr = {}
local buyarr = {}
local sellvol = {}
local buyvol = {}

function getIcebergSellPrice(position)
    local cPrice = 0
    if (#sellarr == 0) then
    for i = 1,  #IcebergArray do
        if (IcebergArray[i].Type == "SELL") then
            table.insert(sellarr,IcebergArray[i].price)
        end
    end
    table.sort(sellarr, function(a, b)
        return tonumber(a.Price) > tonumber(b.Price)
    end)
    if(#sellarr >= position) then
        cPrice = sellarr[position]
    else
        cPrice = 0
    end
else
    cPrice = sellarr[position]
end
    message(tonumber(sellarr[position]))
    if(position == 10) then
        sellarr = {}
    end

    return cPrice
end

function getIcebergBuyPrice(position)
    local cPrice = 0
    if (#buyarr == 0) then
    for i = 1,  #IcebergArray do
        if (IcebergArray[i].Type == "BUY") then
            table.insert(buyarr,IcebergArray[i].price)
        end
    end
    table.sort(buyarr, function(a, b)
        return tonumber(a.Price) > tonumber(b.Price)
    end)
    if(#buyarr >= position) then
        cPrice = buyarr[position]
    else
        cPrice = 0
    end
else
    cPrice = buyarr[position]
end
    if(position == 10) then
        buyarr = {}
    end

    return cPrice
end

function getIcebergSellVol(position)
    local cVol = 0
    if(#sellvol == 0) then
        for i = 1, #IcebergArray do
            if (IcebergArray[i].Type == "SELL") then
            table.insert(sellarr,IcebergArray[i].price)
        end
        end
    end
end

function getIcebergBuyVol(position)
    
end