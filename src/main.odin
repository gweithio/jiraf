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
	fmt.println(strings.concatenate([]string{"Running ", project["name"], "..."}))

	// TODO(gweithio): run the project by calling
	// odin run src/main.odin -file -collection:shared=src -collection:vendor=vendor
}

// build the project by calling odin build
build_project :: proc(project: map[string]string) {
	fmt.println(strings.concatenate([]string{"Building ", project["name"], "..."}))

	// TODO(gweithio): run the project by calling
	// odin build src -o:speed -out:jiraf -collection:shared=src -collection:vendor=vendor
}

// Run tests by calling odin test
run_tests :: proc(project: map[string]string) {
	fmt.println("Running Tests...")

	// TODO(gweithio): run the project by calling
	// odin test tests -warnings-as-errors -show-timings -collection:shared=src
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

main :: proc() {

	args := os.args[1:]

	if is_a_command(args[0]) {
		project_json := get_project_from_json()

		// Get all args other than the current filename
		switch (args[0]) {
		case "run":
			does_package_exist()
			run_project(project_json)
			os.exit(1)
		case "build":
			does_package_exist()
			build_project(project_json)
			os.exit(1)

		case "test":
			does_package_exist()
			run_tests(project_json)
			os.exit(1)
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
	new_name, _ := strings.remove_all(parsed_map["name"], " ")

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
