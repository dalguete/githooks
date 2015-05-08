# githooks
Utility used to enable some particular capabilities when using git hooks, as
chaining support and load of versioned hook files inside the repo. Your defined
hooks will be preserved, but will live in a more appropriate place.

# INSTALL (it's quick)
Clone this repo and store it in a folder named **.githooks** *(dot at the beggining)*
next to *.git* folder, so *code* and *trackedhooks* can travel with your repo. Any
other place works too, as long as that is inside the repo.

For convenience, **$PATH** in your local should be adapted to enable access the
exec files (bin), here delivered.

Run `githooks --init`, and enjoy.

See below for more command options.

# GENERATED STRUCTURE
By default git only handles one hook file per repo. With this solution, you'll
be able to add any amount of hook files, that will be called sequentially.

And this is the new structure:

<pre><strong>
.git/hooks/
 │
 ├── hook files
 ├── hook names folder.d/
 │    ├── script
 │    └── ...
 ├── trackedhooks/
 │    └── hook names folder.d/
 │        ├── script
 │        └── ...
 └── _.sh
</strong></pre>

Can look a bit intimidating, but actually it's really simple.

* **hook files**: are all the Active hook files (use the name of the hook as filename)
  This is the normal git way of handling hook files, but here, in order to support
  chaining, they are only symlinks (ln -s) that points to "_.sh" (more on this, later).

* **hook names folder.d/**: folders that contains all files to be called when a
  hook is executed. For instance, if hook "commit-msg" is Active, a folder named
  "commit-msg.d" must exist.
  Files inside it will be called sequentially, using alphanumeric sort, so you
  state their execution order.

* **trackedhooks/**: link that points to .githooks/ folder, to make them available
  here. Inner structure must follow the one for "*hook names folder*.d/". Only 
  changes performed here are committable.

* **_.sh**: special file used to concentrate all git hooks activity. Remember
  all files in *hook files* are links to this one? Well, that's because this
  is used to dispatch the execution to the other ones, under *hook names folder*.d/
  and/or trackedhooks/, using the hook name as key. That's the reason folders
  must use the hook name as part of their names.
  This file is created by using this script.

This script can be used to create and handle this structure, so you only worry
about creating the hook process you want.

# HOW TO USE THIS SCRIPT
You can perform several operations. You'll see all of them share the option -y,
that's used to reply yes to any prompted question. And the options are:

* **`--status/-s [<hook-name>] [-ty]` (default)**. General status info
with all active hooks and paths to their files. If no options defined, it will print
all hooks info, otherwise only those ones that make a match. '-t' means look only
in trackedhooks/ folder. The status report also includes info about current structure.

* **`--init [-y]`**. Creates the basic structure, as defined above. The next is performed:

  * Remove+Add the _.sh script.
  * Remove+Add the linked trackedhooks/ folder.
  * Transform all active hook files into the new chaining version.

* **`--destroy [-y]`**. Reverts the creation of the new structure, New files and
folders will be removed. Active hooks will be kept as active, but in case more than
one file has been detected, only the '00default' will be used. Other files will be
left their respective folders, ones won't be removed to preserve your data.
trackedhooks/ folder and _.sh script will be removed.

* **`--on/-1 <hook-name> [-y]`**. Activate a given hook given the hook type. It just
deals with the link file, the one that points to the _.sh script.

* **`--off/-0 <hook-name> [-y]`**. Deactivate a given hook given the hook type. It
just deals with the link file, the one that points to the _.sh script.

* **`--add/-a <hook-name> <file-name> [-ty] [--do-edit]`**. Creates a new hook file,
given the hook type and the file name. On collision, it will ask before proceed.
The option '-t' means create it in the trackedhooks/ folder, whenever possible.
When no options given, the command will respond with an error and possible
options.
On success, the file wll be created/recreated and your favorite editor opened, if
the option '--do-edit' is set too.

* **`--edit/-e <hook-name> <file-name> [-ty] [--do-add]`**. Let you edit a given hook
file, given the hook type and the file name. It uses the favorite editor set. The
option '-t' means search in the trackedhooks/ folder, whenever possible. When no
options given, the command will respond with an error and possible options.
In case the file does not exist, you can create it there by using the option --do-add.

* **`--delete/-d <hook-name> <file-name> [-ty]`**. Delete a given hook file, given the
hook type and the file name. The option '-t' means search in the trackedhooks/
folder, whenever possible. When no options given, the command will respond with
an error and possible options.

# EXPORTED VARIABLES
There are some vars you can set to alter some settings. Those are:

* **`TRACKEDHOOKS_FOLDERNAME`**. Used to change the name of the trackedhooks/ folder
to something custom.

* **`TRIGGERSCRIPT_FILENAME`**. Used to change the name of the generated triggering
script.

* **`DEFAULT_EXTENSION`**. Used to change extension used for already existing scripts
in local when moved to the new location.

* **`NO_COLORS`**. Used to deactivate colored messages.

