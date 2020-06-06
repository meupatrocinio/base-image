VERSION  = $(shell git describe --tags)
IMAGE_NAME  = flyimg-base-image
IMAGE_PATH = meupatrocinio/$(IMAGE_NAME):$(VERSION)

build:
	docker build -t $(IMAGE_NAME) .

push: build
	docker tag $(IMAGE_NAME) $(IMAGE_PATH)
	docker push $(IMAGE_PATH)
	@echo "PUSHED ${IMAGE_PATH}"
