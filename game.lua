
local composer = require( "composer" )
local widget = require( "widget" )
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local backGroup, gridGroup, cellValGroup, controlGroup, infoGroup, draftGroup, draftSubGroup, timerText, timerID
local timerValue = 0
local rows = 9 --Matrix 9x9
local draftMode = 0
local colors =
{
	aquamarine = {217/255, 255/255, 212/255},
	black = {0, 0, 0},
	blue = { 153/255, 204/255, 255/255 },
	dodgerblue = { 30/255, 144/255, 255/255 },
	gray = {230/255, 230/255, 230/255},
	green = { 0/255, 153/255, 51/255 },
	lightcyan = {224/255, 255/255, 255/255},
	powderblue = {176/255, 224/255, 230/255},
	red = {255/255, 0, 0},
	silver = {192/255, 192/255, 192/255},
	skyblue = {135/255, 206/255, 235/255},
	white = {1, 1, 1}
}
local defaultGridValue =
{
	{1,2,3,4,5,6,7,8,9},
	{4,5,6,7,8,9,1,2,3},
	{7,8,9,1,2,3,4,5,6},
	{2,3,1,5,6,4,8,9,7},
	{5,6,4,8,9,7,2,3,1},
	{8,9,7,2,3,1,5,6,4},
	{3,1,2,6,4,5,9,7,8},
	{6,4,5,9,7,8,3,1,2},
	{9,7,8,3,1,2,6,4,5}
}
local blockCells =
{
	blocks =
	{
		{1,2,3,10,11,12,19,20,21},
		{4,5,6,13,14,15,22,23,24},
		{7,8,9,16,17,18,25,26,27},
		{28,29,30,37,38,39,46,47,48},
		{31,32,33,40,41,42,49,50,51},
		{34,35,36,43,44,45,52,53,54},
		{55,56,57,64,65,66,73,74,75},
		{58,59,60,67,68,69,76,77,78},
		{61,62,63,70,71,72,79,80,81}
	}
}
local chosenCell = 0
local sudokuTable = {}

local function buildInfoPanel()
	local options =
	{
		text = "00:00",
		x = 80,
		y = -80,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	}
	timerText = display.newText( options )
	timerText:setFillColor( unpack( colors.black ) )
	infoGroup:insert(timerText)

	local arrow = display.newImageRect( infoGroup, "undo.png", 50, 50 )
	arrow.x = 700
	arrow.y = -80

end

local setTimer = function()
	timerValue = timerValue + 1
	local minutes = timerValue / 60
	local seconds = timerValue % 60
	if (minutes < 10) then minutes = "0" + minutes end;
    if (seconds < 10) then seconds = "0" + seconds end;
	timerText.text = string.format("%02d:%02d", minutes, seconds)
end

--Set defauld colors for cells
local function setDefaultCellColor()
	for i = 1, 81, 1 do
		gridGroup[i]:setFillColor( unpack( gridGroup[i].fillColor ) )
	end
end

local function setCellTouchFocus(id)
	if (chosenCell ~= id) then
		setDefaultCellColor()
		chosenCell = id
		if (chosenCell > 0 and cellValGroup[chosenCell].available == true) then
			for i = 1, 12, 1 do
				controlGroup[i]:setEnabled(true)
				controlGroup[i].alpha = 1
			end
		else
			for i = 1, 12, 1 do
				controlGroup[i]:setEnabled(false)
				controlGroup[i].alpha = 0.6
			end
		end
		local cellForColor
		for i = 1, 2, 1 do
			if (i < 2) then
				cellForColor = ((math.ceil(chosenCell / 9) - 1) * 9) --Paint row
				for j = 1, 9, 1 do
					gridGroup[cellForColor + j]:setFillColor( unpack( colors.lightcyan ) )
				end
			else
				local remainder = 1
				cellForColor = (chosenCell % 9)
				if (cellForColor == 0) then remainder = 0 end
				for j = 1, 9, 1 do
					gridGroup[cellForColor + (9 * (j - remainder))]:setFillColor( unpack( colors.lightcyan ) ) --Paint column
				end
			end
		end
		gridGroup[chosenCell]:setFillColor( unpack( colors.powderblue ) ) --Paint chosen cell
	end
