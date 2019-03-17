.PHONY:	build push deploy tf-plan tf-apply

HUB=nareshov
IMAGE=hsimp
TAG=v0.0.1

build:
	docker build . -t $(HUB)/$(IMAGE):$(TAG)

push: build
	docker push $(HUB)/$(IMAGE):$(TAG)

deploy:
	sed s%IMAGE_TAG_PLACEHOLDER%$(HUB)/$(IMAGE):$(TAG)% _deploy/*.yaml | kubectl apply -f - --record

tf-init:
	cd _prometheus; terraform init; cd -

tf-plan: tf-init
	cd _prometheus; terraform plan \
		-var "do_token=$(DO_PAT)" \
		-var "ssh_pub_key=$(SSH_PUB_KEY)" ; cd -

tf-apply:
	cd _prometheus; terraform apply \
		-var "do_token=$(DO_PAT)" \
		-var "ssh_pub_key=$(SSH_PUB_KEY)" ; cd -

run-ansible:
	cd _prometheus; ansible-playbook -i hosts prometheus.yaml ; cd -