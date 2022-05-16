package main

import "core:fmt"
import "core:os"
import "core:strings"
import "shared:jiraf"
import "core:encoding/json"

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
run_project :: proc(project: map[string]string) {
	// Don't really need the command_builder
	command_builder := &strings.Builder{}

	run_command := fmt.sbprintf(
		command_builder,
		"odin run src/main.odin -file -out:%s -warnings-as-errors -collection:shared=src -collection:vendor=vendor",
		strings.to_lower(project["name"]),
	)

	fmt.println(strings.concatenate([]string{"Running ", project["name"], "..."}))

	// TODO(gweithio): run the project by calling run command through Fork
}

// build the project by calling odin build
build_project :: proc(project: map[string]string) {

	// Don't really need the command_builder
	build_command := fmt.tprintf(
		"odin build src -o:speed -out:%s -warnings-as-errors -collection:shared=src -collection:vendor=vendor",
		strings.to_lower(project["name"]),
	)

	fmt.println(strings.concatenate([]string{"Building ", project["name"], "..."}))

	// TODO(gweithio): run the project by calling build_command through Fork
}

// Run tests by calling odin test
run_tests :: proc(project: map[string]string) {

	test_command := fmt.tprintf(
		"odin test tests -warnings-as-errors -show-timings -collection:shared=src -collection:vendor=vendor",
		strings.to_lower(project["name"]),
	)

	fmt.println("Running Tests...")

	// TODO(gweithio): run tests on the project by calling tests_command through Fork
}

// Check if project.json exists, used for whether we can do the run, build or test commands
does_package_exist :: proc() {
	// TODO(gweithio): this doesn't really check if it exists
	if !os.is_file("project.json") {
		fmt.println("Please create a project first")
		return
	}
}

// Check if the given parameter is a command
is_a_command :: proc(cmd: string) -> bool {
	if cmd == "run" || cmd == "test" || cmd == "build" {
		return true
	}
	return false
}

// Get the project.json and stuff it into a map[string]string
get_project_from_json :: proc() -> map[string]string {
	file, err := os.read_entire_file_from_filename("project.json")
	defer delete(file)

	json_data, _ := json.parse(file)

	project_data := json_data.(json.Object)

	// TODO(ethan): this is somewhat trash, needs to be improved, a loop maybe useful!
	project_map := make(map[string]string)
	project_map["name"] = project_data["name"].(json.String)
	project_map["type"] = project_data["type"].(json.String)
	project_map["author"] = project_data["author"].(json.String)
	project_map["version"] = project_data["version"].(json.String)

	return project_map
}

print_help :: proc() {

	fmt.println()
	fmt.println(`usage: jiraf -name:"project name" -type:exe`)

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

	if len(args) <= 0 || args[0] == "-help" || args[0] == "-h" || args[0] == "help" {
		print_help()
		return
	}

	if is_a_command(args[0]) {
		project_json := get_project_from_json()

		// Get all args other than the current filename
		switch (args[0]) {
		case "run":
			does_package_exist()
			run_project(project_json)
			return
		case "build":
			does_package_exist()
			build_project(project_json)
			return
		case "test":
			does_package_exist()
			run_tests(project_json)
			return
		}

		return
	}

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
		return
	}

	if parsed_map["type"] == "" && !is_a_command(args[0]) {
		fmt.eprintln(`Provide a project type, like -type:exe for an executable project or -type:lib for a library`)
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
		fmt.println(strings.concatenate([]string{new_project.name, " has been created"}))
		return
	}

	if !ok {
		fmt.eprintln("Failed to create project")
	}

}
