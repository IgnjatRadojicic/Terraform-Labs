# Terraform Labs

Hands-on practice labs for the HashiCorp Terraform Associate (004) exam. Each lab is a problem statement you solve yourself, with a reference solution kept in a separate directory so you do not spoil it by accident.

These labs exist because reading about Terraform and writing Terraform are different skills. The exam tests the second one.

## The two tracks

The repository is split into two tracks with deliberately different execution models. This distinction matters more than anything else here.

| Track | Runs against | Applied? | What it is for |
|---|---|---|---|
| **AWS** | LocalStack in Docker | Yes, fully | State, imports, drift, destroy behaviour, the complete lifecycle |
| **Azure** | Your real Azure account | **Never** | Configuration structure, resource graphs, provider differences |

**The Azure track is plan-only.** You write configuration and run `terraform validate` and `terraform plan`, then stop. Running `terraform apply` on an Azure lab would attempt to provision real, billable resources in your own subscription. Every Azure lab carries this warning, and no Azure lab has success criteria that require an apply.

The AWS track costs nothing and touches no real AWS account. LocalStack emulates the AWS API inside a Docker container on your machine.

Either track can be done on its own. If you only want one, start with AWS, since it covers more of the exam.

## Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| Terraform CLI | 1.10 or later | Both tracks |
| Docker | Any recent version | AWS track only |
| Azure CLI | Any recent version | Azure track only |

Terraform 1.10 is the floor because later labs use `removed` blocks (1.7) and ephemeral values (1.10). Earlier versions will fail to parse those configurations rather than giving a useful error.

Python is optional. It provides `tflocal`, a convenience wrapper covered in `SETUP-AWS.md`.

## Repository layout

```
terraform-labs/
├── README.md              You are here
├── SETUP-AWS.md           Get LocalStack running and verified
├── SETUP-AZURE.md         Authenticate Azure CLI, and the safety rules
├── WORKFLOW.md            How to actually work through a lab
├── PROGRESS.md            Lab index, difficulty, and your completion status
├── docker-compose.yml     LocalStack stack for the AWS track
├── problems/
│   ├── aws/               Problem statements, and starter files where useful
│   └── azure/
└── solutions/
    ├── aws/               Reference solutions with explanations
    └── azure/
```

## How to start

1. Set up your track: `SETUP-AWS.md` or `SETUP-AZURE.md`. Both end with a verification step, so you will know the setup worked before you hit a lab.
2. Read `WORKFLOW.md`. It is short, and it explains how to get value out of a lab rather than just finishing it.
3. Open `PROGRESS.md` and pick the first unchecked lab in tier order.

## A warning about `solutions/`

That directory contains complete answers. Reading a solution before making a genuine attempt converts a lab from practice into passive reading, and passive reading is what you are presumably trying to supplement.

Each problem statement includes three progressive hints. Use those first. `WORKFLOW.md` suggests when to reach for each one.
