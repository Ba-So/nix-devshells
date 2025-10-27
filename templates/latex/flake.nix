{
  description = "LaTeX development environment";

  inputs = {
    # Import devshells flake
    devshells.url = "git+ssh://git@github.com/Ba-So/nixos-flakes?ref=main&dir=devshells";
  };

  outputs = {devshells, ...}: {
    # Forward only the LaTeX shell outputs
    inherit (devshells.latex) devShells;
  };
}
