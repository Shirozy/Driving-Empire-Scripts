## Open Car Dealership
```lua
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Location"):FireServer("Enter", "Cars")
```

## Sell Car
```lua
local carToSell = "Audi-S2-1990"
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellCar"):FireServer(carToSell)
```

## Buy Car
This remote takes 4 args, car name, followed by colors
```lua
local args = {
    [1] = {
        [1] = "Audi-S2-1990",
        [2] = Color3.new(1, 1, 1), -- Body Color
        [3] = Color3.new(1, 1, 1), -- idk interier maybe?
        [4] = Color3.new(1,1,1) -- Rims Color
    }
}

game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Purchase"):InvokeServer(unpack(args))

```

## Watch Advertisement
```lua
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Claim2DBudgetedAdReward"):FireServer()
```
