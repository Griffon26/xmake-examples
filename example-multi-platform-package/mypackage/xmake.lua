set_defaultplat('windows')
set_defaultarchs('windows|x64', 'mingw|x86_64')

target('otherlib')
    set_kind('static')
    add_files('library.cpp')

target("mylib")
    set_kind("static")
    add_headerfiles('library.h')
    add_files("library.cpp")
