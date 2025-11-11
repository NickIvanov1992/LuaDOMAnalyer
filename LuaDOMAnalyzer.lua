dofile(getScriptPath().."\\LevelViewer.lua")
dofile(getScriptPath().."\\IcebergViewer.lua")

function OnInit()
    MyQuote = {}
    IcebergArray = {}
end
function main()

    local is_run = true

    while is_run do
        CreateLevel2("QJSIM","AFLT")
        FindIceberg()

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
        

        