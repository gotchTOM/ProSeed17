-- Create a container for postitioning of multiple "windows"
SowingSupp.container = {};
function SowingSupp.container:New(baseX, baseY, isVisible)
	SowingSupp.textSize = {};
	SowingSupp.textSize[0] = g_currentMission.timeScaleTextSize;
	SowingSupp.textSize[1] = SowingSupp.textSize[0]*0.8;
	SowingSupp.textSize[2] = SowingSupp.textSize[0];
	SowingSupp.textSize[3] = SowingSupp.textSize[0]*1.2;
	SowingSupp.textSize[4] = SowingSupp.textSize[0]*1.4;
	SowingSupp.textSize[5] = SowingSupp.textSize[0]*1.6;
	SowingSupp.baseHeight =  .6*g_currentMission.weatherForecasetHeight;
	SowingSupp.baseWidth = SowingSupp.baseHeight / g_screenAspectRatio;
	local obj = setmetatable ( { }, { __index = self } )
	-- baseX / baseY = start of all other positioning
	obj.baseX = baseX;
	obj.baseY = baseY;
	obj.height = 0;
	obj.width = 0;
	obj.move = false;
	obj.isVisible = isVisible;
	obj.grids = {};
	obj.renderMe = function ()
		if obj.isVisible then
			-- Render all grids with own render()
			for k, grid in pairs(obj.grids) do
				grid.renderMe(obj);
			end;
		end;
	end;
	obj.moveMe = function (baseX, baseY)
		obj.baseX = baseX;
		obj.baseY = baseY;
		for k, grid in pairs(obj.grids) do
			grid.moveMe(obj);
		end;
	end;
	obj.mouseEvent = function (vehicle, posX, posY, isDown, isUp, button)
		if obj.isVisible then
			if obj.move then
				obj.moveMe(math.min(posX,g_currentMission.vehicleHudBg.x), math.min(posY, 1 - obj.height));
			end;
			for k, grid in pairs(obj.grids) do
				grid.mouseEvent(obj, vehicle, posX, posY, isDown, isUp, button);
			end;
		end;
	end;
	return obj;
end;

