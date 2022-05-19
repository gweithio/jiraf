package main

import "core:fmt"
import "core:os"
import "core:strings"
import "shared:jiraf"
import "core:encoding/json"
import "core:c/libc"

// Parse values from the args so we have a map[string]string
get_value_after_slash :: proc(v: string) -> map[string]string {
	args_map := make(map[string]string)

	index := strings.index(v, ":")

	v1, _ := strings.remove_all(v, ":")
	v2, _ := strings.remove_all(v1, "-")

	if index != -1 {
		args_map[v2[:index - 1]] = v2[index - 1:]
	}

	return args_map
}

// loop through the args and append them to our map
parse_args :: proc(args: []string) -> [dynamic]map[string]string {
	parsed_map := [dynamic]map[string]string{}

	for arg in args {
		append_elem(&parsed_map, get_value_after_slash(arg))
	}

	return parsed_map
}

// run the project by calling odin run
run_project :: proc(project: Project_Data, args: []string) {
	// Don't really need the command_builder

	arg_string := ""
	for arg in args {
		arg_string = strings.concatenate([]string{arg, " "})
	}

	run_command := fmt.tprintf(
		"odin run src/main.odin -file -out:%s %s -collection:shared=src -collection:pkg=pkg",
		strings.to_lower(project.name),
		arg_string,
	)

	fmt.println(strings.concatenate([]string{"Running ", project.name, "..."}))
	cmd := strings.clone_to_cstring(run_command)
	libc.system(cmd)
}

// build the project by calling odin build
build_project :: proc(project: Project_Data, args: []string) {

	arg_string := ""
	for arg in args {
		arg_string = strings.concatenate([]string{arg, " "})
	}

	// Don't really need the command_builder
	build_command := fmt.tprintf(
		"odin build src -out:%s %s -collection:shared=src -collection:pkg=pkg",
		strings.to_lower(project.name),
		arg_string,
	)

	fmt.println("Building", project.name, "...")
	cmd := strings.clone_to_cstring(build_command)
	libc.system(cmd)
}

// Run tests by calling odin test
run_tests :: proc(project: Project_Data, args: []string) {

	arg_string := ""
	for arg in args {
		arg_string = strings.concatenate([]string{arg, " "})
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
	pkg_dir := fmt.tprintf("%s/pkg", curr_dir)

	err := os.set_current_directory(pkg_dir)

	if err != os.ERROR_NONE {
		fmt.eprintln("Failed to swap to pkg directory")
		return
	}

	get_command := fmt.tprintf("git clone %s", url)
	cmd := strings.clone_to_cstring(get_command)
	fmt.println(cmd)
	libc.system(cmd)
}

// Check if the given parameter is a command
is_a_command :: proc(cmd: string) -> bool {
	if cmd == "run" || cmd == "test" || cmd == "build" || cmd == "get" {
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
	content := os.read_entire_file("project.json") or_return

	parsed, err := json.parse(content)
	if err != nil do return

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


main :: proc() {

	args := os.args[1:]

	if len(os.args) <= 1 || !is_a_command(args[0]) {
		print_help()
		return
	}

	if len(args) >= 0 && is_a_command(args[0]) {
		project_json, ok := get_project_from_json()
		if !ok do return

		args_for_command := []string{}

		if (len(args) >= 2) {
			args_for_command = args[2:]
		}

		// Get all args other than the current filename
		switch (args[0]) {
		case "run":
			run_project(project_json, args_for_command)
			return
		case "build":
			build_project(project_json, args_for_command)
			return
		case "test":
			run_tests(project_json, args_for_command)
			return
		case "get":
			if len(args) < 2 {
				fmt.eprintln("Please provide a Github Url")
				return
			}
			get_dep(project_json, args[1])
			return
		}

		return
	} else if args[0] == "-help" || args[0] == "-h" || args[0] == "help" {
		print_help()
		return
	} else {
		return
	}

	if args[0] == "new" {
		parsed_args := parse_args(args)
		parsed_map := make(map[string]string)

		for m, _ in parsed_args {
			for k, v in m {
				parsed_map[k] = v
			}
		}

		// strip whitespace from the name
		new_name, _ := strings.replace_all(parsed_map["name"], " ", "_")

		if parsed_map["name"] == "" && !is_a_command(args[0]) {
			fmt.eprintln(`Provide a name for your project, like -name:"My Cool Project"`)
			fmt.eprintln(`Provide a type for your project, like -type:exe or -type:lib`)
			return
		}


		// create our project
		new_project, ok := jiraf.project_create(
			name = strings.to_lower(new_name),
			type = parsed_map["type"],
			author = parsed_map["author"],
			version = parsed_map["version"],
			description = parsed_map["desc"],
			dependencies = make(map[string]string),
		)

		if ok {
			fmt.printf("%s has been created\n", new_name)
			return
		}

		if !ok {
			fmt.eprintf("Failed to create project %s\n", new_name)
		}

	}
}
