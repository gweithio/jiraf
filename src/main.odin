package main

import "core:fmt"
import "core:os"
import "core:strings"
import "shared:jiraf"
import "core:encoding/json"
import "core:c/libc"

import "pkg:args_parser/args_parser"

// run the project by calling odin run
run_project :: proc(project: Project_Data, args: []string) {
	// Don't really need the command_builder

	arg_string := ""
	for arg in args {
		arg_string = strings.concatenate([]string{arg, " "})
	}

	shared_location := "src"
	if project.type == Project_Type.Lib {
		shared_location = "."
	}

	run_command := fmt.tprintf(
		"odin run src/main.odin -file -out:%s %s -collection:shared=%s -collection:pkg=pkg",
		strings.to_lower(project.name, context.temp_allocator),
		arg_string,
		shared_location,
	)

	fmt.println(strings.concatenate([]string{"Running ", project.name, "..."}))
	cmd := strings.clone_to_cstring(run_command, context.temp_allocator)
	libc.system(cmd)
}

// build the project by calling odin build
build_project :: proc(project: Project_Data, args: []string) {

	arg_string := ""
	for arg in args {
		arg_string = strings.concatenate([]string{arg, " "}, context.temp_allocator)
	}

	shared_location := "src"
	if project.type == Project_Type.Lib {
		shared_location = "."
	}

	// Don't really need the command_builder
	build_command := fmt.tprintf(
		"odin build src -out:%s %s -collection:shared=%s -collection:pkg=pkg",
		strings.to_lower(project.name, context.temp_allocator),
		arg_string,
		shared_location,
	)

	fmt.println("Building", project.name, "...")
	cmd := strings.clone_to_cstring(build_command, context.temp_allocator)
	libc.system(cmd)
}

// Run tests by calling odin test
run_tests :: proc(project: Project_Data, args: []string) {

	arg_string := ""
	for arg, i in args {
		arg_string = strings.concatenate([]string{arg, " "})
	}

	shared_location := "src"
	if project.type == Project_Type.Lib {
		shared_location = "."
	}

	test_command := fmt.tprintf(
		"odin test tests %s -collection:shared=%s -collection:pkg=pkg",
		arg_string,
		shared_location,
	)

	fmt.println("Running Tests...")
	cmd := strings.clone_to_cstring(test_command, context.temp_allocator)
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
	libc.system(cmd)
}

// Check if the given parameter is a command
is_a_command :: proc(cmd: string) -> bool {
	if cmd == "run" || cmd == "test" || cmd == "build" || cmd == "get" || cmd == "version" {
		return true
	}
	return false
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

get_project_from_json :: proc() -> (data: Project_Data, ok: bool) {
	content := os.read_entire_file("project.json", context.temp_allocator) or_return

	parsed, _ := json.parse(
		content,
		json.DEFAULT_SPECIFICATION,
		false,
		context.temp_allocator,
	)

	json_data := parsed.(json.Object) or_return

	name, type, author, version: string
	name = json_data["name"].(json.String) or_return
	type = json_data["type"].(json.String) or_return
	author = json_data["author"].(json.String) or_return
	version = json_data["version"].(json.String) or_return


	ty: Project_Type
	switch type {
	case "exe":
		ty = .Exe
	case "lib":
		ty = .Lib
	case:
		return
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

create_project :: proc(args: []string) -> bool {
	parsed_map := args_parser.parse_args(args)
	defer delete(parsed_map)

	if parsed_map["name"] == "" && !is_a_command(args[0]) {
		fmt.eprintln(`Provide a name for your project, like -name:"My Cool Project"`)
		fmt.eprintln(`Provide a type for your project, like -type:exe or -type:lib`)
		return false
	}

	// strip whitespace from the name
	new_name, _ := strings.replace_all(parsed_map["name"], " ", "_", context.temp_allocator)

	// create our project
	new_project, ok := jiraf.project_create(
		name = strings.to_lower(new_name, context.temp_allocator),
		type = parsed_map["type"],
		author = parsed_map["author"],
		version = parsed_map["version"],
		description = parsed_map["desc"],
	)

	return ok
}

main :: proc() {

	args := os.args[1:]

	if len(args) == 0 {
		print_help()
		return
	}

	if args[0] == "new" {
		create_ok := create_project(args)
		if !create_ok {
			fmt.println("Failed to create project")
			return
		} else {
			fmt.println("Project created")
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
			fmt.println("0.3.3")
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
