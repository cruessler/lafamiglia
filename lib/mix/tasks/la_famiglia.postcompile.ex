defmodule Mix.Tasks.LaFamiglia.Postcompile do
  use Mix.Task

  alias LaFamiglia.Mechanics.Units

  @shortdoc "Compiles the Elm templates for the module `Mechanics`"

  @source_path "lib/mechanics"

  @template_path "assets/elm/Mechanics"

  @template_mappings %{"units.ex" => "Units.elm.eex"}

  def run(_) do
    Mix.shell().info("Compiling templates in #{@template_path} (.elm.eex)")

    for {source, template} <- @template_mappings do
      source = Path.join(@source_path, source)
      template = Path.join(@template_path, template)
      target = Path.join(@template_path, Path.basename(template, ".eex"))

      with {:ok, info_source} <- File.stat(source),
           {:ok, info_template} <- File.stat(template),
           {:ok, source_mtime} = NaiveDateTime.from_erl(info_source.mtime),
           {:ok, template_mtime} = NaiveDateTime.from_erl(info_template.mtime) do
        # Compile the template if either itself or the corresponding source
        # file has been changed or if the target file does not exist.
        compile =
          case File.stat(target) do
            {:ok, info_target} ->
              {:ok, target_mtime} = NaiveDateTime.from_erl(info_target.mtime)

              NaiveDateTime.compare(source_mtime, target_mtime) == :gt ||
                NaiveDateTime.compare(template_mtime, target_mtime) == :gt

            _ ->
              true
          end

        if compile do
          Mix.shell().info("Compiling #{Path.basename(template)} to #{Path.basename(target)}")

          compiled_file = EEx.eval_file(template, template_variables)

          File.write(target, compiled_file)

          Mix.shell().info("Running `elm-format` on #{Path.basename(target)}")

          Mix.shell().cmd("cd assets && npx elm-format --yes #{Path.join("..", target)}")
        else
          Mix.shell().info("Nothing to do for #{Path.basename(template)}")
        end
      end
    end
  end

  defp template_variables do
    [units: Units.units()]
  end
end
