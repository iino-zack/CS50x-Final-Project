-- Initalise required modules/assets
require("modules/buttons")

-- Define constants
local PERFORMANCE_MODE = true
local SHOW_DEBUGGING_INFO = false

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1920, 1080
local WINDOW_WIDTH, WINDOW_HEIGHT = love.graphics.getDimensions()

local WINDOW_SCALE_X, WINDOW_SCALE_Y = WINDOW_WIDTH / VIRTUAL_WIDTH, WINDOW_HEIGHT / VIRTUAL_HEIGHT

local GLOBAL_IMAGE_SCALE = 0.69

local DEFINITE_CANNONBALL_OFFSET_X, DEFINITE_CANNONBALL_OFFSET_Y = 0, 0
local DEFINITE_CANNON_OFFSET_X, DEFINITE_CANNON_OFFSET_Y = 200, 400

local DEGREES_TO_RADIANS = math.pi / 180
local RADIANS_TO_DEGREES = 1 / DEGREES_TO_RADIANS

-- 30 pixels : 1 pixel | this is basically just SIMULATION_SPEED
local PIXEL_SCALE = 30

-- 0.0f to 1.0f
local SIMULATION_SPEED = 1
local MAX_LIFETIME = 10

-- Define variables

local helpMenuOpened = false
-- 1 = menu, 2 = paused, 3 = playing
local gameState = 1
-- 1 = easy | 2 = hard | 3 = extreme
local currentDifficulty = 1

local currentCannon, currentMonkey

local currentGravity = 9.81
local airDensity = 1.2 -- kg/px^3
local dragCoefficient = 0.5
local surfaceArea = 0.01

local generatedVelocity, generatedMass

local cannonballsFired = 0
local scoreCount = 0
local timeOfInterception = 0

local activeCannonballs = {}
local activeVisuals = {}

-- Functions

-- Creates and returns a new cannon struct
-- @return table { cannonBase, CannonWheel }
local function createCannon()
	local newCannonBase = {
		image = love.graphics.newImage("assets/cannon.png"),
		orientation = 0, -- in degrees
		x = 0,
		y = 0,
	}

	local newCannonWheel = {
		image = love.graphics.newImage("assets/wheel.png"),
		orientation = 0, -- in degrees
		x = 0,
		y = 0,
	}

	return {
		newCannonBase,
		newCannonWheel,
	}
end

-- Creates and returns a new monkey struct
-- @return table { cannonBase, CannonWheel }
local function createMonkey()
	local newImage = love.graphics.newImage("assets/monke.png")

	return {
		image = newImage,
		initalVelocity = 0, -- in px/s
		mass = math.random(1, 10), -- in kilograms
		vx = currentDifficulty > 1 and (math.random(-20, 20) + 0.01) * currentDifficulty / 2 or 0.01, --math.random(-80, 80),
		vy = currentDifficulty > 1 and (math.random(-20, 20) + 0.01) * currentDifficulty / 2 or 0.01,
		x = math.random(0, WINDOW_WIDTH - (newImage:getWidth() * WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE)),
		y = 0,
		lifetime = 0,
		destroyed = false,
		active = false,
	}
end

-- Function used to set up a new game environment, randomising and generating new values to be solved
local function setupNewGame()
	currentMonkey = createMonkey()

	generatedVelocity = math.random(80, 150)
	generatedMass = math.random(1, 10)

	if currentDifficulty == 3 then
		currentGravity = math.random(100, 1000) / 100
		airDensity = math.random(80, 120) / 100
		dragCoefficient = math.random(1, 100) / 100
		surfaceArea = math.random(1, 10) / 1000
	end
end

