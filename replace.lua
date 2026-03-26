local targetBlock = "minecraft:stripped_acacia_log"
local placeBlock = "minecraft:acacia_log"

local function findItem(name)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == name then
      return slot
    end
  end
  return nil
end

while true do
  local hasBlock, data = turtle.inspect()

  if hasBlock and data.name == targetBlock then
    local slot = findItem(placeBlock)

    if slot then
      turtle.select(slot)

      local broke = turtle.dig()
      if broke then
        sleep(0.2)
        turtle.place()
        print("заменил блок")
      end
    else
      print("нет акации в инвентаре")
    end
  end

  sleep(0.5)
end