local table_insert = table.insert

local nicolas = {}
nicolas.__index = nicolas

function nicolas.new()
    return setmetatable({_tasks = {}, _destroyed = false}, nicolas)
end

function nicolas:GiveTask(task)
    if self._destroyed then
        self:_cleanupTask(task)
        return
    end
    table_insert(self._tasks, task)
    return task
end

function nicolas:GiveTasks(...)
    for _, task in ipairs({...}) do
        self:GiveTask(task)
    end
end

function nicolas:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "function" then
        task()
    elseif taskType == "table" and type(task.Destroy) == "function" then
        task:Destroy()
    end
end

function nicolas:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    self._tasks = {}
end

function nicolas:Destroy()
    self:DoCleaning()
end

local RootNicolas = nicolas.new()
local shared = odh_shared_plugins
task.spawn(function()
    shared.load_from_github_url("/aux0on/CrashHandler/refs/heads/main/Prevention.lua")
end)

if shared.game_name ~= "Murder Mystery 2" then return end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpectateService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SpectateService"))

local features = {
    fixScoreboard = false,
    perkEnabled = false,
    shiftLockEnabled = false,
    spectateKeybinds = false,
    isSpectating = false,
}

local scoreboardMaid = nil
local shiftLockConnection = nil

SpectateService.SpectateStarted.Event:Connect(function()
    features.isSpectating = true
end)

SpectateService.SpectateCancelled.Event:Connect(function()
    features.isSpectating = false
end)

local function toggleShiftLock()
    local mouseLock = LocalPlayer.PlayerScripts:FindFirstChild("MouseLock")
    if not mouseLock then
        return
    end
    
    local enabled = mouseLock:GetAttribute("Enabled")
    mouseLock:Invoke(not enabled)
end

local function shiftLockKeybind()
    if features.shiftLockEnabled then
        toggleShiftLock()
    end
end

local function activatePerk()
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character then return end
    
    for _, perk in ipairs(character:GetChildren()) do
        local activate = perk:FindFirstChild("Activate")
        if activate then
            activate:FireServer()
            break
        end
    end
end

local function perkKeybind()
    if features.perkEnabled then
        activatePerk()
    end
end

local function enableFixScoreboard()
    if scoreboardMaid then
        scoreboardMaid:DoCleaning()
        scoreboardMaid = nil
    end
    
    scoreboardMaid = nicolas.new()
    
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    
    scoreboardMaid:GiveTask(pg.ChildAdded:Connect(function(child)
        if child.Name:lower():find("scoreboard") then
            task.wait()
            child:Destroy()
        end
    end))
    
    for _, v in pairs(pg:GetChildren()) do
        if v.Name:lower():find("scoreboard") then
            v:Destroy()
        end
    end
end

local function disableFixScoreboard()
    if scoreboardMaid then
        scoreboardMaid:DoCleaning()
        scoreboardMaid = nil
    end
end

local ControllerPlus = shared.CreateTab("Controller+", "/aux0on/NicolasControllerIcon/refs/heads/main/Untitled163_20260920183340")

local section = ControllerPlus:AddSection("Controller+")

section:AddParagraph("Additional Info", "Gives you a better mobile controller experience.\n\nCredits: @drowsynicolas")

section:AddToggle("Fix Scoreboard Bug", function(bool)
    features.fixScoreboard = bool
    if bool then
        enableFixScoreboard()
    else
        disableFixScoreboard()
    end
end)

section:AddToggle("Enable Perk", function(bool)
    features.perkEnabled = bool
end)

section:AddToggle("Enable Shift Lock", function(bool)
    features.shiftLockEnabled = bool
end)

section:AddToggle("Enable Spectate Keybinds", function(bool)
    features.spectateKeybinds = bool
end)

section:AddKeybind("Perk Keybind", "ButtonX", function()
    perkKeybind()
end)

section:AddKeybind("Shift Lock", "ButtonL3", function()
    shiftLockKeybind()
end)

section:AddKeybind("Spectate Next", "ButtonR1", function()
    if features.spectateKeybinds and features.isSpectating then
        SpectateService:NavigateSpectate(1)
    end
end)

section:AddKeybind("Spectate Previous", "ButtonL1", function()
    if features.spectateKeybinds and features.isSpectating then
        SpectateService:NavigateSpectate(-1)
    end
end)

section:AddKeybind("Toggle Spectate", "ButtonR3", function()
    if features.spectateKeybinds then
        SpectateService:ToggleSpectate()
    end
end)

RootNicolas:GiveTask(function()
    features.fixScoreboard = false
    features.perkEnabled = false
    features.shiftLockEnabled = false
    features.spectateKeybinds = false
    features.isSpectating = false
    disableFixScoreboard()
    if shiftLockConnection then
        shiftLockConnection:Disconnect()
        shiftLockConnection = nil
    end
end)