-- Modified AABB function used to check for hit collision provided Cannonball `cannonball` and Monkey `monkey`
-- @param cannonball { image: Image, x: number, y: number, any? } Cannonball table struct
-- @param monkey { image: Image, x: number, y: number, any? } Monkey table struct
local function checkBallMonkeyCollision(cannonball, monkey)
	local x1, y1 = cannonball.x, cannonball.y
	local w1, h1 = cannonball.image:getWidth(), cannonball.image:getHeight()

	local x2, y2 = monkey.x, monkey.y
	local w2, h2 = monkey.image:getWidth(), monkey.image:getHeight()

	-- im sorry this is jank af

	x1 = x1
	x2 = x2 * WINDOW_SCALE_X
	w1 = w1 * WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE
	w2 = w2 * WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE

	y1 = y1
	y2 = y2 * WINDOW_SCALE_Y
	h1 = h1 * WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE
	h2 = h2 * WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE

	return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

-- Update the cannon's orientation to point towards mouse position or `currentMonkey` position depending on gameState
local function pivotCannon()
	if not currentCannon then
		return
	end

	local cannonBase = currentCannon[1]

	local currentX = cannonBase.x
	local currentY = cannonBase.y

	local mx, my

	if gameState == 1 then
		mx = currentMonkey.x * WINDOW_SCALE_X
		my = currentMonkey.y * WINDOW_SCALE_Y
	elseif gameState == 3 then
		mx, my = love.mouse.getPosition()
	end

	local dx, dy = mx - currentX, my - currentY

	cannonBase.orientation = math.atan2(dy, dx)
end

local function shootCannon()
	if gameState == 1 and currentMonkey.active == true then
		return
	end

	--local fireSound = love.audio.newSource("assets/fire.ogg", "static") -- the "static" tells LÖVE to load the file into memory, good for short sound effects
	--fireSound:play()

	timeOfInterception = 0
	cannonballsFired = cannonballsFired + 1

	local cannonBase = currentCannon[1]

	local currentX = cannonBase.x
	local currentY = cannonBase.y

	local newX = currentX
		+ math.cos(cannonBase.orientation) * 180 * WINDOW_SCALE_X
		+ DEFINITE_CANNONBALL_OFFSET_X * WINDOW_SCALE_X
	local newY = currentY
		+ math.sin(cannonBase.orientation) * 180 * WINDOW_SCALE_Y
		+ DEFINITE_CANNONBALL_OFFSET_Y * WINDOW_SCALE_Y

	table.insert(activeCannonballs, {
		image = love.graphics.newImage("assets/cannonball.png"),
		initalVelocity = generatedVelocity, -- in px/s
		mass = generatedMass, -- in kilograms
		vx = generatedVelocity * math.cos(cannonBase.orientation),
		vy = generatedVelocity * math.sin(cannonBase.orientation),
		x = newX,
		y = newY,
		lifetime = 0,
		destroyed = false,
	})

	currentMonkey.active = true
end

local function calculateAirResistanceForVelocity(velocity)
	local force = 0.5 * airDensity * velocity ^ 2 * dragCoefficient * surfaceArea

	force = force * -1 * velocity / math.abs(velocity)
	return force
end

-- Callback function used to update physics for provided physical data struct
-- @param struct { lifetime: number, mass: number x: number, y: number, vx: number, vy: number } no idea what to call nor define this `cannonball` `currentMonkey` `visualMonkey` struct
-- @param deltaTime number The time elapsed between current frame and previous frame
local function stepPhysics(struct, deltaTime)
	struct.lifetime = struct.lifetime + deltaTime

	local x_force = 0
	local y_force = struct.mass * currentGravity

	-- difficulty hard or above
	if currentDifficulty > 1 then
		x_force = x_force + calculateAirResistanceForVelocity(struct.vx)
		y_force = y_force + calculateAirResistanceForVelocity(struct.vy)
	end

	local x_acceleration = x_force / struct.mass
	local y_acceleration = y_force / struct.mass

	struct.vx = struct.vx + x_acceleration * deltaTime * SIMULATION_SPEED * PIXEL_SCALE
	struct.vy = struct.vy + y_acceleration * deltaTime * SIMULATION_SPEED * PIXEL_SCALE

	struct.x = struct.x + struct.vx * deltaTime * SIMULATION_SPEED * PIXEL_SCALE * WINDOW_SCALE_X
	struct.y = struct.y + struct.vy * deltaTime * SIMULATION_SPEED * PIXEL_SCALE * WINDOW_SCALE_Y
