local QBCore = exports['qb-core']:GetCoreObject()
local enabled = false
local player = false
local firstChar = false
local cam = false
local customCam = false
local oldPed = false
local startingMenu = false
local drawable_names = {"face", "masks", "hair", "torsos", "legs", "bags", "shoes", "neck", "undershirts", "vest", "decals", "jackets"}
local prop_names = {"hats", "glasses", "earrings", "mouth", "lhand", "rhand", "watches", "braclets"}
local head_overlays = {"Blemishes","FacialHair","Eyebrows","Ageing","Makeup","Blush","Complexion","SunDamage","Lipstick","MolesFreckles","ChestHair","BodyBlemishes","AddBodyBlemishes"}
local face_features = {"Nose_Width","Nose_Peak_Hight","Nose_Peak_Lenght","Nose_Bone_High","Nose_Peak_Lowering","Nose_Bone_Twist","EyeBrown_High","EyeBrown_Forward","Cheeks_Bone_High","Cheeks_Bone_Width","Cheeks_Width","Eyes_Openning","Lips_Thickness","Jaw_Bone_Width","Jaw_Bone_Back_Lenght","Chimp_Bone_Lowering","Chimp_Bone_Lenght","Chimp_Bone_Width","Chimp_Hole","Neck_Thikness"}
local tatCategory = GetTatCategs()
local tattooHashList = CreateHashList()
local StoreCost = 100;


function RefreshUI()
    hairColors = {}
    for i = 0, GetNumHairColors()-1 do
        local outR, outG, outB= GetPedHairRgbColor(i)
        hairColors[i] = {outR, outG, outB}
    end

    makeupColors = {}
    for i = 0, GetNumMakeupColors()-1 do
        local outR, outG, outB= GetPedMakeupRgbColor(i)
        makeupColors[i] = {outR, outG, outB}
    end

    SendNUIMessage({
        type="colors",
        hairColors=hairColors,
        makeupColors=makeupColors,
        hairColor=GetPedHair()
    })
    SendNUIMessage({
        type = "menutotals",
        drawTotal = GetDrawablesTotal(),
        propDrawTotal = GetPropDrawablesTotal(),
        textureTotal = GetTextureTotals(),
        headoverlayTotal = GetHeadOverlayTotals(),
        skinTotal = GetSkinTotal()
    })
    SendNUIMessage({
        type = "barbermenu",
        headBlend = GetPedHeadBlendData(),
        headOverlay = GetHeadOverlayData(),
        headStructure = GetHeadStructureData()
    })
    SendNUIMessage({
        type = "clothesmenudata",
        drawables = GetDrawables(),
        props = GetProps(),
        drawtextures = GetDrawTextures(),
        proptextures = GetPropTextures(),
        skin = GetSkin(),
        oldPed = oldPed,
    })
    SendNUIMessage({
        type = "tattoomenu",
        totals = tatCategory,
        values = GetTats()
    })
end

function GetSkin()
    for i = 1, #frm_skins do
        if (GetHashKey(frm_skins[i]) == GetEntityModel(PlayerPedId())) then
            return {name="skin_male", value=i}
        end
    end
    for i = 1, #fr_skins do
        if (GetHashKey(fr_skins[i]) == GetEntityModel(PlayerPedId())) then
            return {name="skin_female", value=i}
        end
    end
    return false
end

function GetDrawables()
    drawables = {}
    local model = GetEntityModel(PlayerPedId())
    local mpPed = false
    if (model == `mp_f_freemode_01` or model == `mp_m_freemode_01`) then
        mpPed = true
    end
    for i = 0, #drawable_names-1 do
        if mpPed and drawable_names[i+1] == "undershirts" and GetPedDrawableVariation(player, i) == -1 then
            SetPedComponentVariation(player, i, 15, 0, 2)
        end
        drawables[i] = {drawable_names[i+1], GetPedDrawableVariation(player, i)}
    end
    return drawables
end

function GetProps()
    props = {}
    for i = 0, #prop_names-1 do
        props[i] = {prop_names[i+1], GetPedPropIndex(player, i)}
    end
    return props
end

function GetDrawTextures()
    textures = {}
    for i = 0, #drawable_names-1 do
        table.insert(textures, {drawable_names[i+1], GetPedTextureVariation(player, i)})
    end
    return textures
