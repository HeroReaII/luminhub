-- ======================
-- Anti HTTP spy (unchanged logic)
-- ======================
local req = (http and http.request) or request
local plrs = game:GetService("Players")

local function kick(reason)
    pcall(function()
        if plrs.LocalPlayer and plrs.LocalPlayer.Parent then
            plrs.LocalPlayer:Kick(reason)
        end
    end)
end

local function hooked(f)
    if type(f) ~= "function" then
        return true
    end

    local ok, info = pcall(debug.getinfo, f)
    if not ok or type(info) ~= "table" then
        return true
    end

    if info.what ~= "C" then
        return true
    end

    local called = pcall(f)
    if called then
        return true
    end

    return false
end

if hooked(req) then
    kick("Integrity check failed")
    return
end

-- ======================
-- Loader logic
-- ======================
local HttpService = game:GetService("HttpService")

local function http_request(opts)
    if http and http.request then
        return http.request(opts)
    elseif request then
        return request(opts)
    else
        return {
            Body = HttpService:GetAsync(opts.Url),
            StatusCode = 200
        }
    end
end

local res = http_request({
    Url = "https://lunoria-one.vercel.app/loader",
    Method = "GET"
})

local raw = crypt.base64decode(res.Body)

local prefix_len = raw:byte(1) * 256 + raw:byte(2)
local len_pos = 3 + prefix_len

local len = 0
for i = len_pos, len_pos + 3 do
    len = len * 256 + raw:byte(i)
end

local payload_start = len_pos + 4
local payload = raw:sub(payload_start, payload_start + len - 1)

loadstring(payload)()
