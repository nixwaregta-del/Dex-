--[[
	Quick Execute Module
	
	A lightweight floating console for executing scripts quickly.
	Shows execution history and supports multi-line input.
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
	local QuickExecute = {}
	local window, inputFrame, outputFrame, outputList, historyBtn, clearBtn
	local execHistory = {}
	local maxHistory = 50
	local historyIndex = 0

	QuickExecute.Log = function(msg, msgType)
		if not outputList then return end
		
		local entry = Instance.new("TextLabel")
		entry.Size = UDim2.new(1, -10, 0, 18)
		entry.Position = UDim2.new(0, 5, 0, 0)
		entry.BackgroundTransparency = 1
		entry.Text = msg
		entry.TextColor3 = msgType == "error" and Color3.fromRGB(255, 80, 80) or 
		                   msgType == "warn" and Color3.fromRGB(255, 180, 60) or
		                   msgType == "info" and Color3.fromRGB(130, 200, 255) or
		                   Color3.fromRGB(200, 200, 200)
		entry.TextSize = 12
		entry.Font = Enum.Font.Code
		entry.TextXAlignment = Enum.TextXAlignment.Left
		entry.TextWrapped = true
		entry.Parent = outputList
		
		-- Auto scroll
		outputFrame.CanvasPosition = Vector2.new(0, outputFrame.CanvasPosition.Y + 18)
	end

	QuickExecute.Execute = function(code)
		if not code or code == "" then return end
		
		-- Add to history
		table.insert(execHistory, code)
		if #execHistory > maxHistory then
			table.remove(execHistory, 1)
		end
		historyIndex = #execHistory + 1

		QuickExecute.Log("> " .. code, "command")
		
		-- Execute
		local success, result = pcall(function()
			return loadstring(code)()
		end)
		
		if success then
			if result ~= nil then
				QuickExecute.Log(tostring(result), "output")
			end
		else
			QuickExecute.Log("Error: " .. tostring(result), "error")
		end
	end

	QuickExecute.ShowHistory = function(direction)
		if #execHistory == 0 then return end
		
		historyIndex = historyIndex + direction
		
		if historyIndex < 1 then
			historyIndex = 1
		elseif historyIndex > #execHistory then
			historyIndex = #execHistory + 1
			inputFrame.Text = ""
			return
		end
		
		inputFrame.Text = execHistory[historyIndex]
	end

	QuickExecute.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Quick Execute")
		window:Resize(400, 300)
		QuickExecute.Window = window

		-- Output frame
		outputFrame = Instance.new("ScrollingFrame")
		outputFrame.Size = UDim2.new(1, -10, 1, -70)
		outputFrame.Position = UDim2.new(0, 5, 0, 5)
		outputFrame.BackgroundTransparency = 1
		outputFrame.BorderSizePixel = 0
		outputFrame.ScrollBarThickness = 10
		outputFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		outputFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		outputFrame.Parent = window.GuiElems.Content
		
		outputList = Instance.new("Frame")
		outputList.Size = UDim2.new(1, 0, 0, 0)
		outputList.BackgroundTransparency = 1
		outputList.Parent = outputFrame

		-- Input frame
		inputFrame = Instance.new("TextBox")
		inputFrame.Size = UDim2.new(1, -10, 0, 25)
		inputFrame.Position = UDim2.new(0, 5, 1, -35)
		inputFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		inputFrame.BorderColor3 = Color3.fromRGB(55, 55, 55)
		inputFrame.Text = ""
		inputFrame.PlaceholderText = "Enter Lua code..."
		inputFrame.TextColor3 = Color3.new(1, 1, 1)
		inputFrame.PlaceholderColor3 = Color3.new(100, 100, 100)
		inputFrame.TextSize = 13
		inputFrame.Font = Enum.Font.Code
		inputFrame.Parent = window.GuiElems.Content

		-- History button
		historyBtn = Instance.new("TextButton")
		historyBtn.Size = UDim2.new(0, 50, 0, 25)
		historyBtn.Position = UDim2.new(1, -55, 1, -35)
		historyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		historyBtn.BorderSizePixel = 0
		historyBtn.Text = "Hist"
		historyBtn.TextColor3 = Color3.new(1, 1, 1)
		historyBtn.TextSize = 11
		historyBtn.Font = Enum.Font.SourceSans
		historyBtn.Parent = window.GuiElems.Content
		
		historyBtn.MouseButton1Click:Connect(function()
			QuickExecute.ShowHistory(-1)
		end)
		
		historyBtn.MouseButton2Click:Connect(function()
			QuickExecute.ShowHistory(1)
		end)

		-- Clear button
		clearBtn = Instance.new("TextButton")
		clearBtn.Size = UDim2.new(0, 50, 0, 25)
		clearBtn.Position = UDim2.new(1, -110, 1, -35)
		clearBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		clearBtn.BorderSizePixel = 0
		clearBtn.Text = "Clear"
		clearBtn.TextColor3 = Color3.new(1, 1, 1)
		clearBtn.TextSize = 11
		clearBtn.Font = Enum.Font.SourceSans
		clearBtn.Parent = window.GuiElems.Content
		
		clearBtn.MouseButton1Click:Connect(function()
			for _, child in pairs(outputList:GetChildren()) do
				child:Destroy()
			end
		end)

		-- Execute on Enter
		inputFrame.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				QuickExecute.Execute(inputFrame.Text)
				inputFrame.Text = ""
			end
		end)
		
		-- Keyboard shortcuts
		inputFrame:GetPropertyChangedSignal("Text"):Connect(function()
			if inputFrame.Text == "" then
				historyIndex = #execHistory + 1
			end
		end)
	end

	return QuickExecute
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