end

function GetPropTextures()
    textures = {}
    for i = 0, #prop_names-1 do
        table.insert(textures, {prop_names[i+1], GetPedPropTextureIndex(player, i)})
    end
    return textures
end

function GetDrawablesTotal()
    drawables = {}
    for i = 0, #drawable_names - 1 do
        drawables[i] = {drawable_names[i+1], GetNumberOfPedDrawableVariations(player, i)}
    end
    return drawables
end

function GetPropDrawablesTotal()
    props = {}
    for i = 0, #prop_names - 1 do
        props[i] = {prop_names[i+1], GetNumberOfPedPropDrawableVariations(player, i)}
    end
    return props
end

function GetTextureTotals()
    local values = {}
    local draw = GetDrawables()
    local props = GetProps()

    for idx = 0, #draw-1 do
        local name = draw[idx][1]
        local value = draw[idx][2]
        values[name] = GetNumberOfPedTextureVariations(player, idx, value)
    end

    for idx = 0, #props-1 do
        local name = props[idx][1]
        local value = props[idx][2]
        values[name] = GetNumberOfPedPropTextureVariations(player, idx, value)
    end
    return values
end

function SetClothing(drawables, props, drawTextures, propTextures)
    for i = 1, #drawable_names do
        if drawables[0] == nil then
            if drawable_names[i] == "undershirts" and drawables[tostring(i-1)][2] == -1 then
                SetPedComponentVariation(player, i-1, 15, 0, 2)
            else
                SetPedComponentVariation(player, i-1, drawables[tostring(i-1)][2], drawTextures[i][2], 2)
            end
        else
            if drawable_names[i] == "undershirts" and drawables[i-1][2] == -1 then
                SetPedComponentVariation(player, i-1, 15, 0, 2)
            else
                SetPedComponentVariation(player, i-1, drawables[i-1][2], drawTextures[i][2], 2)
            end
        end
    end

    for i = 1, #prop_names do
        local propZ = (drawables[0] == nil and props[tostring(i-1)][2] or props[i-1][2])
        ClearPedProp(player, i-1)
        SetPedPropIndex(
            player,
            i-1,
            propZ,
            propTextures[i][2], true)
    end
end

