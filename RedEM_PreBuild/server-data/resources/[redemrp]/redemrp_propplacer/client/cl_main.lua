math.randomseed(GetGameTimer())
local CancelPrompt
local SetPrompt
local RotateLeftPrompt
local RotateRightPrompt
local active = false
local Props = {}

local PromptPlacerGroup = GetRandomIntInRange(0, 0xffffff)
--print('PromptPlacerGroup: ' .. PromptPlacerGroup)

Citizen.CreateThread(function()
    Set()
    Del()
    RotateLeft()
    RotateRight()
end)
function Del()
    Citizen.CreateThread(function()
        local str = 'Cancel'
        CancelPrompt = PromptRegisterBegin()
        PromptSetControlAction(CancelPrompt, 0xF84FA74F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(CancelPrompt, str)
        PromptSetEnabled(CancelPrompt, true)
        PromptSetVisible(CancelPrompt, true)
        PromptSetHoldMode(CancelPrompt, true)
        PromptSetGroup(CancelPrompt, PromptPlacerGroup)
        PromptRegisterEnd(CancelPrompt)

    end)
end

function Set()
    Citizen.CreateThread(function()
        local str = 'Set'
        SetPrompt = PromptRegisterBegin()
        PromptSetControlAction(SetPrompt, 0x07CE1E61)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(SetPrompt, str)
        PromptSetEnabled(SetPrompt, true)
        PromptSetVisible(SetPrompt, true)
        PromptSetHoldMode(SetPrompt, true)
        PromptSetGroup(SetPrompt, PromptPlacerGroup)
        PromptRegisterEnd(SetPrompt)

    end)
end


function RotateLeft()
    Citizen.CreateThread(function()
        local str = 'Rotate Left'
        RotateLeftPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateLeftPrompt, str)
        PromptSetEnabled(RotateLeftPrompt, true)
        PromptSetVisible(RotateLeftPrompt, true)
        PromptSetStandardMode(RotateLeftPrompt, true)
        PromptSetGroup(RotateLeftPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateLeftPrompt)

    end)
end

function RotateRight()
    Citizen.CreateThread(function()
        local str = 'Rotate Right'
        RotateRightPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateRightPrompt, 0xDEB34313)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateRightPrompt, str)
        PromptSetEnabled(RotateRightPrompt, true)
        PromptSetVisible(RotateRightPrompt, true)
        PromptSetStandardMode(RotateRightPrompt, true)
        PromptSetGroup(RotateRightPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateRightPrompt)

    end)
end
function modelrequest( model )
    Citizen.CreateThread(function()
        RequestModel( model )
    end)
end

