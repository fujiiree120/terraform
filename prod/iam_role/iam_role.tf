variable "name" {}
variable "policy" {}
variable "identifier" {}

resource "aws_iam_role" "default"{
    name = var.name
    asuume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
    statement {
        action = ["sts.AssumeRole"]

        principals {
            type = "Service"
            identifiers = [var.identifier]
        }
    }
}

resource "aws_iam_policy" "default" {
  name = var.name
  policy = var.policy
}

resource "aws_iam_role_policy_attachment" "default" {
  role = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

module "ecs_task_execution_role"{
  source = "./iam_role"
  name = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy = data.aws_iam_policy_document.ecs_task_execution.json
}

output "iam_role_arn" {
  value       = aws_iam_role.default.arn
}

output "iam_role_name" {
  value       = aws_iam_role.default.name
}