function GetSkinTotal()
    print(#frm_skins)
	return {
        #frm_skins,
        #fr_skins
    }
end

local toggleClothing = {}
function ToggleProps(data)
    local name = data["name"]

    selectedValue = has_value(drawable_names, name)
    if (selectedValue > -1) then
        if (toggleClothing[name] ~= nil) then
            SetPedComponentVariation(
                player,
                tonumber(selectedValue),
                tonumber(toggleClothing[name][1]),
                tonumber(toggleClothing[name][2]), 2)
            toggleClothing[name] = nil
        else
            toggleClothing[name] = {
                GetPedDrawableVariation(player, tonumber(selectedValue)),
                GetPedTextureVariation(player, tonumber(selectedValue))
            }

            local value = -1
            if name == "undershirts" or name == "torsos" then
                value = 15
                if name == "undershirts" and GetEntityModel(PlayerPedId()) == GetHashKey('mp_f_freemode_01') then
                    value = -1
                end
            end
            if name == "legs" then
                value = 14
            end

            SetPedComponentVariation(
                player,
                tonumber(selectedValue),
                value, 0, 2)
        end
    else
        selectedValue = has_value(prop_names, name)
        if (selectedValue > -1) then
            if (toggleClothing[name] ~= nil) then
                SetPedPropIndex(
                    player,
                    tonumber(selectedValue),
                    tonumber(toggleClothing[name][1]),
                    tonumber(toggleClothing[name][2]), true)
                toggleClothing[name] = nil
            else
                toggleClothing[name] = {
                    GetPedPropIndex(player, tonumber(selectedValue)),
                    GetPedPropTextureIndex(player, tonumber(selectedValue))
                }
                ClearPedProp(player, tonumber(selectedValue))
            end
        end
    end
end

function SaveToggleProps()
    for k in pairs(toggleClothing) do
        local name  = k
        selectedValue = has_value(drawable_names, name)
        if (selectedValue > -1) then
            SetPedComponentVariation(
                player,
                tonumber(selectedValue),
                tonumber(toggleClothing[name][1]),
                tonumber(toggleClothing[name][2]), 2)
            toggleClothing[name] = nil
        else
            selectedValue = has_value(prop_names, name)
            if (selectedValue > -1) then
                SetPedPropIndex(
                    player,
                    tonumber(selectedValue),
                    tonumber(toggleClothing[name][1]),
                    tonumber(toggleClothing[name][2]), true)
                toggleClothing[name] = nil
            end
        end
    end
end

function LoadPed(data)
    SetSkin(data.model, true)
    SetClothing(data.drawables, data.props, data.drawtextures, data.proptextures)
    Citizen.Wait(500)
    SetPedHairColor(player, tonumber(data.hairColor[1]), tonumber(data.hairColor[2]))
    SetPedHeadBlend(data.headBlend)
    SetHeadStructure(data.headStructure)
    SetHeadOverlayData(data.headOverlay)
    return
end

function GetCurrentPed()
    player = GetPlayerPed(-1)
    return {
        model = GetEntityModel(PlayerPedId()),
        hairColor = GetPedHair(),
        headBlend = GetPedHeadBlendData(),
        headOverlay = GetHeadOverlayData(),
        headStructure = GetHeadStructure(),
        drawables = GetDrawables(),
        props = GetProps(),
        drawtextures = GetDrawTextures(),
        proptextures = GetPropTextures(),
    }
end

function PlayerModel(data)
    local skins = nil
    if (data['name'] == 'skin_male') then
        skins = frm_skins
    else
        skins = fr_skins
    end
    local skin = skins[tonumber(data['value'])]
    rotation(180.0)
    SetSkin(GetHashKey(skin), true)
    Citizen.Wait(1)
    rotation(180.0)
end

function SetSkin(model, setDefault)
    SetEntityInvincible(PlayerPedId(),true)
    if IsModelInCdimage(model) and IsModelValid(model) then
        RequestModel(model)
        while (not HasModelLoaded(model)) do
            Citizen.Wait(0)
        end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        player = GetPlayerPed(-1)
        FreezePedCameraRotation(player, true)
        if setDefault and model ~= nil and not isCustomSkin(model) then
            if (model ~= `mp_f_freemode_01` and model ~= `mp_m_freemode_01`) then
                SetPedRandomComponentVariation(GetPlayerPed(-1), true)
            else
                SetPedHeadBlendData(player, 0, 0, 0, 15, 0, 0, 0, 1.0, 0, false)
                SetPedComponentVariation(player, 11, 0, 11, 0)
                SetPedComponentVariation(player, 8, 0, 1, 0)
                SetPedComponentVariation(player, 6, 1, 2, 0)
                SetPedHeadOverlayColor(player, 1, 1, 0, 0)
                SetPedHeadOverlayColor(player, 2, 1, 0, 0)
                SetPedHeadOverlayColor(player, 4, 2, 0, 0)
                SetPedHeadOverlayColor(player, 5, 2, 0, 0)
                SetPedHeadOverlayColor(player, 8, 2, 0, 0)
                SetPedHeadOverlayColor(player, 10, 1, 0, 0)
                SetPedHeadOverlay(player, 1, 0, 0.0)
                SetPedHairColor(player, 1, 1)
            end
        end
    end
    SetEntityInvincible(PlayerPedId(),false)
end


RegisterNUICallback('updateclothes', function(data, cb)
    toggleClothing[data["name"]] = nil
    selectedValue = has_value(drawable_names, data["name"])
    if (selectedValue > -1) then
        SetPedComponentVariation(player, tonumber(selectedValue), tonumber(data["value"]), tonumber(data["texture"]), 2)
        cb({
            GetNumberOfPedTextureVariations(player, tonumber(selectedValue), tonumber(data["value"]))
        })
    else
        selectedValue = has_value(prop_names, data["name"])
        if (tonumber(data["value"]) == -1) then
            ClearPedProp(player, tonumber(selectedValue))
        else
            SetPedPropIndex(
                player,
                tonumber(selectedValue),
                tonumber(data["value"]),
                tonumber(data["texture"]), true)
        end
        cb({
            GetNumberOfPedPropTextureVariations(
                player,
                tonumber(selectedValue),
                tonumber(data["value"])
            )
        })
    end
end)

RegisterNUICallback('customskin', function(data, cb)
    if canUseCustomSkins() then
        local valid_model = isInSkins(data)
        if valid_model then
            SetSkin(GetHashKey(data), true)
        end
    end
end)

RegisterNUICallback('setped', function(data, cb)
    PlayerModel(data)
    RefreshUI()
    cb('ok')
end)

RegisterNUICallback('resetped', function(data, cb)
    LoadPed(oldPed)
    cb('ok')
end)


------------------------------------------------------------------------------------------
-- Barber

function GetPedHeadBlendData()
    local blob = string.rep("\0\0\0\0\0\0\0\0", 6 + 3 + 1) -- Generate sufficient struct memory.
    if not Citizen.InvokeNative(0x2746BD9D88C5C5D0, player, blob, true) then -- Attempt to write into memory blob.
        return nil
    end

    return {
        shapeFirst = string.unpack("<i4", blob, 1),
        shapeSecond = string.unpack("<i4", blob, 9),
        shapeThird = string.unpack("<i4", blob, 17),
        skinFirst = string.unpack("<i4", blob, 25),
        skinSecond = string.unpack("<i4", blob, 33),
        skinThird = string.unpack("<i4", blob, 41),
        shapeMix = string.unpack("<f", blob, 49),
        skinMix = string.unpack("<f", blob, 57),
        thirdMix = string.unpack("<f", blob, 65),
        hasParent = string.unpack("b", blob, 73) ~= 0,
    }
end

function SetPedHeadBlend(data)
    SetPedHeadBlendData(player,
        tonumber(data['shapeFirst']),
        tonumber(data['shapeSecond']),
        tonumber(data['shapeThird']),
        tonumber(data['skinFirst']),
        tonumber(data['skinSecond']),
        tonumber(data['skinThird']),
        tonumber(data['shapeMix']),
        tonumber(data['skinMix']),
        tonumber(data['thirdMix']),
        false)
end

function GetHeadOverlayData()
    local headData = {}
    for i = 1, #head_overlays do
        local retval, overlayValue, colourType, firstColour, secondColour, overlayOpacity = GetPedHeadOverlayData(player, i-1)
        if retval then
            headData[i] = {}
            headData[i].name = head_overlays[i]
            headData[i].overlayValue = overlayValue
            headData[i].colourType = colourType
            headData[i].firstColour = firstColour
            headData[i].secondColour = secondColour
            headData[i].overlayOpacity = overlayOpacity
        end
    end
    return headData
end

function SetHeadOverlayData(data)
    if json.encode(data) ~= "[]" then
        for i = 1, #head_overlays do
            SetPedHeadOverlay(player,  i-1, tonumber(data[i].overlayValue),  tonumber(data[i].overlayOpacity))
            --[[ SetPedHeadOverlayColor(player, i-1, data[i].colourType, data[i].firstColour, data[i].secondColour) ]]
        end

        SetPedHeadOverlayColor(player, 0, 0, tonumber(data[1].firstColour), tonumber(data[1].secondColour))
        SetPedHeadOverlayColor(player, 1, 1, tonumber(data[2].firstColour), tonumber(data[2].secondColour))
        SetPedHeadOverlayColor(player, 2, 1, tonumber(data[3].firstColour), tonumber(data[3].secondColour))
        SetPedHeadOverlayColor(player, 3, 0, tonumber(data[4].firstColour), tonumber(data[4].secondColour))
        SetPedHeadOverlayColor(player, 4, 2, tonumber(data[5].firstColour), tonumber(data[5].secondColour))
        SetPedHeadOverlayColor(player, 5, 2, tonumber(data[6].firstColour), tonumber(data[6].secondColour))
        SetPedHeadOverlayColor(player, 6, 0, tonumber(data[7].firstColour), tonumber(data[7].secondColour))
        SetPedHeadOverlayColor(player, 7, 0, tonumber(data[8].firstColour), tonumber(data[8].secondColour))
        SetPedHeadOverlayColor(player, 8, 2, tonumber(data[9].firstColour), tonumber(data[9].secondColour))
        SetPedHeadOverlayColor(player, 9, 0, tonumber(data[10].firstColour), tonumber(data[10].secondColour))
        SetPedHeadOverlayColor(player, 10, 1, tonumber(data[11].firstColour), tonumber(data[11].secondColour))
        SetPedHeadOverlayColor(player, 11, 0, tonumber(data[12].firstColour), tonumber(data[12].secondColour))
    end
end

function GetHeadOverlayTotals()
    local totals = {}
    for i = 1, #head_overlays do
        totals[head_overlays[i]] = GetNumHeadOverlayValues(i-1)
    end
    return totals
end

function GetPedHair()
    local hairColor = {}
    hairColor[1] = GetPedHairColor(player)
    hairColor[2] = GetPedHairHighlightColor(player)
    return hairColor
end

function GetHeadStructureData()
    local structure = {}
    for i = 1, #face_features do
        structure[face_features[i]] = GetPedFaceFeature(player, i-1)
    end
    return structure
end

function GetHeadStructure(data)
    local structure = {}
    for i = 1, #face_features do
        structure[i] = GetPedFaceFeature(player, i-1)
    end
    return structure
end

function SetHeadStructure(data)
    for i = 1, #face_features do
        SetPedFaceFeature(player, i-1, data[i])
    end
end


RegisterNUICallback('saveheadblend', function(data, cb)
    SetPedHeadBlendData(player,
    tonumber(data.shapeFirst),
    tonumber(data.shapeSecond),
    tonumber(data.shapeThird),
    tonumber(data.skinFirst),
    tonumber(data.skinSecond),
    tonumber(data.skinThird),
    tonumber(data.shapeMix) / 100,
    tonumber(data.skinMix) / 100,
    tonumber(data.thirdMix) / 100, false)
    cb('ok')
end)

RegisterNUICallback('savehaircolor', function(data, cb)
    SetPedHairColor(player, tonumber(data['firstColour']), tonumber(data['secondColour']))
end)

RegisterNUICallback('savefacefeatures', function(data, cb)
    local index = has_value(face_features, data["name"])
    if (index <= -1) then return end
    local scale = tonumber(data["scale"]) / 100
    SetPedFaceFeature(player, index, scale)
    cb('ok')
end)

RegisterNUICallback('saveheadoverlay', function(data, cb)
    local index = has_value(head_overlays, data["name"])
    SetPedHeadOverlay(player,  index, tonumber(data["value"]), tonumber(data["opacity"]) / 100)
    cb('ok')
end)

RegisterNUICallback('saveheadoverlaycolor', function(data, cb)
    local index = has_value(head_overlays, data["name"])
    local success, overlayValue, colourType, firstColour, secondColour, overlayOpacity = GetPedHeadOverlayData(player, index)
    local sColor = tonumber(data['secondColour'])
    if (sColor == nil) then
        sColor = tonumber(data['firstColour'])
    end
    SetPedHeadOverlayColor(player, index, colourType, tonumber(data['firstColour']), sColor)
    cb('ok')
end)

----------------------------------------------------------------------------------
-- UTIL SHIT


function has_value(tab, val)
    for index = 1, #tab do
        if tab[index] == val then
            return index-1
        end
    end
    return -1
end

function EnableGUI(enable, menu)
    enabled = enable
    SetNuiFocus(enable, enable)
    SendNUIMessage({
        type = "enableclothesmenu",
        enable = enable,
        menu = menu,
    })

    if (not enable) then
        SaveToggleProps()
        oldPed = {}
    end
end

function CustomCamera(position)
    if customCam or position == "torso" then
        FreezePedCameraRotation(player, false)
        SetCamActive(cam, false)
        RenderScriptCams(false,  false,  0,  true,  true)
        if (DoesCamExist(cam)) then
            DestroyCam(cam, false)
        end
        customCam = false
    else
        if (DoesCamExist(cam)) then
            DestroyCam(cam, false)
        end

        local pos = GetEntityCoords(player, true)
        SetEntityRotation(player, 0.0, 0.0, 0.0, 1, true)
        FreezePedCameraRotation(player, true)

        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(cam, player)
        SetCamRot(cam, 0.0, 0.0, 0.0)

        SetCamActive(cam, true)
        RenderScriptCams(true,  false,  0,  true,  true)

        SwitchCam(position)
        customCam = true
    end
end

function rotation(dir)
    local pedRot = GetEntityHeading(PlayerPedId())+dir
    SetEntityHeading(PlayerPedId(), pedRot % 360)
end

function TogRotation()
    local pedRot = GetEntityHeading(PlayerPedId())+90 % 360
    SetEntityHeading(PlayerPedId(), math.floor(pedRot / 90) * 90.0)
end

function SwitchCam(name)
    if name == "cam" then
        TogRotation()
        return
    end

    local pos = GetEntityCoords(player, true)
    local bonepos = false
    if (name == "head") then
        bonepos = GetPedBoneCoords(player, 31086)
        bonepos = vector3(bonepos.x - 0.1, bonepos.y + 0.4, bonepos.z + 0.05)
    end
    if (name == "torso") then
        bonepos = GetPedBoneCoords(player, 11816)
        bonepos = vector3(bonepos.x - 0.4, bonepos.y + 2.2, bonepos.z + 0.2)
    end
    if (name == "leg") then
        bonepos = GetPedBoneCoords(player, 46078)
        bonepos = vector3(bonepos.x - 0.1, bonepos.y + 1, bonepos.z)
    end

    SetCamCoord(cam, bonepos.x, bonepos.y, bonepos.z)
    SetCamRot(cam, 0.0, 0.0, 180.0)
end

RegisterNUICallback('escape', function(data, cb)
    Save(data['save'])
    EnableGUI(false, false)
    cb('ok')
end)

RegisterNUICallback('discard', function()
    EnableGUI(false, false)
    TriggerServerEvent('raid_clothes:get_character_current')
end)

RegisterNUICallback('togglecursor', function(data, cb)
    CustomCamera("torso")
    SetNuiFocus(false, false)
    FreezePedCameraRotation(player, false)
    cb('ok')
end)

RegisterNUICallback('rotate', function(data, cb)
    if (data["key"] == "left") then
        rotation(20)
    else
        rotation(-20)
    end
    cb('ok')
end)

RegisterNUICallback('switchcam', function(data, cb)
    CustomCamera(data['name'])
    cb('ok')
end)

RegisterNUICallback('toggleclothes', function(data, cb)
    ToggleProps(data)
    cb('ok')
end)

function GetTats()
    local tempTats = {}
    if currentTats == nil then return {} end
    for i = 1, #currentTats do
        for key in pairs(tattooHashList) do
            for j = 1, #tattooHashList[key] do
                if tattooHashList[key][j][1] == currentTats[i][2] then
                    tempTats[key] = j
                end
            end
        end
    end
    return tempTats
end

function SetTats(data)
    currentTats = {}
    for k, v in pairs(data) do
        for categ in pairs(tattooHashList) do
            if k == categ then
                local something = tattooHashList[categ][tonumber(v)]
                if something ~= nil then
                    table.insert(currentTats, {something[2], something[1]})
                end
            end
        end
    end
    ClearPedDecorations(PlayerPedId())
    for i = 1, #currentTats do
        ApplyPedOverlay(PlayerPedId(), currentTats[i][1], currentTats[i][2])
    end
end

RegisterNUICallback('settats', function(data, cb)
    SetTats(data["tats"])
    cb('ok')
end)


--------------------------------------------------------------------
-- Main menu

function OpenMenu(name)
    player = GetPlayerPed(-1)
    oldPed = GetCurrentPed()
    local isAllowed = false
    if(oldPed.model == 1885233650 or oldPed.model == -1667301416) then isAllowed = true end
    if((oldPed.model ~= 1885233650 or oldPed.model ~= -1667301416) and (name == "clothesmenu" or name == "tattoomenu" or name == "healmenu")) then isAllowed = true end
    if isAllowed then
        FreezePedCameraRotation(player, true)
        RefreshUI()
        EnableGUI(true, name)
     else
    --     -- TriggerEvent("DoLongHudText", "Je bent niet welkom hier!");
    end
end

function Save(save)
    if save then
        data = GetCurrentPed()
        TriggerServerEvent("raid_clothes:insert_character_current", data)
        if data.model == `mp_f_freemode_01` or data.model == `mp_m_freemode_01` then
            TriggerServerEvent("raid_clothes:insert_character_face", data)
            TriggerServerEvent("raid_clothes:set_tats", currentTats)
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.5)
        end
    else
        LoadPed(oldPed)
    end

    TriggerEvent("clothing:setupCommandsData")
    CustomCamera('torso')
