--[[
	Script Execution Log Module
	
	Logs all script executions made through Dex+++.
	Tracks execution time, source, and results.
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
	local ScriptLog = {}
	local window, listFrame, clearBtn, filterDropdown
	local logs = {}
	local maxLogs = 200
	local filters = {
		All = true,
		Success = true,
		Error = true,
		Warn = true
	}

	ScriptLog.Log = function(source, code, status, errorMsg)
		local entry = {
			Timestamp = os.date("%H:%M:%S"),
			Source = source or "Unknown",
			Code = code,
			Status = status, -- "success", "error", "warn"
			Error = errorMsg
		}
		
		table.insert(logs, entry)
		if #logs > maxLogs then
			table.remove(logs, 1)
		end
		
		ScriptLog.RefreshList()
	end

	ScriptLog.GetLogs = function()
		return logs
	end

	ScriptLog.ClearLogs = function()
		table.clear(logs)
		ScriptLog.RefreshList()
	end

	ScriptLog.RefreshList = function()
		if not listFrame then return end
		
		for _, child in pairs(listFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		local yOffset = 0
		local showAll = filters.All
		local showSuccess = filters.Success
		local showError = filters.Error
		local showWarn = filters.Warn
		
		for i, entry in ipairs(logs) do
			local visible = showAll or 
				(entry.Status == "success" and showSuccess) or
				(entry.Status == "error" and showError) or
				(entry.Status == "warn" and showWarn)
			
			if not visible then continue end
			
			local color = entry.Status == "error" and Color3.fromRGB(255, 80, 80) or
			              entry.Status == "warn" and Color3.fromRGB(255, 180, 60) or
			              Color3.fromRGB(150, 200, 150)
			
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 30)
			btn.Position = UDim2.new(0, 0, 0, yOffset)
			btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			btn.BorderSizePixel = 0
			btn.Text = string.format("[%s] %s: %s", entry.Timestamp, entry.Status:upper(), entry.Source)
			btn.TextColor3 = color
			btn.TextSize = 12
			btn.Font = Enum.Font.Code
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Parent = listFrame
			
			btn.MouseButton1Click:Connect(function()
				-- Show full code in a popup
				local codeWin = Lib.Window.new()
				codeWin:SetTitle("Script - " .. entry.Source)
				codeWin:Resize(400, 300)
				
				local codeFrame = Lib.CodeFrame.new()
				codeFrame.Frame.Position = UDim2.new(0, 0, 0, 0)
				codeFrame.Frame.Size = UDim2.new(1, 0, 1, 0)
				codeFrame.Frame.Parent = codeWin.GuiElems.Content
				codeFrame:SetText(entry.Code)
				codeWin:Show()
			end)
			
			yOffset = yOffset + 30
		end
		
		listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end

	ScriptLog.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Execution Log")
		window:Resize(400, 350)
		ScriptLog.Window = window

		-- Filter dropdown
		local filterLabel = Instance.new("TextLabel")
		filterLabel.Size = UDim2.new(1, -20, 0, 20)
		filterLabel.Position = UDim2.new(0, 10, 0, 5)
		filterLabel.BackgroundTransparency = 1
		filterLabel.Text = "Filter:"
		filterLabel.TextColor3 = Color3.new(1, 1, 1)
		filterLabel.TextSize = 12
		filterLabel.Font = Enum.Font.SourceSans
		filterLabel.TextXAlignment = Enum.TextXAlignment.Left
		filterLabel.Parent = window.GuiElems.Content

		filterDropdown = Lib.DropDown.new()
		filterDropdown.Size = UDim2.new(1, -20, 0, 22)
		filterDropdown.Position = UDim2.new(0, 10, 0, 22)
		filterDropdown:SetOptions({"All", "Success Only", "Errors Only", "Warnings Only"})
		filterDropdown.Gui.Parent = window.GuiElems.Content
		
		filterDropdown.OnSelect:Connect(function(selected)
			if selected == "All" then
				filters.All = true
				filters.Success = true
				filters.Error = true
				filters.Warn = true
			elseif selected == "Success Only" then
				filters.All = false
				filters.Success = true
				filters.Error = false
				filters.Warn = false
			elseif selected == "Errors Only" then
				filters.All = false
				filters.Success = false
				filters.Error = true
				filters.Warn = false
			elseif selected == "Warnings Only" then
				filters.All = false
				filters.Success = false
				filters.Error = false
				filters.Warn = true
			end
			ScriptLog.RefreshList()
		end)

		-- List frame
		listFrame = Instance.new("ScrollingFrame")
		listFrame.Size = UDim2.new(1, -10, 1, -60)
		listFrame.Position = UDim2.new(0, 5, 0, 50)
		listFrame.BackgroundTransparency = 1
		listFrame.BorderSizePixel = 0
		listFrame.ScrollBarThickness = 10
		listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		listFrame.Parent = window.GuiElems.Content

		-- Clear button
		clearBtn = Instance.new("TextButton")
		clearBtn.Size = UDim2.new(1, -20, 0, 25)
		clearBtn.Position = UDim2.new(0, 10, 1, -30)
		clearBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		clearBtn.BorderSizePixel = 0
		clearBtn.Text = "Clear Log"
		clearBtn.TextColor3 = Color3.new(1, 1, 1)
		clearBtn.TextSize = 13
		clearBtn.Font = Enum.Font.SourceSans
		clearBtn.Parent = window.GuiElems.Content
		
		clearBtn.MouseButton1Click:Connect(function()
			ScriptLog.ClearLogs()
		end)
	end

	return ScriptLog
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
