output "public_route_table_name" {
  value = module.vpc.public_route_table_name
}

output "private_route_table_name" {
  value = module.vpc.private_route_table_name
}