end

function IsNearShop(shops)
    local dstchecked = 1000
    local plyPos = GetEntityCoords(GetPlayerPed(PlayerId()), false)
	for i = 1, #shops do
		shop = shops[i]
		local comparedst = Vdist(plyPos.x, plyPos.y, plyPos.z,shop[1], shop[2], shop[3])
		if comparedst < dstchecked then
			dstchecked = comparedst
		end

		-- if comparedst < 5.0 then
		-- 	DrawMarker(29,shop[1], shop[2], shop[3], 0, 0, 0, 0, 0, 0, 1.001, 1.0001, 1.500, 6, 169, 64, 300, 1, 1, 0, 1)
		-- end
	end
	return dstchecked
end

Citizen.CreateThread(function()
    local alreadyEnteredZone = false
    local text = nil
	while true do
        local ped = PlayerPedId()
        local inZone = false
		Citizen.Wait(1)
        local nearcloth = IsNearShop(clothingShops)
        local neartat = IsNearShop(tattoosShops)
        local nearbarber = IsNearShop(barberShops)


        local menu = nil
        local text = '[E] Open $' .. StoreCost .. ''
        if nearcloth < 4.0 then
           menu = {"clothesmenu"}
            inZone  = true
        elseif neartat < 4.0 then
            inZone  = true
            menu = {"tattoomenu"}

        elseif nearbarber < 4.0 then
            inZone  = true
            menu = {"barbermenu"}
        elseif startingMenu then
            menu = {"clothesmenu"}
            inZone  = true

        end


        if (menu ~= nil) then

            if (not enabled) then
                if IsControlJustPressed(1, 38) then
                    TriggerServerEvent("clothing:checkMoney",menu[1],StoreCost)
                end
            else
                DisablePlayerFiring(PlayerId(), true)
                if (IsControlJustReleased(1, 25)) then
                    SetNuiFocus(true, true)
                    FreezePedCameraRotation(player, true)
                end
                InvalidateIdleCam()
            end
        else
            local dist = math.min(nearcloth, neartat, nearbarber)
            if dist > 10 then
                Citizen.Wait(math.ceil(dist * 10))
            end
		end
        if inZone and not alreadyEnteredZone then
            alreadyEnteredZone = true
            TriggerEvent('cd_drawtextui:ShowUI', 'show', text)
        end

        if not inZone and alreadyEnteredZone then
            alreadyEnteredZone = false
            TriggerEvent('cd_drawtextui:HideUI')
        end
	end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent("clothing:checkIfNew")
end)

