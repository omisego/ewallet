# This is the seeding script for User (admin & viewer users).
import EWalletDB.Helpers.Crypto, only: [generate_key: 1]
alias EWallet.{CLI, Seeder}
alias EWalletDB.{Account, Membership, Role, User}

CLI.info("Seeding admin panel users...")

admin_seeds = [
  # Seed an admin user for each account
  %{email: "admin_brand1@example.com", password: generate_key(16), metadata: %{}},
  %{email: "admin_brand2@example.com", password: generate_key(16), metadata: %{}},
  %{email: "admin_branch1@example.com", password: generate_key(16), metadata: %{}},
  %{email: "admin_branch2@example.com", password: generate_key(16), metadata: %{}},
  %{email: "admin_branch3@example.com", password: generate_key(16), metadata: %{}},
  %{email: "admin_branch4@example.com", password: generate_key(16), metadata: %{}},

  # Seed a viewer user for each account
  %{email: "viewer_master@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_brand1@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_brand2@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_branch1@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_branch2@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_branch3@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_branch4@example.com", password: generate_key(16), metadata: %{}},
]

# Note that we use `account_name` instead of the account's `id` because
# the `id` is autogenerated, so we cannot know the `id` before hand.
memberships = [
  # Assign the admin user to its account
  %{email: "admin_master@example.com", role_name: "admin", account_name: "master_account"},
  %{email: "admin_brand1@example.com", role_name: "admin", account_name: "brand1"},
  %{email: "admin_brand2@example.com", role_name: "admin", account_name: "brand2"},
  %{email: "admin_branch1@example.com", role_name: "admin", account_name: "branch1"},
  %{email: "admin_branch2@example.com", role_name: "admin", account_name: "branch2"},
  %{email: "admin_branch3@example.com", role_name: "admin", account_name: "branch3"},
  %{email: "admin_branch4@example.com", role_name: "admin", account_name: "branch4"},

  # Assign the viewer user to its account
  %{email: "viewer_master@example.com", role_name: "viewer", account_name: "master_account"},
  %{email: "viewer_brand1@example.com", role_name: "viewer", account_name: "brand1"},
  %{email: "viewer_brand2@example.com", role_name: "viewer", account_name: "brand2"},
  %{email: "viewer_branch1@example.com", role_name: "viewer", account_name: "branch1"},
  %{email: "viewer_branch2@example.com", role_name: "viewer", account_name: "branch2"},
  %{email: "viewer_branch3@example.com", role_name: "viewer", account_name: "branch3"},
  %{email: "viewer_branch4@example.com", role_name: "viewer", account_name: "branch4"},
]

Enum.each(admin_seeds, fn(data) ->
  with nil <- User.get_by_email(data.email),
       {:ok, user} <- User.insert(data)
  do
    CLI.success("🔧 Admin Panel user inserted:\n"
      <> "  Email    : #{user.email}\n"
      <> "  Password : #{data.password || '<hashed>'}\n"
      <> "  ID       : #{user.id}\n")
  else
    %User{} = user ->
      CLI.warn("🔧 Admin Panel user already exists:\n"
        <> "  Email    : #{user.email}\n"
        <> "  Password : #{data.password || '<hashed>'}\n"
        <> "  ID       : #{user.id}\n")
    {:error, changeset} ->
      CLI.error("🔧 Admin Panel user #{data.email} could not be inserted:")
      Seeder.print_errors(changeset)
  end
end)

CLI.info("Seeding admin panel user roles...")

Enum.each(memberships, fn(membership) ->
  with %User{} = user       <- User.get_by_email(membership.email),
       %Account{} = account <- Account.get_by_name(membership.account_name),
       %Role{} = role       <- Role.get_by_name(membership.role_name),
       {:ok, _}             <- Membership.assign(user, account, role)
  do
    CLI.success("🔧 Admin Panel user assigned:\n"
      <> "  Email   : #{user.email}\n"
      <> "  Account : #{account.name}\n"
      <> "  Role    : #{role.name}\n")
  else
    {:error, changeset} ->
      CLI.error("🔧 Admin Panel user #{membership.email} could not be assigned:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("🔧 Admin Panel user #{membership.email} could not be assigned:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
