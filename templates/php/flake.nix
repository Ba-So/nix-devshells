{
  description = "PHP development environment";

  inputs = {
    # Import devshells flake
    devshells.url = "git+ssh://git@github.com/Ba-So/nixos-flakes?ref=main&dir=devshells";
  };

  outputs = {devshells, ...}: {
    # Forward only the PHP shell outputs
    inherit (devshells.php) devShells;
  };
}
