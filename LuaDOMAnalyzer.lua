dofile(getScriptPath().."\\LevelViewer.lua")

function OnInit()

end
function main()

    local is_run = true
    
    while is_run do



        --������� ������
        CreateLevel2("QJSIM","AFLT")
        message ('����� ���'..#MyQuote.bid)


        if IsWindowClosed(t_id) or IsWindowClosed(l_id) then
            is_run = false
            message("���������� ������")
            break




        end
        
        sleep(100)  
    end
    
    DestroyTable(t_id)
    return true
end