local HttpService = game:GetService("HttpService")

local function req(u)
    if http and http.request then
        return http.request({Url=u,Method="GET"}).Body
    end
    return HttpService:GetAsync(u)
end

if not _G.scriptkey then return end
loadstring(req(
 "https://lunoria-one.vercel.app/api?route=loader&key=".._G.scriptkey
))()
