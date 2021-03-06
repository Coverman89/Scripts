--<< Bottle_Crow - Script By Coverman 0.2.1 >>
require("libs.ScriptConfig")
require("libs.Utils")

--CONFIGS
local config = ScriptConfig.new()
config:SetParameter("ativar", "T" , config.TYPE_HOTKEY)
config:SetParameter("hotkeygalinha", "Y", config.TYPE_HOTKEY)
config:Load()

--VARIAVEIS GLOBAIS
local monitor = client.screenSize.x/1600
local F11 = drawMgr:CreateFont("F11","Tahoma",11*monitor,550*monitor) 
local texto = drawMgr:CreateText( 350 , 50 , -1 ,  "Test Text" , F11 ) texto.visible=false
local texto2 = drawMgr:CreateText( 350 , 70 , -1 ,  "Stage: " , F11 ) texto2.visible=false

local galinha = nil
local lugar = nil
local me = nil
local player = nil
local play = false
local count = 0 -- variavel de teste de bugs
local fase = 0 -- 0 desligado, 1 buscando, 2 pegando, 3 entregando
local fazendo = 0 -- conserta bug da fase 4
local zerocd = 0
local fez = 0

function Tick()
	if client.console or not SleepCheck() then return end

	if galinha then
		if galinha:GetAbility(6).state == LuaEntityAbility.STATE_READY then
			zerocd = 1
			fez = 0
		else
			zerocd = 0
		end
	end

	if zerocd == 1 and galinha.courState ~= 0 and fez== 0 then
		galinha:CastAbility(galinha:GetAbility(6),false)
		fez = 1
	end

	

	-- FASE 1 (PEGAR ITEM)
	if galinha and lugar and GetDistance2D(galinha,lugar) < 290 and fase == 1 and me.alive then 
		fase = 2 -- CHEGOU AO LUGAR -> pegar
		texto2.text = "Stage: "..fase
	end

	if galinha and lugar and galinha.courStateEntity ~= me and fase == 1 then
		galinha:Move(lugar,false)
	end
	
	-- FASE 2
	if fase == 2 then
		local itemsChao = entityList:GetEntities({type=LuaEntity.TYPE_ITEM_PHYSICAL})
		for i,item in ipairs(itemsChao) do
	  		if GetDistance2D(galinha,item.position) < 350 then
				player:Select(galinha)
				player:TakeItem(item)
				fase = 3
				texto2.text = "Stage: "..fase
				player:Select(me)
			end
		end
	end

	-- FASE 3
	if fase == 3 then 
		if fazendo == 0 then
			galinha:CastAbility(galinha:GetAbility(1),false) -- vai pra base
			fazendo = 1
		end
		if fazendo == 1 and galinha.courState ~= 4 then
			galinha:CastAbility(galinha:GetAbility(1),false) -- vai pra base
		end
		local abottle = galinha:GetItem(1)
		if abottle and abottle.name == "item_bottle" then
			if abottle.charges == 3 then
				fase = 4
				fazendo = 0
				texto2.text = "Stage: "..fase
			end
		end
	end

	if fase == 4 then -- 
		if fazendo == 0 then 
			galinha:CastAbility(galinha:GetAbility(5),false)
			fazendo = 1
		end
		if fazendo == 1 and galinha.courState ~= 3 then
			galinha:CastAbility(galinha:GetAbility(5),false) -- vai pra base
		end
		if me:FindItem("item_bottle") then
			fase = 0
			texto2.text = "Stage: "..fase
			fazendo = 0
		end
	end
	Sleep(200)
end

function Key(msg,code)
	
	if client.chat or msg ~= KEY_DOWN then
		return
	end
	local bottle = me:FindItem("item_bottle")

	--FASE 0 (DROPA ITEM > GALINHA VAI ATE LOCAL)
	if code == config.ativar and galinha ~= nil and bottle and bottle.charges < 3 then
		if fase == 0 then
			fase = 1 -- ir ate local
			texto2.text = "Stage: "..fase
			lugar = me.position
			player:DropItem(bottle,me.position,false)
			galinha:Move(lugar,false)
		end
	end

	-- Tentou ativar sem courier
	if code == config.ativar and galinha == nil then
		texto2.text = "Please, choose a courier first"
	end

	-- Seleção de courier
	if code == config.hotkeygalinha and player.selection[1].name == "npc_dota_courier" then
		galinha = player.selection[1]
		texto2.text = "Courier selected with sucess "..galinha.name
	end

	-- ERRO, SELECIONOU UNIDADE QUE NAO É COURIER
	if code == config.hotkeygalinha and player.selection[1].name ~= "npc_dota_courier" then
		texto2.text = "Please, select a courier type."
	end

	texto.text = "No bugs. Number of keys pressed "..count..". Last key pressed "..tostring(code)
	count = count + 1
end

function Load()
	if PlayingGame() then
		me = entityList:GetMyHero()
		player = entityList:GetMyPlayer()
		script:RegisterEvent(EVENT_KEY,Key)
		script:RegisterEvent(EVENT_TICK,Tick)
		script:UnregisterEvent(Load)
		texto.visible = true
		texto2.visible = true
		play = true
	end
end

function GameClose()
	if play then
		script:UnregisterEvent(Key)
		script:UnregisterEvent(Tick)
		script:RegisterEvent(EVENT_TICK,Load)
		texto.visible = false
		texto2.visible = false
		fase = 0
		player = nil
		me = nil
		galinha = nil
		lugar = nil
		count = 0 -- variavel de teste de bugs
		fase = 0 -- 0 desligado, 1 buscando, 2 pegando, 3 entregando
		fazendo = 0 -- conserta bug da fase 4
		zerocd = 0
		fez = 0
	end
end

script:RegisterEvent(EVENT_CLOSE,GameClose) 
script:RegisterEvent(EVENT_TICK,Load)
