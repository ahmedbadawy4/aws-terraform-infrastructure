# Variables
TERRAFORM_DIR = atlantis-server/terraform
ANSIBLE_DIR = atlantis-server/ansible
ANSIBLE_PLAYBOOK = $(ANSIBLE_DIR)/atlantis-playbook.yaml
EC2_IP_FILE = ec2_ip.txt
GENERATED_INVENTORY = $(ANSIBLE_DIR)/inventory.generated.ini
PRIVATE_KEY ?= /path/to/your/private-key.pem

.PHONY: atlantis-infra atlantis-config clean

# Terraform init, apply, and save the EC2 instance IP
atlantis-infra:
	@echo "Initializing Terraform..."
	terraform -chdir=$(TERRAFORM_DIR) init
	@echo "Applying Terraform to create the Atlantis EC2 instance..."
	terraform -chdir=$(TERRAFORM_DIR) apply -auto-approve
	@echo "Fetching EC2 instance IP..."
	terraform -chdir=$(TERRAFORM_DIR) output -raw atlantis_server_public_ip > $(EC2_IP_FILE)
	@echo "EC2 instance IP saved to $(EC2_IP_FILE)"

# Build an inventory from the saved IP and run the Ansible playbook
atlantis-config:
	@echo "Running the Ansible playbook on $$(cat $(EC2_IP_FILE))..."
	@printf '[atlantis]\n%s ansible_user=ec2-user ansible_ssh_private_key_file=%s ansible_ssh_common_args="-o StrictHostKeyChecking=accept-new"\n' "$$(cat $(EC2_IP_FILE))" "$(PRIVATE_KEY)" > $(GENERATED_INVENTORY)
	ansible-playbook -i $(GENERATED_INVENTORY) $(ANSIBLE_PLAYBOOK)

# Remove the temporary files
clean:
	@rm -f $(EC2_IP_FILE) $(GENERATED_INVENTORY)
	@echo "Cleaned up temporary files."