end

-- Function to handle cell touch event
local function editCellValue(event)
	local cell = event.target
	local phase = event.phase
	if ( "began" == phase ) then
		setCellTouchFocus(cell.id)
	elseif ( "moved" == phase ) then
		setCellTouchFocus(event.target.id)
	end
end

local function buildGrid()
	local cellSize = display.contentWidth / rows

	--Create cells
	local rect, yShift
	for i = 1, rows, 1 do
		yShift = cellSize * (i - 1)
		rect = display.newRect( gridGroup, display.contentCenterX - (cellSize * 4), yShift, cellSize - 6, cellSize - 6)
		rect.strokeWidth = 3
		rect:setStrokeColor( unpack( colors.silver ) )
		if (i < 4) or (6 < i) then
			rect:setFillColor( unpack( colors.gray ) )
			rect.fillColor = colors.gray
		else
			rect.fillColor = colors.white
		end

		for j = 1, rows - 1, 1 do
			rect = display.newRect( gridGroup, rect.x + cellSize, yShift, cellSize - 6, cellSize - 6 )
			rect.strokeWidth = 3
			rect:setStrokeColor( unpack( colors.silver ) )
			if ((i < 4) and (j < 3 or 5 < j)) or
				((6 < i) and (j < 3 or 5 < j)) or
				((3 < i and i < 7) and (2 < j and j < 6)) then
					rect:setFillColor( unpack( colors.gray ) )
					rect.fillColor = colors.gray
			else
				rect.fillColor = colors.white
			end
		end
	end
	--Create lines
	--[=====[
	local x1, x2, x3, x4, y1, y2, y3, y4
	x1 = gridGroup[1].x - cellSize / 2
	x2 = cellSize * 3
	x3 = cellSize * 6
	x4 = gridGroup[81].x + cellSize / 2
	y1 = gridGroup[1].y - cellSize / 2
	y2 = cellSize * 2.5
	y3 = cellSize * 5.5
	y4 = gridGroup[81].y + cellSize / 2
	local coordTable =
	{
		{x1, y2, x4, y2},
		{x1, y3, x4, y3},
		{x2, y1, x2, y4},
		{x3, y1, x3, y4}
	}
	local line
	for i = 1, #coordTable, 1 do
		line = display.newLine( gridGroup, unpack( coordTable[i] ) )
		line:setStrokeColor( unpack( colors.black ) )
		line.strokeWidth = 6
	end
	--]=====]
	--Fill cells
	local cellValue, options, currentObject
	for i = 1, ( rows * rows ), 1 do
		currentObject = gridGroup[i]
		options =
		{
			text = "", --defaultGridValue[math.ceil(i / 9)][((i - 1) % 9) + 1],
			x = currentObject.x,
			y = currentObject.y,
			width = currentObject.width,
			height = currentObject.height * 0.7,
			font = native.systemFont,
    		fontSize = 50,
			align = "center"
		}
		cellValue = display.newText( options )
		cellValue:setFillColor( unpack( colors.black ) )
		cellValue.id = i
		cellValGroup:insert(cellValue)
		cellValue:addEventListener( "touch", editCellValue)
	end

	--Fill draft cells

	local parent, draftCellWidth, draftOptions, draftX, draftY, draftVal
	for k = 1, (rows * rows), 1 do
		parent = gridGroup[k]
		draftCellWidth = parent.width / 3
		draftGroup:insert(display.newGroup())
		draftVal = 1
		for i = 1, 3, 1 do
			for j = 1, 3, 1 do
				if (i == 1) then draftY = parent.y - draftCellWidth
				elseif (i == 2) then draftY = parent.y
				else draftY = parent.y + draftCellWidth
				end
				if (j == 1) then draftX = parent.x - draftCellWidth
				elseif (j == 2) then draftX = parent.x
				else draftX = parent.x + draftCellWidth
				end
				draftOptions =
				{
					text = "",
					x = draftX,
					y = draftY,
					width = draftCellWidth,
					height = draftCellWidth,
					font = native.systemFont,
					fontSize = 25,
					align = "center"
				}
				draftCellValue = display.newText( draftOptions )
				draftCellValue:setFillColor( unpack( colors.black ))
				draftGroup[k]:insert(draftCellValue)
				draftVal = draftVal + 1
			end
		end
	end
