# 🤖 Swat Overflow 2.0 🤖
## ⚡️ Lessons Learned on CI Pipelines for NSO Services Development

This session will cover a collection of small tips and tricks for the development and delivery of **NSO services using CI pipelines**. These insights were gained through **hands-on experience** working with various customers and navigating the challenges and triumphs of establishing a reliable and meaningful CI process to ensure the quality of NSO packages. These pieces of advice are small in scope, but together they make a lot of sense - and might even be the push needed for any future project.

>  This collection of techniques was collected from real projects which take CI design for NSO services development very seriously.
Nevetheless, this does not intend to be a one-size-fits-all recommendations list. Each project has different scopes, infrastructure, tools available, budget, etc.

## 📚 Summary

In this fireside chat, we will briefly discuss the following topics:

- 🤖 Job definition using bash scripting
- 📃 ```docker-compose``` for NSO and other resources management
- 🔖 Features definition in yaml files
- 🔥 Job halting with meaninful checks
- 🔀 Enabling of dynamic parameters on each run
- 📦 Artifact building

## 🤖 Job definition using bash scripting

Definition of the entire CI pipeline with ```make``` commands that trigger small bash scripts.

* 👉🏽 [Our CI pipeline definition](https://github.com/ponchotitlan/embracing-devops-nso-usecase-lifecycle/blob/main/.github/workflows/ci.yml)
* 👉🏽 [Our Makefile](https://github.com/ponchotitlan/embracing-devops-nso-usecase-lifecycle/blob/main/Makefile)
* 👉🏽 [Our bash scripts collection](https://github.com/ponchotitlan/embracing-devops-nso-usecase-lifecycle/tree/main/pipeline/scripts)

👍🏽 Pros
- Your CI pipeline is more portable and can run on almost any standard system without additional configuration
- Bash is almost universally available on UNIX-like systems (Linux, macOS, etc.), which are commonly used for CI/CD environments
- Bash is inherently designed for running shell commands, which are often the backbone of CI pipelines
- Bash scripts are lightweight and have minimal overhead compared to Python
- It's easy to pass variables between steps or jobs, and to handle dynamic configurations

👎🏽 Cons
- Learning curve: More and more programmers are familiar with Python than with bash scripting
- If the logic becomes complex (e.g., conditionals, loops, or error handling), it can be tricky to make it work with bash syntax
- Robust error handling might become complicated with pure bash

## 📃 ```docker-compose``` for NSO and other resources management

{{ nso.container_name }} could be nso-get_current_branch()-get_build_number()