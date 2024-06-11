fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
games { 'gta5' }

name 'lite-core'
version '1.0.0'
description 'A sudo core using KVPs for data storage used for script prototyping'
author 'i_Zolox'

files {
    'classes/*.lua',
    'data/*.lua',
    'data/*.json',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared.lua',
    'settings.lua'
}

client_scripts {
    'client/utility.lua',
    'client/main.lua',
    'client/clothing.lua',
    'client/parser.lua',
    'client/garage.lua',
    'client/commands.lua',
}

server_scripts {
    'server/main.lua',
    'server/garage.lua',
    'server/commands.lua',
}
