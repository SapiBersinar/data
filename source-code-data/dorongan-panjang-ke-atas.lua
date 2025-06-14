local zona = script.Parent -- Mendapatkan 
referensi ke Part yang akan berfungsi sebagai 
zona hover local pemainDiZona = {} -- Tabel 
untuk melacak pemain yang sedang di dalam zona 
hover local Players = 
game:GetService("Players") -- Mendapatkan 
layanan Players local RunService = 
game:GetService("RunService") -- Mendapatkan 
layanan RunService untuk update game loop -- 
Inisialisasi properti part zona 
zona.CanCollide = false -- Pemain bisa 
melewati zona ini tanpa bertabrakan 
zona.CanTouch = true -- Mengizinkan event 
Touched untuk mendeteksi pemain masuk 
zona.Anchored = true -- Memastikan zona tidak 
bergerak atau jatuh -- Parameter Hover local 
HOVER_FORCE_MAX = math.huge -- Kekuatan 
maksimum yang bisa diterapkan oleh 
BodyVelocity. math.huge berarti kekuatan tidak 
terbatas, memastikan hover selalu bisa 
terjadi. local HOVER_P_GAIN_BV = 5000 -- Gain 
'P' (Proportional) untuk BodyVelocity. Semakin 
tinggi nilainya, semakin kuat BodyVelocity 
mencoba mencapai kecepatan targetnya, membuat 
hover lebih responsif. local 
HOVER_HEIGHT_OFFSET = 100 -- Jarak vertikal 
(dalam stud) di atas posisi Y zona di mana 
pemain akan melayang. Jadi, jika zona berada 
di Y=0, pemain akan hover di Y=100. local 
HOVER_P_CONTROLLER_GAIN = 10 -- Gain 'P' untuk 
kontroler hover kustom. Ini menentukan 
seberapa cepat kecepatan vertikal pemain 
menyesuaikan diri dengan perbedaan antara 
ketinggian saat ini dan ketinggian target. 
Nilai lebih tinggi membuat penyesuaian lebih 
cepat. local HOVER_VELOCITY_MIN = -10 -- 
Kecepatan vertikal minimum (ke bawah) yang 
diizinkan untuk hover. Mencegah pemain jatuh 
terlalu cepat. local HOVER_VELOCITY_MAX = 25 
-- Kecepatan vertikal maksimum (ke atas) yang 
diizinkan untuk hover. Mencegah pemain naik 
terlalu cepat. local SLOW_WALK_SPEED_FACTOR = 
0.1 -- Faktor pengali untuk kecepatan berjalan 
pemain saat mereka melayang. 0.1 berarti 
kecepatan berjalan akan menjadi 10% dari 
kecepatan aslinya. -- Fungsi untuk menghapus 
efek hover dari karakter function 
HapusEfekHover(character)
    local root = 
    character:FindFirstChild("HumanoidRootPart") 
    -- Mendapatkan HumanoidRootPart karakter 
    if root then
        local efekHover = 
        root:FindFirstChild("EfekHover") -- 
        Mencari BodyVelocity bernama 
        "EfekHover" if efekHover then
            efekHover:Destroy() -- 
            Menghancurkan BodyVelocity untuk 
            menghentikan efek hover
        end end end
 
