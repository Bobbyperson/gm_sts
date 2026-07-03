mainTrack = mainTrack or nil
mainTrackSound = 1
GlobalSoundCache = GlobalSoundCache or {}
function playGlobalSound(FileName, teamID, cleanupTime)
    local sound
    local filter
    teamID = teamID or -1
    cleanupTime = cleanupTime or 0
    if SERVER then
        filter = RecipientFilter()
        if teamID == -1 then
            filter:AddAllPlayers()
        else
            filter:AddRecipientsByTeam(teamID)
        end
    end

    if SERVER or not GlobalSoundCache[FileName] then
        sound = CreateSound(game.GetWorld(), FileName, filter)
        if sound then
            sound:SetSoundLevel(0) -- play everywhere
            GlobalSoundCache[FileName] = {
                sound = sound,
                filter = filter
            }
        end
    else
        sound = GlobalSoundCache[FileName].sound
        filter = GlobalSoundCache[FileName].filter
    end

    if cleanupTime > 0 then timer.Simple(cleanupTime, function() GlobalSoundCache[FileName] = nil end) end
    if sound then
        if CLIENT then sound:Stop() end
        sound:Play()
    end
    return sound
end

function beginPlayingMainTrack()
    -- Only create a new mainTrack if it does not already exist
    if not mainTrack then
        mainTrack = playGlobalSound("sts_music/miami_sky_hq.wav")
        if mainTrackSound == 0 then mainTrack:ChangeVolume(0, 0) end
        -- Setting up the timer to restart the sound track
        timer.Create("RepeatTrack", 103, 0, function()
            mainTrack:Stop() -- Stop the current track
            mainTrack:Play() -- Play the track again
            if mainTrackSound == 0 then mainTrack:ChangeVolume(0, 0) end
        end)
    end
end

function muteMainTrack()
    mainTrackSound = 0
    if mainTrack then mainTrack:ChangeVolume(0, 2) end
end

function unmuteMainTrack()
    mainTrackSound = 1
    if mainTrack then mainTrack:ChangeVolume(1, 2) end
end
