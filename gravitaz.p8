pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--gravitas
--by kepler
--[[

 v2 changelog:

  added bossfights

  fixed first a in logo + centering

  added better stars + cleaned up code
  fixed draw order of stars (no more drawing over entities/scoreboard)

  shortened beam sfx
  added music "darkwave voyager" by venndaction (it's me!)

  cleaned up some code (split some functions into seperate, moved code from draw to where it should have been)

  added persistent hiscores (now save between sessions)
  
]]
hiscore = {one = 0,
 									ten = 0,
 									hundred = 0,
 									k = 0,
 									tenk = 0,
 									hundredk = 0,
 									mil = 0
          }

 cartdata("kepler_gravitaz_1")
 hiscore.one = dget(0)
 hiscore.ten = dget(1)
 hiscore.hundred = dget(2)
 hiscore.k = dget(3)
 hiscore.tenk = dget(4)
 hiscore.hundredk = dget(5)
 hiscore.mil = dget(6)
          
particles = {}

function _init()

 score = {one = 0,
          ten = 0,
          hundred = 0,
          k = 0,
          tenk = 0,
          hundredk = 0,
          mil = 0
          }

 muzak = false
 kep = {x=53,
        y=-5,
        bounce=false,
        count = 1,
        fx = 0}
        
 sfw = {x=47,
        y=132}
        
 titles = {x=20,
           y=134,
           state = 1}
           
 wavescreen = {x = -90,--24
               y = 64,
               count = 0}
 
 player = {x=64,
           y=120,
           lives = 3,
           dead = false,
           lcount = 3,
           beam = false,
           beamnum = 1,
           beamcharge = 360,
           charged = true,
           respawn = false}
 beamcount = 360
 movecounter = 1
 lasers = {}
 beams = {}
 enemies = {}
 bosses = {}
 animationcount = 1
 elasers = {}
 homings = {}
 spreads = {}
 ehelices = {}
 ebeams = {}
 bouncers = {}
 coins = {}
 globalclock = 1
 enemyright = true
 flashscreen = false
 flashcount = 0
 gamestate = 1
 --[[ gamestate 1 = intro
      gamestate 2 = title
      gamestate 3 = startwave
      gamestate 4 = gameplay
      gamestate 5 = shop
      gamestate 6 = gameover
      gamestate 7 = playerdeath
      ]]
 money = 0
 wave = 28
 selcount = 1
 
 pal(15,136,1)
 pal(4,129,1)
end

--~~~~~~~~~~~~--

function _update60() 
 globalclock += 1
 particlelogic()
 scorelogic()
 
 if gamestate == 1 then
  intro()
 elseif gamestate == 3 or gamestate == 4 then
  if globalclock >= movecounter+1 then
   globalclock = 1
  end
  if player.dead == false then
   beamstuffs()
   laserstuffs()
   enemystuffs()
   coinlogic()
   if muzak == false then
    music(0)
    muzak = true
   end
   if gamestate == 4 then
   playerstuffs()
    if #enemies <=0 then
     if #coins == 0 then 
      waveclear()
     end
    end
   end
  elseif player.dead == true then
   deleteobjects()
   if player.respawn == false then
    player.x = 63
    player.y = 130
   end
   respawn()
   if btnp(❎) then
    player.respawn = true
   end
  end
 end
end 

function respawn ()
 if player.respawn == true then
  if player.y > 120 then
   player.y -= 1
  elseif player.y == 120 then
   player.dead = false
   player.respawn = false
  end
 end
end

--~~~~~~~~~~~~--

function _draw()
 cls()
 stars()
 spacedust()
 particlelogic()
 if flashscreen == true then
  cls(7)
  sfx(1,-1,0)
  flashcount += 1
  if flashcount == 3 then
   flashscreen = false
  end
 end

 for particle in all(particles) do
  circfill(particle.x,
           particle.y,
           particle.rad,
           particle.clr)
 end
 
 map(16,1,wavescreen.x,wavescreen.y,10,2)
 print("wave",wavescreen.x+15,66,8)
 if wave < 10 then
  print(wave,wavescreen.x+37,66,8)
 elseif wave < 100 then
  print(wave,wavescreen.x+35,66,8)
 else
  print(wave,wavescreen.x+33,66,8)
 end
 print("clear",wavescreen.x+47,66,8)
 
 if gamestate == 1 then
  map(9,5,kep.x,kep.y,3,1)
  map(9,7,sfw.x,sfw.y,5,1)
 elseif gamestate == 2 then
  title()
 elseif gamestate == 3 then 
  scoreboard()

  local dchange = flr(rnd(1))
  if dchange == 0 then
   enemyright = false
  else
   enemyleft = true
  end

   if player.charged == false then
    spr(34,player.x,player.y)
   elseif player.charged == true then
    if player.beam == true then
     spr(49,player.x,player.y)
    else
     spr(34,player.x,player.y)
    end
   end
  for enemy in all(enemies) do
   zspr(enemy.class,1,1,enemy.x,enemy.y,enemy.scale)
  end
 elseif gamestate == 4 or gamestate == 7 then
  scoreboard()
  for beam in all(beams) do 
   line(beam.x1,beam.y1,beam.x2,beam.y2,8)
  end
  for ebeam in all(ebeams) do
   line(ebeam.x1,ebeam.y1,ebeam.x2,ebeam.y2,2)
   line(ebeam.x1+1,ebeam.y1,ebeam.x2+1,ebeam.y2,2)
  end
  if player.dead == true then
   print("press ❎ to continue",25,100,7)
  end
  for laser in all(lasers) do
   spr(50,laser.x,laser.y)
  end 
  for enemy in all(enemies) do
   zspr(enemy.class,1,1,enemy.x,enemy.y,enemy.scale)
  end
  for coin in all(coins) do
   spr(35,coin.x,coin.y)
  end
  for elaser in all(elasers) do
   spr(17,elaser.x,elaser.y)
  end
  for homing in all(homings) do
   spr(36,homing.x,homing.y)
  end
  for spread in all(spreads) do
   pset(spread.x,spread.y,9)
  end
  for ehelix in all(ehelices) do
   pset(ehelix.x1,ehelix.y1,12)
   pset(ehelix.x2,ehelix.y2,12)
  end
  for bounce in all(bouncers) do
   rectfill(bounce.x,bounce.y,bounce.x+1,bounce.y+1,11)
  end
  
  if player.charged == false then
   spr(34,player.x,player.y)
  elseif player.charged == true then
   if player.beam == true then
    spr(49,player.x,player.y)
   else
    spr(34,player.x,player.y)
   end
  end
  
 elseif gamestate == 5 then
  scoreboard()
  shopdraw()
  if insufficientfunds == true then
   print("insufficient funds",30,120,8)
  end
  if beambuy == true then
   print("press 🅾️ to fire beam",23,10,7)
   print("cockpit color shows beam ready",5,20,7)
  end
 elseif gamestate == 6 then
  gameover()
 end
end

--thanks to matt and freds72 for this helpful wrapper!
function zspr(n,w,h,dx,dy,dz,fx,fy)
 sspr(8*(n%16),8*flr(n/16),8*w,8*h,dx,dy,8*w*dz,8*h*dz,fx,fy)
end

--thanks to lafolie on discord
 
-->8
function playerstuffs()
 if player.dead == false then
  if btn(➡️) then
   if player.x <= 119 then
    player.x += 1
   elseif player.x >= 119 then
    spawnparticle(127,125-flr(rnd(3)),-flr(rnd(2)),flr(rnd(4))-2,8,6)
   end
  elseif btn(⬅️) then
   if player.x >= 2 then
    player.x -= 1
   elseif player.x <= 2 then
    spawnparticle(2,125-flr(rnd(3)),flr(rnd(2))+1,flr(rnd(4))-2,8,6)
   end
  end
  if btnp(❎) then
   if #lasers < (player.lcount) then
    laserspawn(player.x,player.y)
    sfx(2,0,0)
   end
  end
  if btnp(🅾️) then
   if player.beam == true then
    sfx(3,3,0)
    if player.beamcharge >= 360 then --charge necessary to actually do something
     beamspawn(player.x+3,player.y,player.x+3,player.y)
    end
   end
  end
 end
 if player.beamcharge >= 500 then
  spawnparticle(player.x+3,120,flr(rnd(3))-1,flr(rnd(2))-1,8,6)
 end
 if player.beam == true then
  player.beamcharge += (player.beamnum)
 end
 if player.beamcharge >= beamcount then
  player.charged = true
 end
 if player.lives <=0 then
  gamestate = 6
 end
end

function laserspawn(laserx,lasery)
 laser = {}
 laser.x = laserx --x coordinate
 laser.y = lasery --y coordinate
 add (lasers,laser)
end

function laserstuffs()
 for laser in all (lasers) do 
  laser.y -= 1
  if laser.y <= 0 then
   del(lasers,laser)
  end
  for homing in all(homings) do
   if homing.x >= laser.x-2 and homing.x <= laser.x+2 then
    if homing.y >= laser.y and homing.y <=laser.y+4 then
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,3  ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,11 ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,3  ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,11 ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,11 ,flr(rnd(5))+10)
     del(homings,homing)
     del(lasers,laser)
    end
   end
  end
  for enemy in all(enemies) do
   local scl = 1
   if enemy.class == 7 or enemy.class == 9 or enemy.class == 11 or enemy.class == 23 or enemy.class == 25 or enemy.class == 27 then
    scl = 6
   else
    scl = 8
   end
   if enemy.x+(scl*(enemy.scale-1)) >= laser.x-3 and enemy.x <= laser.x+3 then
    if enemy.y >= laser.y and enemy.y <=laser.y+(scl*(enemy.scale-1)) then
     score.hundred += 1
     enemy.hp -= 1
     if enemy.hp <= 0 then
      death(enemy.x,enemy.y)
      del(enemies,enemy)
     end
     for ebeam in all(ebeams) do
      if ebeam.x1 <= enemy.x+5 and ebeam.x1 >= enemy.x-3 then
        del(ebeams,ebeam)
        sfx(-1,3,0)
      end
     end
     coinchance (enemy.class,enemy.x,enemy.y)
     del(lasers,laser)     
    end
   end 
  end
 end
