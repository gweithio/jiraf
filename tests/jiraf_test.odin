package tests

import "core:testing"
import "shared:jiraf"

@(test)
test_true :: proc(t: ^testing.T) {
	testing.expect_value(t, true, true)
}
