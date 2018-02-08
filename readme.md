## Introduction

Docker image to run API server to interact with OCI.

The server is providing rest API leveraging the following pyhton modules
* Flask --> microframework 
* Flask-RESTPlus --> Flask extension to build REST API
* python-terraform --> providea a wrapper of `terraform` command line tool

## Installation


```bash
    git clone ...
    ./build.sh
```    
## Uage
#### Run API Server
To run the server as daemon
```bash
    ./run-server.sh
    #API Server running on http://localhost:5000/
    
```

To run the server in interactive mode 

```bash
    ./run-server-interactive.sh
    #API Server running on http://localhost:5000/
    
```

The server will run ***terraform init*** on the provided directory at startup

### Available API
- _plan_
    
        shows an execution plan summary
- _apply_

        Builds or changes infrastructure according to Terraform configuration in the working directory
    ##### NOTE: this will apply the configuration without asking for confirmation
- _destroy_

        Destroy Terraform-managed infrastructure.
    ##### NOTE: this will destroy all without asking for confirmation

### Examples

```bash
$ curl http://localhost:5000/plan
{
    "plan": [
        "add oci_core_internet_gateway.internetgateway1", 
        "add oci_core_virtual_network.vcn1"
    ]
}
```
```bash
$ curl http://localhost:5000/apply
{
    "apply": "Apply complete! Resources: 2 added, 0 changed, 0 destroyed."
}
```
```bash
$ curl http://localhost:5000/destroy
{
    "destroy": "Destroy complete! Resources: 2 destroyed."
}
```



    

    
    