local delay = 2

local function turnAround()
  turtle.turnLeft()
  turtle.turnLeft()
end

local function suckBack(count)
  turnAround()
  local ok = turtle.suck(count or 64)
  turnAround()
  return ok
end

local function dropBack(count)
  turnAround()
  local ok = turtle.drop(count or 64)
  turnAround()
  return ok
end

local function getTemplateItem()
  local item = turtle.getItemDetail(1)
  if item then
    return item.name
  end
  return nil
end

local function countItem(name)
  local total = 0
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == name then
      total = total + item.count
    end
  end
  return total
end

local function findTemplateSlot(templateName)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == templateName then
      return slot
    end
  end
  return nil
end

local function dropNonTemplateToBack(templateName)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name ~= templateName then
      turtle.select(slot)
      dropBack()
      print("Moved result to back: " .. item.name)
    end
  end
end

local templateName = getTemplateItem()

if not templateName then
  print("Put source item into slot 1")
  return
end

print("Template item: " .. templateName)

while true do
  local slot = findTemplateSlot(templateName)

  if not slot then
    print("No more template item")
    break
  end

  turtle.select(slot)

  local beforeCount = countItem(templateName)

  local dropped = turtle.drop(1)
  if not dropped then
    print("Failed to insert item")
    sleep(1)
  else
    print("Inserted 1 item of " .. templateName)
    sleep(delay)

    local took = turtle.suck()
    print("Take result: " .. tostring(took))

    local afterCount = countItem(templateName)

    dropNonTemplateToBack(templateName)

    if afterCount >= beforeCount then
      print("Cycle done")
    else
      print("Source item consumed")
    end
  end
end