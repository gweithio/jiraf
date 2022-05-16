package utils

// loop through a dynamic array of bools and return if all values are true used in project_create_dirs (jiraf.odin:L35) 
all_true :: proc(values: [dynamic]bool) -> bool {
	for v in values {
		if !v {
			return false
		}
	}

	return true
}
