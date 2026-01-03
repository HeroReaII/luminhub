local HttpService = game:GetService("HttpService")

local function req(u)
    if http and http.request then
        return http.request({ Url = u, Method = "GET" }).Body
    elseif request then
        return request({ Url = u, Method = "GET" }).Body
    else
        return HttpService:GetAsync(u)
    end
end

-- support all environments
local key = rawget(_G, "scriptkey") or rawget(getgenv(), "scriptkey")
if not key then
    error("scriptkey not set")
end

local src = req("https://lunoria-one.vercel.app/api?route=loader&key=" .. key)
if not src or #src == 0 then
    error("failed to fetch loader")
end

local fn = loadstring or load
if not fn then
    error("no loadstring support")
end

local chunk, err = fn(src)
if not chunk then
    error(err or "compile error")
end

chunk()
