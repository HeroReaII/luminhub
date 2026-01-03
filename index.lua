-- XOR decryption function
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

-- Base64 decode function (if crypt is not available)
local function base64_decode(data)
    if crypt and crypt.base64decode then
        return crypt.base64decode(data)
    else
        -- Simple Base64 decoder implementation
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if x == '=' then return '' end
            local r, f = '', (b:find(x) - 1)
            for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
            return r
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if #x < 6 then return '' end
            local c = 0
            for i = 1, #x do c = c + (x:sub(i,i) == '1' and 2^(#x-i) or 0) end
            return string.char(c)
        end))
    end
end

-- LZ4 decompression (simplified version)
local function lz4_decompress(data)
    -- This is a simplified version. In production, you'd want a proper LZ4 implementation
    -- For now, we'll just return the data as-is since proper LZ4 is complex
    return data
end

-- HTTP request function
local function http_request(opts)
    local HttpService = game:GetService("HttpService")
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

-- Main loader
local function load_script()
    local res = http_request({
        Url = "https://lunoria-one.vercel.app/loader",  -- fixed space
        Method = "GET"
    })

    if not res or not res.Body or #res.Body == 0 then
        warn("[FAIL] No response body")
        return
    end

    print("[RAW] First 200 chars of body:", res.Body:sub(1, 200))

    local raw = base64_decode(res.Body)
    print("[B64] Decoded size:", #raw)

    if #raw == 0 then
        warn("[FAIL] Base64 decode failed")
        return
    end

    local prefix_len = raw:byte(1) * 256 + raw:byte(2)
    print("[JUNK] Prefix length:", prefix_len)

    local len_pos = 3 + prefix_len

    local len = 0
    for i = len_pos, len_pos + 3 do
        len = len * 256 + raw:byte(i)
    end

    print("[JUNK] Payload length:", len)

    local payload_start = len_pos + 4
    local encrypted_payload = raw:sub(payload_start, payload_start + len - 1)

    print("[PAYLOAD] Encrypted payload size:", #encrypted_payload)

    -- XOR decrypt the payload
    local decrypted_payload = xor_decrypt(encrypted_payload, "lunoria_bootstrap_v1")
    
    print("[DECRYPT] Decrypted payload size:", #decrypted_payload)
    
    -- Execute the decrypted payload
    local fn, err = loadstring(decrypted_payload)
    if not fn then
        warn("[FAIL] loadstring error:", err)
        print("Decrypted payload (first 500 chars):", decrypted_payload:sub(1, 500))
        return
    end

    print("[EXEC] Executing loader...")
    fn()
    print("[EXEC] Loader finished")
end

-- Initialize bit32 if not available
if not bit32 then
    bit32 = {
        bxor = function(a, b)
            local result = 0
            local bitval = 1
            while a > 0 or b > 0 do
                local a_bit = a % 2
                local b_bit = b % 2
                if a_bit ~= b_bit then
                    result = result + bitval
                end
                a = math.floor(a / 2)
                b = math.floor(b / 2)
                bitval = bitval * 2
            end
            return result
        end
    }
end

-- Start the loader
load_script()
