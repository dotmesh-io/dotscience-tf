init:
	terraform init

validate:
	terraform validate

apply:
	terraform apply -var-file=inputs.tfvars

plan:
	terraform plan -var-file=inputs.tfvars

destroy:
	terraform destroy -var-file=inputs.tfvars

clean:
	rm -rf terraform.tfstate terraform.tfstate.*