-- Create a grid for easy positioning of guiElements
SowingSupp.hudGrid = {};
function SowingSupp.hudGrid:New(container, offsetX, offsetY, rows, columns, width, height, isVisible, isMaster, showGrid)
	local obj = setmetatable ( { }, { __index = self } )
	-- Create background Overlay
	obj.hudBgOverlay = createImageOverlay(Utils.getFilename("img/hud_bg.dds", SowingSupp.path));
	-- offsetX / offsetY = offset from container baseX / baseY
	obj.offsetX = offsetX;
	obj.offsetY = offsetY;
	obj.rows = rows;
	obj.columns = columns;
	obj.width = width;
	obj.height = height;
	obj.isVisible = isVisible;
	obj.centerX = obj.width/2;
	obj.rightX = obj.width * obj.columns;
	obj.isMaster = isMaster;
	obj.showGrid = showGrid;
	if obj.isMaster then
		container.height = obj.rows * obj.height;
		container.width = obj.columns * obj.width;
	end;
	obj.move = false;
	obj.elements = {};
	obj.table = {};
	for i=1, (obj.rows * obj.columns) do
		obj.table[i] = {};
	end;
	self.tempOffsetY = 0;
	local count = 1;
	for row=1, obj.rows do
		local offsetX = 0;
		for column=1, obj.columns do
			obj.table[count].x = container.baseX + obj.offsetX + offsetX;
			obj.table[count].y = container.baseY + obj.offsetY + self.tempOffsetY;
			offsetX = offsetX + obj.width;
			count = count + 1;
		end;
		self.tempOffsetY = self.tempOffsetY + obj.height;
	end;
	obj.renderMe = function (container)
		if obj.isVisible then
			renderOverlay(obj.hudBgOverlay, container.baseX + obj.offsetX, container.baseY + obj.offsetY, (obj.columns * obj.width), (obj.rows * obj.height));
			-- Render all guiElements with own render()
			for k, guiElement in pairs(obj.elements) do
				if guiElement.renderMe ~= nil then
					guiElement.renderMe(obj, container);
				else
					guiElement:render(obj, container);
				end;
			end;
			if obj.showGrid then
				setTextAlignment(RenderText.ALIGN_LEFT);
				setTextColor(.2,.2,.2,1);
				for k, v in pairs(obj.table) do
					renderText(obj.table[k].x, obj.table[k].y, SowingSupp.textSize[1], tostring(k));
				end;
				setTextColor(1,1,1,1);
			end;
		end;
	end;
	obj.moveMe = function ( container, offsetX, offsetY, rows, columns, width, height, isVisible )
		for k,v in pairs(obj.table) do obj.table[k]=nil end
		-- baseX / baseY = start of all other positioning
		obj.offsetX = offsetX or obj.offsetX;
		obj.offsetY = offsetY or obj.offsetY;
		obj.rows = rows or obj.rows;
		obj.columns = columns or obj.columns;
		obj.width = width or obj.width;
		obj.height = height or obj.height;
		obj.isVisible = isVisible or obj.isVisible;
		obj.centerX = obj.width/2;
		obj.rightX = obj.width * obj.columns;
		if obj.isMaster then
			container.height = obj.rows * obj.height;
			container.width = obj.columns * obj.width;
		end;
		obj.table = {};
		for i=1, (obj.rows * obj.columns) do
			obj.table[i] = {};
		end;
		obj.tempOffsetY = 0;
		local count = 1;
		for row=1, obj.rows do
			local offsetX = 0;
			for column=1, obj.columns do
				obj.table[count].x = container.baseX + obj.offsetX + offsetX;
				obj.table[count].y = container.baseY + obj.offsetY + obj.tempOffsetY;
				offsetX = offsetX + obj.width;
				count = count + 1;
			end;
		obj.tempOffsetY = obj.tempOffsetY + obj.height;
		end;
	end;
	obj.mouseEvent = function (container, vehicle, posX, posY, isDown, isUp, button)
		if obj.isVisible then
			for k, guiElement in pairs(obj.elements) do
				guiElement:mouseEvent(obj, container, vehicle, posX, posY, isDown, isUp, button);
			end;
		end;
	end;
	return obj;
end;

SowingSupp.guiElement = {};