function PropPlacer(ObjectModel)
    local myPed = PlayerPedId()
    local pHead = GetEntityHeading(myPed)
    local pos = GetEntityCoords(myPed)
    local PropHash = GetHashKey(ObjectModel)
    local coords = GetEntityCoords(myPed)
    local _x,_y,_z = table.unpack(coords)
    local forward = GetEntityForwardVector(myPed)
    local x, y, z = table.unpack(pos - forward * -2.0)
    local ox = x -_x
    local oy = y-_y
    local oz = z - _z
    local heading = 0.0
    local object
    --print(ox,oy)
    --print(x,y)
    SetCurrentPedWeapon(myPed, -1569615261, true)
    while not HasModelLoaded( PropHash ) do
        Wait(500)
        modelrequest( PropHash )
    end
    local tempObj = CreateObject(PropHash, pos.x, pos.y, pos.z, false, false, false)
    local tempObj2 = CreateObject(PropHash, pos.x, pos.y, pos.z, false, false, false)
    AttachEntityToEntity(tempObj2, myPed, 0, ox, oy, 0.5, 0.0, 0.0, 0, true, false, false, false, false)
    SetEntityAlpha(tempObj, 60)
    SetEntityAlpha(tempObj2, 0)

    while true do
        Wait(5)
        local PropPlacerGroupName  = CreateVarString(10, 'LITERAL_STRING', "PropPlacer")
        PromptSetActiveGroupThisFrame(PromptPlacerGroup, PropPlacerGroupName)

        AttachEntityToEntity(tempObj, myPed, 0, ox, oy, -0.8, 0.0, 0.0, heading, true, false, false, false, false)
        if IsControlPressed( 1, 0xA65EBAB4) then
            heading = heading - 1
        end
        if IsControlPressed( 1, 0xDEB34313) then
            heading = heading + 1
        end

        local pPos = GetEntityCoords(tempObj2)

        if PromptHasHoldModeCompleted(SetPrompt) then
            FreezeEntityPosition(PlayerPedId() , true)
            TriggerServerEvent("redemrp_propplacer:SaveProp" ,PropHash ,  pPos.x , pPos.y , pPos.z , heading , "perm")
            DeleteEntity(tempObj2)
            DeleteEntity(tempObj)
            FreezeEntityPosition(PlayerPedId() , false)
            break
        end

        if PromptHasHoldModeCompleted(CancelPrompt) then
            DeleteEntity(tempObj2)
            DeleteEntity(tempObj)
            SetModelAsNoLongerNeeded(PropHash)
            break
        end
    end
end

RegisterCommand("placeprop", function(source, args, rawCommand)
  PropPlacer(args[1])
end)

local StopPlace = false
RegisterCommand("deleteprop", function(source, args, rawCommand)
    StopPlace = true
    for k,v in pairs(Props) do
        local coords = GetEntityCoords(PlayerPedId())
        local distance = Vdist(v.x,v.y,v.z ,coords)
        if distance < 1 and v.obj ~= nil and DoesEntityExist(v.obj) then
            DeleteEntity(v.obj)
            TriggerServerEvent("redemrp_propplacer:DeleteProp" , k)
            Props[k] = nil
            --print("deleting...")

        end
    end
end)
RegisterNetEvent('redemrp_propplacer:delete')
AddEventHandler('redemrp_propplacer:delete', function(coords)
    for k,v in pairs(Props) do
        local distance = Vdist(v.x,v.y,v.z,coords)
		--print(distance)
        if distance < 2 and v.obj ~= nil and DoesEntityExist(v.obj) then
            DeleteEntity(v.obj)
			 if v.smoke ~= nil then
				StopParticleFxLooped(v.smoke , true)
				--print("deleting smoke...")
			end
            TriggerServerEvent("redemrp_propplacer:DeleteProp" , k)
            Props[k] = nil
            --print("deleting...")
        end
    end
end)

