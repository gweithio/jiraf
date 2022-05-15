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

@(private)
project_create_json :: proc(using self: Project) -> bool {
	newData, err := json.marshal(self)

	if err != nil {
		return false
	}

	return os.write_entire_file("project.json", newData)
}

@(private)
project_create_dirs :: proc(using self: Project) -> (dir: string, ok: bool) {
	mainOdinContent := `
    package main
    
    import "core:fmt"

    main :: proc() {
        fmt.println("Hellope!")
    }
    `

	packageOdinContent := strings.concatenate([]string{"package ", self.name})

	testOdinContent := `
    import "core:testing"

    @(test)
    test_true_is_true :: proc(t: ^testing.T) {
        testing.expect_value(t, true, true)
    }
    `

	testOdinContent = strings.concatenate([]string{
			"package ",
			self.name,
			"_test",
			testOdinContent,
		})

	createSrcDir := os.make_directory("src")

	SrcPackageDirStr := strings.concatenate([]string{"src/", self.name})
	createSrcPackageDir := os.make_directory(SrcPackageDirStr)

	mainFile := os.write_entire_file("src/main.odin", transmute([]byte)mainOdinContent, true)

	packageFile := os.write_entire_file(
		strings.concatenate([]string{SrcPackageDirStr, "/", self.name, ".odin"}),
		transmute([]byte)packageOdinContent,
		true,
	)

	createTestsDir := os.make_directory("tests")

	testFile := os.write_entire_file(
		strings.concatenate([]string{"tests/", self.name, "_test", ".odin"}),
		transmute([]byte)testOdinContent,
		true,
	)

	createVendorDir := os.make_directory("vendor")
	projectJson := project_create_json(self)
	gitIgnore := os.write_entire_file("vendor/.gitignore", []byte{})

	return "package.json", projectJson
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

	_, result := project_create_dirs(project)

	return project, result
}
