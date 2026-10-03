--[[
	Batch Operations Module
	
	Perform operations on multiple selected instances at once.
	Batch rename, delete, group, change properties, and more.
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
	local BatchOps = {}
	local window, operationDropdown, inputBox, executeBtn
	
	BatchOps.GetSelected = function()
		return selection.List
	end

	BatchOps.BatchRename = function(selected, pattern, replacement)
		if not selected or #selected == 0 then return end
		
		local count = 0
		for i, node in ipairs(selected) do
			local obj = node.Obj
			if obj and obj:IsDescendantOf(game) then
				local oldName = obj.Name
				local newName = string.gsub(oldName, pattern, replacement)
				if newName ~= oldName then
					pcall(function() obj.Name = newName end)
					count = count + 1
				end
			end
		end
		
		return count
	end

	BatchOps.BatchDelete = function(selected)
		if not selected or #selected == 0 then return end
		
		local count = 0
		for i, node in ipairs(selected) do
			local obj = node.Obj
			if obj and obj:IsDescendantOf(game) then
				pcall(function() obj:Destroy() end)
				count = count + 1
			end
		end
		
		selection:Clear()
		return count
	end

	BatchOps.BatchGroup = function(selected)
		if not selected or #selected == 0 then return end
		
		local model = Instance.new("Model")
		model.Name = "BatchGroup_" .. os.time()
		
		local count = 0
		for i, node in ipairs(selected) do
			local obj = node.Obj
			if obj and obj:IsDescendantOf(game) then
				pcall(function() obj.Parent = model end)
				count = count + 1
			end
		end
		
		if count > 0 and model.Parent then
			if nodes[model] then
				selection:Set(nodes[model])
				Explorer.ViewNode(nodes[model])
			end
		else
			model:Destroy()
		end
		
		return count
	end

	BatchOps.BatchSetProperty = function(selected, propName, value)
		if not selected or #selected == 0 then return end
		
		local count = 0
		for i, node in ipairs(selected) do
			local obj = node.Obj
			if obj and obj:IsDescendantOf(game) then
				local success = pcall(function() obj[propName] = value end)
				if success then count = count + 1 end
			end
		end
		
		return count
	end

	BatchOps.BatchClone = function(selected)
		if not selected or #selected == 0 then return end
		
		local clones = {}
		for i, node in ipairs(selected) do
			local obj = node.Obj
			if obj and obj:IsDescendantOf(game) then
				local clone = pcall(function() return obj:Clone() end)
				if clone then
					table.insert(clones, clone)
				end
			end
		end
		
		return clones
	end

	BatchOps.ShowUI = function()
		if not window then
			BatchOps.Init()
		end
		
		local selected = BatchOps.GetSelected()
		if #selected == 0 then
			Lib.CreateNotification("Batch Ops", "Select instances first", 2)
			return
		end
		
		window:Show()
	end

	BatchOps.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Batch Operations")
		window:Resize(300, 250)
		BatchOps.Window = window

		-- Selected count
		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -20, 0, 20)
		countLabel.Position = UDim2.new(0, 10, 0, 10)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = "Selected: 0 instances"
		countLabel.TextColor3 = Color3.new(1, 1, 1)
		countLabel.TextSize = 14
		countLabel.Font = Enum.Font.SourceSans
		countLabel.TextXAlignment = Enum.TextXAlignment.Left
		countLabel.Parent = window.GuiElems.Content
		BatchOps.CountLabel = countLabel

		-- Operation selector
		local opLabel = Instance.new("TextLabel")
		opLabel.Size = UDim2.new(1, -20, 0, 20)
		opLabel.Position = UDim2.new(0, 10, 0, 35)
		opLabel.BackgroundTransparency = 1
		opLabel.Text = "Operation:"
		opLabel.TextColor3 = Color3.new(1, 1, 1)
		opLabel.TextSize = 13
		opLabel.Font = Enum.Font.SourceSans
		opLabel.TextXAlignment = Enum.TextXAlignment.Left
		opLabel.Parent = window.GuiElems.Content

		operationDropdown = Lib.DropDown.new()
		operationDropdown.Size = UDim2.new(1, -20, 0, 25)
		operationDropdown.Position = UDim2.new(0, 10, 0, 55)
		operationDropdown:SetOptions({
			"Rename (Pattern Replace)",
			"Delete Selected",
			"Group Selected",
			"Clone Selected",
			"Set Property (Name)",
			"Set Property (Value)"
		})
		operationDropdown.Gui.Parent = window.GuiElems.Content

		-- Input box
		local inputLabel = Instance.new("TextLabel")
		inputLabel.Size = UDim2.new(1, -20, 0, 20)
		inputLabel.Position = UDim2.new(0, 10, 0, 90)
		inputLabel.BackgroundTransparency = 1
		inputLabel.Text = "Input (pattern:replacement for rename):"
		inputLabel.TextColor3 = Color3.new(1, 1, 1)
		inputLabel.TextSize = 12
		inputLabel.Font = Enum.Font.SourceSans
		inputLabel.TextXAlignment = Enum.TextXAlignment.Left
		inputLabel.Parent = window.GuiElems.Content

		inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(1, -20, 0, 25)
		inputBox.Position = UDim2.new(0, 10, 0, 110)
		inputBox.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		inputBox.BorderColor3 = Color3.fromRGB(55, 55, 55)
		inputBox.Text = ""
		inputBox.PlaceholderText = "e.g. old_:new_ or PropName:Value"
		inputBox.TextColor3 = Color3.new(1, 1, 1)
		inputBox.TextSize = 13
		inputBox.Font = Enum.Font.SourceSans
		inputBox.Parent = window.GuiElems.Content

		-- Execute button
		executeBtn = Instance.new("TextButton")
		executeBtn.Size = UDim2.new(1, -20, 0, 30)
		executeBtn.Position = UDim2.new(0, 10, 1, -40)
		executeBtn.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
		executeBtn.BorderSizePixel = 0
		executeBtn.Text = "Execute"
		executeBtn.TextColor3 = Color3.new(1, 1, 1)
		executeBtn.TextSize = 14
		executeBtn.Font = Enum.Font.SourceSans
		executeBtn.Parent = window.GuiElems.Content

		executeBtn.MouseButton1Click:Connect(function()
			local selected = BatchOps.GetSelected()
			if #selected == 0 then
				Lib.CreateNotification("Batch Ops", "No instances selected", 2)
				return
			end

			local op = operationDropdown.Selected
			local input = inputBox.Text
			local result = 0

			if op == "Rename (Pattern Replace)" then
				local parts = string.split(input, ":")
				if #parts >= 2 then
					result = BatchOps.BatchRename(selected, parts[1], table.concat(parts, ":", 2))
				else
					Lib.CreateNotification("Batch Ops", "Use format: pattern:replacement", 2)
					return
				end
			elseif op == "Delete Selected" then
				result = BatchOps.BatchDelete(selected)
			elseif op == "Group Selected" then
				result = BatchOps.BatchGroup(selected)
			elseif op == "Clone Selected" then
				local clones = BatchOps.BatchClone(selected)
				if #clones > 0 then
					selection:SetTable(clones)
					Lib.CreateNotification("Batch Ops", "Cloned " .. #clones .. " instances", 2)
				end
				return
			elseif op == "Set Property (Name)" then
				if input ~= "" then
					result = BatchOps.BatchSetProperty(selected, "Name", input)
				end
			elseif op == "Set Property (Value)" then
				local parts = string.split(input, ":")
				if #parts >= 2 then
					local val = tonumber(parts[2]) or parts[2]
					result = BatchOps.BatchSetProperty(selected, parts[1], val)
				else
					Lib.CreateNotification("Batch Ops", "Use format: PropertyName:Value", 2)
					return
				end
			end

			Lib.CreateNotification("Batch Ops", "Affected " .. result .. " instances", 2)
			Explorer.Refresh()
		end)
	end

	return BatchOps
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
