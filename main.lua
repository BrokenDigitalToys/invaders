STAGE_WIDTH = love.graphics.getWidth()
STAGE_HEIGHT = love.graphics.getHeight()
game_over = false
game_win = false
level = 0
old_level = level
love.graphics.setDefaultFilter('nearest', 'nearest')

	enemy = {}
	enemyImage = love.graphics.newImage("enemy.PNG")
	enemyExplosionSound = love.audio.newSource("explosion.ogg")
	enemyFrames = {}
	enemyFrames[0] = love.graphics.newQuad(0,0,32,16,32,32)
	enemies_controller = {}
	enemies_controller.enemies = {}
function enemies_controller:spawnEnemy(x, y)
	enemy = {}
	enemy.x = x
	enemy.y = y
	enemy.width = 64
	enemy.height = 32
	enemy.bullets = {}
	enemy.cooldown = 20 -- prevent shooting on every frame
	enemy.speed = 0.3
	table.insert(self.enemies, enemy)
end

spacecraft = {}
spacecraft.image = love.graphics.newImage("spacecraft.PNG")
spacecraft.fireSound = love.audio.newSource("my_laser.ogg")
spacecraft.x = 300
spacecraft.y = STAGE_HEIGHT - 40
spacecraft.height = 50
spacecraft.width = 50
spacecraft.cooldown = 0
spacecraft.speed = 2
spacecraft.bullets = {}
spacecraft.fire = function() 
	if spacecraft.cooldown <= 0 then	
		spacecraft.cooldown = 20
		bullet = {}
		bullet.x = spacecraft.x + spacecraft.width/2
		bullet.y = spacecraft.y 
		table.insert(spacecraft.bullets, bullet)
		love.audio.play(spacecraft.fireSound)
	end
end

function love.load()
	local music = love.audio.newSource("music.ogg")
	music:setLooping(true)
	love.audio.play(music)

	for i=0, 12 do  
		enemies_controller:spawnEnemy(i*60,0)
	end
end



particle_system = {}
particle_system.list = {}
particle_system.img = love.graphics.newImage('particle.png')


function particle_system:spawn(x,y)
	local ps = {}
	ps.ps = love.graphics.newParticleSystem(particle_system.img, 8)
	ps.x = x
	ps.y = y 
	ps.lifetime = 0
	ps.ps:setParticleLifetime(1,2) --particle life 1-2 sec
	ps.ps:setEmissionRate(50) --number of particles per sec
	ps.ps:setSizeVariation(1) --variation on maximum
	ps.ps:setLinearAcceleration(-20,-20,20,20)
	ps.ps:setColors(100, 100, 100,255)
	table.insert(particle_system.list, ps)
end

function particle_system:draw()
	for _, v in pairs(particle_system.list) do
		love.graphics.draw(v.ps, v.x, v.y)
	end
end

function particle_system:update(dt)
	for  _,v in pairs(particle_system.list) do
		v.lifetime = v.lifetime + 1
		v.ps:update(dt)
	end
end

function particle_system:cleanup()
	for  i,v in pairs(particle_system.list) do
		if v.lifetime  > 50 then
			table.remove(particle_system.list, i)
		end

	end
end	

function  checkCollisions(enemies, bullets)
	for i, e in ipairs(enemies) do
		for ib, b in pairs(bullets) do
			if b.y <= e.y + e.height and b.x > e.x and b.x < e.x + e.width then
				particle_system:spawn(e.x, e.y)
				table.remove(enemies, i)
				love.audio.play(enemyExplosionSound)
				table.remove(bullets, ib)
			end
		end
	end
end

function next_level(level)
	love.graphics.scale(1)
	for i,b in pairs(spacecraft.bullets) do
		table.remove(spacecraft.bullets,i)
	end
 	
 	count = 0
	while count <=  level do
		--print("making row of enemies " .. tostring(level_index))
		for i=0, 12 do  
			enemies_controller:spawnEnemy(i*60,60*count)
		end
		count = count + 1
	end	
end

function love.draw()	
	particle_system:draw()

	if game_over == true then
		love.graphics.scale(5)
		love.graphics.print("Game Over")
		return
	elseif game_win ==  true then
		love.graphics.scale(3)
		love.graphics.print("Get ready for the next level!")
	end 

	if spacecraft.cooldown > 0 then
		spacecraft.cooldown = spacecraft.cooldown - 1
	end
	love.graphics.setColor(255,255,255)

	love.graphics.draw(spacecraft.image,spacecraft.x ,spacecraft.y)

	for i,e in pairs(enemies_controller.enemies) do
		love.graphics.draw(enemyImage, enemyFrames[0] ,e.x,e.y,0,2)
	end

	love.graphics.setColor(255,255,255)
	for i,b in pairs(spacecraft.bullets) do
		if b.y < -10 then
			table.remove(spacecraft.bullets,i)
		end 
		b.y = b.y - 8
		love.graphics.rectangle("fill", b.x, b.y, 2, 3)
	end
end


function love.update(dt)
	particle_system:update(dt)
	particle_system:cleanup()

	if level ~= old_level then
		old_level = level
		next_level(level)
		game_win = false
		return
	end
	if game_win == true then
		level = level + 1
	end

	if love.keyboard.isDown("left") then
		spacecraft.x = spacecraft.x - spacecraft.speed
	elseif love.keyboard.isDown("right") then
		spacecraft.x = spacecraft.x + spacecraft.speed
	end

	if love.keyboard.isDown("f") then
		spacecraft.fire()
	end

	if #enemies_controller.enemies == 0 then
		game_win = true
	end 

	for i, e in pairs(enemies_controller.enemies) do
		if e.y >= STAGE_HEIGHT then 
			game_over = true
		end
		e.y = e.y + (1 * enemy.speed)
	end

	checkCollisions(enemies_controller.enemies, spacecraft.bullets)
end