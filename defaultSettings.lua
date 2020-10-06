return({
    Aimkey = {
        EnumType = "UserInputType",
        Name = "MouseButton2"
    },
    FOV = 45,
    TeamCheck = true,
    WallCheck = true,
    Triggerbot = false,
    Triggerdelay = 0,
    DelayVariation = 0,
    Hitscan = true,
    Sensitivity = 3,
    AlwaysOn = false,
    IgnoreTransparency = false,
    AutoStop = false,
    CPS = 0,
    Overshoot = 0,
    ForceFieldCheck = true
}, 

{
    Aimkey = "The keybind you hold down to aim.",
    FOV = "Degrees from your cursor in which targets will be accounted for.",
    TeamCheck = "Prevents aiming at teammates, disable for FFA gamemodes.",
    WallCheck = "Prevents aiming at targets through walls.",
    Triggerbot = "Clicks the left mouse button when your cursor is overtop of the target.",
    Triggerdelay = "Amount of time (in ms) to wait before triggerbot clicks.",
    DelayVariation = "Varies triggerdelay using this number roughly every second.",
    Hitscan = "If on, it will check if other body parts of the target are visible.",
    Sensitivity = "Counterintuitive but, this actually slows down the aimbot, use higher settings if you're being flung around by the aimbot.",
    AlwaysOn = "If on, it will always be looking for and aiming at targets.",
    IgnoreTransparency = "If on, when the wallcheck function is ran, it will ignore semi-transparent objects.",
    AutoStop = "Mainly for CB:RO, when a target is acquired it will reset your velocity to (0,0,0) every frame it still has the target.",
    CPS = "How fast the triggerbot is allowed to click, if left at 0 then it will click as fast as possible.",
    Overshoot = "Amount of time (in ms) to aim infront of the target.",
    ForceFieldCheck = "If on, targets that have a forcefield will be ignored."
})
