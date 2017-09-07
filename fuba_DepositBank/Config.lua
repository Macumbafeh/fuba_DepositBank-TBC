local addonName = "Deposit Bank"
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToFrame
local queryItems


local PanelDescriptionText = [[
|cff00ff00Deposit Items from Inventory to Bank with just One click.|r

By default the following ItemType will be Deposit to Bank:

    Gem
    Recipe
    Book
    Reagent
    Trade Goods (restricted)

Trade Goods are restricted by:

    Elemental
    Cloth
    Leather
    Metal & Stone
    Cooking
    Herb
    Enchanting
    Jewelcrafting
    Parts
    Materials
    Other

There is also a Blacklist and a Whitelist feature to restrict which Items are allowed to Deposit and which not.

Whitelisted Items will alwasy Deposited by DepositBank even if the Item is on Blacklist.
This means Whitelisted Items got first priority.|r
]]

local defaults = {
	itemBlacklist = {
		--[6217] = true, 		-- Copper Rod
		--[6338] = true, 		-- Silver Rod
		--[11128] = true, 	-- Golden Rod
		--[11144] = true,		-- Truesilver Rod
		--[16206] = true,		-- Arcanite Rod
		--[25843] = true,		-- Fel Iron Rod
		--[25844] = true,		-- Adamantite Rod
		--[25845] = true,		-- Eternium Rod
		
		-- Enchanting Rods
		[6218] = true, 		-- Runed Copper Rod
		[6339] = true, 		-- Runed Silver Rod
		[11130] = true, 	-- Runed Golden Rod
		[11145] = true,		-- Runed Truesilver Rod
		[16207] = true,		-- Runed Arcanite Rod
		[22461] = true,		-- Runed Fel Iron Rod
		[22462] = true,		-- Runed Adamantite Rod
		[22463] = true,		-- Runed Eternium Rod
		
		[6948] = true,		-- Hearthstone
		[20815] = true,		-- Jeweler's Kit
	},
	itemWhitelist = {
	}
}

local function GameTooltip_Hide()
	GameTooltip:Hide()
end

local Panel = CreateFrame('Frame', addonName, InterfaceOptionsFramePanelContainer)
Panel.name = addonName
Panel:Hide()

Panel:RegisterEvent('PLAYER_LOGIN')
Panel:SetScript('OnEvent', function()
	fubaDepositBankDB = fubaDepositBankDB or defaults

	for key, value in next, defaults do
		if(fubaDepositBankDB[key] == nil) then
			fubaDepositBankDB[key] = value
		end
	end
end)

Panel:SetScript('OnShow', function(self)
	local Title = self:CreateFontString(nil, nil, 'GameFontNormalLarge')
	Title:SetPoint('TOPLEFT', 16, -16)
	Title:SetText('DepositBank by fuba')
	
	local Description = self:CreateFontString(nil, nil, 'GameFontHighlightSmall')
	Description:SetPoint('TOPLEFT', Title, 'BOTTOMLEFT', 0, -8)
	Description:SetPoint('RIGHT', -32, 0)
	Description:SetJustifyH('LEFT')
	Description:SetText(PanelDescriptionText)
	self.Description = Description

	self:SetScript('OnShow', nil)
end)

local containerBackdrop = {
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]], tile = true, tileSize = 16,
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4}
}

local BlacklistPanel = CreateFrame('Frame', "FDB_BlackList", Panel)
BlacklistPanel.name = 'Item Blacklist'
BlacklistPanel.parent = addonName
BlacklistPanel:Hide()


local WhitelistPanel = CreateFrame('Frame', "FDB_WhiteList", Panel)
WhitelistPanel.name = 'Item Whitelist'
WhitelistPanel.parent = addonName
WhitelistPanel:Hide()

function BlacklistPanel:default()
	table.wipe(fubaDepositBankDB.itemBlacklist)

	for item in next, defaults.itemBlacklist do
		fubaDepositBankDB.itemBlacklist[item] = true
	end

	BlacklistPanel:UpdateList()
end

