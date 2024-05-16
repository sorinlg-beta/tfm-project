resource "null_resource" "example" {
  triggers = {
    # This will cause the resource to be replaced
    always_run      = "${timestamp()}"
    product         = var.tfm_product
    repo            = var.tfm_repo
    module          = var.tfm_module
    env             = var.tfm_env
    module_instance = var.tfm_module_instance
  }
}
