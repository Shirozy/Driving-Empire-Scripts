local vehicleSaveIDs = require(game:GetService("ReplicatedStorage").Modules.DB.VehicleSaveIDs)

    for carName, _ in pairs(vehicleSaveIDs.ids) do
        local args = {
        [1] = {
            [1] = tostring(carName),
            [2] = Color3.new(1, 1, 1),
            [3] = Color3.new(1, 1, 1),
            [4] = Color3.new(1,1,1)
        }
    }

    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Purchase"):InvokeServer(unpack(args))

    task.wait(0.01)

end
