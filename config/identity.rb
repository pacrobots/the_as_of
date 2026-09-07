# frozen_string_literal: true

# End-user identity (docs/design/end-user-identity.md) — the app's WHOLE
# auth surface. The framework is an OIDC Relying Party: point it at your
# IdP and never write a login form. The client SECRET goes in the
# credentials store (`lightyear credentials set oidc_client_secret …`),
# never here.
#
# Lightyear::Identity.issuer       = "https://your-idp.example.com"
# Lightyear::Identity.client_id    = "as_of"
# Lightyear::Identity.redirect_uri = "https://your-app.example.com/auth/callback"

# The viewer resolver — the ONE bridge from a verified session to YOUR
# person row. Until you declare it, `viewer` is the session itself (a fresh
# app can greet by display name before it has a user table).
#
# Lightyear::Identity.viewer_resolver = ->(session) {
#   User.find_by!(idp_subject: session.subject)
# }

# The login hook — your "four writes" moment: find-or-create your person
# row; mint the per-session Writ fencing your agent to this user's slice.
#
# Lightyear::Identity.on_login = ->(session) { … }
