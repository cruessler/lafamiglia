defmodule Mix.Tasks.LaFamiglia.Postcompile do
  use Mix.Task

  alias LaFamiglia.Mechanics.Units

  @shortdoc "Compiles the Elm templates for the module `Mechanics`"

  @source_path "lib/mechanics"

  @template_path "web/static/elm/Mechanics"

  @template_mappings %{"units.ex" => "Units.elm.eex"}

  def run(_) do
    Mix.shell.info "Compiling templates in #{@template_path} (.elm.eex)"

    for {source, template} <- @template_mappings do
      source   = Path.join(@source_path, source)
      template = Path.join(@template_path, template)
      target   = Path.join(@template_path, Path.basename(template, ".eex"))

      with {:ok, info_source}   <- File.stat(source),
           {:ok, info_template} <- File.stat(template),
           {:ok, info_target}   <- File.stat(target),
           source_mtime   = Ecto.DateTime.from_erl(info_source.mtime),
           template_mtime = Ecto.DateTime.from_erl(info_template.mtime),
           target_mtime   = Ecto.DateTime.from_erl(info_target.mtime)
      do
        # Compile the template if either itself or the corresponding source
        # file has been changed.
        if Ecto.DateTime.compare(source_mtime, target_mtime) == :gt ||
           Ecto.DateTime.compare(template_mtime, target_mtime) == :gt
        do
          Mix.shell.info "Compiling #{Path.basename template} to #{Path.basename target}"

          compiled_file = EEx.eval_file(template, template_variables)

          File.write(target, compiled_file)

          Mix.shell.info "Running `elm format` on #{Path.basename target}"

          Mix.shell.cmd "elm format --yes #{target}"
        else
          Mix.shell.info "Nothing to do for #{Path.basename template}"
        end
      end
    end
  end

  defp template_variables do
    [units: Units.units]
  end
end