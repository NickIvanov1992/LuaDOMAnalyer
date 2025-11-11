function FindIceberg ()
    if IcebergArray == nil or #IcebergArray == 0 then
        Initial()
        message(tostring(#IcebergArray))
    end
    PrintValues()
end

function Initial()
    if #MyQuote == 0 then
        message("Пустой стакан")
        return
    end
    for i = #MyQuote, 1, -1 do
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
        -- Clear(id)
        return
    end

    table.sort(IcebergArray, function (a,b)
            return a.Price < b.Price        
        end)
    
    local row = 1
        for i = #IcebergArray, 1, -1 do
            InsertRow(iceberg_id, -1)
            SetCell(iceberg_id, row, 1, tostring(IcebergArray[i].Price))
            SetCell(iceberg_id, row, 2, tostring(IcebergArray[i].Type))
            SetCell(iceberg_id, row, 3, tostring(IcebergArray[i].Volume))
            row = row + 1
        end
end