function SowingSupp.guiElement:NewInteraction ( gridPos, offsetX, offsetY, textColor, functionToCall, parameter1, parameter2, style, label, value, isVisible, graphic, labelTextSize, valueTextSize, textBold)
	local obj = setmetatable ( { }, { __index = self } )
	obj.gridPos = gridPos;
	obj.offsetX = offsetX;
	obj.offsetY = offsetY;
	obj.color = textColor;
	obj.functionToCall = functionToCall;
	obj.parameter1 = parameter1;
	obj.parameter2 = parameter2;
	obj.style = style;
	obj.label = label;
	obj.value = value;
	obj.isVisible = isVisible;
	obj.labelTextSize = labelTextSize;
	obj.valueTextSize = valueTextSize;
	obj.textBold = textBold;
	if obj.functionToCall ~= nil then
		obj.buttonSet = SowingSupp.buttonSet:New( obj.functionToCall, obj.style, obj.gridPos, graphic )
	end;
	obj.renderMe = function (grid, container)
		if obj.isVisible and grid.table[obj.gridPos] ~= nil then
			local r,g,b,a = obj.color[1],obj.color[2],obj.color[3],obj.color[4];
			setTextColor(r,g,b,a);
			setTextBold(false);
			local baseHeight = SowingSupp.baseHeight;
			local baseWidth = SowingSupp.baseHeight;
			if obj.style == "plusminus" or obj.style == "arrow" then
				setTextAlignment(RenderText.ALIGN_CENTER);
				if obj.textBold then
					setTextBold(true);
				else
					setTextBold(false);
				end;
				local yOffsetText = baseHeight/2;
				local iconHeight = .5 * baseHeight;
				local iconWidth = iconHeight / g_screenAspectRatio;
				local yOffsetIcon = baseHeight * 0.15;
				renderText(obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX), obj.offsetY + (grid.table[obj.gridPos].y + 2.7*yOffsetText), SowingSupp.textSize[obj.labelTextSize], tostring(obj.label));
				renderText(obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX), obj.offsetY + (grid.table[obj.gridPos].y + 1.7*yOffsetText), SowingSupp.textSize[obj.valueTextSize], tostring(obj.value));
				if not obj.buttonSet.button1IsActive then
					setOverlayColor(obj.buttonSet.overlays.overlayMinus, 1, 1, 1, 0.1);
				else
					setOverlayColor(obj.buttonSet.overlays.overlayMinus, 1, 1, 1, 1);
				end;
				renderOverlay(obj.buttonSet.overlays.overlayMinus, obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX - 1.5*iconWidth), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetIcon), iconWidth, iconHeight);
				if not obj.buttonSet.button2IsActive then
					setOverlayColor(obj.buttonSet.overlays.overlayPlus, 1, 1, 1, 0.1);
				else
					setOverlayColor(obj.buttonSet.overlays.overlayPlus, 1, 1, 1, 1);
				end;
				renderOverlay(obj.buttonSet.overlays.overlayPlus, obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX + .5*iconWidth), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetIcon), iconWidth, iconHeight);
			elseif obj.style == "toggle" then
				setTextAlignment(RenderText.ALIGN_CENTER);
				if obj.textBold then
					setTextBold(true);
				else
					setTextBold(false);
				end;
				local iconHeight = 1.1*baseHeight;
				local iconWidth = iconHeight / g_screenAspectRatio;
				local yOffsetIcon = baseHeight * 0.15;
				local yOffsetText = 1.5*baseHeight;
				if obj.label ~= nil then
					renderText(obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetText), SowingSupp.textSize[obj.labelTextSize], tostring(obj.label));
				end;
				if obj.value then
					renderOverlay(obj.buttonSet.overlays.overlayToggleOn, obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX - iconWidth/2), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetIcon), iconWidth, iconHeight);
				else
					renderOverlay(obj.buttonSet.overlays.overlayToggleOff, obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX - iconWidth/2), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetIcon), iconWidth, iconHeight);
				end;
			elseif obj.style == "push" then
				setTextAlignment(RenderText.ALIGN_CENTER);
				if obj.textBold then
					setTextBold(true);
				else
					setTextBold(false);
				end;
				local iconHeight = 1.1*baseHeight;
				local iconWidth = iconHeight / g_screenAspectRatio;
				local yOffsetIcon = baseHeight * 0.15;
				local yOffsetText = 1.5*baseHeight;
				if obj.label ~= nil then
					renderText(obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetText), SowingSupp.textSize[obj.labelTextSize], tostring(obj.label));
				end;
				renderOverlay(obj.buttonSet.overlays.overlayPush, obj.offsetX + (grid.table[obj.gridPos].x + grid.centerX - iconWidth/2), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetIcon), iconWidth, iconHeight);
			elseif obj.style == "option" then
				local iconHeight = .7 * baseHeight;
				local iconWidth = iconHeight / g_screenAspectRatio;
				local offsetIcon = baseHeight * 0.11;
				if obj.value then
					renderOverlay(obj.buttonSet.overlays.overlayToggleOptionOn, obj.offsetX + (grid.table[obj.gridPos].x + offsetIcon), obj.offsetY + (grid.table[obj.gridPos].y + offsetIcon), iconWidth, iconHeight);
				else
					renderOverlay(obj.buttonSet.overlays.overlayToggleOptionOff, obj.offsetX + (grid.table[obj.gridPos].x + offsetIcon), obj.offsetY + (grid.table[obj.gridPos].y + offsetIcon), iconWidth, iconHeight);
				end;
				setTextAlignment(RenderText.ALIGN_LEFT);
				if obj.textBold then
					setTextBold(true);
				else
					setTextBold(false);
				end;
				local xOffsetText =  iconWidth + 3 * offsetIcon;
				local yOffsetText = baseHeight * .28;
				renderText(obj.offsetX + (grid.table[obj.gridPos].x + xOffsetText), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetText), SowingSupp.textSize[obj.labelTextSize], tostring(obj.label));
			end;
			setTextAlignment(RenderText.ALIGN_LEFT);
			setTextBold(false);
		end;
	end;
	return obj;
