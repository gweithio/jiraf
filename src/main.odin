package main

import "core:fmt"
import "core:os"
import "core:strings"
import "shared:jiraf"
import "core:encoding/json"
import "core:c/libc"
import "core:mem"

// Parse values from the args into key, val pairs
get_value_after_slash :: proc(v: string) -> (key, val: string) {
	index := strings.index(v, ":")

	if index != -1 {
		key = v[:index]
		val = v[index + 1:]
	} else {
		// No ':' found, return a key with an empty value
		key = v
	}

	// Strip leading dashes from key
	for r, i in key {
		if r != '-' {
			key = key[i:]
			break
		}
	}
	return
}

// loop through the args and append them to our map
parse_args :: proc(args: []string) -> (res: map[string]string) {
	for arg in args {
		key, val := get_value_after_slash(arg)
		res[key] = val
	}

	return res
}

// run the project by calling odin run
run_project :: proc(project: Project_Data, args: []string) {
	// Don't really need the command_builder

	arg_string := ""
	for arg in args {
		arg_string = strings.concatenate([]string{arg, " "}, context.temp_allocator)
	}

	run_command := fmt.tprintf(
		"odin run src/main.odin -file -out:%s %s -collection:shared=src -collection:pkg=pkg",
		strings.to_lower(project.name),
		arg_string,
	)

	fmt.println("Running ", project.name, "...")
	cmd := strings.clone_to_cstring(run_command, context.temp_allocator)
	libc.system(cmd)
}

// build the project by calling odin build
build_project :: proc(project: Project_Data, args: []string) {

	arg_string := ""
	for arg in args {
		arg_string = strings.concatenate([]string{arg, " "}, context.temp_allocator)
	}

	// Don't really need the command_builder
	build_command := fmt.tprintf(
		"odin build src -out:%s %s -collection:shared=src -collection:pkg=pkg",
		strings.to_lower(project.name),
		arg_string,
	)

	fmt.println("Building", project.name, "...")
	cmd := strings.clone_to_cstring(build_command, context.temp_allocator)
	libc.system(cmd)
}

// Run tests by calling odin test
run_tests :: proc(project: Project_Data, args: []string) {

	arg_string := ""
	for arg, i in args {
		arg_string = strings.concatenate([]string{arg, " "}, context.temp_allocator)
	}

	test_command := fmt.tprintf(
		"odin test tests %s -collection:shared=src -collection:pkg=pkg",
		arg_string,
	)

	fmt.println("Running Tests...")
	cmd := strings.clone_to_cstring(test_command)
	libc.system(cmd)
}

get_dep :: proc(project: Project_Data, url: string) {
	if url == "" {
		fmt.eprintln("please provide a github url")
		return
	}

	curr_dir := os.get_current_directory()
	defer delete(curr_dir)

	pkg_dir := fmt.tprintf("%s/pkg", curr_dir)

	err := os.set_current_directory(pkg_dir)


	if err != os.ERROR_NONE {
		fmt.eprintln("Failed to swap to pkg directory")
		return
	}

	get_command := fmt.tprintf("git clone %s", url)

	cmd := strings.clone_to_cstring(get_command, context.temp_allocator)
	fmt.println(cmd)
	libc.system(cmd)
}

// Check if the given parameter is a command
is_a_command :: proc(cmd: string) -> (ok: bool) {
	if cmd == "run" || cmd == "test" || cmd == "build" || cmd == "get" || cmd == "version" {
		ok = true
		return
	}
	ok = true
	return
}

// Possible project types
Project_Type :: enum {
	Exe,
	Lib,
}

// Get the project.json and stuff it into a map[string]string
Project_Data :: struct {
	name, author, version: string,
	type:                  Project_Type,
}

get_project_from_json :: proc() -> (Project_Data, bool) {
	content, ok := os.read_entire_file("project.json", context.temp_allocator)

	parsed, err := json.parse(
		content,
		json.DEFAULT_SPECIFICATION,
		false,
		context.temp_allocator,
	)

	if err != json.Error.None {
		return {}, false
	}

	json_data := parsed.(json.Object)

	name, type, author, version: string
	name = json_data["name"].(json.String)
	type = json_data["type"].(json.String)
	author = json_data["author"].(json.String)
	version = json_data["version"].(json.String)


	ty: Project_Type
	switch type {
	case "exe":
		ty = .Exe
	case "lib":
		ty = .Lib
	case:
		return {}, false
	}

	return {name = name, type = ty, author = author, version = version}, true
}

print_help :: proc() {

	fmt.println()
	fmt.println(`usage: jiraf new -name:"project name" -type:exe`)

	fmt.print(`
    -name:"project name" - [required] The name of the package
    `)
	fmt.print(`
    -type:exe - [required] The project type, exe or lib
    `)

	fmt.print(`
    -author:"author name" - [optional] The author of the project
    `)
	fmt.println(`
    -version:"0.1" - [optional] The initial project version
    `)
}

create_project :: proc(args: []string) -> (ok: bool) {
	parsed_map := parse_args(args)
	defer delete(parsed_map)

	if parsed_map["name"] == "" && !is_a_command(args[0]) {
		fmt.eprintln(`Provide a name for your project, like -name:"My Cool Project"`)
		fmt.eprintln(`Provide a type for your project, like -type:exe or -type:lib`)
		return false
	}

	// strip whitespace from the name
	new_name, _ := strings.replace_all(parsed_map["name"], " ", "_")

	// create our project
	new_project, res := jiraf.project_create(
		name = new_name,
		type = parsed_map["type"],
		author = parsed_map["author"],
		version = parsed_map["version"],
		description = parsed_map["desc"],
		dependencies = map[string]string{},
	)
	ok = res

	if ok {
		fmt.printf("%s has been created\n", new_name)
		return
	} else {
		fmt.eprintf("Failed to create project %s\n", new_name)
		return
	}
}

_main :: proc() {

	args := os.args[1:]

	if len(args) == 0 {
		print_help()
		return
	}

	if args[0] == "new" {
		ok := create_project(args)
		if !ok {
			fmt.println("Failed to create project")
			return
		}
	}

	if len(args) >= 0 && is_a_command(args[0]) {
		project_json, ok := get_project_from_json()
		if !ok do return

		args_for_command := []string{}

		if (len(args) >= 2) {
			args_for_command = args[2:]
		}

		switch (args[0]) {
		case "version":
			fmt.println(project_json.version)
		case "run":
			run_project(project_json, args[1:])
			return
		case "build":
			build_project(project_json, args[1:])
			return
		case "test":
			run_tests(project_json, args[1:])
			return
		case "get":
			if len(args) < 2 {
				fmt.eprintln("Please provide a Github Url")
				return
			}
			get_dep(project_json, args[1])
			return
		}
	} else if args[0] == "-help" || args[0] == "-h" || args[0] == "help" {
		print_help()
		return
	} else {
		return
	}
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}