end

local function shuffleNums()
	local numsTable = {1,2,3,4,5,6,7,8,9}
	local shuffledNumTable = {}
	local tableLength = 9
	local randomIndex
	--Shuffle numTable
	for i = 1, 9, 1 do
		randomIndex = math.random(1, tableLength)
		table.insert(shuffledNumTable, numsTable[randomIndex])
		table.remove(numsTable, randomIndex)
		tableLength = tableLength - 1
	end
	return shuffledNumTable
end

local function existsInRowOrColumn(curCell, curNum, selfNum)
	if (selfNum ~= nil) then sudokuTable[selfNum] = 0 end
	local rowHead = ((math.ceil(curCell / 9) - 1) * 9)
	local columnHead = (curCell % 9)
	for i = 1, 9, 1 do
		if ((rowHead + i) == curCell) then
			break
		else
			if (sudokuTable[rowHead + i] == curNum) then
				if (selfNum ~= nil) then sudokuTable[selfNum] = curNum end
				return true
			end
		end
	end
	local remainder = 1
	if (columnHead == 0) then remainder = 0 end
	for i = 1, 9, 1 do
		if ((columnHead + (9 * (i - remainder))) == curCell) then
			break
		else
			if (sudokuTable[columnHead + (9 * (i - remainder))] == curNum) then
				if (selfNum ~= nil) then sudokuTable[selfNum] = curNum end
				return true
			end
		end
	end
	if (selfNum ~= nil) then sudokuTable[selfNum] = curNum end
	return false
end

local function getBlockNumber(curCell)
	local found = false
	for i = 1, #blockCells.blocks, 1 do
		for j = 1, #blockCells.blocks[i], 1 do
			if (blockCells.blocks[i][j] == curCell) then found = true end
		end
		if (found) then return i end
	end
	return 0
end

local function isUniqueTable(table)
	for i = 1, #table, 1 do
		if (table[i] == 0) then return false end
	end
	return true
end

local function validRow(rowCell, checkUniqueness)
	local summ = 0
	local uniquenessTable = {0,0,0,0,0,0,0,0,0}
	local num, rowHead
	if (rowCell ~= nil) then
		rowHead = ((math.ceil(rowCell / 9) - 1) * 9)
		for i = 1, 9, 1 do
			num = cellValGroup[rowHead + i].text
			if (num == "") then
				num = 0
			else
				num = tonumber( num )
				if (checkUniqueness and uniquenessTable[num] == 1) then return false end
				uniquenessTable[num] = 1
			end
			summ = summ + num
		end
		if (checkUniqueness) then return true end
		if (summ ~= 45 or not isUniqueTable(uniquenessTable)) then return false end
	else
		for i = 1, 81, 1 do --Check validity of all rows.
			num = sudokuTable[i]
			if (num ~= 0) then uniquenessTable[num] = 1 end
			summ = summ + num
			if (i % 9 == 0) then
				if (summ ~= 45 or not isUniqueTable(uniquenessTable)) then return false end
				summ = 0
				uniquenessTable = {0,0,0,0,0,0,0,0,0}
			end
		end
	end
	return true
end

