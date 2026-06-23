package bcd

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/posix"

CONSIDER_FILES := false // if --files is specified
VERBOSE := false // if --verbose is specified

exit :: proc(format: string, args: ..any) {
	fmt.eprintfln(format, ..args)
	os.exit(1)
}

usage :: proc() {
	fmt.eprintf(
		`A program to integrate into cd that makes traversing directories faster

Usage: %s [OPTIONS] <pattern>...

Arguments:
  <pattern>...
    Enough characters to identify a file/directory
    separated by '/' or spaces

Options:
  -h, --help
    Show this usage screen
  -f, --files
    Also look for matching files instead of only directories
  -c, --cwd
    Specify a custom cwd instead of taking the user's "$PWD"
    or getting it via SYS_getcwd
  -n, --no-home
    Don't print the home directory if no arguments are provided
  -p, --print-cwd
    Instead of printing the home directory, print the cwd if
    no arguments are provided (assumes -n)
  -i, --info
    Also print the matched directory to stderr
  -v, --verbose
    Print the list of matched directories to stderr with
    how far they are to the arguments (0 = perfect match)
  --
    Stop looking for other options after this one

Shell integration:
  The program itselft prints the matched file/directory to stdout,
  below is an example implementation to put in .bashrc/.zshrc
  
  c() {{
    local dir; dir=$(bcd $@)
    [ $? = 0 ] && cd $dir >/dev/null
  }

  Example usage:
  ~ $ c ~ lo sh st apps c
  ~/.local/share/Steam/steamapps/common $
To view with a pager remember to redirect stderr to stdout like:
~ $ %s --help 2>&1 | less
`,
		os.args[0],
		os.args[0],
	)
	os.exit(0)
}

main :: proc() {
	ignore_args := false
	absolute_path := false
	custom_cwd := ""
	print_home := true
	info := false
	print_cwd := false
	args: [dynamic]string
	{
		argc := len(os.args)
		for i := 1; i < argc; i += 1 {
			arg := os.args[i]
			if !ignore_args && arg != "" && arg[0] == '-' {
				switch arg {
				case "--":
					ignore_args = true
					continue
				case "--help":
					fallthrough
				case "-h":
					usage()
				case "--files":
					fallthrough
				case "-f":
					CONSIDER_FILES = true
					continue
				case "--cwd":
					fallthrough
				case "-c":
					if i += 1; i >= argc do exit("The flag '%s' needs a parameter", arg)
					custom_cwd = os.args[i]
					continue
				case "--no-home":
					fallthrough
				case "-n":
					print_home = false
					continue
				case "--info":
					fallthrough
				case "-i":
					info = true
					continue
				case "--verbose":
					fallthrough
				case "-v":
					VERBOSE = true
					continue
				case "--print-cwd":
					fallthrough
				case "-p":
					print_home = false
					print_cwd = true
					continue
				case "-":
					fmt.println("-")
					os.exit(0)
				case:
					exit("Invalid flag '%s'", arg)
				}
			}
			if len(args) == 0 && arg != "" && arg[0] == '/' do absolute_path = true
			for path_arg in strings.split(arg, "/") {
				if path_arg != "" do append(&args, path_arg)
			}
		}
	}
	cwd: string
	if !absolute_path && custom_cwd == "" {
		if cwd = os.get_env("PWD", context.allocator); cwd == "" {
			err: os.Error
			cwd, err = os.get_working_directory(context.allocator)
			if err != nil do exit("Error in getting the cwd")
		}
	} else do cwd = custom_cwd
	dir: string
	if len(args) > 0 {
		dir = traverse(args[0], absolute_path ? "/" : cwd, args[1:])
	} else if absolute_path {
		dir = "/"
	} else if print_home {
		if dir = os.get_env("HOME", context.allocator); dir == "" {
			if dir = string(posix.getpwuid(posix.getuid()).pw_dir); dir == "" {
				fmt.eprintln("[\e[31merror\e[0m] Couldn't get home directory")
				os.exit(1)
			}
		}
	} else {
		if print_cwd do fmt.println(cwd)
		os.exit(0)
	}

	if dir != "" {
		fmt.println(dir)
		if info do fmt.eprintln("[\e[33minfo\e[0m]", dir)
	} else {
		if CONSIDER_FILES do fmt.eprintln("[\e[31merror\e[0m] No matching file/directory found")
		else do fmt.eprintln("[\e[31merror\e[0m] No matching directory found")
		os.exit(1)
	}
	os.exit(0)
}
