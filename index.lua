local HttpService = game:GetService("HttpService")

-- MUST MATCH server TEMP_KEY
local TEMP_KEY = "lunoria_bootstrap_v1"

-- ===============================
-- HTTP COMPAT
-- ===============================
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

-- ===============================
-- XOR DECRYPT
-- ===============================
local function xor_decrypt(data, key)
    local out = {}
    local klen = #key
    for i = 1, #data do
        out[i] = string.char(
            bit32.bxor(
                data:byte(i),
                key:byte((i - 1) % klen + 1)
            )
        )
    end
    return table.concat(out)
end

-- ===============================
-- FETCH /loader
-- ===============================
local res = http_request({
    Url = "https://lunoria-one.vercel.app/loader",
    Method = "GET"
})

if not res.Body then
    return
end

-- ===============================
-- BASE64 DECODE WRAPPER
-- ===============================
local raw = crypt.base64decode(res.Body)

-- ===============================
-- UNWRAP JUNK
-- ===============================
local prefix_len = raw:byte(1) * 256 + raw:byte(2)
local len_pos = 3 + prefix_len

local payload_len = 0
for i = len_pos, len_pos + 3 do
    payload_len = payload_len * 256 + raw:byte(i)
end

local payload_start = len_pos + 4
local encrypted_payload = raw:sub(
    payload_start,
    payload_start + payload_len - 1
)

-- ===============================
-- STAGE 1: TEMP KEY DECRYPT
-- ===============================
local stage1 = xor_decrypt(encrypted_payload, TEMP_KEY)

-- ===============================
-- EXTRACT REAL XOR KEY
-- ===============================
local key_b64 = stage1:match('local XOR_KEY="([^"]+)"')
if not key_b64 then
    return
end

local real_key = crypt.base64decode(key_b64)

-- ===============================
-- STAGE 2: REAL KEY DECRYPT
-- ===============================
local final_loader = xor_decrypt(stage1, real_key)

-- ===============================
-- EXECUTE LOADER
-- ===============================
local fn, err = loadstring(final_loader)
if not fn then
    warn("Loader error:", err)
    return
end

fn()