end

-- Callback function used to update activeCannonballs in table `activeCannonballs` provided `deltaTime`
-- @param deltaTime number The time elapsed between current frame and previous frame
local function stepCannonballs(deltaTime)
	for index, cannonball in ipairs(activeCannonballs) do
		if cannonball.lifetime >= MAX_LIFETIME then
			cannonball.destroyed = true
			table.remove(activeCannonballs, index)
			return
		end

		stepPhysics(cannonball, deltaTime)
	end
end

-- Updates the monkey's physics' provided `deltaTime`
-- @param deltaTime number The time elapsed between current frame and previous frame
local function stepMonkey(deltaTime)
	if not currentMonkey then
		return
	end

	if not currentMonkey.active then
		return
	end

	if currentMonkey.lifetime > 3 or currentMonkey.y > WINDOW_HEIGHT then
		setupNewGame()
		return
	end

	stepPhysics(currentMonkey, deltaTime)
end

local function stepVisuals(deltaTime)
	for index, visualMonkey in pairs(activeVisuals) do
		if visualMonkey.lifetime > 3 then
			table.remove(activeVisuals, index)
			return
		end

		if visualMonkey.y > WINDOW_HEIGHT then
			table.remove(activeVisuals, index)
			return
		end

		stepPhysics(visualMonkey, deltaTime)
	end
end

-- This function is called exactly once at the beginning of the game.
function love.load()
	math.randomseed(os.time())

	font = love.graphics.newFont(32)

	table.insert(
		activeButtons,
		createButton("Play", function()
			if gameState == 1 then
				cannonballsFired = 0
				scoreCount = 0
				timeOfInterception = 0
				setupNewGame()
			end
			gameState = 3
		end)
	)

	table.insert(
		activeButtons,
		createButton("Help", function()
			helpMenuOpened = true
		end)
	)

	table.insert(
		activeButtons,
		createButton(
			string.format(
				"Difficulty: %s",
				currentDifficulty == 1 and "Easy"
					or currentDifficulty == 2 and "Hard"
					or currentDifficulty == 3 and "Extreme"
			),
			function()
				currentDifficulty = currentDifficulty + 1

				if currentDifficulty > 3 then
					currentDifficulty = 1
				end

				if currentDifficulty < 3 then
					currentGravity = 9.81
					airDensity = 1.2
					dragCoefficient = 0.5
					surfaceArea = 0.01
				end
			end
		)
	)

	table.insert(
		activeButtons,
		createButton("Quit", function()
			love.event.quit(0)
		end)
	)

	currentCannon = createCannon()
	setupNewGame()

	background = love.graphics.newImage(string.format("assets/background %i.png", math.random(1, 3)))
	background:setWrap("repeat", "repeat")
end

-- Callback function used by the default love.run to update the state of the game every frame.
-- @param deltaTime number The time elapsed between current frame and previous frame
function love.update(deltaTime)
	if gameState == 2 then
		return
	end

	stepCannonballs(deltaTime)
	stepMonkey(deltaTime)
	stepVisuals(deltaTime)

	pivotCannon()

	if gameState == 1 then
		shootCannon()
	end

	if currentMonkey and currentMonkey.active then
		timeOfInterception = timeOfInterception + deltaTime
	end

	for _, cannonball in pairs(activeCannonballs) do
		if not cannonball or cannonball.destroyed then
			return
		end

		if checkBallMonkeyCollision(cannonball, currentMonkey) and currentMonkey.active then
			setupNewGame()

			if gameState == 3 then
				scoreCount = scoreCount + 1
			end

			if PERFORMANCE_MODE then
				return
			end

			table.insert(activeVisuals, {
				image = love.graphics.newImage("assets/dead monke.png"),
				initalVelocity = currentMonkey.initalVelocity,
				mass = currentMonkey.mass,
				vx = math.random(-40, 40),
				vy = math.random(-40, 0),
				x = currentMonkey.x,
				y = currentMonkey.y,
				orientation = 0,
				lifetime = 0,
			})

			return
		end
	end
