install-plugin:
	bash ../scripts/install-plugin.sh

validate:
	terraform validate

update-gcp-mi:
  # TODO: point to either the latest or the latest tagged release URL
	curl https://storage.googleapis.com/dotscience-amis/latest/hub-gcp-image-d552006adc14485a722bf1910b3b2048adab75fa.tfvars.json > terraform.tfvars.json

apply:
	terraform apply -var-file=inputs.tfvars -auto-approve
	
destroy:
	terraform destroy -var-file=inputs.tfvars -auto-approve

init: install-plugin
	terraform init

plan:
	terraform plan -var-file=inputs.tfvars

clean:
	rm -rf .terraform terraform.tfstate terraform.tfstate.*
