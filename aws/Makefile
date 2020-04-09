install-plugin:
	bash ../scripts/install-plugin.sh

init: install-plugin
	terraform init

validate:
	terraform validate

apply:
	terraform apply -var-file=inputs.tfvars -auto-approve

plan:
	terraform plan -var-file=inputs.tfvars

destroy:
	terraform destroy -var-file=inputs.tfvars -auto-approve

clean:
	rm -rf .terraform terraform.tfstate terraform.tfstate.*
