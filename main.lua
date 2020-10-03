FONT = "abeezee.regular.ttf"
PSIZE = 10
TICK = 1

Player = {}
function Player:new(x, y, size)
    _PC = {
        x = x;
        y = y;
        s = size;
        c = {255,0,0}
    }
    setmetatable(_PC, self)
    self._index = self
    function _PC:draw()
        love.graphics.setColor(self.c[1], self.c[2], self.c[3])
        love.graphics.circle("fill", self.x, self.y, self.s)
        love.graphics.setColor(255,255,255)
    end
    return _PC
end

Digit = {}
function Digit:new(digit, scale, x, y)
    font = love.graphics.newFont(FONT, scale)
    text = love.graphics.newText(font, digit)
    _Dig = {
        digit = digit;
        scale = scale;
        font = font;
        text = text;
        color = {255, 255, 255};
        x = x;
        y = y
    }
    setmetatable(_Dig, self)
    self._index = self
    function _Dig:setColor(a, b, c)
        self.color = {a,b,c}
    end
    function _Dig:draw(x, y)
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.draw(self.text, x, y)
        love.graphics.setColor(255,255,255)
    end
    return _Dig
end


function p(val)
    return val * val
end

function between_ellipses(x, y, a_out, b_out, a_in, b_in)
    -- (x^2 / a^2) + (y^2 / b^2) = 1 is an ellipse with width 2a and height 2b
    -- > 1 for outside the ellipse
    -- < 1 for inside the ellipse
    return  ((p(x) / p(a_out)) + (p(y) / p(b_out))) < 1 and 
            ((p(x) / p(a_in)) + (p(y) / p(b_in))) > 1
end

function digit_collision(dig, xa, ya, xb, yb, sb)
    local h = dig.text:getHeight()
    local w = dig.text:getWidth()
    local centerx = xa + (w/2)
    local centery = ya + (h/2) - 0.02*dig.scale
    -- calculate the bounds of the zero, magic multipliers are magic multipliers
    local inner_x = w/2 - 0.45*dig.scale + PSIZE
    local inner_y = h/2 - 0.88*dig.scale + PSIZE

    local outer_x = w/2 - 0.54*dig.scale - PSIZE
    local outer_y = h/2 - 0.95*dig.scale - PSIZE
    return between_ellipses(xb - centerx, yb - centery, outer_x, outer_y, inner_x, inner_y)
end

TextFrame = {}
function TextFrame:new(x, y, text, scale)
    local digits = {}
    for i = 1, #text do
        digits[i] = Digit:new(text:sub(i,i), scale)
    end
    _TF = {
        text = text;
        x = x;
        y = y;
        scale = scale;
        digits = digits
    }
    setmetatable(_TF, self)
    self._index = self
    function _TF:change_text(newtext)
        if self.text == newtext then return end
        self.text = newtext
        local digits = {}
        for i = 1, #newtext do
            digits[i] = Digit:new(newtext:sub(i,i), scale)
        end 
        self.digits = digits
    end
    function _TF:draw()
        local pos = 0
        for index, digit in pairs(self.digits) do
            digit:draw(self.x + pos, self.y)
            pos = pos + digit.text:getWidth()
        end
    end
    function _TF:collision(x, y, s)
        local pos = 0
        for index, digit in pairs(self.digits) do
            if x > self.x + pos and x < (self.x + pos + digit.text:getWidth()) and
            y > self.y and y < (self.y + digit.text:getHeight()) then
                curr_dig = digit
                if digit.digit == "0" and digit_collision(digit, self.x + pos, self.y, x, y, s) then return true end
            end
            pos = pos + digit.text:getWidth()
        end
    end
    return _TF
end

function create_timetable(t)
    local current_time = os.time()
    local timetable = os.date("*t", current_time)
    date = TextFrame:new(50, 100, os.date("%b" .."." .. tostring(timetable.day)),  200)
    year = TextFrame:new(700, 100, tostring(timetable.year), 200)
    time_sep = TextFrame:new(175, 300, sep, 100)
    time_sep2 = TextFrame:new(315, 300, sep, 100)
    time_h = TextFrame:new(50, 300, tostring(timetable.hour), 100)
    time_m = TextFrame:new(200, 300, tostring(timetable.min), 100)
    time_s = TextFrame:new(350, 300, tostring(timetable.sec), 100)
end

function update_timetable()
    if TICK == -1 then sep = ":" else sep = " " end
    TICK = TICK * -1
    local current_time = os.time()
    local timetable = os.date("*t", current_time)
    year:change_text(tostring(timetable.year))
    date:change_text(os.date("%b" .."." .. tostring(timetable.day)))
    time_sep:change_text(tostring(sep))
    time_sep2:change_text(tostring(sep))
    time_h:change_text(tostring(timetable.hour))
    time_m:change_text(tostring(timetable.min))
    time_s:change_text(tostring(timetable.sec))
end

function love.load()
    sep = ":"
    create_timetable(0)
    canvas = love.graphics.newCanvas(1600, 800)
    curr_dig = year.digits[#year.digits]
    pos_curr_dig = - curr_dig.text:getWidth()
    for _, dig in ipairs(year.digits) do
        pos_curr_dig = pos_curr_dig + dig.text:getWidth()
    end
    local h = curr_dig.text:getHeight()
    local w = curr_dig.text:getWidth()
    local centerx = year.x + (w/2) + pos_curr_dig
    local centery = year.y + (h/2) - 0.02*curr_dig.scale
    player = Player:new(centerx, centery, PSIZE)
    ms = 300
    t = 0
end

function checkdirection()
    dir = {0,0}
    if love.keyboard.isDown("up") then
        dir[2] = dir[2] - 1 end
    if love.keyboard.isDown("left") then
        dir[1] = dir[1] - 1 end
    if love.keyboard.isDown("right") then
        dir[1] = dir[1] + 1 end
    if love.keyboard.isDown("down") then
        dir[2] = dir[2] + 1 end
    return dir
end

function love.draw()
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(canvas)
end

function love.update(dt)
    t = t + dt
    if t > 1 then
        update_timetable()
        t = 0
    end

    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setBlendMode("alpha")
    date:draw()
    year:draw()
    time_h:draw()
    time_m:draw()
    time_s:draw()
    time_sep:draw()
    time_sep2:draw()
    player:draw()

    love.graphics.setCanvas()
    if love.keyboard.isDown("escape") then 
        love.event.quit() 
    end
    direction = checkdirection()
    local collision = false
    if not year:collision(player.x + (dt * direction[1] * ms), player.y , player.s) then
        player.x = player.x + (dt * direction[1] * ms)
    end
    if not year:collision(player.x, player.y + (dt * direction[2] * ms), player.s) then
        player.y = player.y + (dt * direction[2] * ms)
    end
    if t > 1 then
        update_timetable(0)
        t = 0
    end
end
