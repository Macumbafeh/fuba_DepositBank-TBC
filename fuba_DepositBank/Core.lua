local verbose = true;
local debug = false;

local BACKPACK_CONTAINER = BACKPACK_CONTAINER or 0
local BANK_CONTAINER = BANK_CONTAINER or -1
local KEYRING_CONTAINER = KEYRING_CONTAINER or -2
local REAGENTBANK_CONTAINER = REAGENTBANK_CONTAINER or -3
local MAX_GUILDBANK_SLOTS_PER_TAB = MAX_GUILDBANK_SLOTS_PER_TAB or 98

local InvSlots = {KEYRING_CONTAINER, 0, 1, 2, 3, 4}
local BnkSlots = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11}

local BankIsOpen = false;

-- Backport Compatibility
local getn = table.maxn
local format, gsub, lower, match, upper = string.format, string.gsub, string.lower, string.match, string.upper

-- >> Get localized Item Types <<
local Weapon, Armor, Container, Consumable, Trade_Goods, Projectile, Quiver, Recipe, Gem, Miscellaneous, Quest = GetAuctionItemClasses()

-- >> Get localized Item SubTypes << --

-- SubTypes for Consumeables
local Food_and_Drink, Potion, Elixir, Flask, Bandage, Item_Enhancement, Scroll, Other = GetAuctionItemSubClasses(4)

-- SubTypes for Trade Goods
local Elemental, Cloth, Leather, Metal_and_Stone, Meat, Herb, Enchanting, Jewelcrafting, Parts, Devices, Explosives, Materials, Other = GetAuctionItemSubClasses(5)


-- SubTypes for Recipe
local Book, Leatherworking, Tailoring, Engineering, Blacksmithing, Cooking, Alchemy, First_Aid, Enchanting, Fishing, Jewelcrafting = GetAuctionItemSubClasses(8)

-- SubTypes for Miscellaneous
local Junk, Reagent, Pet, Holiday, Other, Mount = GetAuctionItemSubClasses(10)


-- SubType for Gem
local Gem_Red, Gem_Blue, Gem_Yellow, Gem_Purple, Gem_Green, Gem_Orange, Gem_Meta, Gem_Simple, Gem_Prismatic = GetAuctionItemSubClasses(9)

-- Bag Types like Herbalism Bag -- NOT used for now ;)
local BagTypeTable = {0x0008, 0x0010, 0x0020, 0x0040, 0x0080, 0x0200, 0x0400, 0x8000, 0x10000}


local function GetContainerItemID(bag, slot)
	local link = GetContainerItemLink(bag, slot)
	return link and tonumber(string.match(link, "item:(%d+)"))
end

-- Deposit function
local function DepositOnClick(self)
	if not BankIsOpen then return end

	for _, bag in ipairs(InvSlots) do
		for slot=1,GetContainerNumSlots(bag) do
			local ItemID = (GetContainerItemID(bag,slot) or 0)
			if (ItemID > 0) then
				local t={GetItemInfo(ItemID)}

				if fubaDepositBankDB.itemWhitelist[ItemID] then
					if verbose then print("|cffff8000Deposit: |r"..t[2]) end;
					UseContainerItem(bag,slot);
				end

				if (not fubaDepositBankDB.itemBlacklist[ItemID]) then
					-- skip Grey Items
					if (t[3] ~= 0) then
						-- skip Bags
						if (t[9] ~= "INVTYPE_BAG") then
							if (t[6] == Gem)
								or ((t[6] == Recipe) and (t[7] ~= Book))
							then
								if verbose then print("|cffff8000Deposit: |r"..t[2]) end;
								UseContainerItem(bag,slot);
							end

							if (t[7] == Reagent) then
								if verbose then print("|cffff8000Deposit: |r"..t[2]) end;
								UseContainerItem(bag,slot);
							end
						end

						if (t[6] == Trade_Goods) then
							if (t[7] == Elemental)
								or (t[7] == Cloth)
								or (t[7] == Leather)
								or (t[7] == Metal_and_Stone)
								or (t[7] == Cooking)
								or (t[7] == Herb)
								or (t[7] == Enchanting)
								or (t[7] == Jewelcrafting)
								or (t[7] == Parts)
								or (t[7] == Materials)
								or (t[7] == Other)
							then
								if verbose then print("|cffff8000Deposit: |r"..t[2]) end;
								UseContainerItem(bag,slot);
							end
						end

						if (t[6] == Consumable) then
						-- maybe later some usefull
						end
					end
				end
			end
		end
	end