end

-- Callback function triggered when a key is pressed.
-- @param key KeyConstant Character of the pressed key.
function love.keypressed(key)
	if gameState == 1 then
		return
	end

	if key == "escape" then
		if gameState == 2 then
			gameState = 3
		elseif gameState == 3 then
			gameState = 2
		end
	end
end

-- Callback function used by the default love.run to update the state of the game every frame.
-- @param button number Differentiator for mouse button types, 1 is left mouse button 2 is right moues button and 3 is middle mouse button
function love.mousepressed(_, _, button, _)
	if gameState ~= 3 then
		return
	end

	if button == 1 then
		shootCannon()
	end
end

-- Called when the window is resized, for example if the user resizes the window, or if love.window.setMode is called with an unsupported width or height in fullscreen and the window chooses the closest appropriate size.
-- @param newWidth number The new window width in pixels
-- @param newHeight number The new window height in pixels
function love.resize(newWidth, newHeight)
	WINDOW_WIDTH = newWidth
	WINDOW_HEIGHT = newHeight
	WINDOW_SCALE_X, WINDOW_SCALE_Y = newWidth / VIRTUAL_WIDTH, newHeight / VIRTUAL_HEIGHT
end

-- Callback function used by the default love.run to draw on the screen every frame.
function love.draw()
	local windowSizeX, windowSizeY = love.graphics.getDimensions()

	-- Draws background
	love.graphics.draw(background, 0, 0, 0, WINDOW_SCALE_X, WINDOW_SCALE_Y)

	local cannonBase = currentCannon[1]

	-- Draws visual monkeys
	for _, visualMonkey in ipairs(activeVisuals) do
		if not visualMonkey then
			return
		end

		love.graphics.draw(
			visualMonkey.image,
			visualMonkey.x * WINDOW_SCALE_X,
			visualMonkey.y * WINDOW_SCALE_Y,
			visualMonkey.lifetime * 10,
			WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE,
			WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE,
			visualMonkey.image:getWidth() / 2,
			visualMonkey.image:getHeight() / 2
		)
	end

	-- Draws the monkey
	love.graphics.draw(
		currentMonkey.image,
		currentMonkey.x * WINDOW_SCALE_X,
		currentMonkey.y * WINDOW_SCALE_Y,
		0,
		WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE,
		WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE
	)

	-- Shows bounding box for `currentMonkey` | collision
	if SHOW_DEBUGGING_INFO then
		love.graphics.push("all")

		-- Draws active cannonball's velocity/force vectors

		love.graphics.setColor(0, 255, 0, 255)

		local x1, y1 = currentMonkey.x, currentMonkey.y
		local w1, h1 = currentMonkey.image:getWidth(), currentMonkey.image:getHeight()

		local startX = x1 * WINDOW_SCALE_X + w1 * 0.5 * WINDOW_SCALE_X
		local startY = y1 * WINDOW_SCALE_Y + h1 * 0.5 * WINDOW_SCALE_Y

		local endX = x1 * WINDOW_SCALE_X + w1 * 0.5 * WINDOW_SCALE_X + currentMonkey.vx
		local endY = y1 * WINDOW_SCALE_Y + h1 * 0.5 * WINDOW_SCALE_Y + currentMonkey.vy

		love.graphics.setLineWidth(5)
		-- horizontial velocity component
		love.graphics.line(startX, startY, endX, startY)
		-- vertical velocity component
		love.graphics.line(startX, startY, startX, endY)

		x1 = x1 * WINDOW_SCALE_X
		w1 = w1 * WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE

		y1 = y1 * WINDOW_SCALE_Y
		h1 = h1 * WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE

		love.graphics.circle("fill", x1, y1, 10)
		love.graphics.circle("fill", x1 + w1, y1 + h1, 10)
		love.graphics.circle("fill", x1 + w1, y1, 10)
		love.graphics.circle("fill", x1, y1 + h1, 10)

		love.graphics.pop()
	end

	-- Draws created activeCannonballs
	for index, cannonball in ipairs(activeCannonballs) do
		if not cannonball or cannonball.destroyed then
			return
		end

		love.graphics.draw(
			cannonball.image,
			cannonball.x,
			cannonball.y,
			0,
			WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE,
			WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE
		)

		if SHOW_DEBUGGING_INFO then
			love.graphics.push("all")
			-- Draws active cannonball's velocity/force vectors

			love.graphics.setColor(0, 255, 0, 255)

			local w = cannonball.image:getWidth() / 2
			local h = cannonball.image:getHeight() / 2

			local startX = cannonball.x + w * WINDOW_SCALE_X
			local startY = cannonball.y + h * WINDOW_SCALE_Y

			local endX = cannonball.x + w * WINDOW_SCALE_X + cannonball.vx
			local endY = cannonball.y + h * WINDOW_SCALE_Y + cannonball.vy

			love.graphics.setLineWidth(5)
			-- horizontial velocity component
			love.graphics.line(startX, startY, endX, startY)
			-- vertical velocity component
			love.graphics.line(startX, startY, startX, endY)

			-- Shows active activeCannonballs's simulation values i.e their velocity, position and lifetime
			love.graphics.print(
				string.format(
					"cannonball %.i: | v: %.3gpx/s, %.3gpx/s | p: %.3gpx, %.3gpx | lifetime: %.3gs",
					index,
					cannonball.vx,
					cannonball.vy,
					cannonball.x,
					cannonball.y,
					cannonball.lifetime
				),
				0,
				20 * (index - 1)
			)

			-- Shows bounding box for `cannonball` | collision
			local x1, y1 = cannonball.x, cannonball.y
			local w1, h1 = cannonball.image:getWidth(), cannonball.image:getHeight()

			x1 = x1
			w1 = w1 * WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE

			y1 = y1
			h1 = h1 * WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE

			love.graphics.circle("fill", x1, y1, 10)
			love.graphics.circle("fill", x1 + w1, y1 + h1, 10)
			love.graphics.circle("fill", x1 + w1, y1, 10)
			love.graphics.circle("fill", x1, y1 + h1, 10)
			love.graphics.pop()
		end
	end

	-- Draws cannon and it's components
	for _, cannonComponent in ipairs(currentCannon) do
		local _, imageSizeY = cannonComponent.image:getDimensions()
		local newX = DEFINITE_CANNON_OFFSET_X * WINDOW_SCALE_X
			- math.abs(cannonComponent.orientation) * RADIANS_TO_DEGREES * 0.5 * WINDOW_SCALE_X
		local newY = windowSizeY + DEFINITE_CANNON_OFFSET_Y * WINDOW_SCALE_Y - imageSizeY * WINDOW_SCALE_Y

		cannonComponent.x = newX
		cannonComponent.y = newY

		love.graphics.draw(
			cannonComponent.image,
			newX,
			newY,
			cannonComponent.orientation,
			WINDOW_SCALE_X * GLOBAL_IMAGE_SCALE,
			WINDOW_SCALE_Y * GLOBAL_IMAGE_SCALE,
			cannonComponent.image:getWidth() / 2,
			cannonComponent.image:getHeight() / 2
		)
	end

	if gameState < 3 then
		love.graphics.push("all")
		local buttonWidth = 300 * WINDOW_SCALE_X
		local margin = 16

		local totalHeight = (BUTTON_HEIGHT + margin) * WINDOW_SCALE_Y * #activeButtons
		local offset = 0

		for _, button in ipairs(activeButtons) do
			button.last = button.now

			local x = (windowSizeX * 0.5) - (buttonWidth * 0.5)
			local y = (windowSizeY * 0.5) - (totalHeight * 0.5) + offset

			local mx, my = love.mouse.getPosition()
			local hovered = mx > x and mx < x + buttonWidth and my > y and my < y + BUTTON_HEIGHT

			local colour = { 0.4, 0.4, 0.5, 1 }

			if hovered then
				colour = { 0.8, 0.8, 0.9, 1 }
			end

			button.now = love.mouse.isDown(1)

			if button.now and not button.last and hovered then
				button.func()
			end

			love.graphics.setColor(unpack(colour))

			love.graphics.rectangle("fill", x, y, buttonWidth, BUTTON_HEIGHT)

			love.graphics.setColor(0, 0, 0, 1)

			local textWidth, textHeight = font:getWidth(button.text), font:getHeight(button.text)

			-- goofy ahhh
			if gameState == 2 and button.text:lower():match("play") then
				button.text = "Resume"
			end

			-- goofy bandaid hack
			if button.text:lower():match("difficulty") then
				button.text = string.format(
					"Difficulty: %s",
					currentDifficulty == 1 and "Easy"
						or currentDifficulty == 2 and "Hard"
						or currentDifficulty == 3 and "Extreme"
				)
			end

			--love.graphics.print(button.text, font, (windowSizeX * 0.5) - (textWidth * 0.5), y + textHeight * 0.5)
			love.graphics.printf(
				button.text,
				font,
				x,
				y + textHeight * 0.5,
				buttonWidth / WINDOW_SCALE_X,
				"center",
				0,
				WINDOW_SCALE_X,
				WINDOW_SCALE_Y
			)

			offset = offset + (BUTTON_HEIGHT + margin)
		end
		love.graphics.pop()
	end

	if gameState > 1 then
		-- Shows gameplay info
		love.graphics.print(
			string.format(
				"score: %i | total shots: %i | time of interception: %.3gs | difficulty: %s",
				scoreCount,
				cannonballsFired,
				timeOfInterception,
				currentDifficulty == 1 and "Easy"
					or currentDifficulty == 2 and "Hard"
					or currentDifficulty == 3 and "Extreme"
			),
			0,
			0
		)

		love.graphics.print(
			string.format(
				"orientation: %.3g° | cannonball velocity: %.3gpx/s | cannonball mass: %.3gkg | gravity: %.3gpx/s^2 | air density: %.3gkg/px^3 | drag coefficient: %.3g | global surface area: %.3gpx^2 | cannon pos: %.3gpx, %.3gpx | monkey pos: %.3gpx, %.3gpx | monkey vel: %.3gpx/s %.3gpx/s",
				-cannonBase.orientation * RADIANS_TO_DEGREES,
				generatedVelocity,
				generatedMass,
				currentGravity,
				airDensity,
				dragCoefficient,
				surfaceArea,
				cannonBase.x,
				cannonBase.y,
				currentMonkey.x,
				currentMonkey.y,
				currentMonkey.vx,
				currentMonkey.vy
			),
			0,
			windowSizeY - 20
		)
	end

	if helpMenuOpened then
		local title = "Help Info"
		local message =
			"Hi, thanks for playing this game! To get started, choose a difficulty from easy to extreme and hit play!\
\
The easy difficulty is as easy as it gets, just point and shoot!\
\
The hard difficulty gets a little challenging, drag force is added into the equation and the monkey can manoeuvre in any direction!\
\
Beware, on the EXTREME difficulty, the world appears to be shapeshifting!\
Gravity, air density, drag coefficent and surface area is ever-changing!\
The monkey knows your gimmicks and will EVADE at all times! Do you have what it takes to beat it head-on?\
\
NOTE: Cannonball velocity and its mass changes each NEW round, regardless of difficulty\
\
CONTROLS: LMB: Fire cannon, Escape: Pause game"
		local buttons = { "OK" }

		local pressedbutton = love.window.showMessageBox(title, message, buttons)
		if pressedbutton == 1 then
			-- "OK" was pressed
			helpMenuOpened = false
		end
	end
end
