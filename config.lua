Config = {}

-- Framework job checker.
-- Options: 'auto', 'esx', 'qb', 'qbox', 'ox', 'standalone'
-- standalone ignores jobs unless you edit HasAllowedJob() in client/main.lua.
Config.Framework = 'auto'

-- Set to false or {} to allow everyone.
-- You can add as many jobs as you want.
Config.AllowedJobs = {
    police = true,
    sheriff = true,
    state = true,
    mechanic = true
}

Config.Target = {
    label = 'Measure suspension',
    icon = 'fa-solid fa-ruler-vertical',
    distance = 2.5
}

Config.Measure = {
    duration = 6500,
    legalDifferenceInches = 4.0,

    -- Difference mode:
    -- 'absolute' = any front/rear difference over limit is illegal.
    -- 'squat_only' = only illegal when the rear is lower than the front by over the limit.
    differenceMode = 'absolute',

    -- GTA uses meters. 1 meter = 39.3701 inches.
    metersToInches = 39.3701,

    -- Adds a small visual offset because wheel bone Z is usually hub/axle height, not ground-to-fender height.
    -- Keep this 0.0 if you only care about comparing front vs rear.
    displayOffsetInches = 0.0
}

Config.Notify = {
    title = 'Squat Checker',
    warningMessage = 'WARNING: Illigial squat (exceeds 4inch difference)', -- User requested exact wording.
    legalMessage = 'Suspension checked: vehicle is within legal stance limit.',
    duration = 6500,
    playSound = true,
    showLegalResult = true,
    showMeasurements = true
}

Config.Debug = false