end;

-- Create object guiElement -> Titlebar
function SowingSupp.guiElement:NewTitlebar ( gridPos, functionToCall, parameter1, parameter2, label, isVisible, textSize)
	local obj = setmetatable ( { }, { __index = self } )
	obj.gridPos = gridPos;
	obj.functionToCall = functionToCall;
	obj.parameter1 = parameter1;
	obj.parameter2 = parameter2;
	obj.style = "titleBar";
	obj.label = label;
	obj.isVisible = isVisible;
	obj.textSize = textSize;
	if obj.functionToCall ~= nil then
		obj.buttonSet = SowingSupp.buttonSet:New( obj.functionToCall, obj.style, obj.gridPos )
	end;
	obj.renderMe = function (grid, container)
		if obj.isVisible and grid.table[obj.gridPos] ~= nil then
			local baseHeight = SowingSupp.baseHeight;
			local baseWidth = SowingSupp.baseHeight;
			setOverlayColor(obj.buttonSet.overlays.overlayRowBg, .05, .05, .05, 1);
			renderOverlay(obj.buttonSet.overlays.overlayRowBg, grid.table[obj.gridPos].x, grid.table[obj.gridPos].y, grid.rightX, grid.height);
			setTextAlignment(RenderText.ALIGN_CENTER);
			local yOffsetText = baseHeight * 0.19;
			renderText((grid.table[obj.gridPos].x + g_currentMission.vehicleHudBg.width/2), (grid.table[obj.gridPos].y + yOffsetText), SowingSupp.textSize[obj.textSize], tostring(obj.label));
			if not obj.buttonSet.button1IsActive then
				setOverlayColor(obj.buttonSet.overlays.overlayConfig, 1, 1, 1, 0);
			else
				setOverlayColor(obj.buttonSet.overlays.overlayConfig, 1, 1, 1, 1);
			end;
			local iconHeight = .5 * baseHeight;
			local iconWidth = iconHeight / g_screenAspectRatio;
			local offsetIcon = baseHeight * 0.15;
			renderOverlay(obj.buttonSet.overlays.overlayConfig, grid.table[obj.gridPos].x + offsetIcon, grid.table[obj.gridPos].y + offsetIcon, iconWidth, iconHeight);
			if not obj.buttonSet.button2IsActive then
				setOverlayColor(obj.buttonSet.overlays.overlayClose, 1, 1, 1, 0);
			else
				setOverlayColor(obj.buttonSet.overlays.overlayClose, 1, 1, 1, 1);
			end;
			renderOverlay(obj.buttonSet.overlays.overlayClose, grid.table[obj.gridPos].x + grid.rightX - offsetIcon - iconWidth, grid.table[obj.gridPos].y + offsetIcon, iconWidth, iconHeight);
		end;
	end;
	return obj;
end;

-- Create object guiElement -> Separatorline
function SowingSupp.guiElement:NewSeparator ( gridPos, offsetX, offsetY, color, style, isVisible)
	local obj = setmetatable ( { }, { __index = self } )
	obj.gridPos = gridPos;
	obj.offsetX = offsetX;
	obj.offsetY = offsetY;
	obj.color = color;
	obj.style = style;
	obj.isVisible = isVisible;
	obj.graphic = createImageOverlay(Utils.getFilename("img/row_bg.dds", SowingSupp.path));
	obj.renderMe = function (grid, container)
		if obj.isVisible and grid.table[obj.gridPos] ~= nil then
			local baseHeight = SowingSupp.baseHeight;
			local baseWidth = SowingSupp.baseHeight;
			local offsetSep = baseHeight * 0.1;
			if obj.color ~= nil then
				local r,g,b,a = obj.color[1],obj.color[2],obj.color[3],obj.color[4];
				setOverlayColor(obj.graphic, r,g,b,a);
			end;
			if obj.style == "h" then
				renderOverlay(obj.graphic, obj.offsetX + (container.baseX + grid.offsetX + offsetSep), obj.offsetY + (grid.table[obj.gridPos].y), grid.columns * grid.width - (2*offsetSep), 0.002);
			elseif obj.style == "v" then
				renderOverlay(obj.graphic, obj.offsetX + (container.baseX + grid.offsetX + offsetSep), obj.offsetY + (grid.table[obj.gridPos].y), 0.002, grid.rows * grid.height - (2*offsetSep));
			end;
		end;
	end;
	return obj;
