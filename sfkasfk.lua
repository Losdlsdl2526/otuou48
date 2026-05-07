do
    local env = getgenv()


    if not env.__EVO_BOOT_ID then
        game:GetService("Players").LocalPlayer:Kick("Invalid entry point")
        return
    end


    if not env.EVOLUTION_HUB_AUTH or env.EVOLUTION_HUB_AUTH._boot ~= env.__EVO_BOOT_ID then
        game:GetService("Players").LocalPlayer:Kick("Loader required")
        return
    end


    if not env.EVOLUTION_HUB_AUTH._polsec_verified then
        game:GetService("Players").LocalPlayer:Kick("PolSec verification required")
        return
    end


    env.__EVO_BOOT_ID = nil
    env.EVOLUTION_HUB_AUTH._boot = nil
end


task.wait(0)


local _0x = {}
_0x[0x1] = 0x539   -- 1337
_0x[0x2] = 0x7
_0x[0x3] = 0x15180 -- 86400


local function _kick(r)
    pcall(function()
        game:GetService("Players").LocalPlayer:Kick(r or "Security violation")
    end)
end


local function _detect_hooks()
    local dominated = false
    local suspicious = {
        "HOOK_LOG", "INTERCEPTED", "LOGGED_CALLS", "HOOK_DATA",
        "oldLoadstring", "oldHttpGet", "hookLog", "interceptLog",
        "HOOKED_FUNCTIONS", "ORIGINAL_FUNCTIONS", "SPY_DATA",
        "DEBUG_MODE", "CRACK_MODE", "BYPASS_AUTH", "FREE_KEY",
        "hookFunction", "detourFunction", "originalFunctions",
        "scriptHook", "functionHook", "methodHook"
    }
    for _, name in ipairs(suspicious) do
        local found = false
        pcall(function()
            if getgenv and getgenv()[name] ~= nil then found = true end
            if _G[name] ~= nil then found = true end
            if rawget(_G, name) ~= nil then found = true end
        end)
        if found then
            dominated = true; break
        end
    end
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, child in ipairs(coreGui:GetChildren()) do
            local n = child.Name:lower()
            for _, bad in ipairs({ "hooker", "interceptor", "spy", "debug", "crack", "bypass", "free", "keygen" }) do
                if string.find(n, bad) then dominated = true end
            end
        end
    end)
    return dominated
end


