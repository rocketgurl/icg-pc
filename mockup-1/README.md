# Policy Central

## You'll want to set up an Apache vhost similar to:
    <VirtualHost *:80>
        DocumentRoot "/Library/WebServer/Documents/arc90/insight/policycentral/"
        ServerName dev.policycentral
    
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !^/.*
        RewriteRule /^([A-Za-z]+)/([0-9]+)$ /$1.html?policy=$2 [L]
    </VirtualHost>