end;

-- Create object guiElement -> IconText
function SowingSupp.guiElement:NewIconText ( gridPos, offsetX, offsetY, color, value, valueTextSize, textBold, isVisible, graphic, uvs)
	local obj = setmetatable ( { }, { __index = self } )
	obj.gridPos = gridPos;
	obj.offsetX = offsetX;
	obj.offsetY = offsetY;
	obj.color = color;
	obj.value = value;
	obj.valueTextSize = valueTextSize;
	obj.textBold = textBold;
	obj.isVisible = isVisible;
	if graphic ~= nil then
		obj.graphic = createImageOverlay(Utils.getFilename("img/"..graphic..".dds", SowingSupp.path));
	end;
	obj.uvs = uvs;
	obj.renderMe = function (grid, container)
		if obj.isVisible and grid.table[obj.gridPos] ~= nil then
			local r,g,b,a = obj.color[1],obj.color[2],obj.color[3],obj.color[4];
			setTextColor(r,g,b,a);
			if obj.textBold then
				setTextBold(true);
			else
				setTextBold(false);
			end;
			setTextAlignment(RenderText.ALIGN_LEFT);
			local baseHeight = SowingSupp.baseHeight;
			local baseWidth = SowingSupp.baseHeight;
			local iconHeight = .6 * baseHeight;
			local iconWidth = iconHeight / g_screenAspectRatio;
			local offsetIcon = baseHeight * 0.05;
			local xOffsetText =  grid.centerX;
			local yOffsetText = baseHeight * .19;
			if obj.graphic ~= nil then
				if obj.uvs ~= nil then
					local u0,v0,u1,v1,u2,v2,u3,v3 = obj.uvs[1],obj.uvs[2],obj.uvs[3],obj.uvs[4],obj.uvs[5],obj.uvs[6],obj.uvs[7],obj.uvs[8];
					setOverlayUVs(obj.graphic, u0,v0,u1,v1,u2,v2,u3,v3 );
				end;
				renderOverlay(obj.graphic, obj.offsetX + (grid.table[obj.gridPos].x + offsetIcon), obj.offsetY + (grid.table[obj.gridPos].y + offsetIcon), iconWidth, iconHeight);
				xOffsetText = iconWidth + 3 * offsetIcon;
			end;
			renderText(obj.offsetX + (grid.table[obj.gridPos].x + xOffsetText), obj.offsetY + (grid.table[obj.gridPos].y + yOffsetText), SowingSupp.textSize[obj.valueTextSize], tostring(obj.value));
			setTextColor(1,1,1,1);
			setTextBold(false);
		end;
	end;
	return obj;
end;

-- Create object guiElement -> Text
function SowingSupp.guiElement:NewText ( gridPos, offsetX, offsetY, color, label, value, isVisible, labelTextSize, valueTextSize, textBold, textAlignment)
	local obj = setmetatable ( { }, { __index = self } )
	obj.gridPos = gridPos;
	obj.offsetX = offsetX;
	obj.offsetY = offsetY;
	obj.color = color;
	obj.label = label;
	obj.value = value;
	obj.isVisible = isVisible;
	obj.labelTextSize = labelTextSize;
	obj.valueTextSize = valueTextSize;
	obj.textBold = textBold;
	obj.textAlignment = textAlignment;
	obj.renderMe = function (grid, container)
		if obj.isVisible and grid.table[obj.gridPos] ~= nil then
			local r,g,b,a = obj.color[1],obj.color[2],obj.color[3],obj.color[4];
			setTextColor(r,g,b,a);
			if obj.textBold then
				setTextBold(true);
			else
				setTextBold(false);
			end;
			local baseHeight = SowingSupp.baseHeight;
			local baseWidth = SowingSupp.baseHeight;
			setTextAlignment(obj.textAlignment);
			local yOffsetText = baseHeight/2;
			if obj.label ~= nil then
				renderText(obj.offsetX+(grid.table[obj.gridPos].x + grid.centerX), obj.offsetY+(grid.table[obj.gridPos].y + 1*yOffsetText), SowingSupp.textSize[obj.labelTextSize], tostring(obj.label));
			end;
			renderText(obj.offsetX+(grid.table[obj.gridPos].x + grid.centerX), obj.offsetY+(grid.table[obj.gridPos].y + 0*yOffsetText), SowingSupp.textSize[obj.valueTextSize], tostring(obj.value));
			setTextColor(1,1,1,1);
			setTextBold(false);
		end;
	end;
	return obj;
