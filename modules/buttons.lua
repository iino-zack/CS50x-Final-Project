BUTTON_HEIGHT = 64
activeButtons = {}
font = nil

-- Creates and returns a clickable button
-- @param text string The text to be displayed on the button
-- @param func (any) -> () The text to be displayed on the button
-- @return table { text: string, func: (any) -> () }
function createButton(text, func)
    return {
        text = text,
        func = func,
        now = false,
        last = false
    }
end