local function validCulumn(columnCell, checkUniqueness)
	local summ = 0
	local uniquenessTable = {0,0,0,0,0,0,0,0,0}
	local num, columnHead
	if (columnCell ~= nil) then
		columnHead = columnCell % 9
		if (columnHead == 0) then columnHead = 9 end
		for i = 1, 9, 1 do
			num = cellValGroup[columnHead + (9 * (i - 1))].text
			if (num == "") then
				num = 0
			else
				num = tonumber( num )
				if (checkUniqueness and uniquenessTable[num] == 1) then return false end
				uniquenessTable[num] = 1
			end
			summ = summ + num
		end
		if (checkUniqueness) then return true end
		if (summ ~= 45 or not isUniqueTable(uniquenessTable)) then return false end
	else
		for i = 1, 9, 1 do --Check validity of all columns.
			for j = 1, 9, 1 do
				num = sudokuTable[i + (9 * (j - 1))]
				if (num ~= 0) then uniquenessTable[num] = 1 end
				summ = summ + num
			end
			if (summ ~= 45 or not isUniqueTable(uniquenessTable)) then return false end
			summ = 0
			uniquenessTable = {0,0,0,0,0,0,0,0,0}
		end
	end
	return true
end

local function validBlock(blockNumber, liveCheck, checkUniqueness)
	local summ = 0
	local uniquenessTable = {0,0,0,0,0,0,0,0,0}
	local num
	if (blockNumber ~= nil) then --Check validity of only one block.
		for i = 1, #blockCells.blocks[blockNumber], 1 do
			if (liveCheck) then
				num = cellValGroup[blockCells.blocks[blockNumber][i]].text
				if (num == "") then
					num = 0
				else
					num = tonumber( num )
					if (checkUniqueness and uniquenessTable[num] == 1) then return false end
					uniquenessTable[num] = 1
				end
			else
				num = sudokuTable[blockCells.blocks[blockNumber][i]]
				if (num ~= 0) then uniquenessTable[num] = 1 end
			end
			summ = summ + num
		end
		if (checkUniqueness) then return true end
		if (summ ~= 45 or not isUniqueTable(uniquenessTable)) then return false end
	else
		for i = 1, #blockCells.blocks, 1 do --Check validity of all block.
			for j = 1, #blockCells.blocks[i], 1 do
				num = sudokuTable[blockCells.blocks[i][j]]
				if (num ~= 0) then uniquenessTable[num] = 1 end
				summ = summ + num
			end
			if (summ ~= 45 or not isUniqueTable(uniquenessTable)) then return false end
			summ = 0
			uniquenessTable = {0,0,0,0,0,0,0,0,0}
		end
	end
	return true
end

local function validGrid()
	return (validRow() and validCulumn() and validBlock())
end

local function validLiveGrid()
	local text
	for i = 1, #sudokuTable, 1 do
		text = cellValGroup[i].text
		if (text == "" or tonumber( text ) ~= sudokuTable[i]) then return false end
	end
	return true
end

