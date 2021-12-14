load(":impl_executable.bzl", "impl_executable")

load("//ocaml/_transitions:transitions.bzl", "executable_in_transition")

load("//ocaml:providers.bzl", "CompilationModeSettingProvider")

load(":options.bzl", "options", "options_executable")

###############################
def _ocaml_test(ctx):

    tc = ctx.toolchains["@ocaml//ocaml:toolchain"]

    mode = ctx.attr._mode[CompilationModeSettingProvider].value

    if mode == "native":
        tool = tc.ocamlopt # .basename
    else:
        tool = tc.ocamlc  #.basename

    tool_args = []

    return impl_executable(ctx, mode, tc.linkmode, tool, tool_args)

################################
rule_options = options("ocaml")
rule_options.update(options_executable("ocaml"))

##################
ocaml_test = rule(
    implementation = _ocaml_test,
    doc = """OCaml test rule.

**CONFIGURABLE DEFAULTS** for rule `ocaml_test`

In addition to the [OCaml configurable defaults](#configdefs) that apply to all
`ocaml_*` rules, the following apply to this rule:

| Label | Default | `opts` attrib |
| ----- | ------- | ------- |
| @ocaml//executable:linkall | True | `-linkall`, `-no-linkall`|
| @ocaml//executable:threads | False | true: `-I +thread`|
| @ocaml//executable:warnings | `@1..3@5..28@30..39@43@46..47@49..57@61..62-40`| `-w` plus option value |

**NOTE** These do not support `:enable`, `:disable` syntax.

 See [Configurable Defaults](../ug/configdefs_doc.md) for more information.
    """,
    attrs = dict(
        rule_options,
        _rule = attr.string( default = "ocaml_test" ),
    ),
    # cfg = executable_in_transition,
    test = True,
    toolchains = ["@ocaml//ocaml:toolchain"],
)
