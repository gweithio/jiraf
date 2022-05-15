package jiraf

import "core:fmt"
import "core:os"
import "core:strings"
import "core:encoding/json"

Project :: struct {
	name:         string,
	type:         string,
	author:       string,
	version:      string,
	description:  string,
	dependencies: []string,
}

@(private)
project_create_json :: proc(using self: Project) -> bool {
	newData, err := json.marshal(self)

	if err != nil {
		return false
	}

	return os.write_entire_file(strings.concatenate([]string{self.name, ".json"}), newData)
}

@(private)
project_create_dirs :: proc(using self: Project) -> (dir: string, ok: bool) {
	// TODO(ethan): create json project file, src, tests and vendor directories

	projectJson := project_create_json(self)

	return strings.concatenate([]string{self.name, ".json"}), projectJson
}

// Create our project
project_create :: proc(
	name,
	type,
	author,
	version,
	description: string,
	dependencies: []string,
) -> (
	dir: string,
	ok: bool,
) {
	project := Project {
		name         = name,
		type         = type,
		author       = author,
		version      = version,
		description  = description,
		dependencies = dependencies,
	}

	return project_create_dirs(project)
}
