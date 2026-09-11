# Workflow

How to actually work through a lab. This is short, and following it is the difference between practice and passive reading.

## 1. Pick a lab

Open `PROGRESS.md` and take the first unchecked lab in tier order.

Tier order matters. Tier 3 labs assume you are fluent with `for_each` and complex types, which is what Tier 2 builds. Skipping ahead produces the specific kind of stuck where you cannot tell whether you are confused about the new concept or the old one.

## 2. Read PROBLEM.txt completely before writing anything

All of it, including `CONSTRAINTS` and `SUCCESS CRITERIA`.

The constraints exist to force the intended learning, and they frequently rule out the first approach that comes to mind. Discovering that after you have written the configuration means throwing it away. A constraint like "use `for_each`, not `count`" is not a style preference. It is the entire lesson.

## 3. Create a working directory outside the repository

Do not write your attempt inside `problems/`. Use a scratch directory somewhere else, or the gitignored `work/` folder at the repository root:

```bash
mkdir -p work/aws-lab-01
cd work/aws-lab-01
```

This keeps your attempts separate from the problem statements, so you can redo a lab later from a clean slate, and so nothing half-finished ends up committed.

Where a lab provides starter files, copy them in rather than editing the originals:

```bash
cp ../../problems/aws/lab-01-provider-and-first-resource/*.tf .
```

## 4. Use the hints in order

Every problem statement has three hints, written to reveal progressively:

| Hint | What it gives you |
|---|---|
| 1 | Points at the right area of the documentation |
| 2 | Names the specific construct |
| 3 | Shows a fragment of the syntax |

Reading all three still leaves you to assemble the answer. Reading hint 3 first wastes the lab, because the struggle between hints is where the learning happens.

## 5. Verify against the success criteria

The commands differ by track, and this difference is not negotiable.

**AWS track**, applies for real:

```bash
terraform init
terraform validate
terraform plan
terraform apply
# check the success criteria
terraform destroy
```

**Azure track**, plan-only:

```bash
terraform init
terraform validate
terraform plan
# stop here, compare plan output against the success criteria
```

Never run `terraform apply` on an Azure lab. See `SETUP-AZURE.md` for why.

Read the plan output rather than skimming to the summary line. Which resources are being created, in what order, and which attributes show `(known after apply)`. That last one tells you exactly what Terraform cannot resolve until provisioning happens, which is worth understanding in its own right.

## 6. Only then read the solution

Open `solutions/<track>/<lab>/SOLUTION.md` after a genuine attempt.

Compare approaches rather than checking for an exact match. Most labs have more than one valid answer, and yours working is a legitimate outcome even if it looks nothing like the reference.

The **Why not the alternative** section is usually the most valuable part of a solution, because it names the tempting wrong approach and explains concretely what breaks. If you considered that approach and rejected it, you have learned the lesson. If you considered it and chose it, this is where you find out what it costs.

## 7. Clean up

For AWS labs, always destroy before moving on:

```bash
terraform destroy
```

Leftover resources from a previous lab make the next lab's plan output confusing, and confusing plan output is the single most common way to waste an hour on these.

## 8. Mark it complete

Change `[ ]` to `[x]` in `PROGRESS.md`.

This is also how the lab generator decides what to create next, so keeping it current is worth the two seconds.

## On getting stuck

Being stuck is the point. It is also, past a certain duration, a waste of your evening. A rough guide:

| Time stuck | Action |
|---|---|
| 0 to 20 minutes | Keep going. This is the productive part |
| 20 minutes | Read the next hint |
| 40 minutes | Read the next hint, and re-read the constraints. Being stuck often means quietly violating one |
| 60 minutes | Read the solution, then redo the lab from scratch without looking |

That last step matters. Reading a solution creates the feeling of understanding without the ability to reproduce it. Redoing the lab immediately afterwards converts one into the other.

## On error messages

Terraform error messages are better than most. Read them fully before searching, including the file and line number and the `on main.tf line 12, in resource ...` context block underneath.

Two categories to distinguish:

**Your errors.** Type mismatches, missing required arguments, unresolvable references. These name a file and a line. They are the useful kind.

**LocalStack's errors.** The AWS track runs against an emulator, and some AWS provider arguments hit LocalStack APIs that are incomplete. These usually surface as an unexpected API error, a 501, or an operation that hangs. They are not your fault and teach you nothing.

If an error makes no sense given your configuration, suspect the emulator before rewriting working code. The labs deliberately stick to S3, IAM, DynamoDB, SQS and VPC primitives because those are the most stable under LocalStack, but it will still happen occasionally.
