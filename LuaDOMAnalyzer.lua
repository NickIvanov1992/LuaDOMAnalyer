dofile(getScriptPath().."\\LevelViewer.lua")

function OnInit()

end
function main()

    local is_run = true
    
    while is_run do



        --Создаем уровни
        CreateLevel2("QJSIM","AFLT")
        message ('Обьем цен'..#MyQuote.bid)


        if IsWindowClosed(t_id) or IsWindowClosed(l_id) then
            is_run = false
            message("Завершение работы")
            break




        end
        
        sleep(100)  
    end
    
    DestroyTable(t_id)
    return true
end