function WhitelistPanel:default()
	table.wipe(fubaDepositBankDB.itemWhitelist)

	for item in next, defaults.itemWhitelist do
		fubaDepositBankDB.itemWhitelist[item] = true
	end

	WhitelistPanel:UpdateList()
end

local BLitems = {}
local WLitems = {}

StaticPopupDialogs.FUBA_DEPOSITBANK_BLACKLISTITEM_REMOVE = {
	text = 'Are you sure you want to delete\n|T%s:16|t%s\nfrom the Blacklist?',
	button1 = 'Yes',
	button2 = 'No',
	OnAccept = function(data)
		fubaDepositBankDB.itemBlacklist[data.itemID] = nil
		BLitems[data.itemID] = nil
		data.button:Hide()

		BlacklistPanel:UpdateList()
	end,
	timeout = 0,
	hideOnEscape = true,
	preferredIndex = 3, -- Avoid some taint
}

StaticPopupDialogs.FUBA_DEPOSITBANK_WHITELISTITEM_REMOVE = {
	text = 'Are you sure you want to delete\n|T%s:16|t%s\nfrom the Whitelist?',
	button1 = 'Yes',
	button2 = 'No',
	OnAccept = function(data)
		fubaDepositBankDB.itemWhitelist[data.itemID] = nil
		WLitems[data.itemID] = nil
		data.button:Hide()

		WhitelistPanel:UpdateList()
	end,
	timeout = 0,
	hideOnEscape = true,
	preferredIndex = 3, -- Avoid some taint
}

BlacklistPanel:SetScript('OnShow', function(self)
	for item in next, fubaDepositBankDB.itemBlacklist do
		GameTooltip:SetHyperlink("item:"..item..":0:0:0:0:0:0:0");
	end

	local Title = self:CreateFontString(nil, nil, 'GameFontHighlight')
	Title:SetPoint('TOPLEFT', 20, -20)
	Title:SetText('Item(s) Ignored from Deposit to Bank')

	local Description = CreateFrame('Button', nil, self)
	Description:SetPoint('LEFT', Title, 'RIGHT')
	Description:SetNormalTexture([[Interface\GossipFrame\ActiveQuestIcon]])
	Description:SetSize(16, 16)

	Description:SetScript('OnLeave', GameTooltip_Hide)
	Description:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:AddLine('Easily add more items to filter by\ngrabbing one from your inventory\nand dropping it into the box below.\n\nJust as easily you remove an existing\nitem by right-clicking on it.\n\n|cffff0000Attention!|r\nWhitelist got first Priority.', 1, 1, 1)
		GameTooltip:Show()
	end)

	local Items = CreateFrame('Frame', nil, self)
	Items:SetPoint('TOPLEFT', Title, 'BOTTOMLEFT', -12, -8)
	Items:SetPoint('BOTTOMRIGHT', -8, 8)
	Items:SetBackdrop(containerBackdrop)
	Items:SetBackdropColor(0, 0, 0, 1/2)
	Items:EnableMouse(true)

	local Boundaries = CreateFrame('Frame', nil, Items)
	Boundaries:SetPoint('TOPLEFT', 8, -8)
	Boundaries:SetPoint('BOTTOMRIGHT', -8, 8)

	local function ItemOnClick(self, button)
		if(button == 'RightButton') then
			local _, link, _, _, _, _, _, _, _, texture = GetItemInfo(self.itemID)
			local dialog = StaticPopup_Show('FUBA_DEPOSITBANK_BLACKLISTITEM_REMOVE', texture, link)
			dialog.data = {
				itemID = self.itemID,
				questID = self.questID,
				button = self
			}
		end
	end

	local function ItemOnEnter(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetHyperlink(format("item:%d:0:0:0:0:0:0:0", self.itemID))
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine('Right-click to remove from list', 0, 1, 0)
		GameTooltip:Show()
	end

	self.UpdateList = function()
		local index = 1
		local width = Boundaries:GetWidth()
		local cols = math.floor((width > 0 and width or 591) / 36)
	
		for item in next, fubaDepositBankDB.itemBlacklist do
			local Button = BLitems[item]
			if(not Button) then
				Button = CreateFrame('Button', nil, Items)
				Button:SetSize(34, 34)
				Button:RegisterForClicks('AnyUp')

				local Texture = Button:CreateTexture()
				Texture:SetAllPoints()
				Button.Texture = Texture

				Button:SetScript('OnClick', ItemOnClick)
				Button:SetScript('OnEnter', ItemOnEnter)
				Button:SetScript('OnLeave', GameTooltip_Hide)

				BLitems[item] = Button
			end

			local _, _, _, _, _, _, _, _, _, textureFile = GetItemInfo(item)

			if(textureFile) then
				Button.Texture:SetTexture(textureFile)
			elseif(not queryItems) then
				self:RegisterEvent('GET_ITEM_INFO_RECEIVED')
				queryItems = true
			end

			Button:ClearAllPoints()
			Button:SetPoint('TOPLEFT', Boundaries, (index - 1) % cols * 36, math.floor((index - 1) / cols) * -36)

			Button.itemID = item

			index = index + 1
		end

		if(not queryItems) then
			self:UnregisterEvent('GET_ITEM_INFO_RECEIVED')
		end
	end

  self:UpdateList()
	
	Items:SetScript('OnMouseUp', function()
		if(CursorHasItem()) then
			local _, itemID = GetCursorInfo()
			if(not fubaDepositBankDB.itemBlacklist[itemID]) then
				fubaDepositBankDB.itemBlacklist[itemID] = true
				ClearCursor()

        self:UpdateList()
				return
			end
		end
	end)	
	
  self:SetScript('OnShow', nil)
end)

