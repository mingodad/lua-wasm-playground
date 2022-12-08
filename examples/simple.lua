-- This is a simple Lua script to show the playground functionality
-- The content of 'Input Text (arg[1])' is available as 'arg[1]'
-- If there is any error they will be shown at the bottom of the screen and we can click on then
-- The output is shown on 'Output'

local input_text = arg[1]

print("Here is the content of 'Input Text (arg[1])'")
print(input_text)

-- There is two embedded files that can be viewed as shown bellow
local lpegrex = io.open('lpegrex.lua'):read("a*")
print(lpegrex)

local relabel = io.open('relabel.lua'):read("a*")
print(relabel)