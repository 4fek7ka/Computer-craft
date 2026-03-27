local delay = 2
local templateSlot = 1
local MAX_STACK = 64
local REFILL_THRESHOLD = 32

local function log(msg)
  print("[LOG] " .. msg)
end

local function getItem(slot)
  return turtle.getItemDetail(slot)
end

local function getCount(slot)
  local item = getItem(slot)
  return item and item.count or 0
end

local function getTemplateName()
  local item = getItem(templateSlot)
  return item and item.name or nil
end

local function freeSpace(slot)
  local item = getItem(slot)
  if not item then
    return MAX_STACK
  end
  return MAX_STACK - item.count
end

local function findSameItemSlot(name, exceptSlot)
  for slot = 1, 16 do
    if slot ~= exceptSlot then
      local item = getItem(slot)
      if item and item.name == name then
        return slot
      end
    end
  end
  return nil
end

local function compactTemplateToSlot1(templateName)
  local slot1Item = getItem(templateSlot)

  if slot1Item and slot1Item.name ~= templateName then
    log("Slot 1 no longer contains template item")
    return false
  end

  while true do
    local free = freeSpace(templateSlot)
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

local function turnToLeftChest()
  turtle.turnLeft()
end

local function returnFromLeftChest()
  turtle.turnRight()
end

local function turnToRightChest()
  turtle.turnRight()
end

local function returnFromRightChest()
  turtle.turnLeft()
end

local function refillFromLeftChest(templateName)
  compactTemplateToSlot1(templateName)

  local current = getCount(templateSlot)
  if current >= MAX_STACK then
    log("Slot 1 already full")
    return
  end

  log("Trying to refill slot 1 from left chest")

  turnToLeftChest()

  for slot = 2, 16 do
    if freeSpace(templateSlot) <= 0 then
      break
    end

    if not getItem(slot) then
      turtle.select(slot)

      local need = freeSpace(templateSlot)
      local took = turtle.suck(need)

      if took then
        local taken = getItem(slot)

        if taken and taken.name == templateName then
          turtle.transferTo(templateSlot)
          log("Pulled template item from left chest into slot " .. slot)
        else
          if taken then
            log("Wrong item in left chest: " .. taken.name .. ", moving to right chest later")
          else
            log("Unknown item pulled from left chest")
          end
        end
      end
    end
  end

  returnFromLeftChest()

  compactTemplateToSlot1(templateName)
  log("Refill finished, slot 1 count: " .. getCount(templateSlot))
end

local function dropNonTemplateToRightChest(templateName)
  turnToRightChest()

  for slot = 1, 16 do
    local item = getItem(slot)
    if item and item.name ~= templateName then
      local name = item.name
      local count = item.count
      turtle.select(slot)
      local ok = turtle.drop()
      log("Dropped non-template to right chest from slot " .. slot .. ": " .. name .. " x" .. count .. " / ok=" .. tostring(ok))
    end
  end

  returnFromRightChest()
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

local templateName = getTemplateName()

if not templateName then
  print("Put source item into slot 1 before start")
  return
end

print("Template item locked: " .. templateName)
log("Initial slot 1 count: " .. getCount(templateSlot))

while true do
  compactTemplateToSlot1(templateName)

  local slot1Item = getItem(templateSlot)
  if not slot1Item or slot1Item.name ~= templateName then
    print("Slot 1 lost template item")
    break
  end

  if slot1Item.count < REFILL_THRESHOLD then
    refillFromLeftChest(templateName)
    compactTemplateToSlot1(templateName)
    slot1Item = getItem(templateSlot)
  end

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
    log("Slot 1 count after insert: " .. getCount(templateSlot))

    local took = waitAndCollectFront()
    log("Collected from front: " .. tostring(took))

    compactTemplateToSlot1(templateName)
    dropNonTemplateToRightChest(templateName)

    local slot1Now = getItem(templateSlot)
    if slot1Now and slot1Now.name == templateName then
      log("End of cycle, slot 1 count: " .. slot1Now.count)
    else
      log("End of cycle, slot 1 is empty or changed")
    end
  end
end