-- Fungsi untuk menerapkan efek hover (angin) 
pada karakter function HoverAngin(character)
    local root = 
    character:FindFirstChild("HumanoidRootPart") 
    -- Mendapatkan HumanoidRootPart local 
    humanoid = 
    character:FindFirstChildOfClass("Humanoid") 
    -- Mendapatkan Humanoid
    
    -- Memastikan HumanoidRootPart dan 
    Humanoid ada, pemain masih hidup, dan 
    belum ada efek hover if root and humanoid 
    and humanoid.Health > 0 and not 
    root:FindFirstChild("EfekHover") then
        local bv = 
        Instance.new("BodyVelocity") -- 
        Membuat BodyVelocity baru bv.Name = 
        "EfekHover" -- Memberi nama 
        BodyVelocity agar mudah dicari dan 
        dihapus bv.MaxForce = Vector3.new(0, 
        HOVER_FORCE_MAX, 0) -- Mengatur 
        kekuatan maksimum (hanya pada sumbu Y) 
        bv.P = HOVER_P_GAIN_BV -- Mengatur 
        gain 'P' untuk BodyVelocity bv.Parent 
        = root -- Menempatkan BodyVelocity di 
        dalam HumanoidRootPart
        
        local targetHoverY = zona.Position.Y + 
        HOVER_HEIGHT_OFFSET -- Menghitung 
        ketinggian target hover local 
        hoverConnection -- Variabel untuk 
        koneksi event Stepped
        
        -- Menyimpan data pemain (kecepatan 
        jalan asli dan BodyVelocity) 
        pemainDiZona[character] = {
            originalWalkSpeed = 
            humanoid.WalkSpeed, hoverEffect = 
            bv
        }
        humanoid.WalkSpeed = 
        humanoid.WalkSpeed * 
        SLOW_WALK_SPEED_FACTOR -- Mengurangi 
        kecepatan jalan pemain
        
        -- Menghubungkan fungsi ke event 
        Stepped (berjalan setiap frame fisika) 
        hoverConnection = 
        RunService.Stepped:Connect(function()
            -- Memeriksa apakah efek hover 
            masih valid (BodyVelocity, 
            RootPart, Humanoid ada dan pemain 
            hidup) if not bv.Parent or not 
            root.Parent or not humanoid or 
            (humanoid and humanoid.Health <= 
            0) then
                if hoverConnection then 
                hoverConnection:Disconnect() 
                end -- Memutuskan koneksi jika 
                tidak valid if 
                pemainDiZona[character] then
                    local currentHumanoid = 
                    character:FindFirstChildOfClass("Humanoid") 
                    if currentHumanoid and 
                    pemainDiZona[character].originalWalkSpeed 
                    then
                        currentHumanoid.WalkSpeed 
                        = 
                        pemainDiZona[character].originalWalkSpeed 
                        -- Mengembalikan 
                        kecepatan jalan
                    end 
                    HapusEfekHover(character) 
                    -- Menghapus efek hover 
                    pemainDiZona[character] = 
                    nil -- Menghapus pemain 
                    dari tabel
                end return -- Keluar dari 
                fungsi
            end
                
            local errorY = targetHoverY - 
            root.Position.Y -- Menghitung 
            selisih antara ketinggian target 
            dan ketinggian saat ini local 
            desiredVelocityY = errorY * 
            HOVER_P_CONTROLLER_GAIN -- 
            Menghitung kecepatan vertikal yang 
            diinginkan berdasarkan error 
            desiredVelocityY = 
            math.clamp(desiredVelocityY, 
            HOVER_VELOCITY_MIN, 
            HOVER_VELOCITY_MAX) -- Membatasi 
            kecepatan vertikal dalam rentang 
            min/max bv.Velocity = 
            Vector3.new(0, desiredVelocityY, 
            0) -- Mengatur kecepatan 
            BodyVelocity (hanya pada sumbu Y)
        end)
            
        -- Menghubungkan fungsi ke event 
        Humanoid.Died (ketika pemain mati) 
        humanoid.Died:Connect(function()
            if hoverConnection then 
            hoverConnection:Disconnect() end 
            -- Memutuskan koneksi if 
            pemainDiZona[character] then
                local currentHumanoid = 
                character:FindFirstChildOfClass("Humanoid") 
                if currentHumanoid and 
                pemainDiZona[character].originalWalkSpeed 
                then
                    currentHumanoid.WalkSpeed 
                    = 
                    pemainDiZona[character].originalWalkSpeed 
                    -- Mengembalikan kecepatan 
                    jalan
                end HapusEfekHover(character) 
                -- Menghapus efek hover 
                pemainDiZona[character] = nil 
                -- Menghapus pemain dari tabel
            end end) end end
        
-- Menghubungkan fungsi ke event Touched zona 
(ketika sesuatu menyentuh zona) 
zona.Touched:Connect(function(hit)
    local character = hit.Parent -- 
    Mendapatkan parent dari bagian yang 
    menyentuh (biasanya karakter) local 
    humanoid = 
    character:FindFirstChildOfClass("Humanoid") 
    -- Mendapatkan Humanoid dari karakter
        
    -- Jika yang menyentuh adalah karakter 
    yang hidup dan belum di zona hover if 
    humanoid and humanoid.Health > 0 then
        if not pemainDiZona[character] then 
            HoverAngin(character) -- 
            Menerapkan efek hover
        end end end)
        
-- Loop utama untuk memeriksa pemain yang 
keluar dari zona secara berkala while true do
    task.wait(0.1) -- Menunggu sebentar agar 
    tidak terlalu membebani CPU for character, 
    data in pairs(pemainDiZona) do -- Iterasi 
    melalui semua pemain yang tercatat di zona
        local root = 
        character:FindFirstChild("HumanoidRootPart") 
        local humanoid = 
        character:FindFirstChildOfClass("Humanoid")
            
        -- Jika karakter tidak lagi valid 
        (misalnya dihapus atau mati) if not 
        root or not humanoid or (humanoid and 
        humanoid.Health <= 0) then
            if humanoid and data and 
            data.originalWalkSpeed then
                humanoid.WalkSpeed = 
                data.originalWalkSpeed -- 
                Mengembalikan kecepatan jalan
            end HapusEfekHover(character) -- 
            Menghapus efek hover 
            pemainDiZona[character] = nil -- 
            Menghapus pemain dari tabel
        else local stillInZone = false -- 
            Memeriksa apakah HumanoidRootPart 
            karakter masih menyentuh zona for 
            _, partInZone in 
            ipairs(zona:GetTouchingParts()) do
                if partInZone.Parent == 
                character and partInZone.Name 
                == "HumanoidRootPart" then -- 
                Periksa hanya HumanoidRootPart
                    stillInZone = true break 
                end
            end
                
            -- Jika pemain tidak lagi 
            menyentuh zona if not stillInZone 
            then
                if humanoid and data and 
                data.originalWalkSpeed then
                    humanoid.WalkSpeed = 
                    data.originalWalkSpeed -- 
                    Mengembalikan kecepatan 
                    jalan
                end HapusEfekHover(character) 
                -- Menghapus efek hover 
                pemainDiZona[character] = nil 
                -- Menghapus pemain dari tabel
            end end end end
        
