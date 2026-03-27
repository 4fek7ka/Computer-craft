local delay = 2
local templateSlot = 1
local MAX_STACK = 64
local REFILL_THRESHOLD = 32

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

local function getCountInSlot(slot)
  local item = turtle.getItemDetail(slot)
  return item and item.count or 0
end

local function countFreeSpaceInSlot(slot)
  local item = turtle.getItemDetail(slot)
  if not item then
    return MAX_STACK
  end
  return MAX_STACK - item.count
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

local function consolidateTemplateInsideInventory(templateName)
  while true do
    local free = countFreeSpaceInSlot(templateSlot)
    if free <= 0 then
      return
    end

    local otherSlot = findSameItemSlot(templateName, templateSlot)
    if not otherSlot then
      return
    end

    turtle.select(otherSlot)
    turtle.transferTo(templateSlot)
    log("Consolidated template from slot " .. otherSlot .. " into slot 1")
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
      turtle.select(slot)
      local ok = turtle.drop()
      log("Dropped non-template from slot " .. slot .. ": " .. item.name .. " x" .. item.count .. " / ok=" .. tostring(ok))
    end
  end
end

local function refillTemplateToFullFromRightChest(templateName)
  consolidateTemplateInsideInventory(templateName)

  local slot1 = turtle.getItemDetail(templateSlot)
  if slot1 and slot1.name ~= templateName then
    log("Slot 1 changed, refill cancelled")
    return
  end

  local free = countFreeSpaceInSlot(templateSlot)
  if free <= 0 then
    log("Slot 1 already full")
    return
  end

  log("Trying to refill slot 1 to 64 from right chest")

  for slot = 2, 16 do
    if countFreeSpaceInSlot(templateSlot) <= 0 then
      break
    end

    local slotItem = turtle.getItemDetail(slot)

    if not slotItem then
      turtle.select(slot)
      local need = countFreeSpaceInSlot(templateSlot)
      local took = turtle.suck(need)

      if took then
        local taken = turtle.getItemDetail(slot)

        if taken and taken.name == templateName then
          turtle.transferTo(templateSlot)
          log("Pulled template from right chest into slot " .. slot)
        else
          if taken then
            log("Pulled wrong item from chest into slot " .. slot .. ": " .. taken.name .. ", returning")
          else
            log("Pulled unknown item from chest into slot " .. slot .. ", returning")
          end
          turtle.drop()
        end
      end
    end
  end

  consolidateTemplateInsideInventory(templateName)
  log("Refill finished, slot 1 count: " .. getCountInSlot(templateSlot))
end

local function handleRightChest(templateName, shouldRefill)
  faceChestRight()
  dropNonTemplateToRightChestWhileFacing(templateName)

  if shouldRefill then
    refillTemplateToFullFromRightChest(templateName)
  else
    log("Refill skipped, slot 1 is above threshold")
  end

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
log("Initial slot 1 count: " .. getCountInSlot(templateSlot))

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
    log("Slot 1 count after insert: " .. getCountInSlot(templateSlot))

    local took = waitAndCollectFront()
    log("Collected from front: " .. tostring(took))

    compactTemplateToSlot1(templateName)

    local currentCount = getCountInSlot(templateSlot)
    local shouldRefill = currentCount < REFILL_THRESHOLD

    log("Slot 1 count before chest handling: " .. currentCount)
    log("Refill threshold: " .. REFILL_THRESHOLD .. ", shouldRefill=" .. tostring(shouldRefill))

    handleRightChest(templateName, shouldRefill)

    local slot1Now = turtle.getItemDetail(templateSlot)
    if slot1Now and slot1Now.name == templateName then
      log("End of cycle, slot 1 count: " .. slot1Now.count)
    else
      log("End of cycle, slot 1 is empty or changed")
    end
  end
end