BlacklistPanel:HookScript('OnUpdate', function(self)
  self:UpdateList()
end)


WhitelistPanel:SetScript('OnShow', function(self)
	for item in next, fubaDepositBankDB.itemBlacklist do
		GameTooltip:SetHyperlink("item:"..item..":0:0:0:0:0:0:0");
	end

	local Title = self:CreateFontString(nil, nil, 'GameFontHighlight')
	Title:SetPoint('TOPLEFT', 20, -20)
	Title:SetText('Item(s) Forced to Deposit to Bank')

	local Description = CreateFrame('Button', nil, self)
	Description:SetPoint('LEFT', Title, 'RIGHT')
	Description:SetNormalTexture([[Interface\GossipFrame\ActiveQuestIcon]])
	Description:SetSize(16, 16)

	Description:SetScript('OnLeave', GameTooltip_Hide)
	Description:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:AddLine('Easily add more items to filter by\ngrabbing one from your inventory\nand dropping it into the box below.\n\nJust as easily you remove an existing\nitem by right-clicking on it.', 1, 1, 1)
		GameTooltip:Show()
	end)

	local Items = CreateFrame('Frame', nil, self)
	Items:SetPoint('TOPLEFT', Title, 'BOTTOMLEFT', -12, -8)
	Items:SetPoint('BOTTOMRIGHT', -8, 8)
	Items:SetBackdrop(containerBackdrop)
	Items:SetBackdropColor(0, 0, 0, 1/2)
	Items:EnableMouse(true)

	local Boundaries = CreateFrame('Frame', nil, Items)
	Boundaries:SetPoint('TOPLEFT', 8, -8)
	Boundaries:SetPoint('BOTTOMRIGHT', -8, 8)

	local function ItemOnClick(self, button)
		if(button == 'RightButton') then
			local _, link, _, _, _, _, _, _, _, texture = GetItemInfo(self.itemID)
			local dialog = StaticPopup_Show('FUBA_DEPOSITBANK_WHITELISTITEM_REMOVE', texture, link)
			dialog.data = {
				itemID = self.itemID,
				questID = self.questID,
				button = self
			}
		end
	end

	local function ItemOnEnter(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetHyperlink(format("item:%d:0:0:0:0:0:0:0", self.itemID))
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine('Right-click to remove from list', 0, 1, 0)
		GameTooltip:Show()
	end

	self.UpdateList = function()
		local index = 1
		local width = Boundaries:GetWidth()
		local cols = math.floor((width > 0 and width or 591) / 36)

		for item in next, fubaDepositBankDB.itemWhitelist do		
			local Button = WLitems[item]
			if(not Button) then
				Button = CreateFrame('Button', nil, Items)
				Button:SetSize(34, 34)
				Button:RegisterForClicks('AnyUp')

				local Texture = Button:CreateTexture()
				Texture:SetAllPoints()
				Button.Texture = Texture

				Button:SetScript('OnClick', ItemOnClick)
				Button:SetScript('OnEnter', ItemOnEnter)
				Button:SetScript('OnLeave', GameTooltip_Hide)

				WLitems[item] = Button
			end

			local _, _, _, _, _, _, _, _, _, textureFile = GetItemInfo(item)

			if(textureFile) then
				Button.Texture:SetTexture(textureFile)
			elseif(not queryItems) then
				self:RegisterEvent('GET_ITEM_INFO_RECEIVED')
				queryItems = true
			end

			Button:ClearAllPoints()
			Button:SetPoint('TOPLEFT', Boundaries, (index - 1) % cols * 36, math.floor((index - 1) / cols) * -36)

			Button.itemID = item

			index = index + 1
		end

		if(not queryItems) then
			self:UnregisterEvent('GET_ITEM_INFO_RECEIVED')
		end
	end

	self:UpdateList()

	Items:SetScript('OnMouseUp', function()
		if(CursorHasItem()) then
			local _, itemID = GetCursorInfo()
			if(not fubaDepositBankDB.itemWhitelist[itemID]) then
				fubaDepositBankDB.itemWhitelist[itemID] = true
				ClearCursor()

				self:UpdateList()
				return
			end
		end
	end)  
  
	self:SetScript('OnShow', nil)
end)

