local delay = 2
local workSlot = 1
local stackSize = 64

local function log(msg)
  print("[LOG] " .. msg)
end

local function faceLeft()
  turtle.turnLeft()
end

local function backFromLeft()
  turtle.turnRight()
end

local function faceRight()
  turtle.turnRight()
end

local function backFromRight()
  turtle.turnLeft()
end

local function getItem(slot)
  return turtle.getItemDetail(slot)
end

local function getCount(slot)
  local item = getItem(slot)
  return item and item.count or 0
end

local function inventoryHasItems()
  for slot = 1, 16 do
    if getItem(slot) then
      return true
    end
  end
  return false
end

local function dropAllRight()
  faceRight()

  for slot = 1, 16 do
    local item = getItem(slot)
    if item then
      turtle.select(slot)
      local ok = turtle.drop()
      log("Dropped to right chest from slot " .. slot .. " / ok=" .. tostring(ok))
    end
  end

  backFromRight()
end

local function keepOnlyWorkSlot()
  for slot = 2, 16 do
    local item = getItem(slot)
    if item then
      turtle.select(slot)
      turtle.transferTo(workSlot)
    end
  end
end

local function takeStackFromLeft()
  if getItem(workSlot) then
    return true
  end

  if inventoryHasItems() then
    dropAllRight()
  end

  faceLeft()
  turtle.select(workSlot)
  local ok = turtle.suck(stackSize)
  backFromLeft()

  if not ok then
    log("Could not take stack from left chest")
    return false
  end

  local item = getItem(workSlot)
  if item then
    log("Took stack from left chest: " .. item.name .. " x" .. item.count)
    return true
  end

  log("Nothing taken into slot 1")
  return false
end

local function collectFromFront()
  sleep(delay)

  local tookAnything = false
  while true do
    local ok = turtle.suck()
    if not ok then
      break
    end
    tookAnything = true
    log("Collected item/result from front")
    sleep(0.2)
  end

  return tookAnything
end

local function processOneItem()
  local item = getItem(workSlot)
  if not item then
    return false
  end

  turtle.select(workSlot)
  local dropped = turtle.drop(1)

  if not dropped then
    log("Front machine did not accept item")
    sleep(1)
    return true
  end

  log("Inserted 1 item of " .. item.name .. ", remaining in slot 1: " .. getCount(workSlot))
  collectFromFront()

  local workItem = getItem(workSlot)
  local workName = workItem and workItem.name or item.name

  faceRight()
  for slot = 2, 16 do
    local slotItem = getItem(slot)
    if slotItem then
      turtle.select(slot)
      turtle.drop()
      log("Dropped result from slot " .. slot .. " to right chest: " .. slotItem.name .. " x" .. slotItem.count)
    end
  end
  backFromRight()

  keepOnlyWorkSlot()
  return true
end

while true do
  local current = getItem(workSlot)

  if not current then
    local gotStack = takeStackFromLeft()
    if not gotStack then
      print("No more items in left chest. Stopping.")
      break
    end
    current = getItem(workSlot)
  end

  if not current then
    print("Slot 1 is empty. Stopping.")
    break
  end

  local ok = processOneItem()
  if not ok then
    print("Stopped.")
    break
  end

  if getCount(workSlot) <= 0 then
    log("Stack finished, taking next stack from left chest")
  end
end