end

local function CreateDefaultButton()
	local f = _G["BankSlotsFrame"]
	if debug then print("|cffff8000fuba: |r FrameName -> "..f:GetName()) end
	if (not f) then return end

	local btnName = "fubaDefaultDepositButton";
	if _G[btnName] or f.BnkDepositButton then
		if debug then print("|cffff8000fuba: |r "..btnName.." still exists.") end;
		return;
	end;

	local btn = _G[btnName] or CreateFrame("Button", btnName, f, "UIPanelButtonTemplate");
	btn:ClearAllPoints();
	btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 22, 60);
	btn:SetSize(150, 24);
	btn:SetText("Deposit");
	btn:SetScript("OnClick", DepositOnClick);
	if IsAddOnLoaded("ElvUI") and ElvUI then
		ElvUI[1]:GetModule('Skins'):HandleButton(btn);
	end
end

local function CreateElvUIButton(self, name, isBank)
	if not ElvUI then return end
	local f = _G[name]
	if (not f) then return; end
	if debug then print("|cffff8000fuba: |r FrameName -> "..f:GetName()) end

	local E, L, V, P, G = unpack(ElvUI);
	local S = E:GetModule('Skins');
	local B = E:GetModule('Bags');

	local isCTEnabled = E.private["CustomTweaks"] and E.private["CustomTweaks"]["BagButtons"] and true or false

	if (isBank) then
		local btnName = "fubaElvBnkDepositButton";
		if _G[btnName] or f.BnkDepositButton then
			if debug then print("|cffff8000fuba: |r "..btnName.." still exists.") end;
			return;
		end;

		f.BnkDepositButton = btnName or CreateFrame("Button", btnName, f.holderFrame);
		f.BnkDepositButton:SetSize(16 + E.Border, 16 + E.Border);
		f.BnkDepositButton:SetTemplate();
		f.BnkDepositButton:SetNormalTexture("Interface\\AddOns\\fuba_DepositBank\\arrowleft");
		f.BnkDepositButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords));
		f.BnkDepositButton:GetNormalTexture():SetInside();
		f.BnkDepositButton:SetPushedTexture("Interface\\AddOns\\fuba_DepositBank\\arrowleft");
		f.BnkDepositButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords));
		f.BnkDepositButton:GetPushedTexture():SetInside();
		f.BnkDepositButton:StyleButton(nil, true);
		f.BnkDepositButton.ttText = 'Deposit';
		f.BnkDepositButton:SetScript("OnEnter", B.Tooltip_Show);
		f.BnkDepositButton:SetScript("OnLeave", B.Tooltip_Hide);
		f.BnkDepositButton:SetScript("OnClick", DepositOnClick);

		f.BnkDepositButton:SetPoint("RIGHT", f.purchaseBagButton, "LEFT", -5, 0);
		f.editBox:Point('RIGHT', f.BnkDepositButton, 'LEFT', -5, 0);

		f.reagentToggle:SetScript("OnClick", function()
			PlaySound("igCharacterInfoTab");
			if f.holderFrame:IsShown() then
				BankFrame.selectedTab = 2
				f.holderFrame:Hide()
				f.reagentFrame:Show()
				f.editBox:Point('RIGHT', f.depositButton, 'LEFT', -5, 0);
				f.bagText:SetText(L["Reagent Bank"])
				if isCTEnabled then
					f.reagentToggle:Point("RIGHT", f.bagText, "LEFT", -5, E.Border * 2)
				end
			else
				BankFrame.selectedTab = 1
				f.reagentFrame:Hide()
				f.holderFrame:Show()
				f.editBox:Point('RIGHT', f.BnkDepositButton, 'LEFT', -5, 0);
				f.bagText:SetText(L["Bank"])
				if isCTEnabled then
					if E.db.CustomTweaks.BagButtons.stackButton then
						f.reagentToggle:Point("RIGHT", f.stackButton, "LEFT", -5, 0)
					else
						f.reagentToggle:Point("RIGHT", f.bagText, "LEFT", -5, E.Border * 2)
					end
				end
			end

			B:Layout(true)
			f:Show()
		end)
	end
