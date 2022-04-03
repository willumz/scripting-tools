# Hook Manager

## Usage

Run `install_hooks.sh` and select which hooks you would like to install.

## Hooks

## Creating Hooks

### Basics

All hooks must be placed in the `hooks` directory.

Each hook must consist of a header (see [headers](#Headers)) and a body.

The body of the hook is a simple shell script, written directly below the header.

### Headers

Headers provide config settings for the hook, and follow a structure like this:

```
----
type=pre-commit
----
```

The above header states that the hook's type is `pre-commit`.

For all the possible options a header can take, see [options](#Options).

### Options

-   `type`: **required**, the type of hook, as understood by git
    -   e.g. `type=pre-commit`
-   `on-modify`: a regex which matches staged files which should trigger the hook
    -   e.g. `on-modify=.*\.py$` which would cause the hook to trigger when python scripts are staged

**Hook script must end in newline, else bash will not interpret correctly.**
