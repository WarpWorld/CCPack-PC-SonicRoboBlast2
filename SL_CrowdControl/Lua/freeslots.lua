freeslot("sfx_qteok", "sfx_qtebad", "sfx_qteyes")

sfxinfo[sfx_qteok] = {
        singular = true,
        priority = 128,
        flags = 0
}
sfxinfo[sfx_qteok].caption = "QTE Success"

sfxinfo[sfx_qtebad] = {
        singular = false,
        priority = 64,
        flags = 0
}
sfxinfo[sfx_qtebad].caption = "QTE Failure"

sfxinfo[sfx_qteyes] = {
        singular = false,
        priority = 64,
        flags = 0
}
sfxinfo[sfx_qteyes].caption = "QTE Correct"