end;

-- Create object guiElement -> Image
function SowingSupp.guiElement:NewImage ( gridPos, offsetX, offsetY, width, height, color, isVisible, graphic, uvs)
	local obj = setmetatable ( { }, { __index = self } )
	obj.gridPos = gridPos;
	obj.offsetX = offsetX;
	obj.offsetY = offsetY;
	obj.width = width;
	obj.height = height;
	obj.color = color;
	obj.isVisible = isVisible;
	obj.uvs = uvs;
	obj.graphic = createImageOverlay(Utils.getFilename("img/"..graphic..".dds", SowingSupp.path));
	obj.renderMe = function (grid, container)
		if obj.isVisible and grid.table[obj.gridPos] ~= nil then
			local baseHeight = SowingSupp.baseHeight;
			local baseWidth = SowingSupp.baseHeight;
			local yOffsetIcon = baseHeight * 0.15;
			if obj.graphic ~= nil then
				if obj.uvs ~= nil then
					local u0,v0,u1,v1,u2,v2,u3,v3 = obj.uvs[1],obj.uvs[2],obj.uvs[3],obj.uvs[4],obj.uvs[5],obj.uvs[6],obj.uvs[7],obj.uvs[8];
					setOverlayUVs(obj.graphic, u0,v0,u1,v1,u2,v2,u3,v3 );
				end;
				if obj.color ~= nil then
					local r,g,b,a = obj.color[1],obj.color[2],obj.color[3],obj.color[4];
					setOverlayColor(obj.graphic, r,g,b,a);
				end;
				renderOverlay(obj.graphic, grid.table[obj.gridPos].x + (container.width * obj.offsetX), grid.table[obj.gridPos].y + (container.height * obj.offsetY), container.width*obj.width, container.height*obj.height);
			end;
		end;
	end;
	return obj;
end;

