local delay = 2
local templateSlot = 1

local function log(msg)
  print("[LOG] " .. msg)
end

local function getTemplateItem()
  local item = turtle.getItemDetail(templateSlot)
  if item then
    return item.name
  end
  return nil
end

local function getSlotItem(slot)
  return turtle.getItemDetail(slot)
end

local function countFreeSpaceInSlot(slot)
  local item = turtle.getItemDetail(slot)
  if not item then
    return 64
  end
  return 64 - item.count
end

local function findSameItemSlot(name, exceptSlot)
  for slot = 1, 16 do
    if slot ~= exceptSlot then
      local item = turtle.getItemDetail(slot)
      if item and item.name == name then
        return slot
      end
    end
  end
  return nil
end

local function compactTemplateToSlot1(templateName)
  local slot1Item = turtle.getItemDetail(templateSlot)

  if slot1Item and slot1Item.name ~= templateName then
    log("Slot 1 no longer contains template item")
    return false
  end

  while true do
    local free = countFreeSpaceInSlot(templateSlot)
    if free <= 0 then
      return true
    end

    local otherSlot = findSameItemSlot(templateName, templateSlot)
    if not otherSlot then
      return true
    end

    turtle.select(otherSlot)
    turtle.transferTo(templateSlot)
    log("Moved template item from slot " .. otherSlot .. " to slot 1")
  end
end

local function faceChestRight()
  turtle.turnRight()
end

local function faceFrontFromChest()
  turtle.turnLeft()
end

local function dropNonTemplateToRightChestWhileFacing(templateName)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name ~= templateName then
      local itemName = item.name
      local itemCount = item.count
      turtle.select(slot)
      local ok = turtle.drop()
      log("Dropped to right chest from slot " .. slot .. ": " .. itemName .. " x" .. itemCount .. " / ok=" .. tostring(ok))
    end
  end
end

local function refillTemplateFromRightChestWhileFacing(templateName)
  local free = countFreeSpaceInSlot(templateSlot)
  if free <= 0 then
    log("Slot 1 is full, refill not needed")
    return
  end

  log("Checking right chest for template item: " .. templateName)

  local moved = 0

  for slot = 1, 16 do
    if slot ~= templateSlot then
      local item = turtle.getItemDetail(slot)
      if item and item.name == templateName then
        turtle.select(slot)
        turtle.transferTo(templateSlot)
      end
    end
  end

  while countFreeSpaceInSlot(templateSlot) > 0 do
    local beforeSelected = turtle.getSelectedSlot()
    local took = turtle.suck(1)

    if not took then
      log("Could not take more items from right chest")
      break
    end

    local takenItem = turtle.getItemDetail(beforeSelected)

    if takenItem and takenItem.name == templateName then
      turtle.select(beforeSelected)
      turtle.transferTo(templateSlot)
      moved = moved + 1
      log("Moved 1 template item from right chest to slot 1")
    else
      if takenItem then
        log("Took non-template item from chest: " .. takenItem.name .. ", returning it")
        turtle.select(beforeSelected)
        turtle.drop()
      else
        log("Took unknown item from chest, returning it")
        turtle.select(beforeSelected)
        turtle.drop()
      end
      break
    end
  end

  log("Refill complete, moved " .. moved .. " items into slot 1")
end

local function handleRightChest(templateName)
  faceChestRight()
  dropNonTemplateToRightChestWhileFacing(templateName)
  refillTemplateFromRightChestWhileFacing(templateName)
  faceFrontFromChest()
end

local function waitAndCollectFront()
  sleep(delay)

  local tookAnything = false
  while true do
    local ok = turtle.suck()
    if not ok then
      break
    end
    tookAnything = true
    log("Took item/result from front")
    sleep(0.2)
  end

  return tookAnything
end

local templateName = getTemplateItem()

if not templateName then
  print("Put source item into slot 1 before start")
  return
end

print("Template item locked: " .. templateName)
log("Initial slot 1 count: " .. (getSlotItem(1) and getSlotItem(1).count or 0))

while true do
  compactTemplateToSlot1(templateName)

  local slot1Item = turtle.getItemDetail(templateSlot)
  if not slot1Item or slot1Item.name ~= templateName then
    print("Slot 1 lost template item")
    break
  end

  if slot1Item.count <= 0 then
    print("No template item left")
    break
  end

  turtle.select(templateSlot)

  local dropped = turtle.drop(1)
  if not dropped then
    print("Failed to insert item")
    log("Front machine did not accept item")
    sleep(1)
  else
    print("Inserted 1 item of " .. templateName)
    log("Slot 1 count after insert: " .. ((turtle.getItemDetail(1) and turtle.getItemDetail(1).count) or 0))

    local took = waitAndCollectFront()
    log("Collected from front: " .. tostring(took))

    handleRightChest(templateName)

    local slot1Now = turtle.getItemDetail(templateSlot)
    if slot1Now and slot1Now.name == templateName then
      log("End of cycle, slot 1 count: " .. slot1Now.count)
    else
      log("End of cycle, slot 1 is empty or changed")
    end
  end
end