H. S. image and TZ server
=========================

This is a simple golang/gin webapp and prometheus server setup to
demonstrate certain bare-minimum components necessary to be able to
deploy today.

The components
--------------
* Lean web-framework with middleware capabilities (such as [Gin](https://github.com/gin-gonic/gin)).
* Instrumentation of HTTP handlers (etc.) (such as [Prometheus](https://prometheus.io)).
* Lean docker image of the runtime application.
* A *preferably* managed dockerised microservice-orchestrator service.
(such as kubernetes)
* A monitoring service which stores the instrumented numbers for
troubleshooting, analysis or dashboards.
* Usage of infrastructure automation tools such as Terraform or/and Ansible.

Choices
-------
* Gin as web-framework: my colleagues use this in our project and it
seemed familiar and simple enough to get started.
* Dockerfile: we use the 'scratch' image as far as possible and I was able
to find a more complete file (with non-root user and so on) to also include
the build stage inside docker itself.
* DigitalOcean: I've lost access to my personal AWS account! And I had
recently learnt that it offered a managed k8s service.
* Terraform: this is my go to tool for infra-layer automation. The creation
of the Droplet for Prometheus server was done with this. I later learnt
that even the k8s service could be managed with it but I had already
launched the service via DigitalOcean's web UI. And this terraform resource
doesn't support `import` yet.
* Ansible: usually I use this in conjunction with Packer to bake an AMI
in order to also reduce launch times in an autoscaling group by reducing
the amount of configuration that may otherwise be necessary in AWS
user-data stage. In this case, I used a public playbook hosted on
`ansible-galaxy` to install and configure Prometheus because it isn't
available as a `.deb` for Ubuntu. A docker-ised installation was also
an option.

Additional venues for scope-creep
---------------------------------
* More microservices:  for the H. S. image service and TZ service. Possibly
randomise H. S. images and make the TZ lookup more dynamic using
geographical distance. i.e. when one looks up for `/covilha`, the TZ service
doesn't need to hard-code the argument to the `time.LoadLocation()` call.
Instead, it could possibly look-up some kind of GEO database (possibly via
another microservice) to find the timezone it belongs to.
* Opentracing: overload the context in function flows to trace function
calls. Useful when there are several microservices.
* gRPC: for faster communication between the above microservices.
* Usage of a service-mesh: to offloaded repeated non-business logic code
outside of our application code such as circuit-breakers, transparent
TLS-encrypion between microservices.
* NOTE: several of these can be seen as additional overhead because it's
time-consuming to evaluate, understand, adopt, use in production and gain
business value out of it. These choices although technical, can eat into
the time which could otherwise be spent on delivering business value. 