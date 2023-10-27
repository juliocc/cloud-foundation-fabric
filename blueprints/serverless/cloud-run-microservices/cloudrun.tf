/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Cloud Run services.

# Cloud Run service A
resource "google_cloud_run_v2_service" "svc_a" {
  project      = module.project_main.project_id
  name         = local.svc_a_name
  location     = var.region
  ingress      = "INGRESS_TRAFFIC_ALL"
  launch_stage = "BETA" # Required to use Direct VPC Egress
  template {
    containers {
      image = local.svc_a_image
    }
    dynamic "vpc_access" {
      for_each = var.prj_svc1_id == null ? [""] : []
      content { # Use Serverless VPC Access connector
        connector = google_vpc_access_connector.connector[0].id
      }
    }
    dynamic "vpc_access" {
      for_each = var.prj_svc1_id != null ? [""] : []
      content { # Use Direct VPC Egress
        network_interfaces {
          subnetwork = module.vpc_main.subnets["${var.region}/subnet-vpc-direct"].name
        }
      }
    }
  }
  # The container image is built and pushed to Artifact Registry by
  # a local-exec provisioner
  depends_on = [null_resource.image]
}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "svc_a_policy" {
  project     = module.project_main.project_id
  location    = var.region
  name        = google_cloud_run_v2_service.svc_a.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

# Cloud Run service B
module "cloud_run_svc_b" {
  source     = "../../../modules/cloud-run"
  project_id = try(module.project_svc1[0].project_id, module.project_main.project_id)
  name       = local.svc_b_name
  region     = var.region
  containers = {
    default = {
      image = var.image
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = "internal"
}

# Serverless VPC Access connector
# The use case where both Cloud Run services are in the same project uses
# a VPC access connector to connect from service A to service B.
# The use case with Shared VPC and internal ALB uses Direct VPC Egress.
resource "google_vpc_access_connector" "connector" {
  count   = var.prj_svc1_id == null ? 1 : 0
  name    = "connector"
  project = module.project_main.project_id
  region  = var.region
  subnet {
    name       = module.vpc_main.subnets["${var.region}/subnet-vpc-access"].name
    project_id = module.project_main.project_id
  }
}
