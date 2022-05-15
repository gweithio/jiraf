package jiraf

import "core:fmt"
import "core:os"
import "core:strings"
import "core:encoding/json"

DEFAULT_AUTHOR :: "TODO: PROJECT AUTHOR"
DEFAULT_VERSION :: "TODO: PROJECT VERSION"
DEFAULT_DESC :: "TODO: PROJECT DESCRIPTION"


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
	// TODO(ethan): create directories, like src, vendor, tests 

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
	// TODO(ethan): figure out a better way to handle this
	newAuthor := author
	newVersion := version
	newDesc := description

	if author == "" do newAuthor = DEFAULT_AUTHOR
	if version == "" do newVersion = DEFAULT_VERSION
	if description == "" do newDesc = DEFAULT_DESC

	project := Project {
		name         = name,
		type         = type,
		author       = newAuthor,
		version      = newVersion,
		description  = newDesc,
		dependencies = dependencies,
	}

	return project_create_dirs(project)
}
