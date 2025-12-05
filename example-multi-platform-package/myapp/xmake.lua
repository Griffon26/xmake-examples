set_defaultplat('windows')
set_defaultarchs('windows|x64', 'mingw|x86_64')

add_repositories("myrepo ../mypackage/build")
add_requires("mylib")

target("app-windows")
    set_plat("windows")
    set_kind("binary")
    add_ldflags('/SUBSYSTEM:CONSOLE')
    add_files("app.cpp")
    add_packages("mylib")
    
--[[
target("app-mingw")
    set_plat("mingw")
    set_kind("binary")
    add_files("app.cpp")
    add_packages("mypackage")
--]]

