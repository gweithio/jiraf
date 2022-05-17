package jiraf

import "core:os"
import "core:strings"
import "core:encoding/json"
import "shared:jiraf/utils"

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

// create our directories, such as src, test, pkg, including any neccessary .odin files
@(private)
project_create_dirs :: proc(using self: Project) -> bool {

	results := [dynamic]bool{}

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

	append(&results, create_src_dir == os.ERROR_NONE)

	src_package_dir_str := strings.concatenate([]string{"src/", self.name})
	create_src_package_dir := os.make_directory(src_package_dir_str)

	append(&results, create_src_package_dir == os.ERROR_NONE)

	main_file := os.write_entire_file(
		"src/main.odin",
		transmute([]byte)main_odin_content,
		true,
	)

	append(&results, main_file)

	package_file := os.write_entire_file(
		strings.concatenate([]string{src_package_dir_str, "/", self.name, ".odin"}),
		transmute([]byte)package_odin_content,
		true,
	)

	append(&results, package_file)

	create_tests_dir := os.make_directory("tests")

	append(&results, create_tests_dir == os.ERROR_NONE)

	test_file := os.write_entire_file(
		strings.concatenate([]string{"tests/", self.name, "_test", ".odin"}),
		transmute([]byte)test_odin_content,
		true,
	)

	append(&results, test_file)

	create_pkg_dir := os.make_directory("pkg")

	append(&results, create_pkg_dir == os.ERROR_NONE)

	project_json := project_create_json(self)
	append(&results, project_json)

	git_keep := os.write_entire_file("pkg/.gitkeep", []byte{})

	append(&results, git_keep)

	result := utils.all_true(results)

	// just return package.json as it will always be that name
	return result
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
	Project,
	bool,
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

	result := project_create_dirs(project)

	return project, result
}
