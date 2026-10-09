terraform {
  required_version = ">= 1.5.0"
  required_providers {
    pingfederate = {
      source  = "pingidentity/pingfederate"
      version = "~> 1.5"
    }
  }
}

provider "pingfederate" {
  https_host                          = var.pf_admin_host
  admin_api_path                      = "/pf-admin-api/v1"
  username                            = var.pf_admin_username
  password                            = var.pf_admin_password
  # Verify the admin API's certificate against your CA (pf_admin_ca_pem_files).
  # Only a local PingFederate whose admin console still has the certificate it
  # made for itself needs pf_admin_insecure_tls = true (the quickstart sets it).
  insecure_trust_all_tls              = var.pf_admin_insecure_tls
  ca_certificate_pem_files            = var.pf_admin_ca_pem_files
  x_bypass_external_validation_header = true
  # Server is 13.1.0.5; highest version this provider release knows. Only used
  # for feature gating — everything used here exists in both.
  product_version = "13.0.0"
}

variable "pf_admin_insecure_tls" {
  description = "Skip verifying the admin API's TLS certificate. For a local PingFederate with its self-made certificate only."
  type        = bool
  default     = false
}
variable "pf_admin_ca_pem_files" {
  description = "PEM files of the CA(s) that issued the admin API's certificate."
  type        = set(string)
  default     = []
}
variable "pf_admin_host" {
  description = "PingFederate's admin API origin. docker-compose.yml publishes it on 127.0.0.1:$PF_ADMIN_PORT."
  type        = string
  default     = "https://localhost:9999"
}
variable "pf_admin_username" {
  type    = string
  default = "administrator"
}
variable "pf_admin_password" {
  type      = string
  sensitive = true
}
variable "form_login_pcv_id" {
  description = "The password credential validator behind the HTML form login the wallet and the portal sign holders in with: your directory's (LDAP, a PingDirectory, ...). Required unless Sign in with Apple replaces the form for every client that uses it."
  type        = string
  default     = null
}

locals {
  apc_wallet_identity_id = pingfederate_authentication_policy_contract.wallet_identity.id
}

# The validator the HTML form login checks passwords against. A local so an overlay
# can supply one it creates itself: the quickstart's quickstart_override.tf does.
locals {
  form_login_pcv_id = var.form_login_pcv_id
}

# ---------------------------------------------------------------------------
# HTML Form login (used when the wallet or the portal asks PF to authenticate
# the holder), against the validator local.form_login_pcv_id names.
# ---------------------------------------------------------------------------

resource "pingfederate_idp_adapter" "html_form" {
  adapter_id = "htmlFormAdapter"
  name       = "HTML Form Login"

  plugin_descriptor_ref = {
    id = "com.pingidentity.adapters.htmlform.idp.HtmlFormIdpAuthnAdapter"
  }

  configuration = {
    tables = [
      {
        name = "Credential Validators"
        rows = [
          {
            fields = [
              {
                name  = "Password Credential Validator Instance"
                value = local.form_login_pcv_id
              }
            ]
            default_row = false
          }
        ]
      }
    ]
    fields = []
  }

  lifecycle {
    precondition {
      condition     = local.form_login_pcv_id != null
      error_message = "The HTML form login needs a password credential validator: set form_login_pcv_id to your directory's."
    }
  }

  attribute_contract = {
    core_attributes = [
      { name = "policy.action" },
      { name = "username", masked = false, pseudonym = true },
    ]
  }

  attribute_mapping = {
    attribute_contract_fulfillment = {
      "policy.action" = { source = { type = "ADAPTER" }, value = "policy.action" }
      "username"      = { source = { type = "ADAPTER" }, value = "username" }
    }
  }
}

# ---------------------------------------------------------------------------
# Route authentication by OAuth client: the wallet gets the HTML form login,
# every other client (a relying party) signs in with a wallet presentation.
# ---------------------------------------------------------------------------

locals {
  # See the byOAuthClient rows below. An overlay may replace this value
  # (conformance/oidf/terraform/oidf_override.tf does, in the source repo).
  form_login_extra_client_ids = []
}

