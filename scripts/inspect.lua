while true do
  local ok, data = turtle.inspect()

  local f = fs.open("log.txt", "a")

  if ok then
    f.writeLine(data.name .. " | " .. textutils.serialize(data.state))
  else
    f.writeLine("no block")
  end

  f.close()

  sleep(1)
end