# Bcd
A program to integrate into cd that makes traversing directories faster using abbreviated strings to match for actual files/directories

# Usage: 
```
  bcd `[OPTIONS]` `<pattern>...`
```

# Arguments:
```
  <pattern>...
    Enough characters to identify a file/directory
    separated by '/' or spaces
```

# Options:
```
  -h, --help`    
    Show this usage screen`
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
```

# Shell integration:
  The program itselft prints the matched file/directory to stdout,
  below is an example implementation to put in .bashrc/.zshrc
``` bash
c() {{
  local dir; dir=$(bcd $@)
  [ $? = 0 ] && cd $dir >/dev/null
}
```
 Example usage:
``` bash
~ $ c ~ lo sh st apps c
~/.local/share/Steam/steamapps/common $
```

# How to build/install
To compiler the program you must have an odin compiler (dev-2026-06 was used to build this program)
In the root directory of the cloned repo run:
``` bash
odin build .
```
Then you can put it into `~/.local/bin` to make it accessible everywhere
``` bash
mkdir -p ~/.local/bin # Ensure the directory exists
mv bcd ~/.local/bin
```
