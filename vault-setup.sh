vault auth enable approle
vault write auth/approle/role/vault-pipeline \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=10 \
	token_policies="rotate-own-secret-id"
	
vault read auth/approle/role/vault-pipeline/role-id
vault write -f auth/approle/role/vault-pipeline/secret-id

# substitute your correct approle mount accessor (from: vault auth list)
vault policy write rotate-own-secret-id - << EOF
path "auth/approle/role/{{identity.entity.aliases.<auth_approle_51dba4f3>.metadata.role_name}}/secret-id" {
  capabilities = [ "read","create","update","delete" ]
}
EOF

# test 
export VAULT_TOKEN=$(vault write -field=token auth/approle/login \
  role_id=bf231f34-7ae2-0256-d825-af9d9744fe00 \
  secret_id=63d48504-eb33-26e7-acfc-2f20341f77d6) 
vault write -f auth/approle/role/vault-pipeline/secret-id