end

local function CreateArkButton()
	if ArkInventory and ArkInventory.Const.Actions then

		-- check for existing button and return if found
		local btnName = "fubaArkDepositButton";
		if _G[btnName] then
			if debug then print("|cffff8000fuba: |r "..btnName.." still exists.") end;
			return;
		end;

		local a = getn(ArkInventory.Const.Actions);
		local f = _G["ARKINV_Frame3"];
		local lab = _G[string.format("%s%s%s", f:GetName(), "TitleActionButton", a)];
		if debug then print("|cffff8000fuba: |r Last Ark Button -> "..lab:GetName()) end;
		if (not f) or (not lab) then return end;
		if debug then print("|cffff8000fuba: |r FrameName -> "..f:GetName()) end;

		local function btnOnEnter(self, motion)
			GameTooltip:Hide();
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
			GameTooltip:AddLine('Deposit', 1, 1, 1, nil, 1 );
			GameTooltip:Show();
		end

		local function btnOnUpdate(self)
			if (self:GetNormalTexture() ~= "Interface\\AddOns\\fuba_DepositBank\\arrowleft") then
				self:SetNormalTexture("Interface\\AddOns\\fuba_DepositBank\\arrowleft");
			end
		end

		local function btnOnLeave(self, motion)
			GameTooltip:Hide();
		end

		local btn = _G[btnName] or CreateFrame("Button", btnName, lab:GetParent(), UIPanelButtonTemplate);
		if IsAddOnLoaded("ElvUI") and ElvUI then
			btn:StripTextures();
			ElvUI[1]:GetModule('Skins'):HandleButton(btn);
		end
		btn:SetPoint("RIGHT", lab, "LEFT", -2, 0);
		btn:SetNormalTexture("Interface\\AddOns\\fuba_DepositBank\\arrowleft");
		btn:SetSize(20, 20);
		btn:RegisterForClicks("AnyUp");
		btn:SetScript("OnClick", DepositOnClick);
		btn:SetScript("OnUpdate", btnOnUpdate);
		btn:SetScript("OnEnter", btnOnEnter);
		btn:SetScript("OnLeave", btnOnLeave);

	end
end

local function CreateDepositButton()
	if IsAddOnLoaded("ElvUI") then
		if debug then print("|cffff8000fuba: |r ElvUI loaded.") end
		local E, L, V, P, G = unpack(ElvUI);
		local B = E:GetModule('Bags');

		if (E.private.bags.enable == true) then
			if debug then print("|cffff8000fuba: |r ElvUI private Bags enabled.") end
			hooksecurefunc(B, "ContructContainerFrame", CreateElvUIButton)
		else
			if debug then print("|cffff8000fuba: |r ElvUI private Bags disabled.") end
			CreateDefaultButton()
		end
	else
		if debug then print("|cffff8000fuba: |r ElvUI not loaded.") end
		CreateDefaultButton()
	end

	if IsAddOnLoaded("ArkInventory") then
		if debug then print("|cffff8000fuba: |r ArkInventory loaded.") end
		CreateArkButton()
	end
end

CreateDepositButton()

local function BankCheckEventHandler(self, event, ...)
	if (event == "BANKFRAME_OPENED") then
		BankIsOpen = true;
		CreateDepositButton();
	end
	if (event == "BANKFRAME_CLOSED") then
		BankIsOpen = false;
	end
end

local BankCheckFrame = CreateFrame("Frame");
BankCheckFrame:RegisterEvent("BANKFRAME_CLOSED");
BankCheckFrame:RegisterEvent("BANKFRAME_OPENED");
BankCheckFrame:SetScript("OnEvent", BankCheckEventHandler);