-- 加载 json 库
local json = require("json")

-- 环境感知
local function GetEnvironmentInfo()
    local env = {}

    -- 获取季节
    env.season = GLOBAL.TheWorld.state.season

    -- 获取温度
    if GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.temperature then
        env.temperature = GLOBAL.ThePlayer.components.temperature:GetCurrent()
    else
        env.temperature = "未知"
    end

    -- 获取生物群系（通过坐标判断）
    local x, y, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    local tile = GLOBAL.TheWorld.Map:GetTileAtPoint(x, y, z)
    env.biome = tostring(tile)

    -- 获取天气
    if GLOBAL.TheWorld.state.israining then
        env.weather = "下雨"
    elseif GLOBAL.TheWorld.state.issnowing then
        env.weather = "下雪"
    else
        env.weather = "晴朗"
    end

    print("环境信息: 季节=" .. env.season .. ", 温度=" .. env.temperature .. ", 生物群系=" .. env.biome .. ", 天气=" .. env.weather)
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
local function SendToDeepSeek(messages, callback)
    local url = "http://localhost:3000/api/chat" -- 本地 DeepSeek API 地址
    local headers = {["Content-Type"] = "application/json"}
    local body = json.encode({messages = messages})

    -- 添加调试信息
    print("发送请求到 DeepSeek API...")
    print("请求内容: " .. body)

    -- 发送 HTTP 请求
    TheSim:QueryServer(url, function(response, isSuccessful, resultCode)
        if not isSuccessful then
            print("错误: 未收到 DeepSeek API 的响应")
            callback("无法获取响应")
            return
        end

        local data = json.decode(response)
        if not data or not data.response then
            print("错误: DeepSeek API 返回无效响应")
            callback("无效的响应")
            return
        end

        print("收到 DeepSeek API 的响应: " .. response)
        callback(data.response) -- 假设 API 返回的响应字段是 response
    end, "POST", body, 60, headers) -- 修改第四个参数为数字（例如 60 秒超时）
end

-- 切斯特发言
local function ChesterSpeak(inst, message)
    if inst.components.talker then
        print("切斯特说: " .. message)
        inst.components.talker:Say(message)
    else
        print("错误: 切斯特没有对话组件")
    end
end

-- 检查环境信息并生成对话
local function GenerateChesterDialogue(inst)
    local env = GetEnvironmentInfo()
    local messages = {
        {
            role = "system",
            content = string.format(
                "当前环境: 季节=%s, 温度=%s, 生物群系=%s, 天气=%s。切斯特应该说什么？",
                env.season, env.temperature, env.biome, env.weather)
        }
    }

    print("生成切斯特对话，环境信息: " .. messages[1].content)
    SendToDeepSeek(messages, function(response)
        ChesterSpeak(inst, response)
    end)
end

-- 检测附近怪物并生成对话
local function CheckForDangers(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local monsters = GLOBAL.TheSim:FindEntities(x, y, z, 10, {"monster"})
    if #monsters > 0 then
        local monster_info = GetMonsterInfo(monsters)
        local messages = {
            {
                role = "system",
                content = string.format(
                    "附近发现怪物: %s。切斯特应该说什么？",
                    monster_info)
            }
        }

        print("生成切斯特对话，怪物信息: " .. messages[1].content)
        SendToDeepSeek(messages, function(response)
            ChesterSpeak(inst, response)
        end)
    else
        print("附近没有发现怪物")
    end
end

-- 修改切斯特行为
local function MakeSmartChester(inst)
    print("初始化智能切斯特4")
    -- if not GLOBAL.TheWorld.ismastersim then
    --     print("智能切斯特只能在服务器端运行")
    --     return inst
    -- end

    -- 添加对话组件
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = GLOBAL.TALKINGFONT
    inst.components.talker.colour = GLOBAL.Vector3(1, 1, 1)
    inst.components.talker.offset = GLOBAL.Vector3(0, -400, 0)

    -- 定时器：每隔一段时间随机发言
    local function OnTimer()
        print("定时器触发")
        GenerateChesterDialogue(inst)
        inst:DoTaskInTime(math.random(30, 60), OnTimer) -- 每隔 30-60 秒发言一次
    end
    inst:DoTaskInTime(10, OnTimer) -- 10 秒后开始发言

    -- -- 监听玩家接近事件
    -- inst:ListenForEvent("onnear", function(inst, player)
    --     if player and player.components.talker then
    --         print("玩家接近，生成对话")
    --         GenerateChesterDialogue(inst)
    --     else
    --         print("玩家接近但没有对话组件")
    --     end
    -- end)

    -- 监听怪物接近事件
    inst:DoPeriodicTask(5, function() CheckForDangers(inst) end) -- 每隔 5 秒检测一次

    return inst
end

-- 覆盖默认切斯特 Prefab
AddPrefabPostInit("chester", MakeSmartChester)