RegisterNetEvent("raid_clothes:hasEnough")
AddEventHandler("raid_clothes:hasEnough", function(menu)
    if menu == "tattoomenu" then
        TriggerServerEvent("raid_clothes:retrieve_tats")
        while currentTats == nil do
            Citizen.Wait(1)
        end
    end

    OpenMenu(menu)
end)

RegisterNetEvent('qb-clothes:client:CreateFirstCharacter', function()
        OpenMenu("clothesmenu")
        SetSkin(`mp_m_freemode_01`, true)
end)

RegisterNetEvent('qb-clothing:client:openMenu', function()
    OpenMenu("clothesmenu")
end)

RegisterNetEvent("raid_clothes:setclothes")
AddEventHandler("raid_clothes:setclothes", function(data,alreadyExist)
    player = GetPlayerPed(-1)
    local function setDefault()
        Citizen.CreateThread(function()
            firstChar = true
            Citizen.Wait(5000)
            SetSkin(`mp_m_freemode_01`, true)
            TriggerServerEvent("HOWMUCHCASHUHGOT")
            OpenMenu("clothesmenu")
            startingMenu = true
            SetEntityCoords(PlayerPedId(),-1038.2766113281 + (math.random(200) / 100),-2738.2648925781 + (math.random(200) / 100),20.169269561768)
            SetEntityHeading(PlayerPedId(),328.30828857422)
            DoScreenFadeIn(50)
            TriggerEvent("tokovoip:onPlayerLoggedIn", true)
            TriggerEvent("customNotification","Looks like you picked a character, nice job! You have a Hotel booked in the city, type /phone or press P to call a Taxi, Or, if you see one, hit F to jump inside it(this works anywhere). Once in the Taxi, mark the location on the map where you want to go for free! (Hotel 1).")
            SetNewWaypoint(312.96966552734,-218.2705078125)
            local dstHt = #(vector3(GetEntityCoords(PlayerPedId())) - vector3(312.96966552734,-218.2705078125,54.221797943115))

            while dstHt > 50.0 do
                dstHt = #(vector3(GetEntityCoords(PlayerPedId())) - vector3(312.96966552734,-218.2705078125,54.221797943115))
                Citizen.Wait(1)
            end

            TriggerEvent("customNotification","Theres the Hotel, finally, go inside and check it out. Be sure to save your clothing in the dresser by typing '/outfitadd 1 New Outfit' when you are near it. (P for Phone, F1 for Actions, K for inventory - most shops will show you what to do, also, you can use gurgle on your phone for more help!)")
        end)
    end

	if not data.model and alreadyExist <= 0 then setDefault() return end
    if not data.model and alreadyExist >= 1 then return end
    model = data.model
    model = model ~= nil and tonumber(model) or false

	if not IsModelInCdimage(model) or not IsModelValid(model) then setDefault() return end
    SetSkin(model, false)
    Citizen.Wait(500)
    SetClothing(data.drawables, data.props, data.drawtextures, data.proptextures)
    Citizen.Wait(500)
	TriggerEvent("clothing:setupCommandsData")
    TriggerServerEvent("raid_clothes:get_character_face")
    TriggerServerEvent("raid_clothes:retrieve_tats")
end)

