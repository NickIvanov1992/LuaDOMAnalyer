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
        Volume = 0
        }
           table.insert(IcebergArray,defaultTable)
    end

end

function PrintValues()
     if #IcebergArray == 0 then
         Clear(iceberg_id)
        return
    end

    table.sort(IcebergArray, function (a,b)
            return a.Price < b.Price        
        end)
    
    
    message(#IcebergArray)
        for i = #IcebergArray, 1, -1 do
            InsertRow(iceberg_id, -1)
            SetCell(iceberg_id, i, 1, tostring(IcebergArray[i].Price))
            SetCell(iceberg_id, i, 2, tostring(IcebergArray[i].Type))
            SetCell(iceberg_id, i, 3, tostring(IcebergArray[i].Volume))
        end
end