local user = "4fek7ka"
local repo = "Computer-craft"
local branch = "main"

local files = {
  { remote = "scripts/replace.lua", localName = "replace.lua" },
  { remote = "scripts/PowahOneItem.lua", localName = "PowahOneItem.lua" },
  { remote = "scripts/inspect.lua", localName = "inspect.lua" }
}

for _, file in ipairs(files) do
  local url = "https://raw.githubusercontent.com/" ..
    user .. "/" .. repo .. "/" .. branch .. "/" .. file.remote

  if fs.exists(file.localName) then
    fs.delete(file.localName)
  end

  print("Downloading: " .. file.localName)
  shell.run("wget", url, file.localName)
end

print("INSTALL COMPLETE")gi