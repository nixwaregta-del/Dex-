--[[
	Favorites Module
	
	Save and quickly access frequently used instances.
	Bookmark objects for fast navigation.
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
	local Favorites = {}
	local window, listFrame, searchBox
	local favorites = {}
	local maxFavorites = 50

	Favorites.AddFavorite = function(obj)
		if not obj or not obj:IsDescendantOf(game) then return end
		
		-- Check if already favorited
		for i, fav in ipairs(favorites) do
			if fav == obj then return end
		end
		
		table.insert(favorites, obj)
		
		-- Trim if over limit
		while #favorites > maxFavorites do
			table.remove(favorites, 1)
		end
		
		Favorites.RefreshList()
	end

	Favorites.RemoveFavorite = function(obj)
		for i, fav in ipairs(favorites) do
			if fav == obj then
				table.remove(favorites, i)
				Favorites.RefreshList()
				return
			end
		end
	end

	Favorites.IsFavorite = function(obj)
		for i, fav in ipairs(favorites) do
			if fav == obj then return true end
		end
		return false
	end

	Favorites.GetFavorites = function()
		return favorites
	end

	Favorites.RefreshList = function()
		if not listFrame then return end
		
		-- Clear existing entries
		for _, child in pairs(listFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		-- Create entries for valid favorites
		local yOffset = 0
		for i, obj in ipairs(favorites) do
			if obj and obj:IsDescendantOf(game) then
				local entry = Instance.new("TextButton")
				entry.Size = UDim2.new(1, 0, 0, 20)
				entry.Position = UDim2.new(0, 0, 0, yOffset)
				entry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				entry.BorderSizePixel = 0
				entry.Text = "  " .. obj.ClassName .. ": " .. obj.Name
				entry.TextColor3 = Color3.new(1, 1, 1)
				entry.TextXAlignment = Enum.TextXAlignment.Left
				entry.TextSize = 13
				entry.Font = Enum.Font.SourceSans
				entry.Parent = listFrame
				
				entry.MouseButton1Click:Connect(function()
					if obj and obj:IsDescendantOf(game) then
						Explorer.ViewObj(obj)
						selection:Set(Explorer.Nodes[obj])
					end
				end)
				
				entry.MouseButton2Click:Connect(function()
					Favorites.RemoveFavorite(obj)
				end)
				
				yOffset = yOffset + 20
			end
		end
		
		listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end

	Favorites.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Favorites")
		window:Resize(250, 300)
		Favorites.Window = window

		-- Search box
		searchBox = Instance.new("TextBox")
		searchBox.Size = UDim2.new(1, 0, 0, 25)
		searchBox.Position = UDim2.new(0, 0, 0, 0)
		searchBox.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		searchBox.BorderColor3 = Color3.fromRGB(55, 55, 55)
		searchBox.Text = ""
		searchBox.PlaceholderText = "Search favorites..."
		searchBox.TextColor3 = Color3.new(1, 1, 1)
		searchBox.PlaceholderColor3 = Color3.new(100, 100, 100)
		searchBox.TextSize = 14
		searchBox.Font = Enum.Font.SourceSans
		searchBox.Parent = window.GuiElems.Content

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

		-- Instructions
		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.new(1, 0, 0, 20)
		hint.Position = UDim2.new(0, 0, 1, -20)
		hint.BackgroundTransparency = 1
		hint.Text = "Left-click: Jump | Right-click: Remove"
		hint.TextColor3 = Color3.fromRGB(150, 150, 150)
		hint.TextSize = 11
		hint.Font = Enum.Font.SourceSans
		hint.Parent = window.GuiElems.Content
	end

	return Favorites
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