-- Create object "buttonSet"
SowingSupp.buttonSet = {}
function SowingSupp.buttonSet:New ( functionToCall, style, gridPos, graphic)
	local obj = setmetatable ( { }, { __index = self } )
	obj.button1IsActive = true;
	obj.button2IsActive = true;

  -- Create button graphics
	obj.overlays = {};
	if style == "plusminus" then -- plus minus
		obj.overlays.overlayMinus = createImageOverlay(Utils.getFilename("img/button_Minus.dds", SowingSupp.path));
		obj.overlays.overlayPlus = createImageOverlay(Utils.getFilename("img/button_Plus.dds", SowingSupp.path));

	elseif style == "arrow" then -- vor zurück
		obj.overlays.overlayMinus = createImageOverlay(Utils.getFilename("img/button_Left.dds", SowingSupp.path));
		obj.overlays.overlayPlus = createImageOverlay(Utils.getFilename("img/button_Right.dds", SowingSupp.path));

	elseif style == "toggle" then -- toggle
		obj.overlays.overlayToggleOff = createImageOverlay(Utils.getFilename("img/2_"..graphic..".dds", SowingSupp.path));
		obj.overlays.overlayToggleOn = createImageOverlay(Utils.getFilename("img/1_"..graphic..".dds", SowingSupp.path));

	elseif style == "option" then -- option on/off
		obj.overlays.overlayToggleOptionOff = createImageOverlay(Utils.getFilename("img/2_"..graphic..".dds", SowingSupp.path));
		obj.overlays.overlayToggleOptionOn = createImageOverlay(Utils.getFilename("img/1_"..graphic..".dds", SowingSupp.path));

	elseif style == "push" then -- push button
		obj.overlays.overlayPush = createImageOverlay(Utils.getFilename("img/1_"..graphic..".dds", SowingSupp.path));

	elseif style == "titleBar" then -- title Bar
		obj.overlays.overlayRowBg = createImageOverlay(Utils.getFilename("img/row_bg.dds", SowingSupp.path));
		obj.overlays.overlayConfig = createImageOverlay(Utils.getFilename("img/button_Config.dds", SowingSupp.path));
		obj.overlays.overlayClose = createImageOverlay(Utils.getFilename("img/button_Close.dds", SowingSupp.path));
	end;

	-- Create button click areas
	obj.areas = { plus = {}, minus = {}, toggle = {}, titleBar = {}, titleBarMove = {}};
	local baseHeight = SowingSupp.baseHeight;
	local baseWidth = SowingSupp.baseWidth;
	if style == "plusminus" or style == "arrow" then -- plus minus & arrow
		local iconHeight = .5 * baseHeight;
		local iconWidth = iconHeight / g_screenAspectRatio;
		local yOffsetIcon = baseHeight * 0.15;
		obj.areas.minus.xMin = -1.5*iconWidth;
		obj.areas.minus.xMax = -.5*iconWidth;
		obj.areas.minus.yMin = yOffsetIcon;
		obj.areas.minus.yMax = yOffsetIcon + iconHeight;
		obj.areas.plus.xMin = .5*iconWidth;
		obj.areas.plus.xMax = 1.5*iconWidth;
		obj.areas.plus.yMin = obj.areas.minus.yMin;
		obj.areas.plus.yMax = obj.areas.minus.yMax;
	elseif style == "toggle" or style == "push" then
		local iconWidth = 1.1*baseWidth;
		obj.areas.toggle.xMin = -iconWidth/2;
		obj.areas.toggle.xMax =  iconWidth/2;
		obj.areas.toggle.yMin = .2 * baseHeight;
		obj.areas.toggle.yMax = 1.25 * baseHeight;
	elseif style == "option" then
		local iconWidth = .6 * baseWidth;
		local offsetIcon = baseHeight * 0.1;
		obj.areas.toggle.xMin = offsetIcon;
		obj.areas.toggle.xMax = offsetIcon + iconWidth;
		obj.areas.toggle.yMin = .1 * baseHeight;
		obj.areas.toggle.yMax = .8 * baseHeight;
	elseif style == "titleBar" then
		local iconWidth = .5 * baseWidth;
		local offsetIcon = baseHeight * 0.15;
		obj.areas.titleBar.xMin = offsetIcon;
		obj.areas.titleBar.xMax = offsetIcon + iconWidth;
		obj.areas.titleBar.yMin = .15 * baseHeight;
		obj.areas.titleBar.yMax = .85 * baseHeight;
		obj.areas.titleBarMove.xMin = iconWidth + 3 * offsetIcon;
		obj.areas.titleBarMove.xMax = iconWidth + 3 * offsetIcon;
		obj.areas.titleBarMove.yMin =  .1 * baseHeight;
		obj.areas.titleBarMove.yMax = .9 * baseHeight;
	end;
	return obj
end;

