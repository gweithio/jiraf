package jiraf

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
	dependencies: map[string]string,
}

// create our project.json
@(private)
project_create_json :: proc(using self: Project) -> bool {
	new_data, err := json.marshal(self)

	if err != nil {
		return false
	}

	return os.write_entire_file("project.json", new_data)
}

// create our directories, such as src, test, vendor, including any neccessary .odin files
@(private)
project_create_dirs :: proc(using self: Project) -> (dir: string, ok: bool) {
	main_odin_content := `
    package main
    
    import "core:fmt"

    main :: proc() {
        fmt.println("Hellope!")
    }
    `

	package_odin_content := strings.concatenate([]string{"package ", self.name})

	test_odin_content := `
    import "core:testing"

    @(test)
    test_true_is_true :: proc(t: ^testing.T) {
        testing.expect_value(t, true, true)
    }
    `

	test_odin_content = strings.concatenate([]string{
			"package ",
			self.name,
			"_test",
			test_odin_content,
		})

	create_src_dir := os.make_directory("src")

	src_package_dir_str := strings.concatenate([]string{"src/", self.name})
	create_src_package_dir := os.make_directory(src_package_dir_str)

	main_file := os.write_entire_file(
		"src/main.odin",
		transmute([]byte)main_odin_content,
		true,
	)

	package_file := os.write_entire_file(
		strings.concatenate([]string{src_package_dir_str, "/", self.name, ".odin"}),
		transmute([]byte)package_odin_content,
		true,
	)

	create_tests_dir := os.make_directory("tests")

	test_file := os.write_entire_file(
		strings.concatenate([]string{"tests/", self.name, "_test", ".odin"}),
		transmute([]byte)test_odin_content,
		true,
	)

	create_vendor_dir := os.make_directory("vendor")
	project_json := project_create_json(self)
	git_keep := os.write_entire_file("vendor/.gitkeep", []byte{})

	return "package.json", project_json
}

// Create our project
project_create :: proc(
	name,
	type,
	author,
	version,
	description: string,
	dependencies: map[string]string,
) -> (
	proj: Project,
	ok: bool,
) {
	// TODO(ethan): figure out a better way to handle this
	new_author := author
	new_version := version
	new_desc := description

	if author == "" do new_author = DEFAULT_AUTHOR
	if version == "" do new_version = DEFAULT_VERSION
	if description == "" do new_desc = DEFAULT_DESC

	project := Project {
		name         = name,
		type         = type,
		author       = new_author,
		version      = new_version,
		description  = new_desc,
		dependencies = dependencies,
	}

	_, result := project_create_dirs(project)

	return project, result
}