WhitelistPanel:HookScript('OnUpdate', function(self)
  self:UpdateList()
end)

BlacklistPanel:HookScript('OnEvent', function(self, event)
	if(event == 'GET_ITEM_INFO_RECEIVED') then
		self:UpdateList()
		queryItems = false
	end
end)

WhitelistPanel:HookScript('OnEvent', function(self, event)
	if(event == 'GET_ITEM_INFO_RECEIVED') then
		self:UpdateList()
		queryItems = false
	end
end)


InterfaceOptions_AddCategory(Panel)
InterfaceOptions_AddCategory(WhitelistPanel)
InterfaceOptions_AddCategory(BlacklistPanel)

_G['SLASH_' .. addonName .. 1] = '/fdb'
_G['SLASH_' .. addonName .. 2] = '/fubadepositbank'
SlashCmdList[addonName] = function()
	-- On first load IOF doesn't select the right category or panel, this is a dirty fix
	InterfaceOptionsFrame_OpenToCategory(addonName)
	InterfaceOptionsFrame_OpenToCategory(addonName)
end

_G['SLASH_' .. addonName .. 'Blacklist' .. 1] = '/fdbb'
_G['SLASH_' .. addonName .. 'Blacklist' .. 2] = '/fubadepositbankblacklist'
SlashCmdList[addonName .. 'Blacklist'] = function()
	-- On first load IOF doesn't select the right category or panel, this is a dirty fix
	InterfaceOptionsFrame_OpenToCategory(BlacklistPanel.name)
	InterfaceOptionsFrame_OpenToCategory(BlacklistPanel.name)
end

_G['SLASH_' .. addonName .. 'Whitelist' .. 1] = '/fdbw'
_G['SLASH_' .. addonName .. 'Whitelist' .. 2] = '/fubadepositbankwhitelist'
SlashCmdList[addonName .. 'Whitelist'] = function()
	-- On first load IOF doesn't select the right category or panel, this is a dirty fix
	InterfaceOptionsFrame_OpenToCategory(WhitelistPanel.name)
	InterfaceOptionsFrame_OpenToCategory(WhitelistPanel.name)
end