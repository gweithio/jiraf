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

Dependency :: struct {
	url:     string,
	version: string,
}

Dependencies :: struct {
	name: string,
	dep:  Dependency,
}

Project :: struct {
	name:           string,
	type:           string,
	author:         string,
	version:        string,
	description:    string,
	dependencies:   map[string]Dependency,
	artifacts_made: bool,
}

Collections :: struct {
	name: string,
	path: string,
}

Odin_Lang_Server :: struct {
	collections:             []Collections,
	thread_pool_count:       i32,
	enable_snippets:         bool,
	enable_document_symbols: bool,
	enable_hover:            bool,
	enable_global_std:       bool,
	verbose:                 bool,
}

@(private)
project_create_ols_json :: proc() -> bool {

	current_dir := os.get_current_directory()

	core_collection := fmt.tprintf(
		"%s/core",
		os.get_env("ODIN_ROOT", context.temp_allocator),
	)

	default_collections := []Collections{
		{name = "core", path = core_collection},
		{name = "shared", path = fmt.tprintf("%s/src", current_dir)},
		{name = "pkg", path = fmt.tprintf("%s%s", current_dir, "/pkg")},
	}

	defer delete(current_dir)

	lang_server_default := Odin_Lang_Server {
		collections = default_collections,
	}

	parsed, _ := json.marshal(lang_server_default, context.temp_allocator)

	return os.write_entire_file("ols.json", parsed)
}

// create our project.json
@(private)
project_create_json :: proc(self: Project) -> bool {
	new_data, _ := json.marshal(self, context.temp_allocator)

	return os.write_entire_file("project.json", new_data)
}

// create our directories, such as src, test, pkg, including any neccessary .odin files
@(private)
project_create_dirs :: proc(self: Project) -> bool {

	results := [dynamic]bool{}
	defer delete(results)

	project_dir := os.make_directory(self.name)

	append(&results, project_dir == os.ERROR_NONE)

	swap_dir := os.set_current_directory(self.name)
	append(&results, swap_dir == os.ERROR_NONE)

	// init git in the project repo
	libc.system("git init")

	// create a lib and return rather than a exe project
	if self.type == "lib" {

		create_pkg_dir := os.make_directory(self.name)

		append(&results, create_pkg_dir == os.ERROR_NONE)

		project_json := project_create_json(self)
		append(&results, project_json)

		package_odin_content := strings.concatenate(
			[]string{"package ", self.name},
			context.temp_allocator,
		)

		package_file_data := strings.concatenate(
			[]string{self.name, "/", self.name, ".odin"},
			context.temp_allocator,
		)
		package_file := os.write_entire_file(
			package_file_data,
			transmute([]byte)package_odin_content,
		)

		append(&results, package_file)

		create_pkg_dep_dir := os.make_directory("pkg")
		append(&results, create_pkg_dep_dir == os.ERROR_NONE)

		git_keep := os.write_entire_file("pkg/.gitkeep", []byte{})
		append(&results, git_keep)

		create_tests_dir := os.make_directory("tests")

		append(&results, create_tests_dir == os.ERROR_NONE)

		test_odin_content := `
        import "core:testing"

        @(test)
        test_true_is_true :: proc(t: ^testing.T) {
            testing.expect_value(t, true, true)
        }
        `

		test_file_data := strings.concatenate(
			[]string{"tests/", self.name, "_test", ".odin"},
			context.temp_allocator,
		)

		test_file := os.write_entire_file(test_file_data, transmute([]byte)test_odin_content)

		append(&results, test_file)

		ols_json := project_create_ols_json()
		append(&results, ols_json)

		ok := utils.all_true(results)

		return ok
	}

	main_odin_content := `
    package main
    
    import "core:fmt"

    main :: proc() {
        fmt.println("Hellope!")
    }
    `

	package_odin_content := strings.concatenate(
		[]string{"package ", self.name},
		context.temp_allocator,
	)

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
		}, context.temp_allocator)

	create_src_dir := os.make_directory("src")

	append(&results, create_src_dir == os.ERROR_NONE)

	src_package_dir_str := strings.concatenate(
		[]string{"src/", self.name},
		context.temp_allocator,
	)

	create_src_package_dir := os.make_directory(src_package_dir_str)

	append(&results, create_src_package_dir == os.ERROR_NONE)

	main_file := os.write_entire_file("src/main.odin", transmute([]byte)main_odin_content)

	append(&results, main_file)

	package_file_data := strings.concatenate(
		[]string{src_package_dir_str, "/", self.name, ".odin"},
		context.temp_allocator,
	)

	package_file := os.write_entire_file(
		package_file_data,
		transmute([]byte)package_odin_content,
	)

	append(&results, package_file)

	create_tests_dir := os.make_directory("tests")

	append(&results, create_tests_dir == os.ERROR_NONE)

	test_file_data := strings.concatenate(
		[]string{"tests/", self.name, "_test", ".odin"},
		context.temp_allocator,
	)

	test_file := os.write_entire_file(
		test_file_data,
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
project_create :: proc(name, type, author, version, description: string) -> (
	Project,
	bool,
) {
	new_author := author
	new_version := version
	new_desc := description

	if author == "" do new_author = DEFAULT_AUTHOR
	if version == "" do new_version = DEFAULT_VERSION
	if description == "" do new_desc = DEFAULT_DESC

	plain_dep := make(map[string]Dependency, 1, context.temp_allocator)

	deps := []Dependencies{{name = "dep1", dep = {url = "url1", version = "0.1"}}}

	// Build our plain_dep array to just fill in the data for now
	for dep in deps {
		plain_dep[dep.name] = dep.dep
	}

	project := Project {
		name           = name,
		type           = type,
		author         = new_author,
		version        = new_version,
		description    = new_desc,
		dependencies   = plain_dep,
		artifacts_made = false,
	}


	result := project_create_dirs(project)

	return project, result
}
