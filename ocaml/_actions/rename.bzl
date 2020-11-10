load("@bazel_skylib//lib:paths.bzl", "paths")
load("//ocaml/_providers:ocaml.bzl", "OcamlNsModuleProvider")
load("//implementation:utils.bzl",
     "capitalize_initial_char",
     "get_opamroot",
     "get_sdkpath"
)

tmpdir = "_obazl_/"

def get_module_name (ctx, src):
    ns = None
    if ctx.attr.ns:
        ns = ctx.attr.ns[OcamlNsModuleProvider].payload.ns

    parts = paths.split_extension(src.basename)
    if ctx.attr.module_name:
        module = ctx.attr.module_name
    else:
        module = parts[0]
        # module = parts[0]
        extension = parts[1]

    if ns == None: ## no ns
        # pfx = TMPDIR
        out_filename = module
    else:
        if ns.find("/") > 0:
            fail("ERROR: ns contains '/' : '%s'" % ns)
        else:
            if ns.lower() == module.lower():
                out_filename = module
            else:
                out_filename = capitalize_initial_char(ns) + ctx.attr.ns_sep + capitalize_initial_char(module)

    out_filename = out_filename + extension
    return out_filename

################################################################
def rename_module(ctx, src):  # , pfx):
  """Rename implementation and interface (if given) using prefix.

  Inputs: context, src
  Outputs: outfile :: declared File
  """

  # if module name == ns, then output module name
  # otherwise, outputp ns + "__" + module name

  out_filename = get_module_name(ctx, src)
  # if (module == ns):
  #   out_filename = module + extension
  # else:
  #   out_filename = ns + capitalize_initial_char(module) + extension
  # print("RENAMED MODULE %s" % out_filename)

  # if pfx.find("/") > 0:
  #   fail("ERROR: ns contains '/' : '%s'" % pfx)

  inputs  = []
  # outputs = []
  outputs = {}
  inputs.append(src)
  outfile = ctx.actions.declare_file(tmpdir + out_filename)

  destdir = paths.normalize(outfile.dirname)
  # print("DESTDIR: %s" % destdir)

  cmd = ""
  dest = outfile.path
  # print("DEST: %s" % dest)
  # cmd = cmd + "touch {dest}; ".format(dest = bindir + "/" + tmpdir + src.path)
  cmd = cmd + "mkdir -p {destdir} && cp {src} {dest} && ".format(
    src = src.path,
    destdir = destdir,
    dest = dest
  )

  cmd = cmd + " true;"
  # print("CMD: %s" % cmd)
  # print("CP SRCS")

  ctx.actions.run_shell(
    # env = env,
    command = cmd,
    inputs = inputs,
    outputs = [outfile],
    progress_message = "rename_src_action ({}){}".format(
      ctx.label.name, src
    )
  )
  return outfile

################################################################
# def to_libarg(lib):
#   return "'library-name=\"{}\"'".format(lib)