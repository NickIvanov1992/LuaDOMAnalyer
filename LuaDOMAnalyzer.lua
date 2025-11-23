dofile(getScriptPath().."\\LevelViewer.lua")
dofile(getScriptPath().."\\IcebergViewer.lua")
dofile(getScriptPath().."\\TimeAndSalesLoader.lua")
dofile(getScriptPath().."\\getStatistic.lua")

filtered_trades = filtered_trades or {}
orderbook_data = orderbook_data or {bids = {}, asks = {}}
orderbook_history = orderbook_history or {}

function OnInit()
    MyQuote = {}
    IcebergArray = IcebergArray or {}
    CurrentTimeAndSales = {}
end
function main()

    local is_run = true
    message("Начало работы")
    
    while is_run do
        CreateLevel2("QJSIM","AFLT")
        safe_AnalyzeIcebergPatterns()
        InitSpoofingTable()

        if(#IcebergArray == 0) then
            FindIceberg()
        end
        

        
        if  IsWindowClosed(l_id) then
            is_run = false
            message("Завершение работы")
            break
        end
        sleep(100)  
    end
    
    DestroyTable(l_id)
    return true
end







    

    
----------------------------------------------------------------------------------------------
        

        