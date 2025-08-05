--<BODY
message("BODY",2)
message("Launch script")
--BODY>

function main()
    message("Launch Main()",2)
    while isConnected() == 1 do
        number_of_trades = getNumberOf("trades")
        message("Общее кол-во сделок:" .. number_of_trades)
        sleep(60000)
    end
end

--<BODY
message("тоже body",2)
--BODY>