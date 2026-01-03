print("[BOOT] index.lua started")

local HttpService = game:GetService("HttpService")
local TEMP_KEY = "lunoria_bootstrap_v1"

print("[BOOT] TEMP_KEY loaded")

-- ===============================
-- HTTP COMPAT
-- ===============================
local function http_request(opts)
    print("[HTTP] Requesting:", opts.Url)
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
-- XOR
-- ===============================
local function xor_decrypt(data, key)
    print("[XOR] Decrypting with key length:", #key)
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

-- ===============================
-- FETCH LOADER
-- ===============================
local res = http_request({
    Url = "https://lunoria-one.vercel.app/loader",
    Method = "GET"
})

if not res or not res.Body then
    warn("[FAIL] No response body")
    return
end

print("[HTTP] Loader response size:", #res.Body)

-- ===============================
-- BASE64 DECODE
-- ===============================
local raw = crypt.base64decode(res.Body)
print("[B64] Decoded size:", #raw)

-- ===============================
-- UNWRAP JUNK
-- ===============================
local prefix_len = raw:byte(1) * 256 + raw:byte(2)
print("[JUNK] Prefix length:", prefix_len)

local len_pos = 3 + prefix_len

local payload_len = 0
for i = len_pos, len_pos + 3 do
    payload_len = payload_len * 256 + raw:byte(i)
end

print("[JUNK] Payload length:", payload_len)

local payload_start = len_pos + 4
local encrypted_payload = raw:sub(payload_start, payload_start + payload_len - 1)

print("[PAYLOAD] Encrypted payload size:", #encrypted_payload)

-- ===============================
-- STAGE 1 XOR
-- ===============================
local stage1 = xor_decrypt(encrypted_payload, TEMP_KEY)
print("[XOR] Stage 1 decrypt OK")

-- ===============================
-- EXTRACT REAL KEY
-- ===============================
local key_b64 = stage1:match('local XOR_KEY="([^"]+)"')
if not key_b64 then
    warn("[FAIL] XOR_KEY not found in stage1")
    print(stage1:sub(1, 300)) -- show beginning
    return
end

print("[KEY] Found XOR_KEY (base64)")

local real_key = crypt.base64decode(key_b64)
print("[KEY] Real key length:", #real_key)

-- ===============================
-- STAGE 2 XOR
-- ===============================
local final_loader = xor_decrypt(stage1, real_key)
print("[XOR] Stage 2 decrypt OK")

-- ===============================
-- EXECUTE
-- ===============================
local fn, err = loadstring(final_loader)
if not fn then
    warn("[FAIL] loadstring error:", err)
    print(final_loader:sub(1, 500))
    return
end

print("[EXEC] Executing loader...")
fn()
print("[EXEC] Loader finished")
