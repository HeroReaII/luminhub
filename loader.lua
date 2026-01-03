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

-- OPTIONAL: require user to set key before loading
if not _G.scriptkey then
    warn("scriptkey not set")
    return
end

local res = http_request({
    Url = "https://lunoria-one.vercel.app/loader?key=" .. tostring(_G.scriptkey),
    Method = "GET"
})

if not res or res.StatusCode ~= 200 or not res.Body then
    warn("Failed to fetch loader")
    return
end

loadstring(res.Body)()
