package example_project_test

import "core:testing"

@(test)
test_true_is_true :: proc(t: ^testing.T) {
	testing.expect_value(t, true, true)
}

