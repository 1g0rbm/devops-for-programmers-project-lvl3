init:
	terraform -chdir=terraform init --backend-config=backend.conf
	make install-ansible-requirements

install-ansible-requirements:
	ansible-galaxy role install -r ansible/requirements.yml
	ansible-galaxy collection install -r ansible/requirements.yml

deploy-infra:
	terraform -chdir=terraform apply

destroy-infra:
	terraform -chdir=terraform destroy

deploy-app:
	ansible-playbook -i ansible/hosts -v --vault-password-file ansible/vault-password ansible/playbook.yml

vault-set-password:
	echo "$(PASSWORD)" > ansible/vault-password

vault-encrypt:
	ansible-vault encrypt $(FILE) --vault-password-file ansible/vault-password

vault-decrypt:
	ansible-vault decrypt $(FILE) --vault-password-file ansible/vault-password

vault-edit:
	ansible-vault edit $(FILE) --vault-password-file ansible/vault-password
