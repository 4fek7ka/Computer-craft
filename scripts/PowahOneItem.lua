local inputItem = "minecraft:acacia_log"
local delay = 2

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
  local slot = findItem(inputItem)

  if not slot then
    print("No input item")
    break
  end

  turtle.select(slot)

  local dropped = turtle.drop(1)
  if not dropped then
    print("Failed to insert item")
    sleep(1)
  else
    print("Inserted 1 item")

    sleep(delay)

    local sucked = turtle.suck()
    print("Take result: " .. tostring(sucked))
  end
end