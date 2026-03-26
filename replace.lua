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
    if item then
      log("Slot " .. slot .. ": " .. item.name)
      if item.name == name then
        log("Found item in slot " .. slot)
        return slot
      end
    end
  end
  log("Item not found in inventory")
  return nil
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

      local slot = findItem(placeBlock)

      if slot then
        turtle.select(slot)
        log("Selected slot " .. slot)

        local broke = turtle.dig()
        log("Dig result: " .. tostring(broke))

        if broke then
          sleep(0.2)

          local placed = turtle.place()
          log("Place result: " .. tostring(placed))

          if placed then
            print("✔ Block replaced")
          else
            print("❌ Failed to place block")
          end
        else
          print("❌ Failed to break block")
        end
      else
        print("❌ No blocks to place (inventory empty)")
      end
    else
      log("Block is not target")
    end
  end

  sleep(0.5)
end