{
  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;

    defaults = {
      dnsPropagationCheck = true;
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = "/data/services/acme/.env";
      group = "acme";
    };
  };
}
