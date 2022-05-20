package jiraf

import "core:os"
import "core:strings"
import "core:fmt"
import "core:encoding/json"
import "shared:jiraf/utils"
import "core:c/libc"

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


Odin_Lang_Server :: struct {
	collections:             []map[string]string,
	thread_pool_count:       i32,
	enable_snippets:         bool,
	enable_document_symbols: bool,
	enable_hover:            bool,
	enable_global_std:       bool,
	verbose:                 bool,
}

@(private)
project_create_ols_json :: proc() -> bool {

	default_collections := make(map[string]string)

	default_collections["core"] = "TODO: SET TO FULL PATH WHERE ODIN IS LOCATED"
	default_collections["shared"] = fmt.tprintf("%s%s", os.get_current_directory(), "/src")
	default_collections["pkg"] = fmt.tprintf("%s%s", os.get_current_directory(), "/pkg")


	lang_server_default := Odin_Lang_Server {
		collections = {default_collections},
	}

	parsed, err := json.marshal(lang_server_default)

	return os.write_entire_file("ols.json", parsed)
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

	project_dir := os.make_directory(self.name)
	append(&results, project_dir == os.ERROR_NONE)

	swap_dir := os.set_current_directory(self.name)
	append(&results, swap_dir == os.ERROR_NONE)


	// create a lib and return rather than a exe project
	if self.type == "lib" {

		create_pkg_dir := os.make_directory(self.name)

		append(&results, create_pkg_dir == os.ERROR_NONE)

		project_json := project_create_json(self)
		append(&results, project_json)

		package_odin_content := strings.concatenate([]string{"package ", self.name})

		package_file := os.write_entire_file(
			strings.concatenate([]string{self.name, "/", self.name, ".odin"}),
			transmute([]byte)package_odin_content,
			true,
		)

		append(&results, package_file)

		create_pkg_dep_dir := os.make_directory("pkg")
		append(&results, create_pkg_dep_dir == os.ERROR_NONE)

		git_keep := os.write_entire_file("pkg/.gitkeep", []byte{})
		append(&results, git_keep)

		create_tests_dir := os.make_directory("tests")

		append(&results, create_tests_dir == os.ERROR_NONE)

		test_file := os.write_entire_file(
			strings.concatenate([]string{"tests/", self.name, "_test", ".odin"}),
			transmute([]byte)test_odin_content,
			true,
		)

		append(&results, test_file)


		ols_json := project_create_ols_json()
		append(&results, ols_json)

		return utils.all_true(results)
	}

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

	ols_json := project_create_ols_json()
	append(&results, ols_json)

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