-- Menghubungkan fungsi ke event 
PlayerRemoving (ketika pemain meninggalkan 
game) 
Players.PlayerRemoving:Connect(function(player)
    local character = player.Character if 
    character and pemainDiZona[character] then 
    -- Jika karakter ada dan tercatat di zona 
    hover
        local humanoid = 
        character:FindFirstChildOfClass("Humanoid") 
        if humanoid and 
        pemainDiZona[character].originalWalkSpeed 
        then
            humanoid.WalkSpeed = 
            pemainDiZona[character].originalWalkSpeed 
            -- Mengembalikan kecepatan jalan
        end HapusEfekHover(character) -- 
        Menghapus efek hover 
        pemainDiZona[character] = nil -- 
        Menghapus pemain dari tabel
    end end) -- PENJELASAN VARIABEL HOVER: -- 
======================================= -- 
HOVER_FORCE_MAX = math.huge -- Ini adalah 
kekuatan maksimum yang dapat diterapkan oleh 
"BodyVelocity" pada pemain. -- Nilai 
`math.huge` (tak terhingga) berarti tidak ada 
batasan kekuatan, sehingga -- pemain dapat 
selalu mencapai kecepatan yang diinginkan 
untuk melayang. Ini memastikan -- efek hover 
selalu bisa terjadi tanpa terhalang batasan 
kekuatan. -- HOVER_P_GAIN_BV = 5000 -- Ini 
adalah 'P' (Proportional) Gain untuk 
"BodyVelocity" itu sendiri. -- Dalam kontrol 
fisika, nilai ini menentukan seberapa agresif 
"BodyVelocity" -- mencoba mencapai kecepatan 
yang telah kita tetapkan (melalui 
`bv.Velocity`). -- Semakin tinggi nilai ini, 
semakin "kaku" atau responsif gerakan 
melayang. -- Jika terlalu rendah, pemain bisa 
jadi tidak stabil saat melayang atau melambat. 
-- HOVER_HEIGHT_OFFSET = 100 -- Ini adalah 
ketinggian di mana pemain akan melayang 
relatif terhadap -- posisi sumbu Y dari `zona` 
(part tempat script ini berada). -- Misalnya, 
jika `zona` Anda berada di Y=0, pemain akan 
melayang di Y=100. -- Jika `zona` berada di 
Y=50, pemain akan melayang di Y=150. -- Anda 
bisa mengubah nilai ini untuk menyesuaikan 
ketinggian hover. -- HOVER_P_CONTROLLER_GAIN = 
10 -- Ini adalah 'P' (Proportional) Gain untuk 
"kontroler" hover kita sendiri, -- bukan untuk 
"BodyVelocity" secara langsung. -- Variabel 
ini digunakan untuk menghitung 
`desiredVelocityY` (kecepatan vertikal -- yang 
diinginkan) berdasarkan seberapa jauh pemain 
menyimpang dari -- ketinggian target 
(`errorY`). -- Semakin tinggi nilainya, 
semakin cepat pemain akan bergerak naik atau 
turun -- untuk kembali ke ketinggian 
targetnya. Ini mempengaruhi seberapa "cepat" 
-- pemain merespons perubahan ketinggian saat 
melayang. -- HOVER_VELOCITY_MIN = -10 -- Ini 
adalah batas kecepatan vertikal minimum (ke 
bawah) yang bisa diterapkan -- oleh kontroler 
hover. Ini mencegah pemain jatuh terlalu cepat 
-- saat mereka melayang. Jika pemain mulai 
melambat, kontroler -- akan memastikan mereka 
tidak turun lebih cepat dari nilai ini. -- 
HOVER_VELOCITY_MAX = 25 -- Ini adalah batas 
kecepatan vertikal maksimum (ke atas) yang 
bisa diterapkan -- oleh kontroler hover. Ini 
mencegah pemain naik terlalu cepat -- saat 
mereka melayang. Kontroler akan memastikan 
pemain tidak naik -- lebih cepat dari nilai 
ini. -- SLOW_WALK_SPEED_FACTOR = 0.1 -- Ini 
adalah faktor pengali untuk `WalkSpeed` 
(kecepatan berjalan) pemain -- saat mereka 
berada dalam efek hover. -- Nilai 0.1 berarti 
kecepatan berjalan pemain akan dikurangi 
menjadi 10% -- dari kecepatan aslinya. Ini 
biasanya digunakan untuk membuat -- gerakan 
saat melayang terasa lebih lambat atau 
terkontrol.