resource "pingfederate_authentication_selector" "by_oauth_client" {
  selector_id = "byOAuthClient"
  name        = "By OAuth Client"

  plugin_descriptor_ref = {
    id = "com.pingidentity.pf.selectors.oauthclient.OAuthClientAdapterSelector"
  }

  configuration = {
    tables = [
      {
        name = "Clients"
        rows = concat([
          # Clients that authenticate the user with the HTML form login (username
          # + password) rather than a wallet presentation: the wallet issuance
          # flow. The two operator consoles (issuer-console, verifier-console)
          # were rows here until 2026-09-24: their clients left PingFederate with
          # the TypeScript consoles on 2026-09-13, and PingFederate validates every
          # row on update, so the selector could not be changed at all until they
          # went ("Client ID issuer-console is not found", 422).
          {
            fields      = [{ name = "Client ID", value = pingfederate_oauth_client.wallet.client_id }]
            default_row = false
          }
          ],
          # Clients an overlay adds to the HTML form login. Empty in the product; the
          # source repo's conformance/oidf/terraform/oidf_override.tf sets it to the
          # OpenID Foundation conformance suite's clients, whose browser automation
          # can only fill a form.
          [for id in local.form_login_extra_client_ids : {
            fields      = [{ name = "Client ID", value = id }]
            default_row = false
          }],
          # The holder portal (portal_client.tf, G-92) signs in where the wallet
          # does: here when Apple is off, ahead of this tree in apple.tf when on.
          [for c in pingfederate_oauth_client.portal : {
            fields      = [{ name = "Client ID", value = c.client_id }]
            default_row = false
          }],
        )
      }
    ]
    fields = []
  }

}

resource "pingfederate_authentication_policies" "default" {
  fail_if_no_selection = false

  # The Apple tree comes first when Sign in with Apple is on (apple.tf): it takes the
  # wallet client before RouteByClient can send it to the HTML form.
  authn_selection_trees = concat(var.apple_login ? local.apple_selection_tree : [], [
    {
      name    = "RouteByClient"
      enabled = true

      root_node = {
        action = {
          authn_selector_policy_action = {
            authentication_selector_ref = {
              id = pingfederate_authentication_selector.by_oauth_client.id
            }
          }
        }
        children = [
          {
            # Not the wallet client: fall through to the next tree.
            action = {
              continue_policy_action = { context = "No" }
            }
          },
          {
            # The wallet client: local login at PF (issuance flow, with consent).
            action = {
              authn_source_policy_action = {
                context = "Yes"
                authentication_source = {
                  type       = "IDP_ADAPTER"
                  source_ref = { id = pingfederate_idp_adapter.html_form.id }
                }
              }
            }
            children = [
              {
                action = {
                  done_policy_action = { context = "Fail" }
                }
              },
              {
                action = {
                  apc_mapping_policy_action = {
                    context                            = "Success"
                    authentication_policy_contract_ref = { id = local.apc_wallet_identity_id }
                    attribute_mapping = {
                      attribute_sources = []
                      attribute_contract_fulfillment = {
                        subject = {
                          source = { type = "ADAPTER", id = pingfederate_idp_adapter.html_form.id }
                          value  = "username"
                        }
                        # A password login vouches for a username and nothing about
                        # the person: their names and date of birth come from the
                        # identity store, where the issuer reads them (HolderSubject).
                        given_name  = { source = { type = "NO_MAPPING" } }
                        family_name = { source = { type = "NO_MAPPING" } }
                        birthdate   = { source = { type = "NO_MAPPING" } }
                        # A password login vouches for no email address.
                        email          = { source = { type = "NO_MAPPING" } }
                        email_verified = { source = { type = "NO_MAPPING" } }
                      }
                    }
                  }
                }
              },
            ]
          },
        ]
      }
    },
    {
      # Fallthrough for every other client (a relying party): wallet presentation
      # login, now the native vpWalletLogin adapter (design/pf-servlets.md
      # §2.1) instead of the standalone verifier's OIDC OP facade.
      name    = "SignInWithWallet"
      enabled = true

      root_node = {
        action = {
          authn_source_policy_action = {
            authentication_source = {
              type       = "IDP_ADAPTER"
              source_ref = { id = pingfederate_idp_adapter.vp_wallet_login.id }
            }
          }
        }
        children = [
          {
            action = {
              done_policy_action = { context = "Fail" }
            }
          },
          {
            action = {
              apc_mapping_policy_action = {
                context                            = "Success"
                authentication_policy_contract_ref = { id = local.apc_wallet_identity_id }
                attribute_mapping = {
                  attribute_sources = []
                  attribute_contract_fulfillment = {
                    # VpAdapter's contract has no "username"/subject attribute
                    # (unlike htmlFormAdapter, whose PF-built-in descriptor
                    # declares one), and PF's EXPRESSION/OGNL context here
                    # doesn't resolve the adapter's raw attributes either
                    # (tried; "Invalid attribute: family_name" even for a
                    # plain declared name) — so subject sources directly from
                    # the adapter's family_name, the same plain ADAPTER
                    # pattern used for given_name/birthdate below.
                    subject = {
                      source = { type = "ADAPTER", id = pingfederate_idp_adapter.vp_wallet_login.id }
                      value  = "family_name"
                    }
                    given_name = {
                      source = { type = "ADAPTER", id = pingfederate_idp_adapter.vp_wallet_login.id }
                      value  = "given_name"
                    }
                    family_name = {
                      source = { type = "ADAPTER", id = pingfederate_idp_adapter.vp_wallet_login.id }
                      value  = "family_name"
                    }
                    birthdate = {
                      source = { type = "ADAPTER", id = pingfederate_idp_adapter.vp_wallet_login.id }
                      value  = "birthdate"
                    }
                    # A presented credential is not an email verification.
                    email          = { source = { type = "NO_MAPPING" } }
                    email_verified = { source = { type = "NO_MAPPING" } }
                  }
                }
              }
            }
          },
        ]
      }
    },
  ])
}

