# dotscience-tf

edit main.tf and set KeyName and AdminPassword

TODO: factor these out to inputs

Deploy the stack:
```
terraform apply
```

Grab the login URL:
```
terraform show |grep '"LoginURL" = "'
```

Log in and do some data science!

## TODO

- [ ] extract dotscience cft into native tf resources (hopefully enabling state-preserving upgrades)
