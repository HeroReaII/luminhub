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
            string.byte(data, i) ~ string.byte(key, (i - 1) % #key + 1)
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

local final_loader = xor_decrypt(encrypted_payload, TEMP_KEY)
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
