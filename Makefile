NVIM := nvim

.PHONY: test test-math test-utils test-prayer

test:
	$(NVIM) --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

test-math:
	$(NVIM) --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedFile tests/math_spec.lua"

test-utils:
	$(NVIM) --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedFile tests/utils_spec.lua"

test-prayer:
	$(NVIM) --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedFile tests/prayer_calc_spec.lua"