end

function beamspawn (x1,y1,x2,y2)
 beam = {}
 beam.x1 = x1
 beam.y1 = y1
 beam.x2 = x2
 beam.y2 = y2
 add(beams,beam)
end

function beamstuffs ()
 if #beams == 0 then
  sfx(-1,2,0)
 end
 for beam in all(beams) do
  if #beams >= 2 then
   player.beamcharge -= 4
   beam.y1 -= 3
  end
  if player.beamcharge >= 0 then
   if btn(➡️) then
    beam.x1 += 1
    beam.x2 += 1
   elseif btn(⬅️) then
    beam.x1 -= 1
    beam.x2 -= 1
   end
  elseif player.beamcharge <= 0 then
   sfx(-1,2,0)
   beam.y2 -= 2
   player.charged = false
   if beam.y2 <= 0 then
    del(beams,beam)
    sfx(-1, 0)
   end
  end
  for enemy in all(enemies) do
   if beam.y1 <= enemy.y+7 then
    if enemy.x <= beam.x1 and enemy.x+7 >= beam.x1 then
     score.hundred += 1

     enemy.hp -= 1
     if enemy.hp <= 0 then
      if enemy.class == 8 or enemy.class == 8 or enemy.class == 8 or enemy.class == 8 or enemy.class == 8 or enemy.class == 8 then
       score.k += 1
      end
      death(enemy.x,enemy.y)
      del(enemies,enemy)
     end
    end
   end
  end
  for homing in all(homings) do
   if homing.x >= beam.y1 then
    if homing.x >= beam.x1-3 and homing.x <= beam.x1+3 then
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,3  ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,11 ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,3  ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,11 ,flr(rnd(5))+10)
     spawnparticle (homing.x,homing.y, flr(rnd(4))-2,flr(rnd(4))-2,11 ,flr(rnd(5))+10)
     del(homings,homing)
     del(lasers,laser)
     score.ten += 1
    end
   end
  end
 end
end

function coinchance (c,x,y)
 if c == 1 then
  local coinchance = flr(rnd(5))
  if coinchance == 1 then
   coinspawn(x,y)
  end
 elseif c == 2 then
  local coinchance = flr(rnd(4))
  if coinchance == 1 then
   coinspawn(x,y)
  end
 elseif c == 3 then
  local coinchance = flr(rnd(3))
  if coinchance == 1 then
   coinspawn(x,y)
  end
 elseif c == 4 then
  local coinchance = flr(rnd(2))
  if coinchance == 1 then
   coinspawn(x,y)
  end 
 elseif c == 5 then
  local coinchance = flr(rnd(1))
  if coinchance == 1 then
   coinspawn(x,y)
  end
 end
end

function coinspawn (coinx,coiny)
 coin = {}
 coin.x = coinx --x
 coin.y = coiny --y
 add(coins,coin)
end

function coinlogic ()
 for coin in all(coins) do
  coin.y += 1
  if coin.y >= 128 then
   del(coins,coin)
  end
  if player.x >= coin.x-3 and player.x <= coin.x+3 then
   if player.y <= coin.y then
    sfx(9,-1,0)
    money += 1
    score.one += 1
    del(coins,coin)
   end
  end
 end
end
-->8
--enemies
enemyxs =
 {30,40,50,60,70,80,90,100
 ,25,35,45,55,65,75,85,95,105
 ,30,40,50,60,70,80,90,100
 ,25,35,45,55,65,75,85,95,105
 ,30,40,50,60,70,80,90,100}