local timer = 0
Citizen.CreateThread(function()
    while true do
        Wait(1)
	local canwait = true		
        if not StopPlace then
	  local coords = GetEntityCoords(PlayerPedId())			
            for k,v in pairs(Props) do
			if v.time ~= "perm" then
				if  math.floor(v.time/1000) > 0 then
					v.time = v.time - 17
				end
			end
              
              		 local distance = #(vector3(v.x,v.y,v.z) - coords)
				if distance < 8 and v.time ~= "perm" then
					canwait = false
				end
				if v.time ~= "perm" then
					if distance < 2  and DoesEntityExist(v.obj) and math.floor(v.time/1000) > 0 then
						TxtAtWorldCoord(v.x,v.y,v.z, SecondsToClock(math.floor(v.time/1000)), 0.2 , 1)
					end
					if distance < 2 and math.floor(v.time/1000) <=0 then
						TxtAtWorldCoord(v.x,v.y,v.z, "Object will be destroyed within minutes", 0.2 , 1)
					end
					if distance < 1.5 and math.floor(v.time/1000) > 0 then
						TxtAtWorldCoord(v.x,v.y,v.z+0.15, "Press F4 to strengthen the structure", 0.2 , 1)
						 if IsControlJustReleased(1, 0x1F6D95E5) then
						   TriggerServerEvent("redemrp_propplacer:Repair" , k)
						 end
					end
					if distance < 1.5 and v.prophash ==  GetHashKey("p_still04x") then
						TxtAtWorldCoord(v.x,v.y,v.z-0.15, "Press Shift to destroy", 0.2 , 1)
						 if IsControlJustReleased(1, 0x8FFC75D6) then
							exports['progressBars']:startUI(5000, 'Destroying the moonshine plant...')
							FreezeEntityPosition(PlayerPedId() , true)
							Wait(5000)
							FreezeEntityPosition(PlayerPedId() , false)
						   TriggerServerEvent("redemrp_propplacer:DestroyProp" , k)
						 end
					end
				end
                if distance > 60 and v.obj ~= nil and DoesEntityExist(v.obj) then
                    DeleteEntity(v.obj)
                    --print("deleting...")
                elseif distance < 40 and (v.obj == nil or not DoesEntityExist(v.obj))then
                    while not HasModelLoaded( v.prophash ) do
                        Wait(100)
                        modelrequest( v.prophash )
                    end
                    v.obj = CreateObject(v.prophash, v.x,v.y,v.z, false, false, false)
                    SetEntityLodDist(v.obj  , 40)
                    SetEntityHeading(v.obj ,v.heading)
                    PlaceObjectOnGroundProperly(v.obj)
                    SetEntityAsMissionEntity(v.obj, true, true)
                    FreezeEntityPosition(v.obj , true)
                    SetModelAsNoLongerNeeded(v.prophash)
                    --print("placing...")
                end
            end
        end
	if canwait and  timer < GetGameTimer() then
		timer = GetGameTimer()+1000
	end
    end
end)

function TxtAtWorldCoord(x, y, z, txt, size, font)
    local s, sx, sy = GetScreenCoordFromWorldCoord(x, y ,z)
    if (sx > 0 and sx < 1) or (sy > 0 and sy < 1) then
        local s, sx, sy = GetHudScreenPositionFromWorldPosition(x, y, z)
        DrawTxt(txt, sx, sy, size, true, 255, 255, 255, 255, true, font) -- Font 2 has some symbol conversions ex. @ becomes the rockstar logo
    end
end

function DrawTxt(str, x, y, size, enableShadow, r, g, b, a, centre, font)
    local str = CreateVarString(10, "LITERAL_STRING", str)
    SetTextScale(1, size)
    SetTextColor(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    SetTextFontForCurrentCommand(font)
    DisplayText(str, x, y)
end

function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
end


RegisterNetEvent("redemrp_propplacer:GetProps")
AddEventHandler("redemrp_propplacer:GetProps", function(data)
    for k,v in pairs(Props) do
        DeleteEntity(v.obj)
		while DoesEntityExist(v.obj) do
			Wait(1)
		end
		--print("deleting...")
        if v.smoke ~= nil then
            StopParticleFxLooped(v.smoke , true)
			--print("deleting smoke...")
        end
    end
    Props = data
    for k,v in pairs(Props) do
        if v.prophash ==  GetHashKey("p_still04x") then
            UseParticleFxAsset("SCR_ADV_SOK")
            v.smoke = StartParticleFxLoopedAtCoord("scr_adv_sok_torchsmoke", v.x,v.y,v.z-2.5, 0.0,0.0,0.0, 2.0, false, false, false, true)
            Citizen.InvokeNative(0x9DDC222D85D5AF2A, v.smoke, 10.0)
            SetParticleFxLoopedAlpha(v.smoke, 1.0)
            SetParticleFxLoopedColour(v.smoke, 0.3, 0.3, 0.3, false)

        end
    end
    StopPlace = false
end)


RegisterNetEvent('playerSpawned')
AddEventHandler('playerSpawned', function()
        TriggerServerEvent('redemrp_propplacer:PropRequest')
end)


