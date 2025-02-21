# Infraestructura en AWS con Terraform

Welcome al lab4 del bootcamp AWS hackaboss.

Este proyecto implementa una infraestructura robusta y escalable en AWS utilizando Terraform, alineándose con los seis pilares del AWS Well-Architected Framework e incorporando las mejores prácticas de AWS. El resultado es una infraestructura eficiente, segura y altamente disponible.

## Excelencia Operativa y Computación
- Infraestructura como código con Terraform, facilitando la automatización y gestión consistente.
- Instancias EC2 con Auto Scaling Group (ASG). àra gestioanr el tráfico.
- Application Load Balancer (ALB) para distribución del tráfico 
- Incluye un dashboard de CloudWatch para monitoreo y alertas.

## Seguridad y Redes
- VPC con subnets públicas y privadas para organización de recursos.
- NAT Gateway e Internet Gateway para control de tráfico.
- Grupos de seguridad configurados para la protección de servicios.
- Encriptación mediante AWS KMS y gestión de credenciales con AWS Secrets Manager.
- IAM para control de accesos y auditoría con CloudTrail.
- Configuración HTTPS para la navegación segura.
- VPC secundaria para backup de seguridad.

## Fiabilidad y Almacenamiento
- Elastic File System (EFS) para almacenamiento adaptable.
- Amazon S3 para imágenes y archivos estáticos.
- Base de datos PostgreSQL en Amazon RDS con alta disponibilidad y backups automáticos.
- Implementación en varias zonas de disponibilidad.

## Eficiencia de Rendimiento
- Cahé Redis en ElastiCache para optimización de rendimiento de la aplicación.
- Uso eficiente de S3.

## Optimización de Costos
- Autoscaling gorup para ajustar recursos según la demanda.
- Diferentes tipos de almacenamiento (S3, EFS, RDS) para adaptarse al contenido.

## Sostenibilidad
- Uso eficiente de los recursos a través del autoscaling group y optimización del rendimiento.

## Otros
- Amazon SNS para notificaciones.
- AWS Route 53 para gestión de dominios.
- Estado de Terraform almacenado en S3 con bloqueo en tabla DynamoDB para prevenir conflictos.

Pretende cumplir los objetivos de ser altamente disponible y segura. Permite despliegues automáticos y escalabilidad según las necesidades, facilitando la gestión y actualización de todos los componentes. 
El cumplimieto de los principios del well-Architected Framework asegura que la infraestructura cumple con las necesidades actuales y sienta la base para nuevas necesidades y crecimiento.


## **Archivos Incluidos**

### **1. Compute (`compute.tf`)**
- **Auto Scaling Group (ASG)**: instancias EC2 con escalado automático.
- **Application Load Balancer (ALB)**: balanceadores de carga públicos e internos.
- **Target Groups y Listeners**: el balanceo de tráfico y las reglas de enrutamiento HTTP.

### **2. Notificaciones (`notifications.tf`)**
- **Amazon SNS**: Envía notificaciones.
- **Suscripción por Email**: modo de notificación de las alertas.
- **CloudWatch Alarms**: Monitorea CPU y errores HTTP 5XX.
- **Notificaciones de Auto Scaling**: Reporta eventos de escalado de instancias.

### **3. Variables (`variables.tf`)**
- Configuración de parámetros generales como **nombre del proyecto, región de AWS, dominio interno y correo de alertas**.

### **4. Monitoreo (`monitoring.tf`)**
- **CloudWatch Dashboard**: Supervisa métricas clave como:
  - Uso de CPU en EC2.
  - Estado del balanceador de carga.
  - Funcionamiento de Redis, RDS y CloudFront.

### **5. CDN (`cdn.tf`)**
- **S3 Bucket**: contenedor de imágenes.
- **CloudFront**: Implementa una Content Delivery Network (CDN).
- **Encriptación y Políticas de Acceso**: protege los archivos almacenados.

### **6. Seguridad (`security.tf`)**
- **AWS KMS**: Gestiona la encriptación.
- **AWS Secrets Manager**: Almacena credenciales de PostgreSQL.
- **Generación de Contraseñas Seguras**.

### **7. Grupos de Seguridad (`security_groups.tf`)**
- Define reglas de seguridad para:
  - Balanceadores de carga.
  - Instancias EC2.
  - Almacenamiento EFS.
  - Redis y PostgreSQL.

### **8. Base de Datos (`database.tf`)**
- **AWS RDS**: Implementa una base de datos PostgreSQL.
- **Grupo de subredes para RDS**.
- **Backup y retención de datos**.

### **9. Cache (`cache.tf`)**
- **ElastiCache**: Configura Redis para caching.
- **Grupo de subredes** para mejorar la disponibilidad.

### **10. Almacenamiento (`storage.tf`)**
- **Elastic File System (EFS)**: Proporciona almacenamiento.
- **Mount Targets**: Conecta el EFS con subredes privadas.

### **11. DNS (`dns.tf`)**
- **Route 53**: Configura una zona DNS privada.
- **Registros DNS** para ALB interno y público.

### **12. IAM (`iam.tf`)**
- **Usuarios y roles IAM** para gestión de permisos.
- **CloudTrail**: Habilita auditoría y seguimiento de eventos en AWS.

### **13. Redes (`networking.tf`)**
- **VPC** principal y secundaria para alta disponibilidad.
- **Subnets públicas y privadas**.
- **NAT Gateway** y **Internet Gateway** para gestión de tráfico.
- **VPC Peering** para conectar redes privadas.

### **14. Backend (`backend.tf`)**
- **S3 Bucket** para almacenar el estado de Terraform.
- **DynamoDB** para bloquear applys simultáneas.

### **15. Proveedor (`provider.tf`)**
- **Configuración del proveedor AWS** indica a terraform cuál es el proveedor.
- **Versionado de Terraform y proveedores**.



## **Requisitos Previos**
- **Terraform instalado**.
- **Credenciales de AWS configuradas**.
- **Dominio registrado si se usa CloudFront**.

## **Cómo Usar**
1. Inicializar Terraform:
   ```sh
   terraform init
   ```
2. Previsualizar cambios:
   ```sh
   terraform plan
   ```
3. Aplicar cambios:
   ```sh
   terraform apply
   ```
4. Para eliminar la infraestructura:
   ```sh
   terraform destroy
   ```

** REpositorio en
https://github.com/leimber/AWS_structure