enemyys =
 {10,10,10,10,10,10,10,10 
 ,20,20,20,20,20,20,20,20,20
 ,30,30,30,30,30,30,30,30
 ,40,40,40,40,40,40,40,40,40
 ,50,50,50,50,50,50,50,50}
 
 --class 1 gunner 
 --class 2 bouncing
 --class 3 spread 
 --class 4 helices
 --class 5 beam
 --class 6 homing 
 --class 7 bosshead
 --class 8 bossarm
 
enemyclass = 
 {2 ,4 ,4 ,4 ,4 ,4 ,4 ,2 
 ,6 ,3 ,1 ,1 ,3 ,1 ,1 ,3 ,6 
 ,6 ,5 ,1 ,1 ,1 ,1 ,5 ,6
 ,6 ,2 ,1 ,1 ,1 ,1 ,1 ,2 ,6
 ,5 ,1 ,2 ,1 ,1 ,2 ,1 ,5}

helixholder = 
 {0, 0.1, 0.2, 0.3, 0.4,
  0.5, 0.5, 0.6, 0.7, 0.8,
  0.9, 1}
    
function enemyspawn(enemyclass,enemyx,enemyy,enemynum,enemyhealth,enemycount,enemyscale)
 enemy = {}
 enemy.class = enemyclass
 enemy.x = enemyx
 enemy.y = enemyy
 enemy.number = enemynum
 enemy.hp = enemyhealth
 enemy.ct = enemycount
 enemy.scale = enemyscale
 add (enemies,enemy)
end

