# Kernel-level hardening: network stack, memory, pointers.
{ ... }:
{
  boot.kernel.sysctl = {
    # -- Network stack --
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;
    "net.ipv4.conf.all.log_martians" = true;
    "net.ipv4.conf.all.rp_filter" = 1;

    # -- Memory / pointer --
    "kernel.kptr_restrict" = 2;
    "kernel.sysrq" = 0;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.suid_dumpable" = 0;

    # -- BPF --
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
  };

  # Disable rarely-used network protocol modules (reduce attack surface)
  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
  ];
}
