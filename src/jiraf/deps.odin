package jiraf

// Add a dep to the project.json
add_dep :: proc(dep_name: string) -> bool {
	return false
}

// Delete dep from the project.json
delete_dep :: proc(dep_name: string) -> bool {

	return false
}

// So we only install ones that aren't already present
check_deps_installed :: proc(possible_deps: []string) -> []string {
	notInstalled := []string{}

	return notInstalled
}

// loop through the deps passed in from check_deps_installed and download them to the vendor directory
download_deps :: proc(deps: []string) -> bool {
	return false
}
