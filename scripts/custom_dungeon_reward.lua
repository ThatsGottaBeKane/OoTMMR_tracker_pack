DungeonReward = CustomItem:extend()

local names = {
  "Free Reward",
  "Deku Tree Reward",
  "Dodongos Cavern Reward",
  "Jabu Jabu Reward",
  "Forest Temple Reward",
  "Fire Temple Reward",
  "Water Temple Reward",
  "Spirit Temple Reward",
  "Shadow Temple Reward",
  "MM Woodfall Temple Reward",
  "MM Snowhead Temple Reward",
  "MM Great Bay Temple Reward",
  "MM Stone Tower Temple Reward"
}

local codes = {
  "free",
  "deku",
  "dodongo",
  "jabu",
  "forest",
  "fire",
  "water",
  "spirit",
  "shadow",
  "mm_woodfall",
  "mm_snowhead",
  "mm_great_bay",
  "mm_stone_tower"
}

local rewards = {
  "unknown",
  "oot_spiritual_stone",
  "oot_medallion_forest",
  "oot_nocturne_med",
  "oot_lacs_med",
  "oot_medallion_light",
  "mm_remains_odolwa",
  "mm_remains_gyorg",
  "mm_remains_goth",
  "mm_remains_twinmold"
}

local images = {
  "images/unknown.png",
  "images/stones.png",
  "images/forestmedallion.png",
  "images/nocturne_medallions.png",
  "images/lacs_medallions.png",
  "images/lightmedallion.png",
  "images/items/mm_odolwa.png",
  "images/items/mm_goht.png",
  "images/items/mm_gyorg.png",
  "images/items/mm_twinmold.png"
}

local quickModeOrder = {6, 3, 4, 4, 5, 5}
local quickModeActive = nil

function DungeonReward:init(number)
  self:createItem(names[number])
  self.number = number
  self.code = codes[number]
  self:setProperty("active", false)
  self:setProperty("stage", 1)
  self.imageBase = ImageReference:FromPackRelativePath(images[1])
  self.ItemInstance.PotentialIcon = self.imageBase
  self:updateIcon()
end

function DungeonReward:updateIcon()
  if self:getProperty("stage") then
    local imageBase = ImageReference:FromPackRelativePath(images[self:getProperty("stage")])
    if self:getProperty("active") then
      self.ItemInstance.Icon = imageBase
    else
      self.ItemInstance.Icon = ImageReference:FromImageReference(imageBase, "@disabled")
    end
  else
    self.ItemInstance.Icon = self.imageBase
  end
end

function DungeonReward:onLeftClick()
  self:setProperty("active", not self:getProperty("active"))
end

function DungeonReward:onRightClick()
  if self:getProperty("stage") then
    if quickModeActive then
      self:setProperty("stage", quickModeOrder[quickModeActive])
      if quickModeActive >= #quickModeOrder then
        quickModeActive = nil
      else
        quickModeActive = quickModeActive + 1
      end
    else
      if self:getProperty("stage") >= #rewards then
        self:setProperty("stage", 1)
      else
        self:setProperty("stage", self:getProperty("stage") + 1)
      end
    end
  end
end

function DungeonReward:canProvideCode(code)
  if
    self.code and self.code == code or
      self:getProperty("stage") and
        (rewards[self:getProperty("stage")] == code or (self:getProperty("stage") >= 3 and self:getProperty("stage") <= 6 and code == "oot_medallion") or (self:getProperty("stage") >= 7 and code == "mm_boss_remain"))
   then
    return true
  end
  return false
end

function DungeonReward:providesCode(code)
  if self:getProperty("active") and self:canProvideCode(code) then
    return 1
  end
  return 0
end

function DungeonReward:advanceToCode(code)
  if code == nil or self:canProvideCode(code) then
    self:setProperty("active", true)
  end
end

function DungeonReward:save()
  local saveData = {}
  saveData["active"] = self:getProperty("active")
  saveData["stage"] = self:getProperty("stage")
  return saveData
end

function DungeonReward:load(data)
  if data["active"] ~= nil then
    self:setProperty("active", data["active"])
  end
  if data["stage"] ~= nil then
    self:setProperty("stage", data["stage"])
  end
  return true
end

function DungeonReward:propertyChanged(key, value)
  self:updateIcon()
end
