# Sample Terraform project using tf-manage (tfm)

This is a sample project that demonstrates how to use tf-manage (tfm) to manage Terraform projects.

## Requirements
- [Ensure tf-manage requirements are met](https://github.com/sorinlg/tf-manage?tab=readme-ov-file#requirements)
- [Install tf-manage](https://github.com/sorinlg/tf-manage?tab=readme-ov-file#installation)
```bash
export _desired_terraform_version='1.8.1'
cd some_path
git clone git@github.com:sorinlg/tf-manage.git
cd tf-manage
./bin/tf_install.sh "${_desired_terraform_version}"
```

## Usage
### Plain local usage
```bash
# direct references
tf project1 sample_module dev instance_x init
tf project1 sample_module dev instance_x plan
tf project1 sample_module dev instance_x apply_plan

# discoverable references
tf [TAB] [TAB] # bash completion will guide you
```

### A more generic readme
Since we have a generic interface, we can prepare the elements and switch contexts easily with env vars. Either for local usage or under CI.
```bash
tf <product> <module> <env> <module_instance> <action> [workspace]
```

```bash
# choose product
export _product='project1'
export _product='project2'

# choose module
export _module='sample_module'

# choose env
export _env='dev'
export _env='staging'
export _env='prod'

# choose module_instance
export _module_instance='instance_x'
export _module_instance='instance_y'
export _module_instance='instance_z'

# general workflow
## init
tf "${_product}" "${_module}" "${_env}" "${_module_instance}" init

## generate a plan. This will also create a plan file
tf "${_product}" "${_module}" "${_env}" "${_module_instance}" plan

## apply the plan file generated by the previous step
tf "${_product}" "${_module}" "${_env}" "${_module_instance}" apply_plan

## alternatively, you can combine the previous two steps
## this will generate a plan and apply it in one go, after confirmation
tf "${_product}" "${_module}" "${_env}" "${_module_instance}" apply

# misc usecases
## passing arbitrary flags to terraform can be done by quoting the last argument and including those flags
## init -reconfigure
tf "${_product}" "${_module}" "${_env}" "${_module_instance}" 'init -reconfigure'

## dynamic values can also be passed if you use double quotes
export backend_flags="-backend-config=bucket=${BUCKET}"
tf "${_product}" "${_module}" "${_env}" "${_module_instance}" "init ${backend_flags}"

## alternatively use environment variables that terraform naturally supports
export TF_VAR_foo='bar'
tf "${_product}" "${_module}" "${_env}" "${_module_instance}" plan
# will pass -var foo=bar to terraform
```
