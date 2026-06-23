package bcd

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:unicode"

matches :: proc(s: string, dirname: string) -> (distance: int) {
	if s == dirname do return 0
	if strings.to_lower(s) == strings.to_lower(dirname) do return 1
	{
		dist := 2
		match := true
		offset := 0
		loop: for rune, i in s {
			for dirrune, j in dirname {
				if j < offset do continue
				if rune == dirrune {
					offset = j + 1
					continue loop
				} else if unicode.to_lower(rune) == unicode.to_lower(dirrune) {
					offset = j + 1
					dist += 1
					continue loop
				} else do dist += 2
			}
			match = false
			break
		}
		if match do return dist
	}
	return -1
}

traverse :: proc(check: string, current: string, remaining: []string) -> string {
	if check == "" do return current
	{
		dots := 0
		for rune in check {
			if rune == '.' do dots += 1
			else {
				dots = 0
				break
			}
		}
		if dots > 0 {
			b := strings.builder_make()
			path := strings.split(current, "/")
			newlen := len(path) - dots
			if newlen <= 1 {
				path = {}
				strings.write_byte(&b, '/')
			} else do path = path[:newlen]
			for e, i in path {
				if i != 0 do strings.write_byte(&b, '/')
				strings.write_string(&b, e)
			}
			if len(remaining) > 0 {
				return traverse(remaining[0], strings.to_string(b), remaining[1:])
			} else {
				return strings.to_string(b)
			}
		}
	}
	d, e := os.open(current, {.Read})
	if e != nil do exit("Error opening '%s' directory")
	defer os.close(d)

	file_info, _ := os.fstat(d, context.allocator)
	defer os.file_info_delete(file_info, context.allocator)

	if file_info.type != .Directory do exit("'%s' isn't a directory", current)

	files, _ := os.read_dir(d, -1, context.allocator)
	slice.sort_by(files, proc(a, b: os.File_Info) -> bool {
		return a.name < b.name
	})
	defer os.file_info_slice_delete(files, context.allocator)

	validvalue :: struct {
		path:  string,
		match: int,
	}
	valid: [dynamic]validvalue
	for dir in files {
		symlinktodir := false
		if dir.type == .Symlink {
			f, _ := os.stat(dir.fullpath, context.allocator)
			defer os.file_info_delete(f, context.allocator)
			if f.type == .Directory do symlinktodir = true
		}
		is_file := dir.type != .Directory && !symlinktodir
		if is_file && !CONSIDER_FILES do continue

		if match := matches(check, dir.name); match >= 0 {
			path, _ := os.join_path({current, dir.name}, context.allocator)
			if len(remaining) > 0 {
				next := traverse(remaining[0], path, remaining[1:])
				if next != "" do append(&valid, validvalue{next, match})
			} else {
				append(&valid, validvalue{path, match})
			}
		}
	}
	if len(valid) == 0 do return "" // "
	slice.sort_by(valid[:], proc(a, b: validvalue) -> bool {
		if a.match == b.match {
			return a.path < b.path
		} else {
			return a.match < b.match
		}
	})
	if VERBOSE {
		for i := len(valid) - 1; i >= 0; i -= 1 {
			v := valid[i]
			fmt.eprintfln("[\e[33minfo\e[0m] %s: %d", v.path, v.match)
		}
	}
	return valid[0].path
}
