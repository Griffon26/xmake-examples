set_defaultplat('windows')
set_defaultarchs('windows|x64', 'mingw|x86_64')

after_load(function (target)
    import('core.project.project')

    print('----------------------------------')
    print('after_load for target', target:name(), '(plat='..(target:get('plat') or 'nil')..')')
    
    local function iterate_deps_recursive(parent, child, visited, func)
        visited = visited or {}
        if visited[child:name()] then
            return
        end
        visited[child:name()] = true

        if parent == nil or func(parent, child) then
            for depname, _ in pairs(child:deps()) do
                local dep = project.target(depname)
                if dep then
                    iterate_deps_recursive(child, dep, visited, func)
                end
            end
        else
            print('abort iteration')
        end
    end
    
    if target:get('plat') then
        iterate_deps_recursive(nil, target, nil, function(parent, child)
            print('Visiting dependency', child:name(), '(plat='..(child:get('plat') or 'nil')..')')
            if child:get('plat') then
                return false
            else
                local continue_recursion = false
                local dep_replacement_name = child:name()..'_'..parent:plat()
                
                replacement_dep = project.target(dep_replacement_name)
                if replacement_dep then
                    print('replacement target', dep_replacement_name, 'already exists, so not making it again')
                    continue_recursion = false
                else               
                    print('cloning target', child:name(), 'to', dep_replacement_name)
                    replacement_dep = child:clone()
                    replacement_dep:name_set(dep_replacement_name)
                    replacement_dep:set('plat', parent:plat())
                    project.target_add(replacement_dep)
                    continue_recursion = true
                end
                    
                local new_deps = {}
                for dep_name, dep in pairs(parent:deps()) do
                    if dep_name == child:name() then
                        print('replacing', child:name(), 'with', replacement_dep:name())
                        new_deps[replacement_dep:name()] = replacement_dep
                    else
                        print('copying dep', dep_name)
                        new_deps[dep_name] = dep
                    end
                end
                -- yikes. I guess this is why when building app-mingw it still builds mylib.lib and not mylib_mingw.lib
                parent._DEPS = new_deps
                
                return continue_recursion
            end
        end)
    else
        print('stopping iteration because this target has no platform')
    end
end)

target('mylib')
    set_kind('static')
    add_headerfiles('library.h')
    add_files('library.cpp')

target('app-windows')
    set_plat('windows')
    set_kind('binary')
    add_ldflags('/SUBSYSTEM:CONSOLE')
    add_files('app.cpp')
    add_deps('mylib')

target('app-windows2')
    set_plat('windows')
    set_kind('binary')
    add_ldflags('/SUBSYSTEM:CONSOLE')
    add_files('app.cpp')
    add_deps('mylib')
    
target('app-mingw')
    set_plat('mingw')
    set_kind('binary')
    add_files('app.cpp')
    add_deps('mylib')

    before_build(function(target)
        import('core.project.project')

        print('before_build, printing overview of targets and deps:')
        for name, target in pairs(project.targets()) do
            print('-----------------------------------')
            print('target', name, '(plat='..(target:get('plat') or 'nil')..')')
            for dep, _ in pairs(target:deps()) do
                print('  depends on', dep)
            end
        end
        print('-----------------------------------')
    end)
    


