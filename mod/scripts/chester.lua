-- 获取环境信息
local function GetEnvironmentInfo()
  local env = {}
  env.season = GLOBAL.TheWorld.state.season
  if GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.temperature then
      env.temperature = GLOBAL.ThePlayer.components.temperature:GetCurrent()
  else
      env.temperature = "unknown"
  end
  local x, y, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
  local tile = GLOBAL.TheWorld.Map:GetTileAtPoint(x, y, z)
  env.biome = tostring(tile)
  if GLOBAL.TheWorld.state.israining then
      env.weather = "raining"
  elseif GLOBAL.TheWorld.state.issnowing then
      env.weather = "snowing"
  else
      env.weather = "clear"
  end
  return env
end

-- 调用 DeepSeek API
local function SendToDeepSeek(prompt)
  local url = "http://localhost:5000/api/chat"
  local headers = {
      ["Content-Type"] = "application/json"
  }
  local body = json.encode({
      prompt = prompt
  })
  local response = GLOBAL.TheSim:HttpGet(url, body, headers)
  local data = json.decode(response)
  return data.response
end

-- 切斯特发言
local function ChesterSpeak(inst, message)
  if inst.components.talker then
      inst.components.talker:Say(message)
  end
end

-- 生成对话
local function GenerateChesterDialogue(inst)
  local env = GetEnvironmentInfo()
  local prompt = string.format("Current environment: Season=%s, Temperature=%s, Biome=%s, Weather=%s. What should Chester say?",
      env.season, env.temperature, env.biome, env.weather)
  local response = SendToDeepSeek(prompt)
  ChesterSpeak(inst, response)
end

-- 修改切斯特行为
local function MakeSmartChester(inst)
  if not GLOBAL.TheWorld.ismastersim then
      return inst
  end

  -- 添加对话组件
  inst:AddComponent("talker")
  inst.components.talker.fontsize = 35
  inst.components.talker.font = GLOBAL.TALKINGFONT
  inst.components.talker.colour = GLOBAL.Vector3(1, 1, 1)
  inst.components.talker.offset = GLOBAL.Vector3(0, -400, 0)

  -- 定时器：每隔 30-60 秒发言一次
  local function OnTimer()
      GenerateChesterDialogue(inst)
      inst:DoTaskInTime(math.random(30, 60), OnTimer)
  end
  inst:DoTaskInTime(10, OnTimer)

  -- 监听玩家接近事件
  inst:ListenForEvent("onnear", function(inst, player)
      if player and player.components.talker then
          GenerateChesterDialogue(inst)
      end
  end)

  return inst
end

-- 覆盖默认切斯特 Prefab
AddPrefabPostInit("chester", MakeSmartChester)