locals {
  apple_selection_tree = [
    {
      # Front tree: the console + wallet OAuth clients authenticate via Sign in
      # with Apple. Any other client falls through ("No") to the trees below,
      # so a relying party (wallet presentation) is unaffected.
      name    = "ConsoleWalletApple"
      enabled = true

      root_node = {
        action = {
          authn_selector_policy_action = {
            authentication_selector_ref = {
              id = one(pingfederate_authentication_selector.console_apple[*].id)
            }
          }
        }
        children = [
          {
            action = {
              continue_policy_action = { context = "No" }
            }
          },
          {
            action = {
              authn_source_policy_action = {
                context = "Yes"
                authentication_source = {
                  type       = "IDP_CONNECTION"
                  source_ref = { id = one(pingfederate_sp_idp_connection.apple[*].id) }
                }
              }
            }
            children = [
              {
                action = {
                  done_policy_action = { context = "Fail" }
                }
              },
              {
                action = {
                  apc_mapping_policy_action = {
                    context                            = "Success"
                    authentication_policy_contract_ref = { id = local.apc_wallet_identity_id }
                    attribute_mapping = {
                      attribute_sources = []
                      attribute_contract_fulfillment = {
                        subject = {
                          source = { type = "IDP_CONNECTION", id = one(pingfederate_sp_idp_connection.apple[*].id) }
                          value  = "sub"
                        }
                        # Apple returns sub, and with the email scope the address and
                        # whether Apple verified it (apple.tf); no name or birth date.
                        given_name  = { source = { type = "TEXT" }, value = "Apple" }
                        family_name = { source = { type = "TEXT" }, value = "User" }
                        birthdate   = { source = { type = "TEXT" }, value = "1970-01-01" }
                        email = {
                          source = { type = "IDP_CONNECTION", id = one(pingfederate_sp_idp_connection.apple[*].id) }
                          value  = "email"
                        }
                        email_verified = {
                          source = { type = "IDP_CONNECTION", id = one(pingfederate_sp_idp_connection.apple[*].id) }
                          value  = "email_verified"
                        }
                      }
                    }
                  }
                }
              },
            ]
          },
        ]
      }
    },
  ]
}