-- Create mouseEvents & call functions
function SowingSupp.guiElement:mouseEvent(grid, container, vehicle, posX, posY, isDown, isUp, button)
	local baseHeight = SowingSupp.baseHeight;
	local baseWidth = SowingSupp.baseHeight;
	if self.isVisible then
		local dlHudchangedJet = false;
		if self.style == "plusminus" or self.style == "arrow" then
			if isDown and button == 1 then
				if self.buttonSet.button1IsActive then
					if (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.minus.xMax) > posX
					and (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.minus.xMin) < posX
					and (grid.table[self.gridPos].y + self.buttonSet.areas.minus.yMax) > posY
					and (grid.table[self.gridPos].y + self.buttonSet.areas.minus.yMin) < posY then
						SowingSupp:modules(grid, container, vehicle, self, self.parameter1);
					end;
				end;
				if self.buttonSet.button2IsActive then
					if (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.plus.xMax) > posX
					and (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.plus.xMin) < posX
					and (grid.table[self.gridPos].y + self.buttonSet.areas.plus.yMax) > posY
					and (grid.table[self.gridPos].y + self.buttonSet.areas.plus.yMin) < posY then
						SowingSupp:modules(grid, container, vehicle, self, self.parameter2);
					end;
				end;
			end;
		elseif self.style == "toggle" then
			if isDown and button == 1 then
				if (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.toggle.xMax) > posX
				and (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.toggle.xMin) < posX
				and (grid.table[self.gridPos].y + self.buttonSet.areas.toggle.yMax) > posY
				and (grid.table[self.gridPos].y + self.buttonSet.areas.toggle.yMin < posY) then
					SowingSupp:modules(grid, container, vehicle, self);
				end;
			end;
		elseif self.style == "push" then
			if isDown and button == 1 then
				if (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.toggle.xMax) > posX
				and (grid.table[self.gridPos].x + grid.centerX + self.buttonSet.areas.toggle.xMin) < posX
				and (grid.table[self.gridPos].y + self.buttonSet.areas.toggle.yMax) > posY
				and (grid.table[self.gridPos].y + self.buttonSet.areas.toggle.yMin < posY) then
					SowingSupp:modules(grid, container, vehicle, self);
					setOverlayColor(self.buttonSet.overlays.overlayPush, .5,.5,.5,1);
				end;
			else
				setOverlayColor(self.buttonSet.overlays.overlayPush, 1,1,1,1);	
			end;
		elseif self.style == "option" then
			if isDown and button == 1 then
				if (grid.table[self.gridPos].x + self.buttonSet.areas.toggle.xMax) > posX
				and (grid.table[self.gridPos].x + self.buttonSet.areas.toggle.xMin) < posX
				and (grid.table[self.gridPos].y + self.buttonSet.areas.toggle.yMax) > posY
				and (grid.table[self.gridPos].y + self.buttonSet.areas.toggle.yMin < posY) then
					SowingSupp:modules(grid, container, vehicle, self);
				end;
			end;
		elseif self.style == "titleBar" then
			if isDown and button == 1 then
				if container.move then
					container.move = false;
					dlHudchangedJet = true;
				end;
				if not dlHudchangedJet then
					if (grid.table[self.gridPos].x + grid.rightX - self.buttonSet.areas.titleBarMove.xMax) > posX
					and (grid.table[self.gridPos].x + self.buttonSet.areas.titleBarMove.xMin) < posX
					and (grid.table[self.gridPos].y + self.buttonSet.areas.titleBarMove.yMax) > posY
					and (grid.table[self.gridPos].y + self.buttonSet.areas.titleBarMove.yMin) < posY then
						container.move = true;
					end;
				end;
				if self.buttonSet.button1IsActive then
					if (grid.table[self.gridPos].x + self.buttonSet.areas.titleBar.xMax) > posX
					and (grid.table[self.gridPos].x + self.buttonSet.areas.titleBar.xMin) < posX
					and (grid.table[self.gridPos].y + self.buttonSet.areas.titleBar.yMax) > posY
					and (grid.table[self.gridPos].y + self.buttonSet.areas.titleBar.yMin) < posY then
						SowingSupp:modules(grid, container, vehicle, self, self.parameter1);
					end;
				end;
				if self.buttonSet.button2IsActive then
					local iconHeight = .6*baseHeight;
					local iconWidth = .8 * baseHeight / g_screenAspectRatio;
					local offsetIcon = baseHeight * 0.2;
					if (grid.table[self.gridPos].x + grid.rightX - offsetIcon - iconWidth + self.buttonSet.areas.titleBar.xMax) > posX
					and (grid.table[self.gridPos].x + grid.rightX - offsetIcon - iconWidth + self.buttonSet.areas.titleBar.xMin) < posX
					and (grid.table[self.gridPos].y + self.buttonSet.areas.titleBar.yMax) > posY
					and (grid.table[self.gridPos].y + self.buttonSet.areas.titleBar.yMin) < posY then
						SowingSupp:modules(grid, container, vehicle, self, self.parameter2);
					end;
				end;
			end;
		end;
	end;
end;
