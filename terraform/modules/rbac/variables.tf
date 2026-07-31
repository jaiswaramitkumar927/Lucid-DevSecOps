resource "kubernetes_role" "developer" {

  metadata {
    name = "developer"
    namespace = "dev"
  }

  rule {

    api_groups = [""]

    resources = [

      "pods",

      "services",

      "configmaps"

    ]

    verbs = [

      "get",

      "list",

      "watch",

      "create",

      "update",

      "delete"

    ]
  }
}