-- RegisterNetEvent("raid_clothes:AdminSetModel")
-- AddEventHandler("raid_clothes:AdminSetModel", function(model)
--     local hashedModel = GetHashKey(model)
--     if not IsModelInCdimage(hashedModel) or not IsModelValid(hashedModel) then return end
--     SetSkin(hashedModel, true)
-- end)

-- RegisterNetEvent("raid_clothes:defaultReset")
-- AddEventHandler("raid_clothes:defaultReset", function()
--     local LocalPlayer = exports["np-base"]:getModule("LocalPlayer")
--     local gender = LocalPlayer:getCurrentCharacter().gender
--     Citizen.Wait(1000)
--     if gender ~= 0 then
--         SetSkin(`mp_f_freemode_01`, true)
--     else
--         SetSkin(`mp_m_freemode_01`, true)
--     end
--     --SetPedHeadBlendData(PlayerPedId(), 0, 0, 0, 15, 0, 0, 0, 1.0, 0, false)
--     --menu = "clothesmenu"
--     OpenMenu("clothesmenu")
--     startingMenu = true
-- end)

RegisterNetEvent("raid_clothes:settattoos")
AddEventHandler("raid_clothes:settattoos", function(playerTattoosList)
    currentTats = playerTattoosList
    SetTats(GetTats())
end)

