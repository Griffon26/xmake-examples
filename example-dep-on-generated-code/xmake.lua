-- This rule adds a dependency on a target that generates code in case the include dirs of a target
-- contain the generator output directory
rule("dynamic_dep_injector")
    on_load(function (target)
        print(">> rule dynamic_dep_injector:on_load target=" .. target:name())

        local found_path = false

        local includes = target:get("includedirs")
        if includes then
            for _, include_info in pairs(includes) do
                interfacename = string.match(include_info, "build/gen%-output/(%w+)")
                if interfacename then
                    print(">> Found ifacegenerator include path. Injecting dependency: " .. interfacename)
                    target:add("deps", interfacename)
                    break
                end
            end
        else
            print(">> no ifacegenerator includes found")
        end
    end)

-- This is the generic behavior for a code generation target.
-- With this rule a code generation target only needs to specify the input.
rule("ifacegenerator")
    set_extensions(".iface")

    on_load(function(target)
      print(">> rule ifacegenerator:on_load target=" .. target:name())
      target:set("targetdir", "build/gen-output/" .. target:name())
      target:set('policy', 'build.fence', true)
    end)

    on_build_file(function (target, sourcefile, opt)
        print(">> rule ifacegenerator:on_build_file sourcefile=" .. sourcefile)
        import("core.project.depend")
        import("utils.progress")

        os.mkdir(target:targetdir())

        local targetfile = path.join(target:targetdir(), path.basename(sourcefile) .. "_types.h")

        depend.on_changed(function ()
            print(">> starting ifacegenerator " .. sourcefile .. " -> " .. targetfile)

            -- Make this generation extremely slow to look for build order problems
            for i=1,3 do
                print("  still generating  " .. targetfile .. " (" .. i .. ")")
                os.sleep(1000)
            end

            -- Just as a test copy the input file to the output file.
            -- The input file has some structure definition in C++ in it.
            os.vrunv('cp', {sourcefile, targetfile})
            progress.show(opt.progress, "${color.build.object}ifacegenerator %s", sourcefile)

            -- Make this generation extremely slow to look for build order problems
            for i=4,6 do
                print("  still generating  " .. targetfile .. " (" .. i .. ")")
                os.sleep(1000)
            end

            print(">> stopping ifacegenerator " .. sourcefile .. " -> " .. targetfile)
        end, {files = sourcefile})
    end)

-- This is a code generation target that generates a header file out of an interface description,
-- in this case the someinterface.iface description.
target("someinterface")
    set_kind("object")
		add_rules("ifacegenerator")
    add_files(
      "gen-input/someinterface.iface",
      "gen-input/dummy.cpp"
    )

-- This is the first target that depends on the generated interface header file
target("main1")
    set_kind("binary")
    add_files("main1.cpp")
    add_includedirs("build/gen-output/someinterface") 

    add_rules("dynamic_dep_injector") 

-- This is the second target that depends on the generated interface header file
target("main2")
    set_kind("binary")
    add_files("main2.cpp")
    add_includedirs("build/gen-output/someinterface") 

    add_rules("dynamic_dep_injector") 

-- This target builds both previous targets
target("all")
    set_kind("phony")
    add_deps("main1", "main2")

