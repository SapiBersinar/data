--print("Hello, World!")
local zona = script.Parent -- Mendapatkan referensi ke Part yang akan berfungsi sebagai zona hover
local pemainDiZona = {} -- Tabel untuk melacak pemain yang sedang di dalam zona hover
local Players = game:GetService("Players") -- Mendapatkan layanan Players
local RunService = game:GetService("RunService") -- Mendapatkan layanan RunService untuk update game loop

-- Inisialisasi properti part zona
zona.CanCollide = false -- Pemain bisa melewati zona ini tanpa bertabrakan
zona.CanTouch = true -- Mengizinkan event Touched untuk mendeteksi pemain masuk
zona.Anchored = true -- Memastikan zona tidak bergerak atau jatuh

-- Parameter Hover (pengaturan efek melayang)
local HOVER_FORCE_MAX = math.huge -- Kekuatan dorong ke atas. Tak terbatas biar selalu kuat ngangkat pemain.
local HOVER_P_GAIN_BV = 5000 -- Seberapa agresif BodyVelocity ngejar kecepatan target. Makin tinggi, makin responsif.
local HOVER_HEIGHT_OFFSET = 100 -- Ketinggian hover dari posisi zona. Misalnya zona Y = 0, pemain melayang di Y = 100.
local HOVER_P_CONTROLLER_GAIN = 10 -- Seberapa cepat sistem menyesuaikan tinggi pemain ke posisi hover yang ideal.
local HOVER_VELOCITY_MIN = -10 -- Batas kecepatan jatuh. Biar gak turun terlalu cepat.
local HOVER_VELOCITY_MAX = 25 -- Batas kecepatan naik. Biar gak naik kayak roket.
local SLOW_WALK_SPEED_FACTOR = 0.1 -- Pemain jadi lebih lambat saat hover. Nilai 0.1 = 10% kecepatan jalan normal.

-- Fungsi untuk menghapus efek hover dari karakter
function HapusEfekHover(character)
    local root = character:FindFirstChild("HumanoidRootPart") -- Mendapatkan HumanoidRootPart karakter
    if root then
        local efekHover = root:FindFirstChild("EfekHover") -- Mencari BodyVelocity bernama "EfekHover"
        if efekHover then
            efekHover:Destroy() -- Menghancurkan BodyVelocity untuk menghentikan efek hover
        end
    end
end
 
-- Fungsi untuk menerapkan efek hover (angin) pada karakter
function HoverAngin(character)
    local root = character:FindFirstChild("HumanoidRootPart") -- Mendapatkan HumanoidRootPart
    local humanoid = character:FindFirstChildOfClass("Humanoid") -- Mendapatkan Humanoid
    
    -- Memastikan HumanoidRootPart dan Humanoid ada, pemain masih hidup, dan belum ada efek hover
    if root and humanoid and humanoid.Health > 0 and not root:FindFirstChild("EfekHover") then
        local bv = Instance.new("BodyVelocity") -- Membuat BodyVelocity baru
        bv.Name = "EfekHover" -- Memberi nama BodyVelocity agar mudah dicari dan dihapus
        bv.MaxForce = Vector3.new(0, HOVER_FORCE_MAX, 0) -- Mengatur kekuatan maksimum (hanya pada sumbu Y)
        bv.P = HOVER_P_GAIN_BV -- Mengatur gain 'P' untuk BodyVelocity
        bv.Parent = root -- Menempatkan BodyVelocity di dalam HumanoidRootPart
        
        local targetHoverY = zona.Position.Y + HOVER_HEIGHT_OFFSET -- Menghitung ketinggian target hover
        local hoverConnection -- Variabel untuk koneksi event Stepped
        
        -- Menyimpan data pemain (kecepatan jalan asli dan BodyVelocity)
        pemainDiZona[character] = {
            originalWalkSpeed = humanoid.WalkSpeed,
            hoverEffect = bv
        }
        humanoid.WalkSpeed = humanoid.WalkSpeed * SLOW_WALK_SPEED_FACTOR -- Mengurangi kecepatan jalan pemain
        
        -- Menghubungkan fungsi ke event Stepped (berjalan setiap frame fisika)
        hoverConnection = RunService.Stepped:Connect(function()
            -- Memeriksa apakah efek hover masih valid (BodyVelocity, RootPart, Humanoid ada dan pemain hidup)
            if not bv.Parent or not root.Parent or not humanoid or (humanoid and humanoid.Health <= 0) then
                if hoverConnection then hoverConnection:Disconnect() end -- Memutuskan koneksi jika tidak valid
                if pemainDiZona[character] then
                    local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
                    if currentHumanoid and pemainDiZona[character].originalWalkSpeed then
                        currentHumanoid.WalkSpeed = pemainDiZona[character].originalWalkSpeed -- Mengembalikan kecepatan jalan
                    end
                    HapusEfekHover(character) -- Menghapus efek hover
                    pemainDiZona[character] = nil -- Menghapus pemain dari tabel
                end
                return -- Keluar dari fungsi
            end
                
            local errorY = targetHoverY - root.Position.Y -- Menghitung selisih antara ketinggian target dan ketinggian saat ini
            local desiredVelocityY = errorY * HOVER_P_CONTROLLER_GAIN -- Menghitung kecepatan vertikal yang diinginkan berdasarkan error
            desiredVelocityY = math.clamp(desiredVelocityY, HOVER_VELOCITY_MIN, HOVER_VELOCITY_MAX) -- Membatasi kecepatan vertikal dalam rentang min/max
            bv.Velocity = Vector3.new(0, desiredVelocityY, 0) -- Mengatur kecepatan BodyVelocity (hanya pada sumbu Y)
        end)
            
        -- Menghubungkan fungsi ke event Humanoid.Died (ketika pemain mati)
        humanoid.Died:Connect(function()
            if hoverConnection then hoverConnection:Disconnect() end -- Memutuskan koneksi
            if pemainDiZona[character] then
                local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
                if currentHumanoid and pemainDiZona[character].originalWalkSpeed then
                    currentHumanoid.WalkSpeed = pemainDiZona[character].originalWalkSpeed -- Mengembalikan kecepatan jalan
                end
                HapusEfekHover(character) -- Menghapus efek hover
                pemainDiZona[character] = nil -- Menghapus pemain dari tabel
            end
        end)
    end
