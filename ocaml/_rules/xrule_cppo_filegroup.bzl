load("@bazel_skylib//rules:common_settings.bzl", "int_setting", "string_setting", "BuildSettingInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")

load("//implementation:utils.bzl",
     "capitalize_initial_char",
     "get_opamroot",
     "get_sdkpath",
     "get_src_root",
     "strip_ml_extension",
     "OCAML_FILETYPES",
     "OCAML_IMPL_FILETYPES",
     "OCAML_INTF_FILETYPES",
     "WARNING_FLAGS"
     )


# BuildSettingInfo = provider(
#     doc = "A singleton provider that contains the raw value of a build setting",
#     fields = {
#         "value": "The value of the build setting in the current configuration. " +
#                  "This value may come from the command line or an upstream transition, " +
#                  "or else it will be the build setting's default.",
#     },
# )

## example:
# xrule_cppo_filegroup(
#     name = "ExtArray.cppo_mli",
#     srcs = ["extArray.mli"],
#     opts = ["-I", "foo"],
#     defines = [
#         "OCAML 407"
#     ] + WORD_SIZE + HAS_BYTES_FLAG,
#     undefines = ["FOO"],
#     exts = {
#         "lowercase": 'tr "[A-Z]" "[a-z]"'
#     }
# )

# output has same name as input, but is output to a Bazel-controlled
# dir (e.g. bazel-bin/src)

################################################################
def _xrule_cppo_filegroup_impl(ctx):

  debug = False
  # if (ctx.label.name == "snark0.cm_"):
  # if ctx.label.name == "RefList":
  #     debug = True

  if debug:
      print("XRULE_CPPO_FILEGROUP TARGET: %s" % ctx.label.name)

  tc = ctx.toolchains["@obazl_rules_ocaml//ocaml:toolchain"]
  env = {"OPAMROOT": get_opamroot(),
         "PATH": get_sdkpath(ctx)}

  entailed_deps = None

  dep_graph = []
  dep_graph.extend(ctx.files.srcs)
  outputs   = []
  for src in ctx.files.outs:
      o = ctx.actions.declare_file("_obazl_/" + src.basename)
      outputs.append(o)

  ################################################################
  args = ctx.actions.args()
  args.add_all(ctx.attr.opts)

  args.add_all(ctx.attr.defines, before_each="-D", uniquify = True)
  args.add_all(ctx.attr.undefines, before_each="-U", uniquify = True)

  for var in ctx.attr.vars.items():
      args.add("-V", var[1] + ":" + var[0][BuildSettingInfo].value)

  if ctx.attr.exts:
      for k in ctx.attr.exts.keys():
          args.add("-x")
          args.add(k + ":" + ctx.attr.exts[k])

  args.add_all(outputs, before_each="-o", uniquify = True)
  # args.add_all(ctx.files.includes, before_each="-I", uniquify = True)

  args.add_all(dep_graph)

  if debug:
      print("\n\t\t================ INPUTS (DEP_GRAPH) ================\n\n")
      for dep in dep_graph:
          print("\nINPUT: %s\n\n" % dep)

  if debug:
      print("\n\t\t================ OUTPUTS ================\n\n")
      for out in outputs:
          print("\nOUTPUT: %s\n\n" % out)

  ctx.actions.run(
      env = env,
      executable = ctx.file._tool,
      arguments = [args],
      inputs = dep_graph,
      outputs = outputs,
      tools = [ctx.file._tool],
      mnemonic = "OcamlxCPPORunner",
      progress_message = "xrule_cppo_filegroup"
  )

  defaultInfo = DefaultInfo(
      # payload
      files = depset(
          order = "postorder",
          direct = outputs
      )
  )

  return [defaultInfo]

#############################################
########## DECL:  OCAML_MODULE  ################
xrule_cppo_filegroup = rule(
    implementation = _xrule_cppo_filegroup_impl,
    attrs = dict(
        _sdkpath = attr.label(
            default = Label("@ocaml//:path")
        ),
        doc = attr.string(
            doc = "Docstring for module"
        ),
        srcs = attr.label_list(
            allow_files = True
        ),
        outs = attr.label_list(
            allow_files = True
        ),
        defines  = attr.string_list(
            doc = "CPPO -D (define) declarations.",
        ),
        undefines  = attr.string_list(
            doc = "CPPO -U (undefine) declarations.",
        ),
        vars = attr.label_keyed_string_dict(
            doc = "Dictionary of cppo VAR (-V) options. Keys: label. Values: string VAR name."
        ),
        opts = attr.string_list(),
        exts = attr.string_dict(
        ),
        msg = attr.string(),
        _tool = attr.label(
            allow_single_file = True,
            default = "@opam//:bin/cppo"
        )
    ),
    # provides = [OcamlModuleProvider],
    # provides = [DefaultInfo, OutputGroupInfo, PpxInfo],
    executable = False,
    toolchains = ["@obazl_rules_ocaml//ocaml:toolchain"],
)