local function generateSudoku()
	for i = 1, cellValGroup.numChildren, 1 do
		table.insert( sudokuTable, 0 )
	end
	local numsTable, currentCell, swaped
	while (not validGrid()) do
		for i = 1, #blockCells.blocks, 1 do
			numsTable = shuffleNums()
			for j = 1, #blockCells.blocks[i], 1 do
				currentCell = blockCells.blocks[i][j]
				for k = 1, #numsTable, 1 do
					if (not existsInRowOrColumn(currentCell, numsTable[k])) then
						sudokuTable[currentCell] = numsTable[k]
						table.remove( numsTable, k )
						break
					elseif (k == #numsTable) then
						for m = 1, j, 1 do
							swaped = false
							for n = 1, #numsTable, 1 do
								if (not existsInRowOrColumn(currentCell, sudokuTable[blockCells.blocks[i][m]], blockCells.blocks[i][m]) and
									not existsInRowOrColumn(blockCells.blocks[i][m], numsTable[n])) then
									sudokuTable[currentCell] = sudokuTable[blockCells.blocks[i][m]]
									sudokuTable[blockCells.blocks[i][m]] = numsTable[n]
									table.remove( numsTable, n )
									swaped = true
									break
								end
							end
							if (swaped) then break end
						end
					end
				end
			end
			if (not validBlock(i)) then --If the current block is not valid, then stop processing and start from the very beginning.
				for p = 1, #sudokuTable, 1 do
					sudokuTable[p] = 0
				end
				break
			end
		end
	end
	for i = 1, cellValGroup.numChildren, 1 do --Fill the grid from sudoku table
		cellValGroup[i].text = sudokuTable[i]
	end
	local cutTable = {}
	for i = 1, 81, 1 do
		table.insert( cutTable, i )
	end
	local rnd
	for i = 1, 5, 1 do
		rnd = math.random(1, #cutTable)
		cellValGroup[cutTable[rnd]].text = ""
		cellValGroup[cutTable[rnd]].available = true
		cellValGroup[cutTable[rnd]]:setFillColor(unpack( colors.dodgerblue ))
		table.remove(cutTable, rnd)
	end
end

local function paintStroke(event)
	local params = event.source.params
	if (params.mode == 0) then
		gridGroup[params.index]:setStrokeColor(unpack( colors.green ))
		gridGroup[params.index].strokeWidth = 4
	else
		gridGroup[params.index]:setStrokeColor(unpack( colors.silver ))
		gridGroup[params.index].strokeWidth = 3
	end
end

local function completeEffect(curCell, forRow, forColumn, forBlock)
	local whiteTimer, silverTimer, rowHead, columnHead, neededBlock
	if (forRow) then
		rowHead = ((math.ceil(curCell / 9) - 1) * 9)
		for i = 1, 9, 1 do
			whiteTimer = timer.performWithDelay( 500 + i * 10,  paintStroke)
			whiteTimer.params = {index = rowHead + i, mode = 0}
			silverTimer = timer.performWithDelay( 1000 + i * 10,  paintStroke)
			silverTimer.params = {index = rowHead + i, mode = 1}
		end
	end
	if (forColumn) then
		columnHead = curCell % 9
		if (columnHead == 0) then columnHead = 9 end
		for i = 1, 9, 1 do
			whiteTimer = timer.performWithDelay( 500 + i * 10,  paintStroke)
			whiteTimer.params = {index = columnHead + (9 * (i - 1)), mode = 0}
			silverTimer = timer.performWithDelay( 1000 + i * 10,  paintStroke)
			silverTimer.params = {index = columnHead + (9 * (i - 1)), mode = 1}
		end
	end
	if (forBlock) then
	 	neededBlock = blockCells.blocks[getBlockNumber(curCell)]
		for i = 1, 9, 1 do
			whiteTimer = timer.performWithDelay( 500 + i * 10,  paintStroke)
			whiteTimer.params = {index = neededBlock[i], mode = 0}
			silverTimer = timer.performWithDelay( 1000 + i * 10,  paintStroke)
			silverTimer.params = {index = neededBlock[i], mode = 1}
		end
	end
end

local function clearDraft()
	for i = 1, draftGroup[chosenCell].numChildren, 1 do
		draftGroup[chosenCell][i].text = ""
	end
end
-- Function to handle button events
local function handleButtonEvent( event )
	if ("moved" == event.phase and event.target:getLabel() ~= "") then
		--print(event.x)
	elseif ( "ended" == event.phase ) then
		local label = event.target:getLabel()
		if (label ~= "" and chosenCell ~= 0 ) then
			if (draftMode == 0) then
				if cellValGroup[chosenCell].text ~= label then
					clearDraft()
					cellValGroup[chosenCell].text = label
					if (not validRow(chosenCell, true) or
						not validCulumn(chosenCell, true) or
						not validBlock(getBlockNumber(chosenCell), true, true)) then
							cellValGroup[chosenCell]:setFillColor(unpack( colors.red ))
					else
						cellValGroup[chosenCell]:setFillColor(unpack( colors.dodgerblue ))
						completeEffect(chosenCell, validRow(chosenCell), validCulumn(chosenCell), validBlock(getBlockNumber(chosenCell), true))
						if (validLiveGrid()) then
							timer.pause( timerID )
							native.showAlert( "title", "OK" )
						end
					end

				else
					cellValGroup[chosenCell].text = ""
				end
			else
				cellValGroup[chosenCell].text = ""
				if (draftGroup[chosenCell][tonumber( label )].text == "") then
					draftGroup[chosenCell][tonumber( label )].text = label
				else
					draftGroup[chosenCell][tonumber( label )].text = ""
				end
			end
		elseif (event.target.id == "eraser" and chosenCell ~= 0) then
			clearDraft()
			cellValGroup[chosenCell].text = ""
		elseif (event.target.id == "pensil") then
			if (draftMode == 0) then
				draftMode = 1 --Draft mode on
				controlGroup[10]:setFillColor( unpack( colors.blue ))
				controlGroup[10].currentColor = colors.blue
			else
				draftMode = 0 --Draft mode off
				controlGroup[10]:setFillColor( unpack( colors.white ))
				controlGroup[10].currentColor = colors.white
			end
		end
    end
end

local function buildButtonPanel()
	local button, yShift
	local tmpIndex = 1
	local buttonSize = display.contentWidth / 6
	local options =
	{
		onEvent = handleButtonEvent,
		isEnabled = false,
		font = native.systemFont,
	    fontSize = 80,
		labelColor = { default = colors.black, over = colors.green },
		-- Properties for a rounded rectangle button
		shape = "roundedRect",
		width = buttonSize - 6,
		height = buttonSize - 6,
		cornerRadius = 2,
		fillColor = { default = colors.white, over = colors.blue },
		strokeColor = { default = colors.silver, over = colors.silver },
		strokeWidth = 3
	}
	for i = 1, 2, 1 do
		yShift = buttonSize * (i - 1) + (gridGroup[81].y + buttonSize)
		options["left"] = display.contentCenterX - (buttonSize * 3)
		options["top"] = yShift
		button = widget.newButton( options )
		button.alpha = 0.6
		button:setLabel(defaultGridValue[1][tmpIndex])
		tmpIndex = tmpIndex + 1
		controlGroup:insert(button)
		for j = 1, 5, 1 do
			options["left"] = button.x + buttonSize * 0.5
			options["top"] = yShift
			button = widget.newButton( options )
			button.alpha = 0.6
			if (tmpIndex <= 9) then button:setLabel(defaultGridValue[1][tmpIndex]) end
			tmpIndex = tmpIndex + 1
			controlGroup:insert(button)
		end
	end
	local imgTable = { "pensil", "eraser", "bulb" }
	local pictogram
	for i = 1, 3, 1 do
		pictogram = display.newImageRect( controlGroup, imgTable[i] .. ".png", buttonSize / 2, buttonSize / 2 )
		pictogram.x = controlGroup[i - 1 + 10].x
		pictogram.y = controlGroup[i - 1 + 10].y
		controlGroup[i - 1 + 10].id = imgTable[i]
		controlGroup[i - 1 + 10].currentColor = colors.white
	end
end



-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	-- Set up display groups
	backGroup = display.newGroup() --Display group for the background image
	sceneGroup:insert(backGroup)

	gridGroup = display.newGroup() --Display group for the grid
	sceneGroup:insert(gridGroup)

	cellValGroup = display.newGroup() --Display group for the cells values
	sceneGroup:insert(cellValGroup)

	controlGroup = display.newGroup() --Display group for the control buttons
	sceneGroup:insert(controlGroup)

	infoGroup = display.newGroup() --Display group for the information on game mode and status
	sceneGroup:insert(infoGroup)

	draftGroup = display.newGroup() --Display group for the draft cells
	sceneGroup:insert(draftGroup)

	-- Load the background
    local background = display.newImageRect( backGroup, "background.png", 800, 1400 )
    background.x = display.contentCenterX
    background.y = display.contentCenterY

	buildInfoPanel()
	buildGrid()
	buildButtonPanel()
	generateSudoku()

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		timerID = timer.performWithDelay( 1000, setTimer, -1)
		physics.start()


	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)


	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		physics.pause()
		composer.removeScene( "game" )



	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view


end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
