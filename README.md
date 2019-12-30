# dotscience-tf

edit variables.tf and set `dotscience_hub_ssh_key` and `dotscience_hub_admin_password`

Deploy the stack:
```
terraform apply
```

Grab the login URL:
```
terraform show |grep '"LoginURL" = "'
```

Log in and do some data science!
