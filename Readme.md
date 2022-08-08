# Public Actions

## get-params

Pulls arbitrary parameters out of AWS SSM and Secrets Manager and puts them in environment variables,
taking care to mask secret values. 

Ideal for use with [OIDC](https://github.com/aws-actions/configure-aws-credentials).

Example:

```yaml
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v1
    with:
      role-to-assume: arn:aws:iam::111111111111:role/my-github-actions-role
      aws-region: us-east-1
  - name: Get build parameters
    uses: hack-edu/public-actions/get-params@main
    with:
      secrets:
        FOO: path/to/my-secret
      params:
        BAR: /normal/param
        BAZ: /secret-string/param
  - run: |
      echo "BAR: ${BAR}"
      echo "BAZ(value will be ****): ${BAZ}"
      echo "FOO: ${FOO}"

      echo "BAZ=" >> $GITHUB_ENV  # hide the secret from subsequent steps 
```

NOTE: [Debug logging](https://docs.github.com/en/actions/managing-workflow-runs/enabling-debug-logging) 
will print parameter values, but secrets will remain masked.

## update-images

Updates images in a kustomization.yaml file using output from skaffold build.

An image mapping is required to match up the image name from skaffold yaml to 
the image to update in kustomize. 

By default, skaffold build is run to build the images and output tags
according to your config. If you want bypass `skaffold build`
you can pass build-json.

This action does not commit the changes back to the repo, that can be
accomplished by some other action.


Example:

```yaml
      - name: Build & Update Image
        uses: hack-edu/public-actions/update-images@main
        with:
          working-directory: kustomize/
          image-mapping: |
            placeholder-for-image: my-image$
```

`image-mapping` is a YAML mapping from the kustomize image name to a regular
expression that matches the image name from skaffold.

Given the above example and the following skaffold.yaml file:

```yaml
apiVersion: skaffold/v1beta1
kind: Config
metadata:
    name: example
build:
    artifacts:
    - image: my-repository/my-image
```

Will generate this update:

```shell
kustomize edit set image placeholder-for-image=my-repository/my-image:generate-tag@sha256:<hash>
```
