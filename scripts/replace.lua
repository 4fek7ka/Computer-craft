print("VERSION 3 CHEST BACK")
sleep(1)

local targetBlock = "minecraft:stripped_acacia_log"
local placeBlock = "minecraft:acacia_log"

local DEBUG = true

local function log(msg)
  if DEBUG then
    print("[DEBUG] " .. msg)
  end
end

local function findItem(name)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == name then
      log("Found " .. name .. " in slot " .. slot .. " x" .. item.count)
      return slot
    end
  end
  return nil
end

local function selectItem(name)
  local slot = findItem(name)
  if slot then
    turtle.select(slot)
    return true
  end
  return false
end

local function turnAround()
  turtle.turnLeft()
  turtle.turnLeft()
end

local function suckFromBack(amount)
  turnAround()
  local ok = turtle.suck(amount or 64)
  turnAround()
  log("Suck from back: " .. tostring(ok))
  return ok
end

local function dropSlotToBack(slot)
  local item = turtle.getItemDetail(slot)
  if not item then
    return
  end

  turtle.select(slot)
  turnAround()
  local ok = turtle.drop()
  turnAround()

  log("Drop to back from slot " .. slot .. ": " .. tostring(ok))
end

local function ensurePlaceBlock()
  if findItem(placeBlock) then
    return true
  end

  log("No " .. placeBlock .. " in inventory, trying chest behind")
  local ok = suckFromBack(64)

  if not ok then
    log("Could not take items from chest behind")
    return false
  end

  return findItem(placeBlock) ~= nil
end

local function cleanupDropsToBack()
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name ~= placeBlock then
      log("Moving drop to chest: " .. item.name .. " x" .. item.count)
      dropSlotToBack(slot)
    end
  end
end

print("=== START REPLACE SCRIPT ===")

while true do
  local hasBlock, data = turtle.inspect()

  if not hasBlock then
    log("No block in front")
  else
    log("Detected block: " .. data.name)

    if data.name == targetBlock then
      log("Target block detected")

      if ensurePlaceBlock() then
        local slot = findItem(placeBlock)

        if slot then
          turtle.select(slot)
          log("Selected slot " .. slot)

          local broke = turtle.dig()
          log("Dig result: " .. tostring(broke))

          if broke then
            sleep(0.2)

            local placeSlot = findItem(placeBlock)
            if placeSlot then
              turtle.select(placeSlot)
              local placed = turtle.place()
              log("Place result: " .. tostring(placed))

              if placed then
                print("Block replaced")
                cleanupDropsToBack()
              else
                print("Failed to place block")
              end
            else
              print("No acacia_log after dig")
            end
          else
            print("Failed to break block")
          end
        else
          print("No blocks to place")
        end
      else
        print("No acacia_log in chest")
      end
    else
      log("Block is not target")
    end
  end

  sleep(0.5)
end