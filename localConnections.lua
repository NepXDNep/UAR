local localConnections = {}
localConnections.__index = localConnections

function localConnections.new()
    local connection = {}
    connection.__stack = {}

    function connection:Connect(onFire: function)
        local index = #connection+1
        connection.__stack[index] = {}

        local activeConnection = connection.__stack[index]
        activeConnection.Function = onFire
        activeConnection.Disabled = false

        function activeConnection:Disconnect()
            activeConnection = nil
            return
        end

        return activeConnection
    end

    function connection:Fire(...)
        table.foreach(connection.__stack, function(_,activeConnection)
            if not activeConnection.Disabled then activeConnection.Function(...) end
        end)
    end

    function connection:GetConnections()
        return connection.__stack
    end

    return connection
end

return localConnections