# jupyterhub-docker

# Building & Pushing Docker Images to ECR

The docker images in ECS are pulled by ECS from ECR. To push the images _to_ ECR, You can follow the usual `View Push Commands` instructions given in the AWS Console, _except_ that to build the notebook image, you must specify the correct Dockerfile with `-f Dockerfile-singleuser`, and for development work, be mindful to replace the `:latest` tag with a unique name.
