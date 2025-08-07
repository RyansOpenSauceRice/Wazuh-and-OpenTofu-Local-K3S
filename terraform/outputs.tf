output "wazuh_namespace" {
  description = "The namespace where Wazuh is deployed"
  value       = kubernetes_namespace.wazuh.metadata[0].name
}

output "wazuh_dashboard_service" {
  description = "The service name for Wazuh dashboard"
  value       = "wazuh-dashboard"
}

output "wazuh_master_service" {
  description = "The service name for Wazuh master"
  value       = "wazuh-manager-master"
}

output "wazuh_workers_service" {
  description = "The service name for Wazuh workers"
  value       = "wazuh-manager-worker"
}

output "wazuh_indexer_service" {
  description = "The service name for Wazuh indexer"
  value       = "wazuh-indexer"
}

output "dashboard_credentials" {
  description = "Credentials for Wazuh dashboard"
  value       = {
    username = "admin"
    password = random_password.dashboard_admin_password.result
  }
  sensitive = true
}

output "api_credentials" {
  description = "Credentials for Wazuh API"
  value       = {
    username = "wazuh-api"
    password = random_password.wazuh_api_password.result
  }
  sensitive = true
}

output "access_instructions" {
  description = "Instructions to access Wazuh dashboard"
  value       = <<-EOT
    To access the Wazuh dashboard:
    
    1. Run the following command to port-forward the Wazuh dashboard service:
       kubectl port-forward -n ${kubernetes_namespace.wazuh.metadata[0].name} svc/wazuh-dashboard 5601:5601
    
    2. Open your browser and navigate to:
       https://localhost:5601
    
    3. Default credentials:
       Username: admin
       Password: ${random_password.dashboard_admin_password.result}
       
    To access the Wazuh API:
    
    1. Run the following command to port-forward the Wazuh manager service:
       kubectl port-forward -n ${kubernetes_namespace.wazuh.metadata[0].name} svc/wazuh-manager-master 55000:55000
    
    2. You can now access the API at:
       https://localhost:55000
    
    3. API credentials:
       Username: wazuh-api
       Password: ${random_password.wazuh_api_password.result}
  EOT
}