RegisterNetEvent("raid_clothes:setpedfeatures")
AddEventHandler("raid_clothes:setpedfeatures", function(data)
    player = GetPlayerPed(-1)
    
    if not data then
        return
    end

    local head = data.headBlend
    local haircolor = data.hairColor

    SetPedHeadBlendData(player,
        tonumber(head['shapeFirst']),
        tonumber(head['shapeSecond']),
        tonumber(head['shapeThird']),
        tonumber(head['skinFirst']),
        tonumber(head['skinSecond']),
        tonumber(head['skinThird']),
        tonumber(head['shapeMix']),
        tonumber(head['skinMix']),
        tonumber(head['thirdMix']),
    false)

    SetHeadStructure(data.headStructure)
    SetPedHairColor(player, tonumber(haircolor[1]), tonumber(haircolor[2]))
    SetHeadOverlayData(data.headOverlay)
end)

RegisterCommand("outfits", function(source, args, rawCommand)
    if (IsNearShop(clothingShops) < 9.0) then
        TriggerServerEvent('qb-outfits:server:openUI')
    else
        QBCore.Functions.Notify("You are not near a wardrobe", "error")
    end
end, false)

RegisterCommand("loadskin", function(source, args, rawCommand)

TriggerServerEvent('raid_clothes:get_character_current')
end)