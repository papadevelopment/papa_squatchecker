fx_version 'cerulean'
game 'gta5'

name 'papa_squatchecker'
author 'Lowkeypapa'
description 'Measure front/rear vehicle suspension stance with ox_target, ox_lib, and okokNotify.'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target'
}