local function _hardened_verify()
    local env = getgenv and getgenv()
    if type(env) ~= "table" then return false end

    local auth = env.EVOLUTION_HUB_AUTH
    if type(auth) ~= "table" then return false end
    if auth.isAuthenticated ~= true then return false end

    -- Check 1: flow state
    if type(auth._flow_s) ~= "number" then return false end
    if auth._flow_s < 2 then return false end
    if type(auth._flow_acc) ~= "number" then return false end


    if type(auth._session_expires) ~= "number" then return false end
    if os.time() > auth._session_expires then return false end


    if type(auth._nonce_hash) ~= "number" then return false end


    if auth._flow_s >= 5 and type(auth._flow_check) == "number" then
        local expected = (auth._flow_acc % 131) * 7 + auth._flow_s
        if auth._flow_check ~= expected then return false end
    end


    if auth._polsec_verified ~= true then
        return false
    end


    if type(auth._timing_hash) == "number" then
        if auth._timing_hash > 0 and auth._timing_hash < 10 then
            return false
        end
    end


    if type(auth._time) ~= "number" then return false end
    if type(auth._secret) ~= "number" then return false end
    if type(auth._token) ~= "string" then return false end
    if type(auth._checksum) ~= "number" then return false end
    if type(auth._session) ~= "string" then return false end
    if type(auth._flow) ~= "number" then return false end


    local now = os.time()
    if auth._time > now + 5 then return false end
    if now - auth._time > _0x[0x3] then return false end


    if #auth._token < 10 then return false end


    if auth._checksum ~= (#auth._token * _0x[0x1]) then return false end


    local expected_base = auth._time * _0x[0x2] + _0x[0x1]
    if expected_base == 0 then return false end
    local seed = auth._secret / expected_base
    if seed < 100000 or seed > 999999 then
        if auth._secret < 1e10 or auth._secret > 1e15 then
            return false
        end
        if type(auth._secret_mod) == "number" then
            if auth._secret % _0x[0x1] ~= auth._secret_mod then
                return false
            end
        end
    end


    local hub = env.EvolutionHub
    if type(hub) ~= "table" then return false end
    if type(hub.CheckAuth) ~= "function" then return false end

    -- Check 13: heartbeat function
    if type(auth.heartbeat) ~= "function" then return false end

    -- Check 14: sign function
    if type(auth.sign) ~= "function" then return false end

    return true
end


local function _consume_nonce()
    local env = getgenv and getgenv()
    if type(env) ~= "table" then return false end

    local nonce = env.EVOLUTION_PAYLOAD_NONCE
    if not nonce then return false end

    -- Consume (one-time use)
    env.EVOLUTION_PAYLOAD_NONCE = nil

    if type(nonce) ~= "string" or #nonce < 10 then return false end


    local auth = env.EVOLUTION_HUB_AUTH
    if type(auth) == "table" and type(auth._nonce_hash) == "number" then
        local h = 0
        for i = 1, #nonce do
            h = (h * 31 + string.byte(nonce, i)) % 2 ^ 32
        end
        if auth._nonce_hash ~= h then return false end
    end

    return true
end


local function _verify_flow_heartbeat()
    local env = getgenv and getgenv()
    if type(env) ~= "table" then return false end

    local auth = env.EVOLUTION_HUB_AUTH
    if type(auth) ~= "table" then return false end

    if type(auth.heartbeat) ~= "function" then return false end

    local ok, result = pcall(auth.heartbeat)
    if not ok or type(result) ~= "number" then return false end

    return true
end


local function _verify_signature()
    local env = getgenv and getgenv()
    if type(env) ~= "table" then return false end

    local auth = env.EVOLUTION_HUB_AUTH
    if type(auth) ~= "table" then return false end
    if type(auth.sign) ~= "function" then return false end


    local ok1, r1 = pcall(auth.sign, 1337)
    if not ok1 or type(r1) ~= "number" then return false end

    local ok2, r2 = pcall(auth.sign, 7331)
    if not ok2 or type(r2) ~= "number" then return false end


    if r1 == r2 then return false end

    return true
end


local function _check_timing()
    local t1  = os.clock()
    local sum = 0


    for j = 1, 2000 do sum = sum + j * 1.001 end
    local delta = os.clock() - t1
    return delta >= 0 and delta <= 5
end


local function _verify_memory()
    local t = tick and tick() or os.time()
    return t >= 0
end



if _detect_hooks() then
    warn("⛔ Evolution Hub: Hook detected")
    _kick("Security violation")
    return
end
task.wait(0)

if not _check_timing() then
    warn("⛔ Evolution Hub: Timing anomaly")
    _kick("Timing violation")
    return
end
task.wait(0)

if not _verify_memory() then
    warn("⛔ Evolution Hub: Memory check failed")
    _kick("Memory violation")
    return
end
task.wait(0)

if not _consume_nonce() then
    warn("⛔ Evolution Hub: Invalid nonce (possible replay)")
    _kick("Session expired")
    return
end
task.wait(0)

if not _verify_flow_heartbeat() then
    warn("⛔ Evolution Hub: Heartbeat failure")
    _kick("Session corrupted")
    return
end
task.wait(0)

if not _verify_signature() then
    warn("⛔ Evolution Hub: Signature mismatch")
    _kick("Integrity violation")
    return
end
task.wait(0)

if not _hardened_verify() then
    warn("⛔ Evolution Hub: Auth verification failed")
    _kick("Authentication required")
    return
end
task.wait(0)

return true
