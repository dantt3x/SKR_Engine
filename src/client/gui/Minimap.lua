local Minimap = {}

function Minimap:Load(mapImage: string, studSizeX: number, studSizeY: number)
	
end

function Minimap:SetEnable(bool: boolean)
	
end

function Minimap:Init(coreGui: ScreenGui)
	self.Minimap = coreGui.Minimap :: ScreenGui
end

return setmetatable({}, Minimap)
