output "wazuh_namespace" {
  description = "The namespace where Wazuh is deployed"
  value       = kubernetes_namespace.wazuh.metadata[0].name
}

output "wazuh_dashboard_service" {
  description = "The service name for Wazuh dashboard"
  value       = "wazuh-dashboard"
}

output "wazuh_manager_service" {
  description = "The service name for Wazuh manager"
  value       = "wazuh-manager"
}

output "wazuh_indexer_service" {
  description = "The service name for Wazuh indexer"
  value       = "wazuh-indexer"
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
       Password: admin
       
    Note: You should change the default password after the first login.
  EOT
}