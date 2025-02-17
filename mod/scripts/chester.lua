-- 环境感知
local function GetEnvironmentInfo()
    local env = {}

    -- 获取季节
    env.season = GLOBAL.TheWorld.state.season

    -- 获取温度
    if GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.temperature then
        env.temperature = GLOBAL.ThePlayer.components.temperature:GetCurrent()
    else
        env.temperature = "unknown"
    end

    -- 获取生物群系（通过坐标判断）
    local x, y, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    local tile = GLOBAL.TheWorld.Map:GetTileAtPoint(x, y, z)
    env.biome = tostring(tile)

    -- 获取天气
    if GLOBAL.TheWorld.state.israining then
        env.weather = "raining"
    elseif GLOBAL.TheWorld.state.issnowing then
        env.weather = "snowing"
    else
        env.weather = "clear"
    end

    return env
end

-- 获取怪物信息
local function GetMonsterInfo(monsters)
    local monster_info = {}
    for _, monster in ipairs(monsters) do
        table.insert(monster_info, monster.prefab)
    end
    return table.concat(monster_info, ", ")
end

-- 调用 DeepSeek 模型
local function SendToDeepSeek(prompt)
    local url = "http://localhost:5000/api/chat" -- 本地 DeepSeek API 地址
    local headers = {["Content-Type"] = "application/json"}
    local body = json.encode({prompt = prompt, max_tokens = 50})

    -- 发送 HTTP 请求
    local response = GLOBAL.TheSim:HttpGet(url, body, headers)
    local data = json.decode(response)
    return data.response -- 假设 API 返回的响应字段是 response
end

-- 切斯特发言
local function ChesterSpeak(inst, message)
    if inst.components.talker then inst.components.talker:Say(message) end
end

-- 检查环境信息并生成对话
local function GenerateChesterDialogue(inst)
    local env = GetEnvironmentInfo()
    local prompt = string.format(
                       "Current environment: Season=%s, Temperature=%s, Biome=%s, Weather=%s. What should Chester say?",
                       env.season, env.temperature, env.biome, env.weather)

    local response = SendToDeepSeek(prompt)
    ChesterSpeak(inst, response)
end

-- 检测附近怪物并生成对话
local function CheckForDangers(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local monsters = GLOBAL.TheSim:FindEntities(x, y, z, 10, {"monster"})
    if #monsters > 0 then
        local monster_info = GetMonsterInfo(monsters)
        local prompt = string.format(
                           "Monsters detected nearby: %s. What should Chester say?",
                           monster_info)
        local response = SendToDeepSeek(prompt)
        ChesterSpeak(inst, response)
    end
end

-- 修改切斯特行为
local function MakeSmartChester(inst)
    if not GLOBAL.TheWorld.ismastersim then return inst end

    -- 添加对话组件
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = GLOBAL.TALKINGFONT
    inst.components.talker.colour = GLOBAL.Vector3(1, 1, 1)
    inst.components.talker.offset = GLOBAL.Vector3(0, -400, 0)

    -- 定时器：每隔一段时间随机发言
    local function OnTimer()
        GenerateChesterDialogue(inst)
        inst:DoTaskInTime(math.random(30, 60), OnTimer) -- 每隔 30-60 秒发言一次
    end
    inst:DoTaskInTime(10, OnTimer) -- 10 秒后开始发言

    -- 监听玩家接近事件
    inst:ListenForEvent("onnear", function(inst, player)
        if player and player.components.talker then
            GenerateChesterDialogue(inst)
        end
    end)

    -- 监听怪物接近事件
    inst:DoPeriodicTask(5, function() CheckForDangers(inst) end) -- 每隔 5 秒检测一次

    -- 玩家互动
    -- inst:AddComponent("inspectable")
    -- inst.components.inspectable:SetDescription(function()
    --     return "A smart Chester who loves to chat!"
    -- end)

    -- inst:ListenForEvent("onactivate", function(inst, doer)
    --     if doer and doer.components.talker then
    --         GenerateChesterDialogue(inst)
    --     end
    -- end)

    return inst
end

-- 覆盖默认切斯特 Prefab
AddPrefabPostInit("chester", MakeSmartChester)
