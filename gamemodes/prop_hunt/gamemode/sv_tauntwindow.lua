-- Validity check to prevent some sort of spam
local function IsTaunting(ply)
    return ply:GetNWFloat("NextCanTaunt", 0) >= CurTime()
end

local function CanWaitHint(ply)
    return (ply.WaitHint or 0) < CurTime()
end

-- this now works because I made these enums init sooner
local TEAM_TAUNT_DIRS = {
    [TEAM_PROPS] = "taunts/props",
    [TEAM_HUNTERS] = "taunts/hunters"
}

net.Receive("CL2SV_PlayThisTaunt", function(len, ply)
    local snd = net.ReadString() or "" -- don't error if client is drunk
    snd = "taunts/" .. snd

    if IsTaunting(ply) then
        if CanWaitHint(ply) then
            ply.WaitHint = math.min(ply:GetNWFloat("NextCanTaunt", 0), CurTime() + 1)
            ply:ChatPrint("[PH: Infinity] - You're still playing a taunt. You can taunt again in " .. math.ceil(ply:GetNWFloat("NextCanTaunt", 0) - CurTime()) .. " seconds.")
        end

        return
    end

    if not file.Exists("sound/" .. snd, "GAME") then
        ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (doesn't exist???)")

        return
    end

    local teamdir = TEAM_TAUNT_DIRS[ply:Team()] or "NONE"

    if not string.StartWith(snd, teamdir) then
        ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (it doesn't belong to your team!)")

        return
    end

    if not ply:Alive() then
        ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (ur dead, lol)")

        return
    end

    ply:EmitSound(snd, 100)
    local duration = NewSoundDuration("sound/" .. snd)
    local score = math.pow(duration, 1.2)
    local decimal = score % 1
    score = math.floor(score) + (math.random() < decimal and 1 or 0)

    if ply:Team() == TEAM_PROPS and GAMEMODE:IsRoundPlaying() then
        ply:PS2_AddStandardPoints(score, "Taunting")
    end

    ply:SetNWFloat("NextCanTaunt", CurTime() + duration)
end)