function enemystuffs() 
 if wave == 15 or wave == 20 or wave == 25 or wave == 30 or wave == 35 or wave == 40 then
  movecounter = 60
 else
  movecounter = #enemies+20
 end
 movecounter -= wave 
 if movecounter <= 0 then
  movecounter = 1
 end
 for enemy in all(enemies) do
  if enemy.x == 118 then
   enemyright = false
   globalclock = movecounter
   movedown()
  elseif enemy.x == 5 then
   enemyright = true 
   globalclock = movecounter
   movedown()
  end
 end
 enemyspawnlogic()
 if gamestate == 4 then
  if (enemyright == true) and (globalclock == movecounter) then
   for enemy in all(enemies) do
    enemy.x += 1
   end
   for ebeam in all(ebeams) do
    ebeam.x1 += 1
    ebeam.x2 += 1
   end
  elseif (enemyright == false) and (globalclock == movecounter) then
   for enemy in all(enemies) do
    enemy.x -= 1
   end
   for ebeam in all(ebeams) do
    ebeam.x1 -= 1
    ebeam.x2 -= 1
   end
  end
  --actual li is li + 400x
  local li = 2500
  li -= (10*wave)
  if #enemies <= 10 then
   li = 400
  elseif #enemies <= 5 then
   li = 30
  elseif #enemies <= 3 then
   li = 10
   if wave >= 15 then 
    li = 9
   end
  end
  li -= wave
  local laserc = flr(rnd(li))+1
  
  for enemy in all(enemies) do 
   if enemy.number == laserc then
    if enemy.class == 1 then
     enemylaserspawn(enemy.x,enemy.y+3)  
     sfx(4,0,0)
    elseif enemy.class == 2 then
     bouncespawn(enemy.x+3,enemy.y+4,flr(rnd(2)))
     sfx(5,0,0)
    elseif enemy.class == 3 then
     spreadspawn(enemy.x+2,enemy.y+5,0.1)
     spreadspawn(enemy.x+2,enemy.y+5,0.2)
     spreadspawn(enemy.x+2,enemy.y+5,0.3)
     spreadspawn(enemy.x+2,enemy.y+5,0.4)
     spreadspawn(enemy.x+2,enemy.y+5,0.5)
     spreadspawn(enemy.x+3,enemy.y+5,0.6)
     spreadspawn(enemy.x+3,enemy.y+5,0.7)
     spreadspawn(enemy.x+3,enemy.y+5,0.8)
     spreadspawn(enemy.x+3,enemy.y+5,0.9)    
     sfx(7,0,0)
    elseif enemy.class == 4 then
     ehelixspawn(enemy.x+2,enemy.y+5,enemy.x+3,enemy.y+5,1)
     sfx(6,0,0)
    elseif enemy.class == 5 then
     sfx(3,0,0)
     if #ebeams < 2 then
      ebeamspawn(enemy.x+3,enemy.y+5,enemy.x+3,enemy.y+1,#ebeams+1,1)
      enemy.bt = #ebeams+1
     end 
    elseif enemy.class == 6 then
     homingspawn(enemy.x+2,enemy.y+5)   
     sfx(8,0,0)
    else
     if wave == 15 then
      enemylaserspawn(enemy.x,enemy.y+3)  
      sfx(4,0,0)
     elseif wave == 20 then
      bouncespawn(enemy.x+3,enemy.y+4,flr(rnd(2)))
      sfx(5,0,0)
     elseif wave == 25 then
      spreadspawn(enemy.x+2,enemy.y+5,0.1)
      spreadspawn(enemy.x+2,enemy.y+5,0.2)
      spreadspawn(enemy.x+2,enemy.y+5,0.3)
      spreadspawn(enemy.x+2,enemy.y+5,0.4)
      spreadspawn(enemy.x+2,enemy.y+5,0.5)
      spreadspawn(enemy.x+3,enemy.y+5,0.6)
      spreadspawn(enemy.x+3,enemy.y+5,0.7)
      spreadspawn(enemy.x+3,enemy.y+5,0.8)
      spreadspawn(enemy.x+3,enemy.y+5,0.9) 
      sfx(7,0,0)
     elseif wave == 30 then
      ehelixspawn(enemy.x+2,enemy.y+5,enemy.x+3,enemy.y+5,1)
      sfx(6,0,0)
     elseif wave == 35 then
      sfx(3,0,0)
      if #ebeams < 2 then
       ebeamspawn(enemy.x+3,enemy.y+5,enemy.x+3,enemy.y+1,#ebeams+1,1)
       enemy.bt = #ebeams+1
      end 
     elseif wave == 40 then
      homingspawn(enemy.x+2,enemy.y+5)   
      sfx(8,0,0)
     end
    end
   end
  end
 end
 enemyanimation()
 enemycollision()
 
 --enemy attack patterns (tab 4)
 laserlogic()
 hominglogic()
 spreadlogic()
 helixlogic()
 ebeamlogic()
 bouncelogic()
 
 function movedown ()
  for enemy in all(enemies) do
   enemy.y += 2
  end
  for ebeam in all(ebeams) do
   ebeam.y2 += 2
  end 
 end
end

function enemyanimation()
 for enemy in all(enemies) do
  animationcount += 1
  if animationcount >= 16 then
   enemy.ct += 1
   if enemy.class == 7 or enemy.class == 9 or enemy.class == 11 or enemy.class == 23 or enemy.class == 25 or enemy.class == 27 then
    if enemy.ct == 1 then
     enemy.x += 1
    elseif enemy.ct == 1 then 

    elseif enemy.ct == 2 then
     enemy.x += 1 
    elseif enemy.ct == 3 then

    elseif enemy.ct == 4 then
     enemy.y -= 1
    elseif enemy.ct == 5 then

    elseif enemy.ct == 6 then
     enemy.y -= 1
    elseif enemy.ct == 7 then

    elseif enemy.ct == 8 then
     enemy.x -= 1
    elseif enemy.ct == 9 then

    elseif enemy.ct == 10 then
     enemy.x -= 1
    elseif enemy.ct == 11 then

    elseif enemy.ct == 12 then
     enemy.y += 1
    elseif enemy.ct == 13 then

    elseif enemy.ct == 14 then
     enemy.y += 1
    elseif enemy.ct == 15 then

    elseif enemy.ct == 16 then
     enemy.x += 1
    end
    if enemy.ct >= 16 then
     enemy.ct = 1
    end
    if animationcount >= 17 then
     animationcount = 1
    end
   end
  end
 end
end

 --[[thanks to bab_b for his 
 suggestion of using 
 #enemies to count enemies]]
 
function enemyspawnlogic()
 if gamestate == 3 then
  if wave == 15 or wave == 20 or wave == 25 or wave == 30 or wave == 35 or wave == 40 then
   if #enemies <= 2 then
    if wave == 15 then
     enemyspawn(8,64,-32,1,15,1,2) --core
     enemyspawn(7,44,-36,2,10,1,2) --arm
     enemyspawn(7,84,-36,3,10,1,2) --arm
    elseif wave == 20 then
     enemyspawn(10,64,-32,1,15+(5*wave),1,2) --core
     enemyspawn(9,44,-36,2,10+(5*wave),1,2) --arm
     enemyspawn(9,84,-36,3,10+(5*wave),1,2) --arm
    elseif wave == 25 then
     enemyspawn(12,64,-32,1,15+(5*wave),1,2) --core
     enemyspawn(11,44,-36,2,10+(5*wave),1,2) --arm
     enemyspawn(11,84,-36,3,10+(5*wave),1,2) --arm
    elseif wave == 30 then
     enemyspawn(24,64,-32,1,15+(5*wave),1,2) --core
     enemyspawn(23,44,-36,2,10+(5*wave),1,2) --arm
     enemyspawn(23,84,-36,3,10+(5*wave),1,2) --arm
    elseif wave == 35 then
     enemyspawn(26,64,-32,1,15+(5*wave),1,2) --core
     enemyspawn(25,44,-36,2,10+(5*wave),1,2) --arm
     enemyspawn(25,84,-36,3,10+(5*wave),1,2) --arm
    elseif wave == 40 then
     enemyspawn(28,64,-32,1,15+(5*wave),1,2) --core
     enemyspawn(27,44,-36,2,10+(5*wave),1,2) --arm
     enemyspawn(27,84,-36,3,10+(5*wave),1,2) --arm
    end
   end
   for enemy in all(enemies) do
    if flashscreen == 1 then
     enemy.y += 3
    end
    if enemy.y >= 50 then
     gamestate = 4 
    end
    flashscreen = 1  
   end
  else
   if #enemies <= 41 then
    if wave == 3 or wave == 5 or wave == 7 or wave == 9 or wave > 10 then
     enemyspawn(
     flr(rnd(6))+1,
     enemyxs[1+#enemies],
     enemyys[1+#enemies]-60,
     (#enemies),1,1,1)
    else
     enemyspawn(
     enemyclass[#enemies+1],
     enemyxs[1+#enemies],
     enemyys[1+#enemies]-60,
     (#enemies),1,1,1)
    end
   elseif #enemies >= 41 then
    for enemy in all(enemies) do
     if wave == 1 and enemy.class >= 2 then
      enemy.class = 1
     elseif wave <= 3 and enemy.class >= 3 then
      enemy.class = 1
     elseif wave <= 5 and enemy.class >= 4 then
      enemy.class = 1
     elseif wave <= 7 and enemy.class >= 5 then
      enemy.class = 1
     elseif wave <= 9 and enemy.class >= 6 then
      enemy.class = 1
     end
     if flashscreen == 1 then
      enemy.y += 3
     end
     if enemy.y >= 50 then
      gamestate = 4 
     end
    end
    flashscreen = 1  
   end
  end
 end
end
 
function enemylaserspawn (elaserx,elasery)
 elaser = {}
 elaser.x = elaserx
 elaser.y = elasery
 add(elasers,elaser)
end

function homingspawn (x,y)
 homing = {}
 homing.x = x
 homing.y = y
 add(homings,homing)
end

function spreadspawn (x,y,a)
 spread = {}
 spread.x = x
 spread.y = y
 spread.angle = a
 add(spreads,spread)
end

function ehelixspawn (x1,y1,x2,y2,n1)
 ehelix = {}
 ehelix.x1 = x1
 ehelix.y1 = y1
 ehelix.x2 = x2
 ehelix.y2 = y2
 ehelix.num = n1
 add(ehelices,ehelix)
end

function ebeamspawn (x1,y1,x2,y2,num,ct)
 ebeam = {}
 ebeam.x1 = x1
 ebeam.y1 = y1
 ebeam.x2 = x2
 ebeam.y2 = y2
 ebeam.num = num
 ebeam.count = ct
 add(ebeams,ebeam)
end

function bouncespawn (x,y,s)
 bounce = {}
 bounce.x = x
 bounce.y = y
 bounce.state = s
 add(bouncers,bounce)
end
-->8
--title and stuff
function title()
 if titles.state == 1 then
  titles.y -= 1
 end
 if titles.y <= 24 then
  titles.state = 2
 end
 map (5,2,titles.x,titles.y,11,2)
 print ("highscore:",30,titles.y+41,7)
 print(hiscore.mil,70,titles.y+41,7)
 print(hiscore.hundredk,74,titles.y+41,7)
 print(hiscore.tenk,78,titles.y+41,7)
 print(hiscore.k,82,titles.y+41,7)
 print(hiscore.hundred,86,titles.y+41,7)
 print(hiscore.ten,90,titles.y+41,7)
 print(hiscore.one,94,titles.y+41,7)
 print ("press ❎ to begin",30,titles.y+76,7)
 if btn(❎) or btn(🅾️) then
  flashscreen = true
  gamestate = 3
 end
end

function scorelogic()
 if score.one > 9 then
  score.one = 0
  score.ten += 1
 end
 if score.ten > 9 then
  score.ten = 0
  score.hundred += 1
 end
 if score.hundred > 9 then
  score.hundred = 0
  score.k += 1
 end
 if score.k > 9 then
  score.k = 0
  score.tenk += 1
 end
 if score.tenk > 9 then
  score.tenk = 0
  score.hundredk += 1
 end
 if score.hundredk > 9 then
  score.hundredk = 0
  score.mil += 1
 end
 if score.mil > 9 then
  score.one = 9
  score.ten = 9
  score.hundred = 9
  score.k = 9
  score.tenk = 9
  score.hundredk = 9
  score.mil = 9
 end
end
 
function scoreboard ()
 print("score:",2,0,7) 
 print(score.mil,26,0,7)
 print(score.hundredk,30,0,7)
 print(score.tenk,34,0,7)
 print(score.k,38,0,7)
 print(score.hundred,42,0,7)
 print(score.ten,46,0,7)
 print(score.one,50,0,7)
 print("●",56,0,10)
 print(":",63,0,10)
 print(money,67,0,10)
 print("wave:",80,0,8)
 print(wave,100,0,8)
 spr(18,107,-2)
 print(":",114,0,11)
 print(player.lives,118,0,11)
 line (0,0,0,128,8)
 line (127,0,127,128,8)
end

function shopdraw()
  map(0,4,32,32,8,10)
  print ("shop",58,36,3)
 --[[1]] print ("life-10",43,47,5)
 --[[2]] print ("xtrashot-",43,57,5)
 --[[2]] print (10*player.lcount,79,57,5)
 if player.beam == false then
 --[[3]] print ("beam-100",43,67,5)
 elseif player.beam == true then
 --[[3]] print ("beamv -",43,67,5)
 --[[3]] print (player.beamnum+1,63,67,5)
 --[[3]] print (10*(1+player.beamnum),71,67,5)
 end
 --[[4]] print ("continue",50,100,5)
  if selcount == 1 then
   spr (16,38,48)
   if btnp(❎) or btnp(🅾️) then
    if money >= 10 then
     money -= 10
     player.lives += 1
    elseif money < 10 then
     insufficientfunds = true
    end
   end
  elseif selcount == 2 then
   spr (16,38,58)
   if btnp(❎) or btnp(🅾️) then
    if money >= 10*player.lcount then
     money -= 30
     player.lcount += 1
    elseif money < 30 then
     insufficientfunds = true
    end
   end 
  elseif selcount == 3 then
   spr (16,38,68)
   if player.beam == false then
    if btnp(❎) or btnp(🅾️) then
     if money >= 100 then
      money -= 100
      player.beam = true
      beambuy = true
      player.beamnum += 1
     elseif money < 100 then
      insufficientfunds = true
     end
    end
   elseif player.beam == true then
    if btnp(❎) or btnp(🅾️) then
     if money >= 10*(1+player.beamnum) then
      money -= 10*(1+player.beamnum)
      player.beamnum += 1
      beamcount -= 10
     elseif money < 10*(1+player.beamnum) then
      insufficientfunds = true
     end
    end
   end
  elseif selcount == 4 then
   spr (16,45,101) 
   if btnp(🅾️) or (btnp(❎)) then
    del(lasers,laser)
    del(coins,coin)
    insufficientfunds = false
    gamestate = 3
   end 
  end
  if selcount > 1 then
   if btnp(⬆️) then
    selcount -= 1 
   end
  end
  if selcount < 4 then
   if btnp(⬇️) then
    selcount += 1
   end
  end
end

scorenumber = 0

function gameover ()
  scorenumber += 1
 if scorenumber < 20 then
  scorecolor = 7
 elseif scorenumber < 40 then
  scorecolor = 8
 elseif scorenumber >= 10 then
  scorenumber = 1
 end

 map (0,0,45,32,5,4)
 print("score:",38,64,7) 
 print(score.mil,62,64,7)
 print(score.hundredk,66,64,7)
 print(score.tenk,70,64,7)
 print(score.k,74,64,7)
 print(score.hundred,78,64,7)
 print(score.ten,82,64,7)
 print(score.one,86,64,7)
 
 print("hiscore:",35,71,7) 
 print(hiscore.mil,67,71,7)
 print(hiscore.hundredk,71,71,7)
 print(hiscore.tenk,75,71,7)
 print(hiscore.k,79,71,7)
 print(hiscore.hundred,83,71,7)
 print(hiscore.ten,87,71,7)
 print(hiscore.one,91,71,7)
 
 print ("credits:",46,78,7)
 print (money,78,78,6)
 
 print ("press ❎ to try again",24,89,8)

 checkhiscore()

 if globalclock >= 90 then
  if (btnp(❎)) or (btnp(🅾️)) then
   _init()
  end
 end
end

function checkhiscore()
 if score.mil > hiscore.mil then
  print("new high score!",35,100,scorecolor)
  scoreupdate()
 elseif score.mil == hiscore.mil then
  if score.hundredk >= hiscore.hundredk then
   print("new high score!",35,100,scorecolor)
   scoreupdate()
  elseif score.hundredk == hiscore.hundredk then
   if score.tenk >= hiscore.tenk then
    print("new high score!",35,100,scorecolor)
    scoreupdate()
   elseif score.tenk == hiscore.tenk then   
    if score.kk >= hiscore.k then
     print("new high score!",35,100,scorecolor)
     scoreupdate()
    elseif score.k == hiscore.k then
     if score.hundred >= hiscore.hundred then
      print("new high score!",35,100,scorecolor)
      scoreupdate()
     elseif score.hundred == hiscore.hundred then
      if score.ten >= hiscore.ten then
       print("new high score!",35,100,scorecolor)
       scoreupdate()
      elseif score.ten == hiscore.ten then 
       if score.one >= hiscore.one then
        print("new high score!",35,100,scorecolor)
        scoreupdate()
       end
      end
     end
    end
   end
  end
 end
end

function scoreupdate()
 hiscore.mil = score.mil
 hiscore.hundredk = score.hundredk
 hiscore.tenk = score.tenk
 hiscore.k = score.k
 hiscore.hundred = score.hundred
 hiscore.ten = score.ten
 hiscore.one = score.one
 
 dset(0, hiscore.one)
 dset(1, hiscore.ten)
 dset(2, hiscore.hundred)
 dset(3, hiscore.k)
 dset(4, hiscore.tenk)
 dset(5, hiscore.hundredk)
 dset(6, hiscore.mil)
end

function niltest(x)
 if x == nil then
  x = 0
 end
end

function waveclear()
 if wavescreen.x < 24 then
  wavescreen.x += 3
 elseif wavescreen.x == 24 then
  wavescreen.count += 1
 elseif wavescreen.x >= 130 then
  wave += 1
  gamestate = 5
  for beam in all(beams) do
   del(beams,beam)
  end
  sfx(-1, 0)
 end 
 if wavescreen.count >= 40 then
  wavescreen.x += 3
 end
end

-->8
--enemy projectiles

function enemycollision ()
 for enemy in all(enemies) do
  if player.x >= enemy.x-3 and player.x <= enemy.x+3 then
    if player.y+8 >= enemy.y and player.y <= enemy.y then
    player.dead = true
    player.accept = false
    player.lives -= 1
    death(player.x,player.y)
    del(enemies,enemy)
    sfx(1,-1,0)
   end
  end
 end
end

function laserlogic ()
 for elaser in all(elasers) do
  elaser.y += 1
  if elaser.y >= 128 then
   del(elasers,elaser)
  end
  if player.x >= elaser.x-3 and player.x <= elaser.x+3 then
   if player.y+8 >= elaser.y and player.y <= elaser.y then
    player.dead = true
    player.lives -= 1
    death(player.x,player.y)
    del(elasers,elaser)
    sfx(1,-1,0)
   end
  end
 end
end

function hominglogic ()
 for homing in all(homings) do
  homing.y +=1
  if homing.y >= 64 then
   if player.x > homing.x then
    homing.x += 1
   elseif player.x < homing.x then 
    homing.x -= 1
   end
  end
  if homing.y >= 128 then
   del(homings,homing)
  end
  if player.x >= homing.x-3 and player.x <= homing.x+3 then
    if player.y+8 >= homing.y and player.y <= homing.y then
    player.dead = true
    player.lives -= 1
    death(player.x,player.y)
    del(homings,homing)
    sfx(1,-1,0)
   end
  end
 end
end

function spreadlogic ()
 for spread in all(spreads) do
  spread.y += 1
  spread.x += sin(spread.angle)
  if spread.x >= 128 then
   del(spreads,spread)
  elseif spread.x <= 0 then
   del(spreads,spread)
  end
  if spread.y >= 128 then
   del(spreads,spread)
  end
  if player.x >= spread.x-3 and player.x <= spread.x+3 then
   if player.y+8 >= spread.y and player.y <= spread.y then
    player.dead = true
    player.lives -= 1
    death(player.x,player.y)
    del(spreads,spread)
    sfx(1,-1,0)
   end
  end
 end
end

function helixlogic ()
 for ehelix in all(ehelices) do
  ehelix.num += 1
  if ehelix.num >= 12 then
  	ehelix.num = 0
  end
  ehelix.y1 += 1
  ehelix.y2 += 1
  ehelix.x1 += sin(helixholder[ehelix.num])
  ehelix.x2 -= sin(helixholder[ehelix.num]) 
  if ehelix.y1 and ehelix.y2 >= 128 then
   del(ehelices,ehelix)
  end
  if player.x >= ehelix.x1-3 and player.x <= ehelix.x1+3 then
   if player.y+8 >= ehelix.y1 and player.y <= ehelix.y1 then
    player.dead = true
    player.lives -= 1
    death(player.x,player.y)
    del(ehelices,ehelix)
    sfx(1,-1,0)
   elseif player.x >= ehelix.x2-3 and player.x <= ehelix.x2+3 then
    if player.y+8 >= ehelix.y2 and player.y <= ehelix.y1 then
     player.dead = true
     player.lives -= 1
     death(player.x,player.y)
     del(ehelices,ehelix)
     sfx(1,-1,0)
    end
   end
  end
 end
end

function ebeamlogic ()
 for ebeam in all(ebeams) do
  ebeam.count += 1
  if ebeam.y1 <= 128 then
   ebeam.y1 += 1
  end 
  if ebeam.count >= 500 then
   ebeam.y2 += 1
   if ebeam.y2 == 128 then
    del(ebeams,ebeam)
    sfx(-1,3,0)
   end
  end
  if #ebeams == 0 then
   sfx(-1,3,0)
  end
  if player.x >= ebeam.x1-3 and player.x <= ebeam.x1+3 then
   if player.y+3 <= ebeam.y1 then
    player.dead = true
    player.lives -= 1
    death(player.x,player.y)
    del(ebeams,ebeam)
    sfx(1,-1,0)
   end
  end
 end
end

function bouncelogic ()
 for bounce in all(bouncers) do
  bounce.y += 1
  if bounce.state == 0 then
   bounce.x += sin(0.3)
  elseif bounce.state == 1 then
   bounce.x -= sin(0.3)
  end
  if bounce.x <= 1 then
   bounce.state = 1
   sfx(4,0,0)
  elseif bounce.x >= 126 then
   bounce.state = 0
   sfx(4,0,0)
  end
  if player.x >= bounce.x-3 and player.x <= bounce.x+3 then
    if player.y+8 >= bounce.y and player.y <= bounce.y then
    player.dead = true
    player.lives -= 1
    death(player.x,player.y)
    del(bouncers,bounce)
    sfx(1,-1,0)
   end
  end
  if bounce.y >= 128 then
   del(bouncers,bounce)
  end
 end
end
-->8
-- particles

function spawnparticle (x,y,vx,vy,c,l,t,r)
 particle = {}
 particle.x = x
 particle.y = y
 particle.velx = vx
 particle.vely = vy
 particle.clr = c
 particle.life = l
 particle.type = t
 particle.rad = r
 add(particles,particle)
end



function spacedust()
 
 
 
 local r = flr(rnd(20))
 if r == 1 then
	 for i=10,1,-1 do
	 
	  local c = 4
	  r = flr(rnd(2))
   if r == 1 then c = 1 end
  
   local xseed = 
   flr(rnd(90))+20
  
	 	spawnparticle(
	 	  xseed + flr(rnd(30))-15,--x
	    -60+rnd(30),     --y
	    0,              --vx
	    flr(rnd(1))+0.5,--vy
	    c,              --color
	    450,            --life
	    2,              --type
	    6+rnd(15))      --radius
	 end
 end
end

function stars ()
 local sc = flr(rnd(2))
 local sh = 0
 if gamestate >= 4 then 
  sh = 5 
 end

 if sc == 1 then 
  spawnparticle(flr(rnd(126))+1,sh,0,flr(rnd(3))+1,6,128,0,0)
  spawnparticle(flr(rnd(126))+1,sh+rnd(6),0,flr(rnd(3))+1,6,128,0,0)
 
 end
end

function particlelogic ()
 for particle in all(particles) do
  if particle.vely == 0 then
   particle.vely += 1
  end
  particle.life -= 1
  particle.x += particle.velx
  particle.y += particle.vely
  if particle.life <= 0 then
   del (particles,particle)
  end
  
 end
end

function death (x,y)
 sfx(1,-1,0)
 sfx(-1,3,0)
 spawnparticle (x,y, flr(rnd(4))-2,flr(rnd(4))-2,flr(rnd(4))+7 ,flr(rnd(5))+40,1,0)
 spawnparticle (x,y, flr(rnd(4))-2,flr(rnd(4))-2,flr(rnd(4))+7 ,flr(rnd(5))+40,1,0)
 spawnparticle (x,y, flr(rnd(4))-2,flr(rnd(4))-2,flr(rnd(4))+7 ,flr(rnd(5))+40,1,0)
 spawnparticle (x,y, flr(rnd(4))-2,flr(rnd(4))-2,flr(rnd(4))+7 ,flr(rnd(5))+40,1,0)
 spawnparticle (x,y, flr(rnd(4))-2,flr(rnd(4))-2,flr(rnd(4))+7 ,flr(rnd(5))+40,1,0)
end
-->8
--delete

function deleteobjects ()
 for laser in all(lasers) do
  del(lasers,laser)
 end
 for beam in all(beams) do
  del(beams,beam)
 end
 sfx(-1,3,0)
 for elaser in all(elasers) do
  del(elasers,elaser)
 end
 for homing in all(homings) do
  del(homings,homing)
 end
 for spread in all(spreads) do
  del(spreads,spread)
 end
 for ehelix in all(ehelices) do
  del(ehelices,ehelix)
 end
 for ebeam in all(ebeams) do
  del(ebeams,ebeam)
 end
 for bounce in all(bouncers) do
  del(bouncers,bounce)
 end
end




-->8
--intro

function intro ()
 if kep.y >= 60 then
  kep.fx += 1  
  kep.bounce = true
 end
 if kep.bounce == false then
  kep.y += 1
  sfw.y -= 1
 elseif kep.bounce == true then
   kep.count += 1
   if kep.count >= 60 then
    kep.x -= 1 
    sfw.x += 1
   end
   if kep.x <= -30 then
    gamestate = 2
   end
  if kep.fx == 1 then
   sfx(0)
  end
 end
end





__gfx__
00000000000000000000000000000000000000000000000000000000000000000077770000000000007777000000000000777700000000000000000000000000
00000000007777000077770000777700007777000077770000777700007777000777777000700700077777700077770007777770000000000000000000000000
00000000077777700777777007777770077777700777777007777770077777707778877607000070777bb7760777777077799776000000000000000000000000
000000000788887007bbbb700799997007cccc70072222700733337007777770778888760777777077bbbb760777777077999976000000000000000000000000
0000000007777770077777700777777007777770077777700777777007777770778888760777777077bbbb760779977077999976000000000000000000000000
00000000077007700007700007077070070000700070070000777700077887707778877607777770777bb7760709907077799776000000000000000000000000
000000000070070000700700000770000070070000700700077007700788887007777760077bb770077777600700007007777760000000000000000000000000
00000000000000000000000000000000000000000000000007000070000000000066660000b00b00006666000000000000666600000000000000000000000000
33300000000880000000000000000000000000000000000000000000000000000077770000000000007777000000000000777700000000000000000000000000
00330000000880000000000000000000000000000000000000000000007777000777777000777700077777700077770007777770000000000000000000000000
3330000000088000000000000000000000000000000000000000000007777770777cc77607777770777227760777777077733776000000000000000000000000
000000000000000000008000000000000000000000000000000000000777777077cccc7607777770772222760777777077333376000000000000000000000000
000000000000000000077700000000000000000000000000000000000777777077cccc7607722770772222760777777077333376000000000000000000000000
00000000000000000007070000000000000000000000000000000000077cc770777cc77607200270777227760733337077733776000000000000000000000000
00000000000000000000000000000000000000000000000000000000077cc7700777776007200270077777600330033007777760000000000000000000000000
00000000000000000000000000000000000000000000000000000000007007000066660000000000006666000300003000666600000000000000000000000000
00000000000000000008000000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000070000000000003bb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000777000000aa0003bb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000007c700000a99a00033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000771770000a99a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000077777770000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007700077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000800000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007770000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007870000008000000787000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077877000008000007787700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777700000000077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000770007700000000077000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000700000000070000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888008888888f008888888f008888888f000000000000707070707070707070707000000000000000000000000000000000000000000000000000000000
8fffffff008fffff8f008ff8888f008fffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8f000000008f00008f008f08888f008f000000000000000000700000000000000000007000000000000000000000000000000000000000000000000000000000
8f000000008f00008f008f0f888f008f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8f000000008f00008f008f00888f008888888f000000000000700000000000000000007000000000000000000000000000000000000000000000000000000000
8f000000008f00008f008f00ff8f008fffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8f00888f008888888f008f00008f008f000000000000000000700000000000000000007000000000000000000000000000000000000000000000000000000000
8f00ff8f008fffff8f008f00008f008f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8f00008f008f00008f008f00008f008f000000000000000000707070707070707070707000000000000000000000000000000000000000000000000000000000
8f00008f008f00008f008f00008f008f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888f008f00008f008f00008f008888888f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff008f00008f008f0000ff00ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888f008f00008f008888888f008888888f000000006666666666666666666666666666666666006666666666666666666666666666666666666666000000
8fffff8f008f00008f008fffffff008fffff8f000000006222222226622222222662222222266226666226622662222222222662222222266222222226000000
8f00008f008f00008f008f000000008f00008f000000666222222226622222222662222222266226666226622662222222222662222222266222222226660000
8f00008f008f00008f008f000000008f00008f000000655225555555522555522552255552255225555225522555555225555552255552255555555225560000
8f00888f008f00008f008888888f008f00008f000000655225555555522555522552255552255225555225522555555225555552255552255555555225560000
8f08ff8f008f00008f008fffffff008f00008f000000666226666666622666622662266662266226666226622666666226666662266662266666622226660000
888ff08f008f00008f008f000000008888888f000000006226666666622666622662266662266226666226622600006226000062266662266666622226000000
8fff008f008f00008f008f000000008fff8fff000000006226622226622222222662222222266226666226622600006226000062222222266222266666000000
8f00008f00888f008f008f000000008f008f00000000007dd77dddd77dddddddd77dddddddd77dd7777dd77dd700007dd700007dddddddd77dddd77000000000
8f00008f00ff88888f008f000000008f00f8f0000000007dd7777dd77dd77dd7777dd7777dd77dddd77dd77dd700007dd700007dd7777dd77dd7770000000000
8888888f0000888f00008888888f008f000f8f000000007dd7777dd77dd77dd7777dd7007dd77dddd77dd77dd700007dd700007dd7007dd77dd7777777000000
ffffffff0000ffff0000ffffffff008f0000ff000000007dddddddd77dd7777dd77dd7007dd7777dddd7777dd700007dd700007dd7007dd77dddddddd7000000
00000000000000000000000000000000000000000000007dddddddd77dd7077dd77dd7007dd7007dddd7007dd700007dd700007dd7007dd77dddddddd7000000
00000000000000000000000000000000000000000000007777777777777700777777770077770077777700777700007777000077770077777777777777000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03333333333333333333333000000000000000002200222020202000222022200000000000000000088888888888888880000000000000000000000000000000
36666666666666666666666300000000000000002020200020202000202020000000000000000000087777777777777778000000000000000000000000000000
36666666666666666666666300000000000000002020222020202000202020000000000000000000008777777777777777800000000000000000000000000000
36666666666666666666666300000000000000002020200020202000202020200000000000000000000877777777777777780000000000000000000000000000
36666666666666666666666300000000000000002020200020202000202020200000000000000000000087777777777777778000000000000000000000000000
36666666666666666666666300000000000000002200222002002220222022200000000000000000000008777777777777777800000000000000000000000000
36666666666666666666666300000000000000000000000000000000000000000000000000000000000000877777777777777780000000000000000000000000
36666666666666666666666300000000000000000000000000000000000000000000000000000000000000087777777777777778000000000000000000000000
3666666666666666666666630000000000000000c0c0ccc0ccc0c000ccc0ccc00000000000000000000000008888888888888888000000000000000000000000
3666666666666666666666630000000000000000c0c0c000c0c0c000c000c0c00000000000000000000000000000000000000000000000000000000000000000
3666666666666666666666630000000000000000cc00ccc0ccc0c000ccc0cc000000000000000000000000000000000000000000000000000000000000000000
3666666666666666666666630000000000000000c0c0c000c000c000c000c0c00000000000000000000000000000000000000000000000000000000000000000
3666666666666666666666630000000000000000c0c0ccc0c000ccc0ccc0c0c00000000000000000000000000000000000000000000000000000000000000000
36666666666666666666666300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
36666666666666666666666300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
36666666666666666666666300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3666666666666666666666630000000000000000ccc0ccc0ccc0ccc0c0c0ccc0ccc0c0c0ccc00000000000000000000000000000000000000000000000000000
3666666666666666666666630000000000000000c000c0c0c0000c00c0c0c0c0c0c0c0c0c0000000000000000000000000000000000000000000000000000000
3666666666666666666666630000000000000000ccc0c0c0ccc00c00c0c0c0c0cc00cc00ccc00000000000000000000000000000000000000000000000000000
366666666666666666666663000000000000000000c0c0c0c0000c00ccc0c0c0c0c0c0c000c00000000000000000000000000000000000000000000000000000
3666666666666666666666630000000000000000ccc0ccc0c0000c00ccc0ccc0c0c0c0c0ccc00000000000000000000000000000000000000000000000000000
36666666666666666666666300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
36666666666666666666666300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222222220022222222002222222002200002200220022222222220022222222002222222200000000000000000000000
00000000000000000000000000000000222222220022222222002222222062200002200220022222222220022222222002222222200000000000000000000000
00000000000000000000000000000055225555555522555555552255555552255555555225555555555555522555555555555552255000000000000000000000
00000000000000000000000000000055225555555522555555552255555552255555555225555555555555522555555555555552255000000000000000000000
00000000000000000000000000000000220000000022000022002200022002200002200220000002200000022000022000000222200000000000000000000000
00000000000000000000000000000000220000000022000022002200022002200002200220000002200000022000022000000222200000000000000000000000
00000000000000000000000000000000220022220022222222002222222002200002200220000002200000022222222002222000000000000000000000000000
00000000000000000000000000000000220022220022222222002222222002200002200220000002200000022222222002222000000000000000000000000000
00000000000000000000000000000000220000220022002200002200022002222002200220000002200000022000022002200000000000000000000000000000
00000000000000000000000000000000220000220022002200002200022002222002200220000002200000022000022002200000000000000000000000000000
00000000000000000000000000000000222222220022000022002200022000022220000220000002200000022000022002222222200000000000000000000000
00000000000000000000000000000000222222220022000022002200022000022220000220000002200000022000022002222222200000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000707077700770707007700770077077707770000077707770770077707770777077700000000000000000000000000
00000000000000000000000000000000000707007007000707070007000707070707000070070707070070070707070707070700000000000000000000000000
00000000000000000000000000000000000777007007000777077707000707077007700000070707070070070707070707070700000000000000000000000000
00000000000000000000000000000000000707007007070707000707000707070707000070070707070070070707070707070700000000000000000000000000
00000000000000000000000000000000000707077707770707077000770770070707770000077707770777077707770777077700000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000077707770777007700770000007777700000077700770000077707770077077707700000000000000000000000000000
00000000000000000000000000000000070707070700070007000000077070770000007007070000070707000700007007070000000000000000000000000000
00000000000000000000000000000000077707700770077707770000077707770000007007070000077007700700007007070000000000000000000000000000
00000000000000000000000000000000070007070700000700070000077070770000007007070000070707000707007607070000000000000000000000000000
00000000000000000000000000000000070007070777077007700000007777700000007007700000077707770777077707070000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
4041424344454647474747474747010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051525354555657575757575757585f8a8b8b8b8b8b8b8b8b8c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
606162636465666768696a6b6c6d6e6f009b9b9b9b9c9c9c9c9c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
707172737475767778797a7b7c7d7e7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
808181818181818288898888888d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
909191919191919298959697089d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091919191919192882727272727aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091919191919192b8a5a6a7a8a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091919191919192000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091919191919192000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091919191919192000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091919191919192000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091919191919192000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a1a1a1a1a1a1a2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010d000024352263522b3520000001000010000100001000010000200001000010000200002000010000200001000146000200003000030000300003000030000300003000000000000000000000000000000000
010d00001765109641076310562102611000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00002f36300400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002477400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00200837100700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001455100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001675300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003a15638156361563315600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002475123752000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003575637752000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001265500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000018050160201b050110201405013020160501402018050160201b050140201605011020140500402018050160201b050110201405013020160501402018050160201b0501402016050110201405004020
010c002018050160201b050110201405013020160501402018050160201b050140201605011020140500402018050140201b0501102014050130201605014020240501f020200501b0201d050180501b05016050
010c00100c633180030c6331a0030c6330c633000030c6330c633000030c633000030c6330c633000030c63300000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002433024330243302433022330223301f3301f3301f3301f3301b3301b3301a3301a33018330183301b3301b3301d3301d3301f3301f3301d3301d3301d3301d3301b3301b33018330183301833018330
010c00002433024330243302433022330223301f3301f3301f3301f3301b3301b3301a3301a33018330183301b3301b3301d3301d3301f3301f33020330203302033020330223302233026330263302633026330
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f77
__music__
01 410b4344
00 420c474d
01 4b0b4d4e
00 420c4d4f
00 420b4d4d
00 420c0d4d
00 4e0b0d0e
00 420c0d0f
00 420b0d0e
00 420c0d0f
00 420b0d0e
02 420c0d0f
00 424b4d4e
02 424c4d4f
00 42554c4d
00 42564c4d
02 42574c4d
00 42584c41
00 42584441
00 42594441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434441
00 42434400
00 00000000

