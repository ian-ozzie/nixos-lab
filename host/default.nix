{
  lib,
  ...
}:
{
  options.ozzie.lab.host = {
    bind = {
      ip = lib.mkOption {
        default = "127.0.0.1";
        description = "IP to bind services to";
        type = lib.types.str;
      };

      domain = lib.mkOption {
        default = "localhost";
        description = "Hostname to bind services to";
        type = lib.types.str;
      };
    };
  };
}
