# tf-aws-infra  

This is for assignment 9.  

1. Prerequisites  
Terraform CL  
AWS CLI  

2. AWS CLI Configuration  
Dev Profile: aws configure –profile dev  
Demo Profile: aws configure –profile demo  

3. Usage & Deployment  

terraform init  

# SSL Certificate for Demo Environment

The dev environment uses AWS ACM-issued certificates.

The demo environment MUST use a third-party certificate (ZeroSSL or Namecheap).
AWS ACM cannot be used for demo.

## Steps to request and install demo SSL certificate

1. Request a certificate from ZeroSSL for domain:
   demo.ibchiang.me

2. Complete DNS verification by adding the CNAME record  
   in the Demo Route53 Hosted Zone.

3. Download certificate zip from ZeroSSL.
   The zip contains:
   - certificate.crt
   - ca_bundle.crt
   - private.key

4. Import the certificate into AWS ACM (Demo Account):
   aws acm import-certificate
    --certificate fileb://certificate.crt
    --certificate-chain fileb://ca_bundle.crt
    --private-key fileb://private.key
    --region us-east-1
    --profile demo

5. Get the returned CertificateArn and update `demo.tfvars`:
   acm_certificate_arn = "arn:aws:acm:us-east-1:<acct>:certificate/<uuid>"

6. Apply Terraform for demo:
   terraform apply -var-file=demo.tfvars
   
    This will configure the ALB HTTPS listener to use the imported certificate.

