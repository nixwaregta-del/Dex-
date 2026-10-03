--[[
	Search History Module
	
	Tracks recent explorer searches for quick navigation.
	Provides quick access to previous search queries.
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	ModelViewer = Apps.ModelViewer
	Notebook = Apps.Notebook
end

local function main()
	local SearchHistory = {}
	local history = {}
	local maxHistory = 100
	local window, listFrame

	SearchHistory.AddSearch = function(query)
		if not query or query == "" then return end
		
		-- Remove duplicate
		for i, entry in ipairs(history) do
			if entry == query then
				table.remove(history, i)
				break
			end
		end
		
		-- Add to end
		table.insert(history, query)
		
		-- Trim
		while #history > maxHistory do
			table.remove(history, 1)
		end
		
		SearchHistory.RefreshList()
	end

	SearchHistory.GetHistory = function()
		return history
	end

	SearchHistory.ClearHistory = function()
		table.clear(history)
		SearchHistory.RefreshList()
	end

	SearchHistory.RefreshList = function()
		if not listFrame then return end
		
		for _, child in pairs(listFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		local yOffset = 0
		for i, query in ipairs(history) do
			local entry = Instance.new("TextButton")
			entry.Size = UDim2.new(1, 0, 0, 20)
			entry.Position = UDim2.new(0, 0, 0, yOffset)
			entry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			entry.BorderSizePixel = 0
			entry.Text = "  " .. query
			entry.TextColor3 = Color3.new(1, 1, 1)
			entry.TextXAlignment = Enum.TextXAlignment.Left
			entry.TextSize = 13
			entry.Font = Enum.Font.SourceSans
			entry.Parent = listFrame
			
			entry.MouseButton1Click:Connect(function()
				if Explorer.SearchBox then
					Explorer.SearchBox.Text = query
					Explorer.PerformSearch(query)
				end
			end)
			
			entry.MouseButton2Click:Connect(function()
				table.remove(history, i)
				SearchHistory.RefreshList()
			end)
			
			yOffset = yOffset + 20
		end
		
		listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end

	SearchHistory.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Search History")
		window:Resize(250, 300)
		SearchHistory.Window = window

		-- Clear button
		local clearBtn = Instance.new("TextButton")
		clearBtn.Size = UDim2.new(1, 0, 0, 25)
		clearBtn.Position = UDim2.new(0, 0, 0, 0)
		clearBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		clearBtn.BorderSizePixel = 0
		clearBtn.Text = "Clear History"
		clearBtn.TextColor3 = Color3.new(1, 1, 1)
		clearBtn.TextSize = 13
		clearBtn.Font = Enum.Font.SourceSans
		clearBtn.Parent = window.GuiElems.Content
		
		clearBtn.MouseButton1Click:Connect(function()
			SearchHistory.ClearHistory()
		end)

		-- List frame
		listFrame = Instance.new("ScrollingFrame")
		listFrame.Size = UDim2.new(1, 0, 1, -30)
		listFrame.Position = UDim2.new(0, 0, 0, 25)
		listFrame.BackgroundTransparency = 1
		listFrame.BorderSizePixel = 0
		listFrame.ScrollBarThickness = 12
		listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		listFrame.Parent = window.GuiElems.Content

		-- Hint
		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.new(1, 0, 0, 20)
		hint.Position = UDim2.new(0, 0, 1, -20)
		hint.BackgroundTransparency = 1
		hint.Text = "Left-click: Search | Right-click: Remove"
		hint.TextColor3 = Color3.fromRGB(150, 150, 150)
		hint.TextSize = 11
		hint.Font = Enum.Font.SourceSans
		hint.Parent = window.GuiElems.Content
	end

	return SearchHistory
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