end
        
-- Menghubungkan fungsi ke event Touched zona (ketika sesuatu menyentuh zona)
zona.Touched:Connect(function(hit)
    local character = hit.Parent -- Mendapatkan parent dari bagian yang menyentuh (biasanya karakter)
    local humanoid = character:FindFirstChildOfClass("Humanoid") -- Mendapatkan Humanoid dari karakter
        
    -- Jika yang menyentuh adalah karakter yang hidup dan belum di zona hover
    if humanoid and humanoid.Health > 0 then
        if not pemainDiZona[character] then
            HoverAngin(character) -- Menerapkan efek hover
        end
    end
end)
        
-- Loop utama untuk memeriksa pemain yang keluar dari zona secara berkala
while true do
    task.wait(0.1) -- Menunggu sebentar agar tidak terlalu membebani CPU
    for character, data in pairs(pemainDiZona) do -- Iterasi melalui semua pemain yang tercatat di zona
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
            
        -- Jika karakter tidak lagi valid (misalnya dihapus atau mati)
        if not root or not humanoid or (humanoid and humanoid.Health <= 0) then
            if humanoid and data and data.originalWalkSpeed then
                humanoid.WalkSpeed = data.originalWalkSpeed -- Mengembalikan kecepatan jalan
            end
            HapusEfekHover(character) -- Menghapus efek hover
            pemainDiZona[character] = nil -- Menghapus pemain dari tabel
        end
    end
end
        
-- Menghubungkan fungsi ke event PlayerRemoving (ketika pemain meninggalkan game)
Players.PlayerRemoving:Connect(function(player)
    local character = player.Character
    if character and pemainDiZona[character] then -- Jika karakter ada dan tercatat di zona hover
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and pemainDiZona[character].originalWalkSpeed then
            humanoid.WalkSpeed = pemainDiZona[character].originalWalkSpeed -- Mengembalikan kecepatan jalan
        end
        HapusEfekHover(character) -- Menghapus efek hover
        pemainDiZona[character] = nil -- Menghapus pemain dari tabel
    end
end)

--- local HOVER_FORCE_MAX = math.huge
--- Kekuatan maksimal buat ngangkat pemain ke atas.
--- math.huge = tak terbatas, jadi efek hover-nya bakal selalu aktif walau pemain berat.

--- local HOVER_P_GAIN_BV = 5000
--- Seberapa agresif BodyVelocity mendorong kecepatan target.
--- Nilai besar bikin hover responsif dan 'keras', kayak jetpack.

--- local HOVER_HEIGHT_OFFSET = 100
--- Jarak melayang dari zona ke atas, dalam satuan stud.
--- Kalau zona ada di Y = 0, pemain melayang di Y = 100.

--- local HOVER_P_CONTROLLER_GAIN = 10
--- Seberapa cepat karakter menyesuaikan tinggi ke target hover.
--- Semakin tinggi nilainya, makin cepat dia naik/turun buat nyamain target.

--- local HOVER_VELOCITY_MIN = -10
--- Kecepatan maksimal waktu karakter turun (arah ke bawah).
--- Biar gak jatuh terlalu cepat. Hover tetap terasa pelan dan stabil.

--- local HOVER_VELOCITY_MAX = 25
--- Kecepatan maksimal waktu karakter naik (arah ke atas).
--- Mencegah pemain naik terlalu cepat kayak roket.

--- local SLOW_WALK_SPEED_FACTOR = 0.1
--- Pengurang kecepatan jalan saat melayang.
--- 0.1 artinya cuma 10% dari kecepatan jalan normal. Jadi jalan pelan kayak melayang tenang.
