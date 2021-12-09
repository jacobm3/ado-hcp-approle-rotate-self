vault auth enable approle

# 44640m = 31 days
vault write auth/approle/role/vault-pipeline \
    token_num_uses=10 \
    token_ttl=60m \
    token_max_ttl=30m \
    secret_id_num_uses=1 \
    secret_id_ttl=44640m \
    token_policies="rotate-own-secret-id,secret-by-role-name"

vault read auth/approle/role/vault-pipeline/role-id
vault write -f auth/approle/role/vault-pipeline/secret-id

# substitute your correct approle mount accessor (from: vault auth list)
vault policy write rotate-own-secret-id - << EOF
path "auth/approle/role/{{identity.entity.aliases.APPROLE_MOUNT_ACCESSOR.metadata.role_name}}/secret-id" {
  capabilities = [ "read","create","update" ]
}
EOF

vault policy write secret-by-role-name - << EOF
path "secret/data/{{identity.entity.aliases.APPROLE_MOUNT_ACCESSOR.metadata.role_name}}/*" {
  capabilities = [ "read","create","update","delete","list" ]
}
EOF

# test 
export VAULT_TOKEN=$(vault write -field=token auth/approle/login \
  role_id=bf231f34-7ae2-0256-d825-af9d9744fe00 \
  secret_id=63d48504-eb33-26e7-acfc-2f20341f77d6) 
vault write -f auth/approle/role/vault-pipeline/secret-id


# Existing secret ID accessors can be listed like this - 
vault list auth/approle/role/vault-pipeline/secret-id

# Individual accessors can be read like this - 
vault write auth/approle/role/vault-pipeline/secret-id-accessor/lookup secret_id_accessor=1c62e8e4-c66c-f190-ce4f-47db8266bf94
Key                   Value
---                   -----
cidr_list             <nil>
creation_time         2021-12-09T06:30:25.973346132Z
expiration_time       0001-01-01T00:00:00Z
last_updated_time     2021-12-09T13:55:19.339133055Z
metadata              map[]
secret_id_accessor    1c62e8e4-c66c-f190-ce4f-47db8266bf94
secret_id_num_uses    7
secret_id_ttl         0s
token_bound_cidrs     []

# Delete an existing secret-id by its accessor
vault write auth/approle/role/vault-pipeline/secret-id-accessor/destroy \
  secret_id_accessor=1c62e8e4-c66c-f190-ce4f-47db8266bf94

# Delete all secret-ids
for x in $(vault list -format=json auth/approle/role/vault-pipeline/secret-id | jq -r '.[]'); do
  vault write auth/approle/role/vault-pipeline/secret-id-accessor/destroy \
    secret_id_accessor=$x
done

# Revoke the Vault token once no longer needed in the pipeline
vault token revoke -self
