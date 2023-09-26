local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Ser = require(script.Serializer)
local TextCompression = require(script.Compression)
local Value = require(script.Value)

local REPLICATED_LAYER_KEY = "ReplicatedLayerId"
local COMPRESSION_CONFIG = {level = 4, strategy = "dynamic"}
local MAX_REMOTE_REQUEST_RATE = 120 -- x calls in a frame
local IS_SERVER = RunService:IsServer()
local PACKET_TYPES = {Fire = "Fire", InvokeOut = "InvokeOut", InvokeIn = "InvokeIn"}

local NetworkBridgeEvent = script:WaitForChild("NetworkBridgeEvent")

local EncryptionLib do
    --[[
    ADVANCED ENCRYPTION STANDARD (AES)

    Implementation of secure symmetric-key encryption specifically in Luau
    Includes ECB, CBC, PCBC, CFB, OFB and CTR modes without padding.
    Made by @RobloxGamerPro200007 (verify the original asset)

    MORE INFORMATION: https://devforum.roblox.com/t/advanced-encryption-standard-in-luau/2009120
    ]]

    -- SUBSTITUTION BOXES
    local s_box 	= { 99, 124, 119, 123, 242, 107, 111, 197,  48,   1, 103,  43, 254, 215, 171, 118, 202,
    130, 201, 125, 250,  89,  71, 240, 173, 212, 162, 175, 156, 164, 114, 192, 183, 253, 147,  38,  54,
    63, 247, 204,  52, 165, 229, 241, 113, 216,  49,  21,   4, 199,  35, 195,  24, 150,   5, 154,   7,
    18, 128, 226, 235,  39, 178, 117,   9, 131,  44,  26,  27, 110,  90, 160,  82,  59, 214, 179,  41,
    227,  47, 132,  83, 209,   0, 237,  32, 252, 177,  91, 106, 203, 190,  57,  74,  76,  88, 207, 208,
    239, 170, 251,  67,  77,  51, 133,  69, 249,   2, 127,  80,  60, 159, 168,  81, 163,  64, 143, 146,
    157,  56, 245, 188, 182, 218,  33,  16, 255, 243, 210, 205,  12,  19, 236,  95, 151,  68,  23, 196,
    167, 126,  61, 100,  93,  25, 115,  96, 129,  79, 220,  34,  42, 144, 136,  70, 238, 184,  20, 222,
    94,  11, 219, 224,  50,  58,  10,  73,   6,  36,  92, 194, 211, 172,  98, 145, 149, 228, 121, 231,
    200,  55, 109, 141, 213,  78, 169, 108,  86, 244, 234, 101, 122, 174,   8, 186, 120,  37,  46,  28,
    166, 180, 198, 232, 221, 116,  31,  75, 189, 139, 138, 112,  62, 181, 102,  72,   3, 246,  14,  97,
    53,  87, 185, 134, 193,  29, 158, 225, 248, 152,  17, 105, 217, 142, 148, 155,  30, 135, 233, 206,
    85,  40, 223, 140, 161, 137,  13, 191, 230,  66, 104,  65, 153,  45,  15, 176,  84, 187,  22}
    local inv_s_box	= { 82,   9, 106, 213,  48,  54, 165,  56, 191,  64, 163, 158, 129, 243, 215, 251, 124,
    227,  57, 130, 155,  47, 255, 135,  52, 142,  67,  68, 196, 222, 233, 203,  84, 123, 148,  50, 166,
    194,  35,  61, 238,  76, 149,  11,  66, 250, 195,  78,   8,  46, 161, 102,  40, 217,  36, 178, 118,
    91, 162,  73, 109, 139, 209,  37, 114, 248, 246, 100, 134, 104, 152,  22, 212, 164,  92, 204,  93,
    101, 182, 146, 108, 112,  72,  80, 253, 237, 185, 218,  94,  21,  70,  87, 167, 141, 157, 132, 144,
    216, 171,   0, 140, 188, 211,  10, 247, 228,  88,   5, 184, 179,  69,   6, 208,  44,  30, 143, 202,
    63,  15,   2, 193, 175, 189,   3,   1,  19, 138, 107,  58, 145,  17,  65,  79, 103, 220, 234, 151,
    242, 207, 206, 240, 180, 230, 115, 150, 172, 116,  34, 231, 173,  53, 133, 226, 249,  55, 232,  28,
    117, 223, 110,  71, 241,  26, 113,  29,  41, 197, 137, 111, 183,  98,  14, 170,  24, 190,  27, 252,
    86,  62,  75, 198, 210, 121,  32, 154, 219, 192, 254, 120, 205,  90, 244,  31, 221, 168,  51, 136,
    7, 199,  49, 177,  18,  16,  89,  39, 128, 236,  95,  96,  81, 127, 169,  25, 181,  74,  13,  45,
    229, 122, 159, 147, 201, 156, 239, 160, 224,  59,  77, 174,  42, 245, 176, 200, 235, 187,  60, 131,
    83, 153,  97,  23,  43,   4, 126, 186, 119, 214,  38, 225, 105,  20,  99,  85,  33,  12, 125}

    -- ROUND CONSTANTS ARRAY
    local rcon = {  0,   1,   2,   4,   8,  16,  32,  64, 128,  27,  54, 108, 216, 171,  77, 154,  47,  94,
    188,  99, 198, 151,  53, 106, 212, 179, 125, 250, 239, 197, 145,  57}
    -- MULTIPLICATION OF BINARY POLYNOMIAL
    local function xtime(x)
    local i = bit32.lshift(x, 1)
    return if bit32.band(x, 128) == 0 then i else bit32.bxor(i, 27) % 256
    end

    -- TRANSFORMATION FUNCTIONS
    local function subBytes		(s, inv) 		-- Processes State using the S-box
    inv = if inv then inv_s_box else s_box
    for i = 1, 4 do
        for j = 1, 4 do
            s[i][j] = inv[s[i][j] + 1]
        end
    end
    end
    local function shiftRows		(s, inv) 	-- Processes State by circularly shifting rows
    s[1][3], s[2][3], s[3][3], s[4][3] = s[3][3], s[4][3], s[1][3], s[2][3]
    if inv then
        s[1][2], s[2][2], s[3][2], s[4][2] = s[4][2], s[1][2], s[2][2], s[3][2]
        s[1][4], s[2][4], s[3][4], s[4][4] = s[2][4], s[3][4], s[4][4], s[1][4]
    else
        s[1][2], s[2][2], s[3][2], s[4][2] = s[2][2], s[3][2], s[4][2], s[1][2]
        s[1][4], s[2][4], s[3][4], s[4][4] = s[4][4], s[1][4], s[2][4], s[3][4]
    end
    end
    local function addRoundKey	(s, k) 			-- Processes Cipher by adding a round key to the State
    for i = 1, 4 do
        for j = 1, 4 do
            s[i][j] = bit32.bxor(s[i][j], k[i][j])
        end
    end
    end
    local function mixColumns	(s, inv) 		-- Processes Cipher by taking and mixing State columns
    local t, u
    if inv then
        for i = 1, 4 do
            t = xtime(xtime(bit32.bxor(s[i][1], s[i][3])))
            u = xtime(xtime(bit32.bxor(s[i][2], s[i][4])))
            s[i][1], s[i][2] = bit32.bxor(s[i][1], t), bit32.bxor(s[i][2], u)
            s[i][3], s[i][4] = bit32.bxor(s[i][3], t), bit32.bxor(s[i][4], u)
        end
    end

    local i
    for j = 1, 4 do
        i = s[j]
        t, u = bit32.bxor		(i[1], i[2], i[3], i[4]), i[1]
        for k = 1, 4 do
            i[k] = bit32.bxor	(i[k], t, xtime(bit32.bxor(i[k], i[k + 1] or u)))
        end
    end
    end

    -- BYTE ARRAY UTILITIES
    local function bytesToMatrix	(t, c, inv) -- Converts a byte array to a 4x4 matrix
    if inv then
        table.move		(c[1], 1, 4, 1, t)
        table.move		(c[2], 1, 4, 5, t)
        table.move		(c[3], 1, 4, 9, t)
        table.move		(c[4], 1, 4, 13, t)
    else
        for i = 1, #c / 4 do
            table.clear	(t[i])
            table.move	(c, i * 4 - 3, i * 4, 1, t[i])
        end
    end

    return t
    end
    local function xorBytes		(t, a, b) 		-- Returns bitwise XOR of all their bytes
    table.clear		(t)

    for i = 1, math.min(#a, #b) do
        table.insert(t, bit32.bxor(a[i], b[i]))
    end
    return t
    end
    local function incBytes		(a, inv)		-- Increment byte array by one
    local o = true
    for i = if inv then 1 else #a, if inv then #a else 1, if inv then 1 else - 1 do
        if a[i] == 255 then
            a[i] = 0
        else
            a[i] += 1
            o = false
            break
        end
    end

    return o, a
    end

    -- MAIN ALGORITHM
    local function expandKey	(key) 				-- Key expansion
    local kc = bytesToMatrix(if #key == 16 then {{}, {}, {}, {}} elseif #key == 24 then {{}, {}, {}, {}
        , {}, {}} else {{}, {}, {}, {}, {}, {}, {}, {}}, key)
    local is = #key / 4
    local i, t, w = 2, {}, nil

    while #kc < (#key / 4 + 7) * 4 do
        w = table.clone	(kc[#kc])
        if #kc % is == 0 then
            table.insert(w, table.remove(w, 1))
            for j = 1, 4 do
                w[j] = s_box[w[j] + 1]
            end
            w[1]	 = bit32.bxor(w[1], rcon[i])
            i 	+= 1
        elseif #key == 32 and #kc % is == 4 then
            for j = 1, 4 do
                w[j] = s_box[w[j] + 1]
            end
        end
        
        table.clear	(t)
        xorBytes	(w, table.move(w, 1, 4, 1, t), kc[#kc - is + 1])
        table.insert(kc, w)
    end

    table.clear		(t)
    for j = 1, #kc / 4 do
        table.insert(t, {})
        table.move	(kc, j * 4 - 3, j * 4, 1, t[#t])
    end
    return t
    end
    local function encrypt	(key, km, pt, ps, r) 	-- Block cipher encryption
    bytesToMatrix	(ps, pt)
    addRoundKey		(ps, km[1])

    for i = 2, #key / 4 + 6 do
        subBytes	(ps)
        shiftRows	(ps)
        mixColumns	(ps)
        addRoundKey	(ps, km[i])
    end
    subBytes		(ps)
    shiftRows		(ps)
    addRoundKey		(ps, km[#km])

    return bytesToMatrix(r, ps, true)
    end
    local function decrypt	(key, km, ct, cs, r) 	-- Block cipher decryption
    bytesToMatrix	(cs, ct)

    addRoundKey		(cs, km[#km])
    shiftRows		(cs, true)
    subBytes		(cs, true)
    for i = #key / 4 + 6, 2, - 1 do
        addRoundKey	(cs, km[i])
        mixColumns	(cs, true)
        shiftRows	(cs, true)
        subBytes	(cs, true)
    end

    addRoundKey		(cs, km[1])
    return bytesToMatrix(r, cs, true)
    end

    -- INITIALIZATION FUNCTIONS
    local function convertType	(a) 					-- Converts data to bytes if possible
    if type(a) == "string" then
        local r = {}

        for i = 1, string.len(a), 7997 do
            table.move({string.byte(a, i, i + 7996)}, 1, 7997, i, r)
        end
        return r
    elseif type(a) == "table" then
        for _, i in ipairs(a) do
            assert(type(i) == "number" and math.floor(i) == i and 0 <= i and i < 256,
                "Unable to cast value to bytes")
        end
        return a
    else
        error("Unable to cast value to bytes")
    end
    end
    local function init			(key, txt, m, iv, s) 	-- Initializes functions if possible
    key = convertType(key)
    assert(#key == 16 or #key == 24 or #key == 32, "Key must be either 16, 24 or 32 bytes long")
    txt = convertType(txt)
    assert(#txt % (s or 16) == 0, "Input must be a multiple of " .. (if s then "segment size " .. s
        else "16") .. " bytes in length")
    if m then
        if type(iv) == "table" then
            iv = table.clone(iv)
            local l, e 		= iv.Length, iv.LittleEndian
            assert(type(l) == "number" and 0 < l and l <= 16,
                "Counter value length must be between 1 and 16 bytes")
            iv.Prefix 		= convertType(iv.Prefix or {})
            iv.Suffix 		= convertType(iv.Suffix or {})
            assert(#iv.Prefix + #iv.Suffix + l == 16, "Counter must be 16 bytes long")
            iv.InitValue 	= if iv.InitValue == nil then {1} else table.clone(convertType(iv.InitValue
            ))
            assert(#iv.InitValue <= l, "Initial value length must be of the counter value")
            iv.InitOverflow = if iv.InitOverflow == nil then table.create(l, 0) else table.clone(
                convertType(iv.InitOverflow))
            assert(#iv.InitOverflow <= l,
                "Initial overflow value length must be of the counter value")
            for _ = 1, l - #iv.InitValue do
                table.insert(iv.InitValue, 1 + if e then #iv.InitValue else 0, 0)
            end
            for _ = 1, l - #iv.InitOverflow do
                table.insert(iv.InitOverflow, 1 + if e then #iv.InitOverflow else 0, 0)
            end
        elseif type(iv) ~= "function" then
            local i, t = if iv then convertType(iv) else table.create(16, 0), {}
            assert(#i == 16, "Counter must be 16 bytes long")
            iv = {Length = 16, Prefix = t, Suffix = t, InitValue = i,
                InitOverflow = table.create(16, 0)}
        end
    elseif m == false then
        iv 	= if iv == nil then  table.create(16, 0) else convertType(iv)
        assert(#iv == 16, "Initialization vector must be 16 bytes long")
    end
    if s then
        s = math.floor(tonumber(s) or 1)
        assert(type(s) == "number" and 0 < s and s <= 16, "Segment size must be between 1 and 16 bytes"
        )
    end

    return key, txt, expandKey(key), iv, s
    end
    type bytes = {number} -- Type instance of a valid bytes object

    -- CIPHER MODES OF OPERATION
    EncryptionLib = {
    -- Electronic codebook (ECB)
    encrypt_ECB = function(key : bytes, plainText : bytes) 									: bytes
        local km
        key, plainText, km = init(key, plainText)
        
        local b, k, s, t = {}, {}, {{}, {}, {}, {}}, {}
        for i = 1, #plainText, 16 do
            table.move(plainText, i, i + 15, 1, k)
            table.move(encrypt(key, km, k, s, t), 1, 16, i, b)
        end
        
        return b
    end,
    decrypt_ECB = function(key : bytes, cipherText : bytes) 								: bytes
        local km
        key, cipherText, km = init(key, cipherText)
        
        local b, k, s, t = {}, {}, {{}, {}, {}, {}}, {}
        for i = 1, #cipherText, 16 do
            table.move(cipherText, i, i + 15, 1, k)
            table.move(decrypt(key, km, k, s, t), 1, 16, i, b)
        end
        
        return b
    end,
    -- Cipher block chaining (CBC)
    encrypt_CBC = function(key : bytes, plainText : bytes, initVector : bytes?) 			: bytes
        local km
        key, plainText, km, initVector = init(key, plainText, false, initVector)
        
        local b, k, p, s, t = {}, {}, initVector, {{}, {}, {}, {}}, {}
        for i = 1, #plainText, 16 do
            table.move(plainText, i, i + 15, 1, k)
            table.move(encrypt(key, km, xorBytes(t, k, p), s, p), 1, 16, i, b)
        end
        
        return b
    end,
    decrypt_CBC = function(key : bytes, cipherText : bytes, initVector : bytes?) 			: bytes
        local km
        key, cipherText, km, initVector = init(key, cipherText, false, initVector)
        
        local b, k, p, s, t = {}, {}, initVector, {{}, {}, {}, {}}, {}
        for i = 1, #cipherText, 16 do
            table.move(cipherText, i, i + 15, 1, k)
            table.move(xorBytes(k, decrypt(key, km, k, s, t), p), 1, 16, i, b)
            table.move(cipherText, i, i + 15, 1, p)
        end
        
        return b
    end,
    -- Propagating cipher block chaining (PCBC)
    encrypt_PCBC = function(key : bytes, plainText : bytes, initVector : bytes?) 			: bytes
        local km
        key, plainText, km, initVector = init(key, plainText, false, initVector)
        
        local b, k, c, p, s, t = {}, {}, initVector, table.create(16, 0), {{}, {}, {}, {}}, {}
        for i = 1, #plainText, 16 do
            table.move(plainText, i, i + 15, 1, k)
            table.move(encrypt(key, km, xorBytes(k, xorBytes(t, c, k), p), s, c), 1, 16, i, b)
            table.move(plainText, i, i + 15, 1, p)
        end
        
        return b
    end,
    decrypt_PCBC = function(key : bytes, cipherText : bytes, initVector : bytes?) 			: bytes
        local km
        key, cipherText, km, initVector = init(key, cipherText, false, initVector)
        
        local b, k, c, p, s, t = {}, {}, initVector, table.create(16, 0), {{}, {}, {}, {}}, {}
        for i = 1, #cipherText, 16 do
            table.move(cipherText, i, i + 15, 1, k)
            table.move(xorBytes(p, decrypt(key, km, k, s, t), xorBytes(k, c, p)), 1, 16, i, b)
            table.move(cipherText, i, i + 15, 1, c)
        end
        
        return b
    end,
    -- Cipher feedback (CFB)
    encrypt_CFB = function(key : bytes, plainText : bytes, initVector : bytes?, segmentSize : number?)
        : bytes
        local km
        key, plainText, km, initVector, segmentSize = init(key, plainText, false, initVector,
            if segmentSize == nil then 1 else segmentSize)
        
        local b, k, p, q, s, t = {}, {}, initVector, {}, {{}, {}, {}, {}}, {}
        for i = 1, #plainText, segmentSize do
            table.move(plainText, i, i + segmentSize - 1, 1, k)
            table.move(xorBytes(q, encrypt(key, km, p, s, t), k), 1, segmentSize, i, b)
            for j = 16, segmentSize + 1, - 1 do
                table.insert(q, 1, p[j])
            end
            table.move(q, 1, 16, 1, p)
        end
        
        return b
    end,
    decrypt_CFB = function(key : bytes, cipherText : bytes, initVector : bytes, segmentSize : number?)
        : bytes
        local km
        key, cipherText, km, initVector, segmentSize = init(key, cipherText, false, initVector,
            if segmentSize == nil then 1 else segmentSize)
        
        local b, k, p, q, s, t = {}, {}, initVector, {}, {{}, {}, {}, {}}, {}
        for i = 1, #cipherText, segmentSize do
            table.move(cipherText, i, i + segmentSize - 1, 1, k)
            table.move(xorBytes(q, encrypt(key, km, p, s, t), k), 1, segmentSize, i, b)
            for j = 16, segmentSize + 1, - 1 do
                table.insert(k, 1, p[j])
            end
            table.move(k, 1, 16, 1, p)
        end
        
        return b
    end,
    -- Output feedback (OFB)
    encrypt_OFB = function(key : bytes, plainText : bytes, initVector : bytes?) 			: bytes
        local km
        key, plainText, km, initVector = init(key, plainText, false, initVector)
        
        local b, k, p, s, t = {}, {}, initVector, {{}, {}, {}, {}}, {}
        for i = 1, #plainText, 16 do
            table.move(plainText, i, i + 15, 1, k)
            table.move(encrypt(key, km, p, s, t), 1, 16, 1, p)
            table.move(xorBytes(t, k, p), 1, 16, i, b)
        end
        
        return b
    end,
    -- Counter (CTR)
    encrypt_CTR = function(key : bytes, plainText : bytes, counter : ((bytes) -> bytes) | bytes | { [
        string]: any }?) : bytes
        local km
        key, plainText, km, counter = init(key, plainText, true, counter)
        
        local b, k, c, s, t, r, n = {}, {}, {}, {{}, {}, {}, {}}, {}, type(counter) == "table", nil
        for i = 1, #plainText, 16 do
            if r then
                if i > 1 and incBytes(counter.InitValue, counter.LittleEndian) then
                    table.move(counter.InitOverflow, 1, 16, 1, counter.InitValue)
                end
                table.clear	(c)
                table.move	(counter.Prefix, 1, #counter.Prefix, 1, c)
                table.move	(counter.InitValue, 1, counter.Length, #c + 1, c)
                table.move	(counter.Suffix, 1, #counter.Suffix, #c + 1, c)
            else
                n = convertType(counter(c, (i + 15) / 16))
                assert		(#n == 16, "Counter must be 16 bytes long")
                table.move	(n, 1, 16, 1, c)
            end
            table.move(plainText, i, i + 15, 1, k)
            table.move(xorBytes(c, encrypt(key, km, c, s, t), k), 1, 16, i, b)
        end
        
        return b
    end
    } -- Returns the library
end

local UnconnectedEventsCalls = {}
local ConnectedBridges = {}
local PacketQueue = {}

local GetEncryptionId do
    if IS_SERVER then
        local RNG = Random.new()

        local elapsed = 0
        local profiles = {}

        local function generateRandomString(strSize: number?): string
            local str = ""
            for _ = 1, (strSize or 16) do
                local char = string.char(RNG:NextInteger(65, 90))
                if RNG:NextNumber() > 0.6 then
                    char = char:lower()
                end
                str = str .. char
            end
            return str
        end
        
        function GetEncryptionId(player: Player)
            assert(player ~= nil, "Argument 1 must not be nil")
            assert(typeof(player) == "Instance" and player:IsA("Player"), "Argument 1 must be a Player object")
            if profiles[player] then
                return profiles[player].id:get()
            end
            local id = generateRandomString(32)
            profiles[player] = {
                id = Value.new(id),
                lastElapsedPacketSent = elapsed, -- the more frequent the more likely session update rate is gonna keep on changing, on top of that can be used to detect for those tryna crash the server
                lastSessionElapsed = 0,
                sessionUpdateRate = 60,--every 60 seconds, the key changes
            }
            player:SetAttribute(REPLICATED_LAYER_KEY, id)--either way experienced exploiters will still get the id; server-client, value or attribute-wise. our main objective is to prevent skids from cheating:v
            return id
        end

        local function onPlayerAdded(player)
            local _id = GetEncryptionId(player)
            
            PacketQueue[player] = {packetsIn = {}, packetsOut = {}, flushingOutPackets = false, outgoingPacketRate = 0, incomingPacketRate = 0, runningInvokeThreads = {}}
            local _playerPacket = PacketQueue[player]
        end

        Players.PlayerAdded:Connect(onPlayerAdded)
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(onPlayerAdded, player)
        end
        Players.PlayerRemoving:Connect(function(player)
            profiles[player] = nil
        end)

        RunService.Heartbeat:Connect(function(_dt)
            elapsed = tick()
            for player, profile in pairs(profiles) do
                if elapsed-profile.lastSessionElapsed >= profile.sessionUpdateRate then
                    profile.lastSessionElapsed = elapsed
                    local id = generateRandomString(32)
                    profile.id:set(id)
                    player:SetAttribute(REPLICATED_LAYER_KEY, id)
                end
            end
        end)
        script:SetAttribute("EstablishedRouting", true)
    else
        PacketQueue.packetsIn = {}
        PacketQueue.packetsOut = {}
        PacketQueue.flushingOutPackets = false
        PacketQueue.outgoingPacketRate = 0
        PacketQueue.runningInvokeThreads = {}
        PacketQueue.incomingPacketRate = 0

        function GetEncryptionId()
            if not script:GetAttribute("EstablishedRouting") then
                error("Internal construct failed, no route has been established yet", 2)
            end
            local attr = Players.LocalPlayer:GetAttribute(REPLICATED_LAYER_KEY)
            if attr then
                return attr
            end
            error("Bad routing, please wait while this issue resolves itself.")
        end
    end
end

local function encodePackets(id: string, args: {any}): string
    local serialized = Ser.SerializeTable(args)
    local result = HttpService:JSONEncode(serialized)
    local compressed = TextCompression.Deflate.Compress(result, COMPRESSION_CONFIG)
    local encrypted = EncryptionLib.encrypt_CFB(id, compressed, nil, 1)
    encrypted = string.char(table.unpack(encrypted))
    return encrypted
end

local function decodePackets(id: string, data: string): (...any)
    local decrypted = EncryptionLib.decrypt_CFB(id, {string.byte(data, 1, #data)}, nil, 1)
    decrypted = string.char(table.unpack(decrypted))
    local decompressed = TextCompression.Deflate.Decompress(decrypted)
    local result = HttpService:JSONDecode(decompressed)
    local deserialized = Ser.DeserializeTable(result)
    return deserialized
end

--
-- OUTGOING PACKETS
--

local function compressAndMergeOutgoingPacketArgumentsTo(packet: {}, queue: {}, dst: {}) -- TODO do this instead under an actor
    local same = {}
    for i = #queue, 1, -1 do
        local samePacket = queue[i]
        if not samePacket or not packet then continue end -- whilst iterating, packet might be lost so, just checking it twice
        if (samePacket.path.bridge == packet.path.bridge and samePacket.path.remote == packet.path.remote) or samePacket.path.invokeId == packet.path.invokeId then
            same[#same+1] = samePacket
        end
    end
    if #same > 0 then
        table.sort(same, function(a, b)
            return a.upSent < b.upSent
        end)
        local dominantPacket = same[1]
        if #packet.args > 0 then
            dominantPacket.args[#dominantPacket.args+1] = packet.args[1]
        end
        if not dominantPacket._processed then
            dominantPacket._processed = true
            dst[#dst+1] = dominantPacket
        end
        return dominantPacket
    else
        if not packet._processed then
            packet._processed = true
            dst[#dst+1] = packet
        end
        return packet
    end
end

local function postProcessOutgoingPackets(outPackets: {}, key: string, targetPlayer: Player)
    local compressedOutPackets = {}
    for c = 1, #outPackets do
        local currentPacketRate = if IS_SERVER then PacketQueue[targetPlayer].outgoingPacketRate else PacketQueue.outgoingPacketRate
        local packet = outPackets[c]
        outPackets[c] = nil
        if currentPacketRate <= MAX_REMOTE_REQUEST_RATE then
            compressAndMergeOutgoingPacketArgumentsTo(packet, outPackets, compressedOutPackets)
        end
        if IS_SERVER then
            PacketQueue[targetPlayer].outgoingPacketRate += 1
        else
            PacketQueue.outgoingPacketRate += 1
        end
    end
    local traffic = {}
    for i = #compressedOutPackets, 1, -1 do
        local packet = compressedOutPackets[i] -- fast remove
        compressedOutPackets[i] = nil -- fast remove
        packet = encodePackets(key, packet)
        traffic[#traffic+1] = packet
    end

    if IS_SERVER then
        NetworkBridgeEvent:FireClient(targetPlayer, traffic)
    else
        NetworkBridgeEvent:FireServer(traffic)
    end
end

local function preProcessOutgoingPackets(targetPlayer: Player)
    local packets = if IS_SERVER then PacketQueue[targetPlayer].packetsOut else PacketQueue.packetsOut
    local key = if IS_SERVER then GetEncryptionId(targetPlayer) else GetEncryptionId()
    postProcessOutgoingPackets(packets, key, targetPlayer)
    if IS_SERVER then
        PacketQueue[targetPlayer].flushingOutPackets = false
    else
        PacketQueue.flushingOutPackets = false
    end
end

local function sendOutgoingPacket(packet: {}, targetPlayer: Player)
    local currentPacketRate = if IS_SERVER then PacketQueue[targetPlayer].outgoingPacketRate else PacketQueue.outgoingPacketRate
    if currentPacketRate > MAX_REMOTE_REQUEST_RATE then
        return
    end
    
    if IS_SERVER then
        local playerPacket = PacketQueue[targetPlayer]
        table.insert(playerPacket.packetsOut, packet)
        if not playerPacket.flushingOutPackets then
            playerPacket.flushingOutPackets = true
            task.defer(preProcessOutgoingPackets, targetPlayer)
        end
    else
        table.insert(PacketQueue.packetsOut, packet )
        if not PacketQueue.flushingOutPackets then
            PacketQueue.flushingOutPackets = true
            task.defer(preProcessOutgoingPackets)
        end
    end
end

--
-- INCOMING PACKETS
--

local function warnMissedCallsOf(remoteName: string)
    UnconnectedEventsCalls[remoteName] = (UnconnectedEventsCalls[remoteName] or 0) + 1
    if UnconnectedEventsCalls[remoteName] % 16 == 0 then
        warn(string.format("Multiple events fired for %s but no bound connections found (Fired %i times)", remoteName, UnconnectedEventsCalls[remoteName]))
    end
end

local function managePreProcessOfIncomingPackets(targetQueue: {}, traffic: {string}, key: string)
    local trafficCount = #traffic
    for i = 1, trafficCount do
        local packet = decodePackets(key, traffic[i])
        table.insert(targetQueue, packet)
    end
end

local function preProcessIncomingPackets(traffic: {string}, targetPlayer: Player?)
    if IS_SERVER then
        local playerPacket = PacketQueue[targetPlayer]
        if playerPacket then
            local key = GetEncryptionId(targetPlayer)
            managePreProcessOfIncomingPackets(playerPacket.packetsIn, traffic, key)
        end
    else
        local key = GetEncryptionId()
        managePreProcessOfIncomingPackets(PacketQueue.packetsIn, traffic, key)
    end
end

local function postProcessIncomingPackets(sourcePacketQueue: {}, fromPlayer: Player?)
    local currentPacketCount = #sourcePacketQueue.packetsIn
    if currentPacketCount > 0 then
        if not sourcePacketQueue.flushingInPackets then
            sourcePacketQueue.flushingInPackets = true
            local reliablePacketsIn = sourcePacketQueue.packetsIn
            for i = currentPacketCount, 1, -1 do
                local packet = reliablePacketsIn[i]
                if not packet then continue end
                local packetType = packet.packetType
                if packetType == PACKET_TYPES.Fire then
                    local bridge = ConnectedBridges[packet.path.bridge]
                    local remoteName = packet.path.remote
                    if bridge then
                        local event = bridge:__getEvent(remoteName)
                        if event then
                            for j = #packet.args, 1, -1 do
                                local bit = packet.args[j]
                                packet.args[j] = nil
                                if sourcePacketQueue.incomingPacketRate <= MAX_REMOTE_REQUEST_RATE then
                                    if not bit._processing then
                                        bit._processing = true
                                        if IS_SERVER then
                                            xpcall(event, warn, fromPlayer, table.unpack(bit))
                                        else
                                            xpcall(event, warn, table.unpack(bit))
                                        end
                                    end
                                end
                                sourcePacketQueue.incomingPacketRate += 1
                            end
                        else
                            warnMissedCallsOf(remoteName)
                        end
                    end
                elseif packetType == PACKET_TYPES.InvokeOut then
                    local bridge = ConnectedBridges[packet.path.bridge]
                    if bridge then
                        local method = bridge:__getMethod(packet.path.remote)
                        if method then
                            for j = #packet.args, 1, -1 do
                                local bit = packet.args[j]
                                packet.args[j] = nil
                                if sourcePacketQueue.incomingPacketRate <= MAX_REMOTE_REQUEST_RATE then
                                    if not bit._processing then
                                        bit._processing = true
                                        local args = nil
                                        local _pack = if IS_SERVER then {xpcall(method, warn, fromPlayer, table.unpack(bit))} else {xpcall(method, warn, table.unpack(bit))}
                                        if _pack then
                                            if _pack[1] then
                                                args = {table.unpack(_pack, 2, #_pack)}
                                            end
                                            if #args > 0 then
                                                sendOutgoingPacket({
                                                    packetType = PACKET_TYPES.InvokeIn,
                                                    path = {bridge = nil, remote = nil, invokeId = packet.path.invokeId},
                                                    args = {args},
                                                    upSent = tick(),
                                                }, fromPlayer)
                                            end
                                        end
                                    end
                                end
                                sourcePacketQueue.incomingPacketRate += 1
                            end
                        end
                    end
                elseif packetType == PACKET_TYPES.InvokeIn then
                    local invokeId = packet.path.invokeId
                    if invokeId then
                        local threadQueue = if IS_SERVER then PacketQueue[fromPlayer].runningInvokeThreads else PacketQueue.runningInvokeThreads
                        local thread = threadQueue[invokeId]
                        if thread then
                            threadQueue[invokeId] = nil
                            -- we will only accept the first argument processed
                            local first = packet.args[1]
                            packet.args = nil
                            if first then
                                task.spawn(thread.thread, table.unpack(first))
                            end
                        else
                            warn(`Invoke thread [{invokeId}] might have already expired!`)
                        end
                    end
                end
                reliablePacketsIn[i] = nil
            end
            sourcePacketQueue.flushingInPackets = false
            sourcePacketQueue.packetsIn = reliablePacketsIn
        end
    end
end

local PacketManager = {}
function PacketManager.ConnectBridgeToPacketNetwork(bridge)
    local id = bridge.Identity
    ConnectedBridges[id] = bridge
    if IS_SERVER then
        script:SetAttribute(id, true)
    else
        if not script:GetAttribute(id) then
            warn("Routing fault; are you sure that this bridge connection exists?")
        end
    end
end

if IS_SERVER then
    NetworkBridgeEvent.OnServerEvent:Connect(function(player: Player, traffic: {string})
        preProcessIncomingPackets(traffic, player)
    end)
    
    function PacketManager.FireFromBridge(bridge: string, target: string, targetPlayer: Player?, ...: any)
        sendOutgoingPacket({
            packetType = PACKET_TYPES.Fire,
            path = {bridge = bridge, remote = target, invokeId = nil},
            args = {{...}},
            upSent = tick(),
        }, targetPlayer)
    end

    function PacketManager.TryInvokeFromBridge(bridge:string, target: string, targetPlayer: Player, timeOut: number?, ...: any)
        local id = HttpService:GenerateGUID(false)
        sendOutgoingPacket({
            packetType = PACKET_TYPES.InvokeOut,
            path = {bridge = bridge, remote = target, invokeId = id},
            args = {{...}},
            upSent = tick(),
        }, targetPlayer)
        --now prepare a thread
        local queue = PacketQueue.runningInvokeThreads
        queue[id] = {
            thread = coroutine.running(),
            lifetime = timeOut or 8,
        }
        return coroutine.yield()
    end
else
    NetworkBridgeEvent.OnClientEvent:Connect(function(traffic: {string})
        preProcessIncomingPackets(traffic)
    end)
    
    function PacketManager.FireFromBridge(bridge: string, target: string, ...: any)
        sendOutgoingPacket({
            packetType = PACKET_TYPES.Fire,
            path = {bridge = bridge, remote = target},
            args = {{...}},
            upSent = tick(),
        })
    end
    
    function PacketManager.InvokeFromBridge(bridge:string, target: string, timeOut: number?, ...: any)
        local id = HttpService:GenerateGUID(false)
        sendOutgoingPacket({
            packetType = PACKET_TYPES.InvokeOut,
            path = {bridge = bridge, remote = target, invokeId = id},
            args = {{...}},
            upSent = tick(),
        })
        --now prepare a thread
        local queue = PacketQueue.runningInvokeThreads
        queue[id] = {
            thread = coroutine.running(),
            lifetime = timeOut or 8,
        }
        return coroutine.yield()
    end
end

RunService.Heartbeat:Connect(function(_dt)
    if IS_SERVER then
        for player, queue in pairs(PacketQueue) do
            coroutine.wrap(xpcall)(postProcessIncomingPackets, warn, queue, player)
            --local _success, _err = xpcall(postProcessIncomingPackets, warn, queue, player)
            --[[if not success then
                warn(err)
            end]]

            for _id, threadInfo in pairs(queue.runningInvokeThreads) do
                local lifetime = threadInfo.lifetime
                if lifetime <= 0 then
                    task.spawn(threadInfo.thread) -- we dont want our thread to wait infinitely
                    queue.runningInvokeThreads[_id] = nil
                else
                    threadInfo.lifetime = lifetime - _dt
                end
            end

            queue.outgoingPacketRate *= 0
            queue.incomingPacketRate *= 0
        end
    else
        coroutine.wrap(xpcall)(postProcessIncomingPackets, warn, PacketQueue)
        --local _success, _err = xpcall(postProcessIncomingPackets, warn, PacketQueue)
        --[[if not success then
            warn(err)
        end]]

        for _id, threadInfo in pairs(PacketQueue.runningInvokeThreads) do
            local lifetime = threadInfo.lifetime
            if lifetime <= 0 then
                PacketQueue.runningInvokeThreads[_id] = nil
            else
                threadInfo.lifetime = lifetime - _dt
            end
        end

        PacketQueue.outgoingPacketRate *= 0
        PacketQueue.incomingPacketRate *= 0
    end
end)

return PacketManager