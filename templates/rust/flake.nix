{
  description = "Rust development environment";

  inputs = {
    # Import devshells flake
    devshells.url = "git+ssh://git@github.com/Ba-So/nixos-flakes?ref=main&dir=devshells";
  };

  outputs = {devshells, ...}: {
    # Forward only the Rust shell outputs
    inherit (devshells.rust) devShells;
  };
}
