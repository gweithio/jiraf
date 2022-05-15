package main

import "core:fmt"
import "core:os"
import "core:strings"
import "shared:jiraf"

get_value_after_slash :: proc(v: string) -> map[string]string {
	argsMap := make(map[string]string)

	index := strings.index(v, ":")

	v1, _ := strings.remove_all(v, ":")
	v2, _ := strings.remove_all(v1, "-")

	if index != -1 {
		argsMap[v2[:index - 1]] = v2[index - 1:]
	}

	return argsMap
}

parse_args :: proc(args: []string) -> [dynamic]map[string]string {
	parsedArgs := [dynamic]map[string]string{}

	for arg in args {
		append_elem(&parsedArgs, get_value_after_slash(arg))
	}

	return parsedArgs
}


main :: proc() {
	// Get all args other than the current filename
	args := os.args[1:]

	parsedArgs := parse_args(args)
	parsedMap := make(map[string]string)

	for m, _ in parsedArgs {
		for k, v in m {
			parsedMap[k] = v
		}
	}

	// strip whitespace from the name
	newName, _ := strings.remove_all(parsedMap["name"], " ")

	if parsedMap["name"] == "" {
		fmt.println(`Provide a name for your project, like -name:"My Cool Project"`)
		os.exit(1)
	}

	if parsedMap["type"] == "" {
		fmt.println(`Provide a project type, like -type:exe for an executable project or -type:lib for a library`)
		os.exit(
			1,
		)
	}

	// create our project
	newProject, ok := jiraf.project_create(
		name = newName,
		type = parsedMap["type"],
		author = parsedMap["author"],
		version = parsedMap["version"],
		description = parsedMap["desc"],
		dependencies = []string{},
	)

	if !ok {
		panic("Failed to create project")
	}

	fmt.println(newProject)

}
