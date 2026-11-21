{
  project,
  projectName,
  ...
}:
{
  config,
  ...
}:
{
  assertions = [
    {
      assertion = config.ozzie.lab.caddy.security.verificationKeyFile != null;
      message = "Project '${projectName}': caddy.security.verificationKeyFile is required for role 'authorization'";
    }
  ];

  ozzie.lab.caddy = {
    enable = true;

    security = {
      enable = true;

      authUrl = "https://${project.hostName}/auth/login";
      policies = project.policies or { };
    };
  };
}
