# Input validation tests: bad input must fail at plan time, before anything reaches the cluster.
mock_provider "kubernetes" {}

variables {
  name       = "app-data"
  namespace  = "team-a"
  nfs_server = "nfs.example.internal"
  nfs_path   = "/exports/app-data"
}

run "rejects_relative_nfs_path" {
  command = plan

  variables {
    nfs_path = "exports/app-data"
  }

  expect_failures = [var.nfs_path]
}

run "rejects_bad_capacity" {
  command = plan

  variables {
    capacity = "ten gigabytes"
  }

  expect_failures = [var.capacity]
}

run "rejects_unknown_access_mode" {
  command = plan

  variables {
    access_modes = ["ReadWriteSometimes"]
  }

  expect_failures = [var.access_modes]
}

run "rejects_invalid_name" {
  command = plan

  variables {
    name = "App_Data"
  }

  expect_failures = [var.name]
}
